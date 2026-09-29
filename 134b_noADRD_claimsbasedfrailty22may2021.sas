
/*start-header
################################################################################
# Type of File     : SAS
#
# Program Name     : 134_claimsbasedfrailty22may2021.sas
#
# Program Path     : sasccw
#
# Programmed By    : Jonathan Martindale
#
# Date Created     : 18Apr2025
# 
# Project Title    : Bell-Davis RF1
# 
# Purpose		   : Generate CFI score for each storm.
#
# Input files      : SH070617.[storm]_[source]_hcpcs_long
#					 SH070617.[storm]_[source]_icd9_long
#					 SH070617.[storm]_[source]_icd10_long
#					 SH070617.disease_weights (from CFI)
#					 SH070617.icd10_score (from CFI)
#					 SH070617.icd9_score (from CFI)
#					 SH070617.px_score (from CFI)
#
# Output files     : SH070617.[storm]_frailty_score
#
################################################################################
end-header*/

*options ls=120 ps=64 nocenter nodate nonumber pagesize=6500 nofullstimer mprint msglevel=i;



options ps=54 ls=72 obs=max pageno=1 compress=yes;
%let DemDx9=( '2900', '2901',' 29010', '29011', '29012', '29013' ,'2902', '29020', '29021', '2903', '2904', '29040',
  '29041', '29042', '29043', '2941', '29410', '29411', '2942', '29420', '29421', '331', '3310', '33111', '33119',
  '33182', '2908', '2940', '3312', '3317', '3318', '33189', '797');


**************************************;
* sample datasets:    variables:      ;
* 1.ids               bene_id           ;
* 2.dx09              bene_id, dx(icd9) ;
* 3.dx10              bene_id, dx(icd10);
* 4.px                bene_id, px(CPT4) ;
**************************************;

**************************************;
* Import the procedure disease nums   ;
* Skip first header row               ;
**************************************;
data px_score;
	set SH070617.px_score;
run;

**************************************;
* Import the ICD-9 diagnosis mapping  ;
* Skip first header row               ;
**************************************;
data icd9_score;
	set SH070617.icd9_score;
run;

**************************************;
* Add weights                         ;
**************************************;
proc sql;
  create table icd9_weights as
    select dis.dx, dis.disease_number, wgt.weight
    from icd9_score dis, SH070617.disease_weight wgt
    where dis.disease_number = wgt.disease_number;
quit;

**************************************;
* Import the ICD-10 diagnosis mapping ;
* Skip first header row               ;
**************************************;
data icd10_score;
	set SH070617.icd10_score;
run;

**************************************;
* Add weights                         ;
**************************************;
proc sql;
  create table icd10_weights as
    select dis.dx, dis.disease_number, wgt.weight
    from icd10_score dis, SH070617.disease_weight wgt
    where dis.disease_number = wgt.disease_number;
quit;

**********************************************;
* cpt4 procedures format for frailty disease  ;
**********************************************;

data master;
  length label $5;
  set px_score;
  label = left(put(disease_number, 2.));
  drop disease_number;
run;

data other;
  start = 'other';
  end   = 'other';
  label = 'other';
run;

data study_px;
  set master(rename=(range_min=start range_max=end))
      other;
  fmtname = '$study_px';
run;

proc format cntlin=study_px;
run;


/* Start macro for each storm */

%macro run_cfi(storm, source);

/* create dataset for IDs */
data ids;
	set SH070617.&storm._mbsf_elig (keep=bene_id);
run;

**********************************************;
* Assign a disease number to each procedure   ;
* Keep only rows having a mapped value        ;
**********************************************;
data score_px;
  set SH070617.&storm._&source._hcpcs_long(rename=(hcpcs_cd=px) keep=bene_id hcpcs_cd);
  class = put(px, $study_px.);
  if class ne 'other';
  last_d = substr(left(px),5,1);
  if last_d = ' '  or last_d = '0'  or last_d = '1'  or last_d ='2' or
     last_d = '3'  or last_d = '4'  or last_d = '5'  or last_d ='6' or
     last_d = '7'  or last_d = '8'  or last_d = '9';
  drop last_d;
run;

*****************************;
* frailty procedure weight   ;
*****************************;

data weight;
  set SH070617.disease_weight;
  class = left(put(disease_number, 2.));
  keep class weight;
run;

proc sort data=weight;
  by class;
run;

data score;
  set score_px;
  keep bene_id class;
run;

