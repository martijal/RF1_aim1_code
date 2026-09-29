

/*start-header
################################################################################
# Type of File     : SAS
#
# Program Name     : 132_elix_bene
#
# Program Path     : sasccw
#
# Programmed By    : Jonathan Martindale
#
# Date Created     : 03Apr2025
# 
# Project Title    : Bell-Davis RF1
# 
# Purpose		   : Generate bene-level ELixhauser datasets for each storm.
#
# Input files      : SH070617.hurricanes, 
#					SH070617.&storm._elix9_&file._&source.
#					SH070617.&storm._elix10_&file._&source.
#					SH070617.&storm._mbsf_elig
#
# Output files     : combined Outpatient and Carrier claims for Elixhauser (claims_elix_ob_all)
#                    only including claims that are at least 7 days apart per condition
#
################################################################################
end-header*/

*options ls=120 ps=64 nocenter nodate nonumber pagesize=6500 nofullstimer mprint msglevel=i;

proc contents data=SH070617.hurricanes; run;

%macro elix_all_source(storm, source);

proc sql;
	create table storm as
	select distinct storm, year as index_year
	from SH070617.hurricanes hurr
	where lowcase(hurr.storm) in("&storm")
	;
quit;

data storm;
	set storm;
	format pre_index_yr index_yr $2.;
	
	pre_index_year = index_year - 1;
	pre_index_year_str = put(pre_index_year, 4.);
	index_year_str = put(index_year, 4.);
	
	pre_index_yr = substrn(pre_index_year_str, 3, 2);
	index_yr = substrn(index_year_str, 3, 2);
	
	drop pre_index_year_str index_year_str;
run;

proc print data=storm; title "Metadata/params for &storm."; run;
proc contents data=storm; run;
	
proc sql noprint;
select index_yr
	, pre_index_yr
	, index_year
	, pre_index_year
	into  :index_yr trimmed
		, :pre_index_yr trimmed
		, :index_year trimmed
		, :pre_index_year trimmed
from storm
;
quit;

/* limit to datasets where we will need to run ICD9 */
%if &pre_index_year. <= 2015 %then %do;

* convert Elix9 dataset into standardized conditions per specs;
* file = file abbreviation used in first pass on Elixhauser coding: medpar, hha, outpt, prtb;
* year = full calendar year (e.g., 2015);

%macro recode_elix_9(file);
data &storm._elix9_&file._&source.;
    set SH070617.&storm._elix9_&file._&source.;

    length  CMR_AIDS_R      CMR_ALCOHOL_R   CMR_ANEMDEF_R   CMR_AUTOIMMUNE_R
            CMR_BLDLOSS_R   CMR_CANCER_R    CMR_CBVD_R      CMR_COAG_R
            CMR_DEPRESS_R   CMR_DIAB_R      CMR_DRUG_ABUSE_R
            CMR_HF_R        CMR_HTN_R       CMR_LIVER_R     CMR_LUNG_CHRONIC_R
            CMR_NEURO_R     CMR_OBESE_R     CMR_PARALYSIS_R CMR_PERIVASC_R
            CMR_PSYCHOSES_R CMR_PULMCIRC_R  CMR_RENLFL_R    CMR_THYROID_R
            CMR_ULCER_PEPTIC_R              CMR_VALVE_R     CMR_WGHTLOSS_R 
            3.;


    array d(*) CMR_AIDS_R      CMR_ALCOHOL_R   CMR_ANEMDEF_R   CMR_AUTOIMMUNE_R
            CMR_BLDLOSS_R   CMR_CANCER_R    CMR_CBVD_R      CMR_COAG_R
            CMR_DEPRESS_R   CMR_DIAB_R      CMR_DRUG_ABUSE_R
            CMR_HF_R        CMR_HTN_R       CMR_LIVER_R     CMR_LUNG_CHRONIC_R
            CMR_NEURO_R     CMR_OBESE_R     CMR_PARALYSIS_R CMR_PERIVASC_R
            CMR_PSYCHOSES_R CMR_PULMCIRC_R  CMR_RENLFL_R    CMR_THYROID_R
            CMR_ULCER_PEPTIC_R              CMR_VALVE_R     CMR_WGHTLOSS_R 
            ;
    do i=1 to dim(d);
        d(i) = 0;
    end;

    if aids=1 then cmr_aids_r=1;
    if alcohol=1 then cmr_alcohol_r=1;
    if anemdef=1 then cmr_anemdef_r=1;
    if arth=1 then cmr_autoimmune_r=1;
    if bldloss=1 then cmr_bldloss_r=1;
    if (lymph=1 or mets=1 or tumor=1) then cmr_cancer_r=1;
    cmr_cbvd_r=0;
    if coag=1 then cmr_coag_r=1;
    if depress=1 then cmr_depress_r=1;
    if (dm=1 or dmcx=1) then cmr_diab_r=1;
    if drug=1 then cmr_drug_abuse_r=1;
    if chf=1 then cmr_hf_r=1;
    if htn_c=1 then cmr_htn_r=1;
    if liver=1 then cmr_liver_r=1;
    if chrnlung=1 then cmr_lung_chronic_r=1;
    if neuro=1 then cmr_neuro_r=1;
    if obese=1 then cmr_obese_r=1;
    if para=1 then cmr_paralysis_r=1;
    if perivasc=1 then cmr_perivasc_r=1;
    if psych=1 then cmr_psychoses_r=1;
    if pulmcirc=1 then cmr_pulmcirc_r=1;
    if renlfail=1 then cmr_renlfl_r=1;
    if hypothy=1 then cmr_thyroid_r=1;
    if ulcer=1 then cmr_ulcer_peptic_r=1;
    if valve=1 then cmr_valve_r=1;
    if wghtloss=1 then CMR_WGHTLOSS_R=1;

run;


/*proc freq data=&storm._elix9_&file._&source.;*/
/*    title "checking coding for elix9_&file._&source.";*/
/*    tables */
/*        CMR_AIDS_R*AIDS*/
/*        CMR_ALCOHOL_R*ALCOHOL*/
/*        CMR_ANEMDEF_R*ANEMDEF*/
/*        CMR_AUTOIMMUNE_R*ARTH*/
/*        CMR_BLDLOSS_R*BLDLOSS*/
/*        CMR_CANCER_R*LYMPH*METS*TUMOR*/
/*        CMR_COAG_R*COAG*/
/*        CMR_DEPRESS_R*DEPRESS*/
/*        CMR_DIAB_R*DM*DMCX*/
/*        CMR_DRUG_ABUSE_R*DRUG*/
/*        CMR_HF_R*CHF*/
/*        CMR_HTN_R*HTN_C*/
/*        CMR_LIVER_R*LIVER*/
/*        CMR_LUNG_CHRONIC_R*CHRNLUNG*/
/*        CMR_NEURO_R*NEURO*/
/*        CMR_OBESE_R*OBESE*/
/*        CMR_PARALYSIS_R*PARA*/
/*        CMR_PERIVASC_R*PERIVASC*/
/*        CMR_PSYCHOSES_R*PSYCH*/
/*        CMR_PULMCIRC_R*PULMCIRC*/
/*        CMR_RENLFL_R*RENLFAIL*/
/*        CMR_THYROID_R*HYPOTHY*/
/*        CMR_ULCER_PEPTIC_R*ULCER*/
/*        CMR_VALVE_R*VALVE*/
/*        CMR_WGHTLOSS_R*WGHTLOSS*/
/*        / list missing;*/
/*run;*/

data &storm._elix9_&file._&source. 
    (keep=bene_id service_dt include 
    CMR_AIDS_R      CMR_ALCOHOL_R   CMR_ANEMDEF_R   CMR_AUTOIMMUNE_R
    CMR_BLDLOSS_R   CMR_CANCER_R    CMR_CBVD_R      CMR_COAG_R
    CMR_DEPRESS_R   CMR_DIAB_R      CMR_DRUG_ABUSE_R
    CMR_HF_R        CMR_HTN_R       CMR_LIVER_R     CMR_LUNG_CHRONIC_R
    CMR_NEURO_R     CMR_OBESE_R     CMR_PARALYSIS_R CMR_PERIVASC_R
    CMR_PSYCHOSES_R CMR_PULMCIRC_R  CMR_RENLFL_R    CMR_THYROID_R
    CMR_ULCER_PEPTIC_R              CMR_VALVE_R     CMR_WGHTLOSS_R )
    ;
    set &storm._elix9_&file._&source.;
run;

proc contents data=&storm._elix9_&file._&source.;
	title "Confirm correct data for &storm._elix9_&file._&source.";
run;
proc print data=&storm._elix9_&file._&source. (obs=10); run;

%mend;

%if "&source." = "claims" %then %do;
	%recode_elix_9(medpar);
	%recode_elix_9(hha);
	%recode_elix_9(hospice);
	%recode_elix_9(outpt);
	%recode_elix_9(carrier);
%end;

%if "&source." = "enc" %then %do;
	%recode_elix_9(ip);
	%recode_elix_9(snf);
	%recode_elix_9(hha);
	%recode_elix_9(outpt);
	%recode_elix_9(carrier);
%end;

%end;


/* limit to datasets where we will need to run ICD10 */
%if &pre_index_year. >= 2015 %then %do;

%macro recode_elix_10(file);