proc sort nodupkey data=score;
  by bene_id class;
run;

proc sort data=score;
  by class;
run;

*****************************;
* Assign a weight to each    ;
*****************************;
data scores_px;
  merge score(in=in1)
        weight(in=in2);
  by class;
  if in1 and in2;
run;

*******************************************;
* link icd10/disease/weight to             ;
* prior icd10 dx                           ;
*******************************************;
data dx10;
	set SH070617.&storm._&source._icd10_long;

	dx3 = substr(dx, 1, 3);
	dx4 = substr(dx, 1, 4);

	adrd_dx = 0; 
	if dx3 in("F01", "F02", "F03", "G30", "F04", "G39", "R54") then adrd_dx = 1;
	if dx in("G3101", "G3109", "G310", "G311", "G3183", "R4181", "F068", "G312", "F061", "G138", "G3184", "G3189", "G319") then adrd_dx = 1;

	if adrd_dx = 1 then delete;
run;

proc freq data=dx10;
	title "check no ADRD dx for dx10 - &storm.";
	tables adrd_dx / missing;
run;

proc sql;
  create table score_dx10(keep=bene_id dx disease_number weight) as
    select dx10.bene_id, diag.dx, diag.disease_number, diag.weight
    from icd10_weights diag, dx10
    where diag.dx = dx10.dx;
quit;

data score_10;
  set score_dx10;
  class = left(put(disease_number, 2.));
  keep bene_id class weight;
run;

proc sort nodupkey data=score_10;
  by bene_id class;
run;

*******************************************;
* link icd9/disease/weight to              ;
* prior icd9 dx                            ;
*******************************************;
data dx09;
	set SH070617.&storm._&source._icd9_long;

	adrd_dx = 0;
	if dx in &DemDx9. then adrd_dx = 1;

	if adrd_dx = 1 then delete;
run;

proc freq data=dx09;
	title "check no ADRD dx for dx9 - &storm.";
	tables adrd_dx / missing;
run;

proc sql;
  create table score_dx09(keep=bene_id dx disease_number weight) as
    select dx09.bene_id, diag.dx, diag.disease_number, diag.weight
    from icd9_weights diag, dx09
    where diag.dx = dx09.dx;
quit;

data score_09;
  set score_dx09;
  class = left(put(disease_number, 2.));
  keep bene_id class weight;
run;

proc sort nodupkey data=score_09;
  by bene_id class;
run;

*******************************************;
* Combine the procedure, ICD-10 and ICD-9  ;
* weighted files                           ;
*******************************************;
data scores;
  set scores_px
      score_10
      score_09;
  keep bene_id class weight;
run;

proc sort nodupkey data=scores;
  by bene_id class;
run;

*******************************************;
* Add up the weights per patient           ;
*******************************************;
data count;
  set scores;
  by bene_id;
  if first.bene_id then score = 0.10288;
  score + weight;
  if last.bene_id then output;
  keep bene_id score;
run;

*******************************************;
* Ensure all patients in the ids data have ;
* a score. If a patient does not have any  ;
* PX or DX, then default model score is    ;
* assigned.                                ;
*******************************************;
data SH070617.&storm._&source.cfi_alt;
  merge ids(in=in1 keep=bene_id)
        count(in=in2);
  by bene_id;
  if in1;
  if not in2 then score = 0.10288;
  keep bene_id score;
run;

proc sql;
	title "original numbers for &storm. - SH070617.&storm._mbsf_elig";
	select count(*) as recs, count(distinct bene_id) as u_benes
	from SH070617.&storm._mbsf_elig
	;
quit;

proc means data=SH070617.&storm._&source.cfi_alt;
	title "final scores for SH070617.&storm._&source.cfi_alt";
    var score;
run;



%mend run_cfi;


%run_cfi(allison, claims);

%run_cfi(charley, claims);

%run_cfi(florence, claims);
%run_cfi(florence, enc);

%run_cfi(frances, claims);

%run_cfi(harvey, claims);
%run_cfi(harvey, enc);

%run_cfi(ike, claims);

%run_cfi(irene, claims);

%run_cfi(irma, claims);
%run_cfi(irma, enc);

%run_cfi(ivan, claims);

%run_cfi(katrina, claims);

%run_cfi(matthew, claims);
%run_cfi(matthew, enc);

%run_cfi(michael, claims);
%run_cfi(michael, enc);

%run_cfi(rita, claims);

%run_cfi(sandy, claims);

%run_cfi(wilma, claims);