data &storm._elix10_&file._&source.;
    set SH070617.&storm._elix10_&file._&source.;

    length  CMR_AIDS_R      CMR_ALCOHOL_R   CMR_ANEMDEF_R   CMR_AUTOIMMUNE_R
            CMR_BLDLOSS_R   CMR_CANCER_R    CMR_CBVD_R      CMR_COAG_R
            CMR_DEPRESS_R   CMR_DIAB_R      CMR_DRUG_ABUSE_R
            CMR_HF_R        CMR_HTN_R       CMR_LIVER_R     CMR_LUNG_CHRONIC_R
            CMR_NEURO_R     CMR_OBESE_R     CMR_PARALYSIS_R CMR_PERIVASC_R
            CMR_PSYCHOSES_R CMR_PULMCIRC_R  CMR_RENLFL_R    CMR_THYROID_R
            CMR_ULCER_PEPTIC_R              CMR_VALVE_R     CMR_WGHTLOSS_R 
            3.;
    length data_source $3.;

    if lowcase("&file") = "outpt" then data_source = "OPT";
    if lowcase("&file") = "medpar" then data_source = "MED";
    if lowcase("&file") = "carrier" then data_source = "PTB";
    if lowcase("&file") = "hha" then data_source = "HHA";
	if lowcase("&file") = "ip" then data_source = "IP";
	if lowcase("&file") = "snf" then data_source = "SNF";


    array d(*) CMR_AIDS_R      CMR_ALCOHOL_R   CMR_ANEMDEF_R   CMR_AUTOIMMUNE_R
            CMR_BLDLOSS_R   CMR_CANCER_R    CMR_CBVD_R      CMR_COAG_R
            CMR_DEPRESS_R   CMR_DIAB_R      CMR_DRUG_ABUSE_R
            CMR_HF_R        CMR_HTN_R       CMR_LIVER_R     CMR_LUNG_CHRONIC_R
            CMR_NEURO_R     CMR_OBESE_R     CMR_PARALYSIS_R CMR_PERIVASC_R
            CMR_PSYCHOSES_R CMR_PULMCIRC_R  CMR_RENLFL_R    CMR_THYROID_R
            CMR_ULCER_PEPTIC_R              CMR_VALVE_R     CMR_WGHTLOSS_R 
            ;

    do i=1 to dim(d);
        d(i) = 0;
    end;

    if CMR_AIDS=1 then CMR_AIDS_R=1;
    if CMR_ALCOHOL=1 then CMR_ALCOHOL_R=1;
    if CMR_ANEMDEF=1 then CMR_ANEMDEF_R=1;
    if CMR_AUTOIMMUNE=1 then CMR_AUTOIMMUNE_R=1;
    if CMR_BLDLOSS=1 then CMR_BLDLOSS_R=1;
    if (CMR_CANCER_LYMPH=1 or CMR_CANCER_METS=1 or CMR_CANCER_LEUK=1 
        or CMR_CANCER_NSITU=1 or CMR_CANCER_SOLID=1) then CMR_CANCER_R=1;
    if CMR_CBVD=1 then CMR_CBVD_R=1;
    if CMR_COAG=1 then CMR_COAG_R=1;
    if CMR_DEPRESS=1 then CMR_DEPRESS_R=1;
    if (CMR_DIAB_UNCX=1 or CMR_DIAB_CX=1) then CMR_DIAB_R=1;
    if CMR_DRUG_ABUSE=1 then CMR_DRUG_ABUSE_R=1;
    if CMR_HF=1 then CMR_HF_R=1;
    if (CMR_HTN_CX=1 or CMR_HTN_UNCX=1) then CMR_HTN_R=1;
    if (CMR_LIVER_MLD=1 or CMR_LIVER_SEV=1) then CMR_LIVER_R=1;
    if CMR_LUNG_CHRONIC=1 then CMR_LUNG_CHRONIC_R=1;
    if (CMR_DEMENTIA=1 or CMR_NEURO_MOVT=1 or CMR_NEURO_OTH=1 or CMR_NEURO_SEIZ=1) then CMR_NEURO_R=1;
    if CMR_OBESE=1 then CMR_OBESE_R=1;
    if CMR_PARALYSIS=1 then CMR_PARALYSIS_R=1;
    if CMR_PERIVASC=1 then CMR_PERIVASC_R=1;
    if CMR_PSYCHOSES=1 then CMR_PSYCHOSES_R=1;
    if CMR_PULMCIRC=1 then CMR_PULMCIRC_R=1;
    if (CMR_RENLFL_MOD=1 or CMR_RENLFL_SEV=1) then CMR_RENLFL_R=1;
    if (CMR_THYROID_HYPO=1 or CMR_THYROID_OTH=1) then CMR_THYROID_R=1;
    if CMR_ULCER_PEPTIC=1 then CMR_ULCER_PEPTIC_R=1;
    if CMR_VALVE=1 then CMR_VALVE_R=1;
    if CMR_WGHTLOSS=1 then CMR_WGHTLOSS_R=1;

run;


/*proc freq data=&storm._elix10_&file._&source.;*/
/*    tables */
/*        CMR_AIDS*CMR_AIDS_R*/
/*        CMR_ALCOHOL*CMR_ALCOHOL_R*/
/*        CMR_ANEMDEF*CMR_ANEMDEF_R*/
/*        CMR_AUTOIMMUNE*CMR_AUTOIMMUNE_R*/
/*        CMR_BLDLOSS*CMR_BLDLOSS_R*/
/*        CMR_CANCER_LYMPH*CMR_CANCER_METS*CMR_CANCER_LEUK**/
/*            CMR_CANCER_NSITU*CMR_CANCER_SOLID*CMR_CANCER_R*/
/*        CMR_CBVD*CMR_CBVD_R*/
/*        CMR_COAG*CMR_COAG_R*/
/*        CMR_DEPRESS*CMR_DEPRESS_R*/
/*        CMR_DIAB_UNCX*CMR_DIAB_CX*CMR_DIAB_R*/
/*        CMR_DRUG_ABUSE*CMR_DRUG_ABUSE_R*/
/*        CMR_HF*CMR_HF_R*/
/*        CMR_HTN_CX*CMR_HTN_UNCX*CMR_HTN_R*/
/*        CMR_LIVER_MLD*CMR_LIVER_SEV*CMR_LIVER_R*/
/*        CMR_LUNG_CHRONIC*CMR_LUNG_CHRONIC_R*/
/*        CMR_DEMENTIA*CMR_NEURO_MOVT*CMR_NEURO_OTH*CMR_NEURO_SEIZ*CMR_NEURO_R*/
/*        CMR_OBESE*CMR_OBESE_R*/
/*        CMR_PARALYSIS*CMR_PARALYSIS_R*/
/*        CMR_PERIVASC*CMR_PERIVASC_R*/
/*        CMR_PSYCHOSES*CMR_PSYCHOSES_R*/
/*        CMR_PULMCIRC*CMR_PULMCIRC_R*/
/*        CMR_RENLFL_MOD*CMR_RENLFL_SEV*CMR_RENLFL_R*/
/*        CMR_THYROID_HYPO*CMR_THYROID_OTH*CMR_THYROID_R*/
/*        CMR_ULCER_PEPTIC*CMR_ULCER_PEPTIC_R*/
/*        CMR_VALVE*CMR_VALVE_R*/
/*        CMR_WGHTLOSS*CMR_WGHTLOSS_R*/
/*        data_source*/
/*        / list missing;*/
/*run;*/

data &storm._elix10_&file._&source.
    (keep=bene_id service_dt include data_source
    CMR_AIDS_R      CMR_ALCOHOL_R   CMR_ANEMDEF_R   CMR_AUTOIMMUNE_R
    CMR_BLDLOSS_R   CMR_CANCER_R    CMR_CBVD_R      CMR_COAG_R
    CMR_DEPRESS_R   CMR_DIAB_R      CMR_DRUG_ABUSE_R
    CMR_HF_R        CMR_HTN_R       CMR_LIVER_R     CMR_LUNG_CHRONIC_R
    CMR_NEURO_R     CMR_OBESE_R     CMR_PARALYSIS_R CMR_PERIVASC_R
    CMR_PSYCHOSES_R CMR_PULMCIRC_R  CMR_RENLFL_R    CMR_THYROID_R
    CMR_ULCER_PEPTIC_R              CMR_VALVE_R     CMR_WGHTLOSS_R )
    ;
    set &storm._elix10_&file._&source.;
run;

proc contents data=&storm._elix10_&file._&source.;
	title "Confirm correct data for &storm._elix10_&file._&source.";
run;
proc print data=&storm._elix10_&file._&source. (obs=10); run;

%mend;

%if "&source." = "claims" %then %do;
	%recode_elix_10(medpar);
	%recode_elix_10(hha);
	%recode_elix_10(hospice);
	%recode_elix_10(outpt);
	%recode_elix_10(carrier);
%end;

%if "&source." = "enc" %then %do;
	%recode_elix_10(ip);
	%recode_elix_10(snf);
	%recode_elix_10(hha);
	%recode_elix_10(outpt);
	%recode_elix_10(carrier);
%end;

%end;

/* based on year, combine correct files for processing */
%if &pre_index_year. = 2015 %then %do;
data elix_ob;
    set &storm._elix9_outpt_&source.
	&storm._elix9_carrier_&source.
	&storm._elix10_outpt_&source.
	&storm._elix10_carrier_&source.
        ;
    format Service_Dt date9.;
run;
%end;

%if &pre_index_year. > 2015 %then %do;
data elix_ob;
    set 
	&storm._elix10_outpt_&source.
	&storm._elix10_carrier_&source.
        ;
    format Service_Dt date9.;
run;
%end;


%if &pre_index_year. < 2015 %then %do;
data elix_ob;
    set 
	&storm._elix9_outpt_&source.
	&storm._elix9_carrier_&source.
        ;
    format Service_Dt date9.;
run;
%end;

proc contents data=elix_ob; run;
proc print data=elix_ob(obs=10); run;

proc sort data=elix_ob;
    by bene_id service_dt;
run;

* master file with all benes and dates of service to merge variable flags back on to;
data elix_ob_master(keep=bene_id service_dt);
    set elix_ob;
run;


* start macro to process individual variables;
%macro process_vrbl(vrbl);

data elix_temp (keep=Bene_id service_dt &vrbl.);
    set elix_ob;
    where &vrbl.=1;
run;

data elix_temp;
    set elix_temp;
    rowid = monotonic();
run;

proc sql;
  create table bo1 as
  select bene_id, rowid as rowid1, service_dt as service_dt1
  from elix_temp
  ;

  create table bo2 as
  select bene_id, rowid as rowid2, service_dt as service_dt2
  from elix_temp
  ;

  create table bo12 as
  select a.bene_id, a.rowid1, a.service_dt1, b.rowid2, b.service_dt2, 
  ((b.service_dt2 - a.service_dt1) + 1) as interval 
  from bo1 a, bo2 b
  where a.bene_id = b.bene_id
    and b.service_dt2 - a.service_dt1 >= 7
    and b.service_dt2 - a.service_dt1 <= 365
  order by bene_id,rowid1,rowid2;
quit;


* merge back on to temp dataset;
proc sql;
  create table bo_final_1 as
  select a.*
  from elix_temp a, bo12 b
  where a.bene_id=b.bene_id
    and a.rowid=b.rowid1;
quit;


proc sql;
  create table bo_final_2 as
  select a.*
  from elix_temp a, bo12 b
  where a.bene_id=b.bene_id
    and a.rowid=b.rowid2;
quit;


* combine datasets to make sure we get all claims 7+ days apart;
data bo_final (keep=bene_id service_dt &vrbl.);
  set bo_final_1 bo_final_2;
  &vrbl. = 1;
run;

/* remove duplicates */
proc sort data=bo_final nodup; by bene_id service_dt; run;


* check that we got the right results;
/*proc print data=Elix_temp(obs=20);*/
/*    title1 "check that correct obs were kept";*/
/*    title2 "original for &vrbl.";*/
/*run;*/
/**/
/**/
/*proc print data=bo_final(obs=20); */
/*    title2 "Final";*/
/*run;*/


/*proc sql;*/
/*    title "number of claims and benes from ORIGINAL where &vrbl. = 1";*/
/*    select count(*) as o_cnt_clms_&vrbl., count(distinct bene_id) as o_u_bene_&vrbl.*/
/*    from elix_temp*/
/*    ;*/
/**/
/*    title "number of claims and benes from FINAL where &vrbl. = 1";*/
/*    select count(*) as o_cnt_clms_&vrbl., count(distinct bene_id) as o_u_bene_&vrbl.*/
/*    from bo_final*/
/*    ;*/
/*quit;*/

* Merge back on to base;
data elix_ob_master;
    merge elix_ob_master bo_final;
    by bene_id service_dt;
run;

%mend;
%process_vrbl(CMR_AIDS_R)       %process_vrbl(CMR_ALCOHOL_R)   
%process_vrbl(CMR_ANEMDEF_R)     %process_vrbl(CMR_AUTOIMMUNE_R)
%process_vrbl(CMR_BLDLOSS_R)     %process_vrbl(CMR_CANCER_R)
%process_vrbl(CMR_CBVD_R)        %process_vrbl(CMR_COAG_R)
%process_vrbl(CMR_DEPRESS_R)   
%process_vrbl(CMR_DIAB_R)      %process_vrbl(CMR_DRUG_ABUSE_R)
%process_vrbl(CMR_HF_R)        %process_vrbl(CMR_HTN_R)
%process_vrbl(CMR_LIVER_R)     %process_vrbl(CMR_LUNG_CHRONIC_R)
%process_vrbl(CMR_NEURO_R)     %process_vrbl(CMR_OBESE_R)
%process_vrbl(CMR_PARALYSIS_R) %process_vrbl(CMR_PERIVASC_R)
%process_vrbl(CMR_PSYCHOSES_R) %process_vrbl(CMR_PULMCIRC_R)  
%process_vrbl(CMR_RENLFL_R)    %process_vrbl(CMR_THYROID_R)
%process_vrbl(CMR_ULCER_PEPTIC_R)              
%process_vrbl(CMR_VALVE_R)     %process_vrbl(CMR_WGHTLOSS_R)


proc sql;
    title "check that we start and end with the same number of rows and benes";
    select count(*) as cnt_ob_elix_clms, count(distinct bene_id) as u_elix_ob_benes
    from elix_ob
    ;

    select count(*) as f_cnt_ob_elix_clms, count(distinct bene_id) as f_u_elix_ob_benes
    from elix_ob_master
    ;
quit;


data &storm._elix_ob_&source.;
    set elix_ob_master;

    length  CMR_AIDS_R      CMR_ALCOHOL_R   CMR_ANEMDEF_R   CMR_AUTOIMMUNE_R
            CMR_BLDLOSS_R   CMR_CANCER_R    CMR_CBVD_R      CMR_COAG_R
            CMR_DEPRESS_R   CMR_DIAB_R      CMR_DRUG_ABUSE_R
            CMR_HF_R        CMR_HTN_R       CMR_LIVER_R     CMR_LUNG_CHRONIC_R
            CMR_NEURO_R     CMR_OBESE_R     CMR_PARALYSIS_R CMR_PERIVASC_R
            CMR_PSYCHOSES_R CMR_PULMCIRC_R  CMR_RENLFL_R    CMR_THYROID_R
            CMR_ULCER_PEPTIC_R              CMR_VALVE_R     CMR_WGHTLOSS_R 
            3.;
    length data_source $3.;

    data_source="OB";

    label   CMR_AIDS_R = "Elixhauser Recoded Comorbidity: AIDS"
            CMR_ALCOHOL_R = "Elixhauser Recoded Comorbidity: Alochol abuse"
            CMR_ANEMDEF_R = "Elixhauser Recoded Comorbidity: Deficiency anemias"
            CMR_AUTOIMMUNE_R = "Elixhauser Recoded Comorbidity: Autoimmune conditions"
            CMR_BLDLOSS_R = "Elixhauser Recoded Comorbidity: Chronic blood loss anemia"
            CMR_CANCER_R = "Elixhauser Recoded Comorbidity: All Cancer conditions"
            CMR_CBVD_R = "Elixhauser Recoded Comorbidity: Cerebrovascular disease"
            CMR_COAG_R = "Elixhauser Recoded Comorbidity: Coagulopathy"
            CMR_DEPRESS_R = "Elixhauser Recoded Comorbidity: Depression"
            CMR_DIAB_R = "Elixhauser Recoded Comorbidity: All diabetes conditions"
            CMR_DRUG_ABUSE_R = "Elixhauser Recoded Comorbidity: Drug abuse"
            CMR_HF_R = "Elixhauser Recoded Comorbidity: (Congestive) heart failure"
            CMR_HTN_R = "Elixhauser Recoded Comorbidity: All hypertension conditions"
            CMR_LIVER_R = "Elixhauser Recoded Comorbidity: All liver disease conditions"
            CMR_LUNG_CHRONIC_R = "Elixhauser Recoded Comorbidity: Chronic pulminary disease"
            CMR_NEURO_R = "Elixhauser Recoded Comorbidity: All Neuro conditions and Dementia"
            CMR_OBESE_R = "Elixhauser Recoded Comorbidity:  Obesity"
            CMR_PARALYSIS_R = "Elixhauser Recoded Comorbidity: Paralysis"
            CMR_PERIVASC_R = "Elixhauser Recoded Comorbidity: Peripheral vascular disease"
            CMR_PSYCHOSES_R = "Elixhauser Recoded Comorbidity: Psychoses"
            CMR_PULMCIRC_R = "Elixhauser Recoded Comorbidity: Pulmonary circulation disease"
            CMR_RENLFL_R = "Elixhauser Recoded Comorbidity: All renal failure conditions"
            CMR_THYROID_R = "Elixhauser Recoded Comorbidity: All thyroid conditions"
            CMR_ULCER_PEPTIC_R = "Elixhauser Recoded Comorbidity: Peptic ulcer with bleeding"
            CMR_VALVE_R = "Elixhauser Recoded Comorbidity: Valvular disease"
            CMR_WGHTLOSS_R = "Elixhauser Recoded Comorbidity: Weight loss"
            data_source = "source of data. Med=Medpar, HHA=Home Health, OB=Office Based (carrier+outpt)"
            ;

    array d(*) CMR_AIDS_R      CMR_ALCOHOL_R   CMR_ANEMDEF_R   CMR_AUTOIMMUNE_R
            CMR_BLDLOSS_R   CMR_CANCER_R    CMR_CBVD_R      CMR_COAG_R
            CMR_DEPRESS_R   CMR_DIAB_R      CMR_DRUG_ABUSE_R
            CMR_HF_R        CMR_HTN_R       CMR_LIVER_R     CMR_LUNG_CHRONIC_R
            CMR_NEURO_R     CMR_OBESE_R     CMR_PARALYSIS_R CMR_PERIVASC_R
            CMR_PSYCHOSES_R CMR_PULMCIRC_R  CMR_RENLFL_R    CMR_THYROID_R
            CMR_ULCER_PEPTIC_R              CMR_VALVE_R     CMR_WGHTLOSS_R 
            ;
    do i=1 to dim(d);
        if d(i) = . then d(i) = 0;
    end;

    if sum (of CMR_AIDS_R      CMR_ALCOHOL_R   CMR_ANEMDEF_R   CMR_AUTOIMMUNE_R
            CMR_BLDLOSS_R   CMR_CANCER_R    CMR_CBVD_R      CMR_COAG_R
            CMR_DEPRESS_R   CMR_DIAB_R      CMR_DRUG_ABUSE_R
            CMR_HF_R        CMR_HTN_R       CMR_LIVER_R     CMR_LUNG_CHRONIC_R
            CMR_NEURO_R     CMR_OBESE_R     CMR_PARALYSIS_R CMR_PERIVASC_R
            CMR_PSYCHOSES_R CMR_PULMCIRC_R  CMR_RENLFL_R    CMR_THYROID_R
            CMR_ULCER_PEPTIC_R              CMR_VALVE_R     CMR_WGHTLOSS_R)
            = 0 then delete;
run;


proc contents data=&storm._elix_ob_&source.; 
    title "checking final OB file for elixhauser";
run;
proc print data=&storm._elix_ob_&source.(obs=10);

proc freq data=&storm._elix_ob_&source.;
    tables CMR_AIDS_R      CMR_ALCOHOL_R   CMR_ANEMDEF_R   CMR_AUTOIMMUNE_R
            CMR_BLDLOSS_R   CMR_CANCER_R    CMR_CBVD_R      CMR_COAG_R
            CMR_DEPRESS_R   CMR_DIAB_R      CMR_DRUG_ABUSE_R
            CMR_HF_R        CMR_HTN_R       CMR_LIVER_R     CMR_LUNG_CHRONIC_R
            CMR_NEURO_R     CMR_OBESE_R     CMR_PARALYSIS_R CMR_PERIVASC_R
            CMR_PSYCHOSES_R CMR_PULMCIRC_R  CMR_RENLFL_R    CMR_THYROID_R
            CMR_ULCER_PEPTIC_R              CMR_VALVE_R     CMR_WGHTLOSS_R
            data_source
            / list missing;
run;


proc sql;
    title "number of claims and benes BEFORE removing ineligible claims (0 comob)";
    select count(*) as ob_elix_clms, count(distinct bene_id) as ob_elix_benes
    from elix_ob_master
    ;

    title "final number of claims and benes after removing ineligible claims (0 comob)";
    select count(*) as ob_elix_clms, count(distinct bene_id) as ob_elix_benes
    from &storm._elix_ob_&source.
    ;
quit;


/* based on year, combine correct files for processing */
%if "&source." = "claims" %then %do;
	%if &pre_index_year. = 2015 %then %do;
	data elix_all;
	    set &storm._elix_ob_&source.
		&storm._elix9_hha_&source.
		&storm._elix9_hospice_&source.
		&storm._elix9_medpar_&source.
		&storm._elix10_hha_&source.
		&storm._elix10_hospice_&source.
		&storm._elix10_medpar_&source.
	        ;
	    format Service_Dt date9.;
	run;
	%end;

	%if &pre_index_year. > 2015 %then %do;
	data elix_all;
	    set 
		&storm._elix_ob_&source.
		&storm._elix10_hha_&source.
		&storm._elix10_hospice_&source.
		&storm._elix10_medpar_&source.
	        ;
	    format Service_Dt date9.;
	run;
	%end;


	%if &pre_index_year. < 2015 %then %do;
	data elix_all;
	    set 
		&storm._elix_ob_&source.
		&storm._elix9_hha_&source.
		&storm._elix9_hospice_&source.
		&storm._elix9_medpar_&source.
	        ;
	    format Service_Dt date9.;
	run;
	%end;
%end;

%if "&source." = "enc" %then %do;
	%if &pre_index_year. = 2015 %then %do;
	data elix_all;
	    set &storm._elix_ob_&source.
		&storm._elix9_hha_&source.
		&storm._elix9_ip_&source.
		&storm._elix9_snf_&source.
		&storm._elix10_hha_&source.
		&storm._elix10_ip_&source.
		&storm._elix10_snf_&source.
	        ;
	    format Service_Dt date9.;
	run;
	%end;

	%if &pre_index_year. > 2015 %then %do;
	data elix_all;
	    set 
		&storm._elix_ob_&source.
		&storm._elix10_hha_&source.
		&storm._elix10_ip_&source.
		&storm._elix10_snf_&source.
	        ;
	    format Service_Dt date9.;
	run;
	%end;

%end;



proc sql;
    create table elix_agg as
    select  bene_id, 
            max(CMR_AIDS_R) as CMR_AIDS_R,
            max(CMR_ALCOHOL_R) as CMR_ALCOHOL_R,
			max(CMR_AUTOIMMUNE_R) as CMR_AUTOIMMUNE_R,
            max(CMR_BLDLOSS_R) as CMR_BLDLOSS_R,
            max(CMR_DEPRESS_R) as CMR_DEPRESS_R,
            max(CMR_HF_R) as CMR_HF_R,
            max(CMR_NEURO_R) as CMR_NEURO_R,
            max(CMR_PSYCHOSES_R) as CMR_PSYCHOSES_R,
            max(CMR_ULCER_PEPTIC_R) as CMR_ULCER_PEPTIC_R,
            max(CMR_ANEMDEF_R) as CMR_ANEMDEF_R,
            max(CMR_CANCER_R) as CMR_CANCER_R,
            max(CMR_DIAB_R) as CMR_DIAB_R,
            max(CMR_HTN_R) as CMR_HTN_R,
            max(CMR_OBESE_R) as CMR_OBESE_R,
            max(CMR_PULMCIRC_R) as CMR_PULMCIRC_R,
            max(CMR_VALVE_R) as CMR_VALVE_R,
            max(CMR_CBVD_R) as CMR_CBVD_R,
            max(CMR_DRUG_ABUSE_R) as CMR_DRUG_ABUSE_R,
            max(CMR_LIVER_R) as CMR_LIVER_R,
            max(CMR_PARALYSIS_R) as CMR_PARALYSIS_R,
            max(CMR_RENLFL_R) as CMR_RENLFL_R,
            max(CMR_WGHTLOSS_R) as CMR_WGHTLOSS_R,
            max(CMR_COAG_R) as CMR_COAG_R,
            max(CMR_LUNG_CHRONIC_R) as CMR_LUNG_CHRONIC_R,
            max(CMR_PERIVASC_R) as CMR_PERIVASC_R,
            max(CMR_THYROID_R) as CMR_THYROID_R
    from elix_all
    group by bene_id
    ;
quit;


data SH070617.&storm._elix_agg_&source.;
	merge SH070617.&storm._mbsf_elig (in=a keep=bene_id)
	elix_agg;
	by bene_id;
	if a;
run;

proc sql;

	title "check numbers - SH070617.&storm._mbsf_elig";
	select count(*) as recs, count(distinct bene_id) as u_benes
	from SH070617.&storm._mbsf_elig
	;

	title "check numbers - SH070617.&storm._elix_agg_&source.";
	select count(*) as recs, count(distinct bene_id) as u_benes
	from SH070617.&storm._elix_agg_&source.
	;
quit;


data SH070617.&storm._elix_agg_&source.;
    set SH070617.&storm._elix_agg_&source.;

    label   CMR_AIDS_R = "Elixhauser Recoded Comorbidity: AIDS"
            CMR_ALCOHOL_R = "Elixhauser Recoded Comorbidity: Alochol abuse"
            CMR_ANEMDEF_R = "Elixhauser Recoded Comorbidity: Deficiency anemias"
			CMR_AUTOIMMUNE_R = "Elixhauser Recoded Comoribidity: Autoimmune disorders/arthritis"
            CMR_BLDLOSS_R = "Elixhauser Recoded Comorbidity: Chronic blood loss anemia"
            CMR_CANCER_R = "Elixhauser Recoded Comorbidity: All Cancer conditions"
            CMR_CBVD_R = "Elixhauser Recoded Comorbidity: Cerebrovascular disease"
            CMR_COAG_R = "Elixhauser Recoded Comorbidity: Coagulopathy"
            CMR_DEPRESS_R = "Elixhauser Recoded Comorbidity: Depression"
            CMR_DIAB_R = "Elixhauser Recoded Comorbidity: All diabetes conditions"
            CMR_DRUG_ABUSE_R = "Elixhauser Recoded Comorbidity: Drug abuse"
            CMR_HF_R = "Elixhauser Recoded Comorbidity: (Congestive) heart failure"
            CMR_HTN_R = "Elixhauser Recoded Comorbidity: All hypertension conditions"
            CMR_LIVER_R = "Elixhauser Recoded Comorbidity: All liver disease conditions"
            CMR_LUNG_CHRONIC_R = "Elixhauser Recoded Comorbidity: Chronic pulminary disease"
            CMR_NEURO_R = "Elixhauser Recoded Comorbidity: All Neuro conditions and Dementia"
            CMR_OBESE_R = "Elixhauser Recoded Comorbidity:  Obesity"
            CMR_PARALYSIS_R = "Elixhauser Recoded Comorbidity: Paralysis"
            CMR_PERIVASC_R = "Elixhauser Recoded Comorbidity: Peripheral vascular disease"
            CMR_PSYCHOSES_R = "Elixhauser Recoded Comorbidity: Psychoses"
            CMR_PULMCIRC_R = "Elixhauser Recoded Comorbidity: Pulmonary circulation disease"
            CMR_RENLFL_R = "Elixhauser Recoded Comorbidity: All renal failure conditions"
            CMR_THYROID_R = "Elixhauser Recoded Comorbidity: All thyroid conditions"
            CMR_ULCER_PEPTIC_R = "Elixhauser Recoded Comorbidity: Peptic ulcer with bleeding"
            CMR_VALVE_R = "Elixhauser Recoded Comorbidity: Valvular disease"
            CMR_WGHTLOSS_R = "Elixhauser Recoded Comorbidity: Weight loss"
            ;

    array d(*) CMR_:
            ;
    do i=1 to dim(d);
        if d(i) = . then d(i) = 0;
    end;

    drop i;
run;



proc contents data=SH070617.&storm._elix_agg_&source.; title "final file - SH070617.&storm._elix_agg_&source.";
proc means data=SH070617.&storm._elix_agg_&source.; run;

/* remove datasets from work */
proc datasets library=work;
    delete  &storm.: BO: ELIX:
            ;
quit;


%mend;



%elix_all_source(allison, claims);

%elix_all_source(charley, claims);

%elix_all_source(florence, claims);
%elix_all_source(florence, enc);

%elix_all_source(frances, claims);

%elix_all_source(harvey, claims);
%elix_all_source(harvey, enc);

%elix_all_source(ike, claims);

%elix_all_source(irene, claims);

%elix_all_source(irma, claims);
%elix_all_source(irma, enc);

%elix_all_source(ivan, claims);

%elix_all_source(katrina, claims);

%elix_all_source(matthew, claims);
%elix_all_source(matthew, enc);

%elix_all_source(michael, claims);
%elix_all_source(michael, enc);

%elix_all_source(rita, claims);

%elix_all_source(sandy, claims);

%elix_all_source(wilma, claims);
