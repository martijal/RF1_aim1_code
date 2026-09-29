

/*start-header
################################################################################
# Type of File     : SAS
#
# Program Name     : 111_claims_hha_enc.sas
#			
# Program Path     : sasCCW\Files\dua_070617_jma617\code
#
# Programmed By    : Jonathan Martindale
#
# Date Created     : 05Feb2025	
#
# Project Title    : Bell-Davis RF1
#
# Purpose          : Process hha files for each storm to pull diagnosis codes to be used for ADRD identification, Elixhauser, and CFI
#
# Input files      : SH070617.hurricanes
#					 SH070617.[storm]_mbsf_elig
#					 in070617.hhabenc&pre_index_yr._r14229
#					 in070617.hharenc&pre_index_yr._r14229
#
# Output file      : SH070617.[storm]_hha_enc_pre
#
#################################################################################
end-header*/

proc contents data=IN070617.hhabenc15_r14229 varnum; run;
proc contents data=IN070617.hharenc15_r14229 varnum; run;


%macro hha_enc_storm(storm);

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

%if &pre_index_year >= 2015 %then %do;
proc freq data=in070617.hhabenc&pre_index_yr._r14229;
	format clm_from_dt BENE_DSCHRG_DT year4.;
	tables clm_from_dt BENE_DSCHRG_DT / missing;
run;


proc sql;
	create table hha_pre as
	select mbsf.bene_id
		, mbsf.storm
		, mbsf.index_date
		, mbsf.obs_start_date
		, hha.ENC_JOIN_KEY
		, hha.clm_from_dt as service_dt
		, hha.BENE_DSCHRG_DT as service_thru_dt
		, hha.CLM_CHRT_RVW_SW
		, hha.PRNCPAL_DGNS_CD
		, hha.ICD_DGNS_CD1
		, hha.ICD_DGNS_CD2
		, hha.ICD_DGNS_CD3
		, hha.ICD_DGNS_CD4
		, hha.ICD_DGNS_CD5
		, hha.ICD_DGNS_CD6
		, hha.ICD_DGNS_CD7
		, hha.ICD_DGNS_CD8
		, hha.ICD_DGNS_CD9
		, hha.ICD_DGNS_CD10
		, hha.ICD_DGNS_CD11
		, hha.ICD_DGNS_CD12
		, hha.ICD_DGNS_CD13
		, hha.ICD_DGNS_CD14
		, hha.ICD_DGNS_CD15
		, hha.ICD_DGNS_CD16
		, hha.ICD_DGNS_CD17
		, hha.ICD_DGNS_CD18
		, hha.ICD_DGNS_CD19
		, hha.ICD_DGNS_CD20
		, hha.ICD_DGNS_CD21
		, hha.ICD_DGNS_CD22
		, hha.ICD_DGNS_CD23
		, hha.ICD_DGNS_CD24
		, hha.ICD_DGNS_CD25
	from SH070617.&storm._mbsf_elig mbsf
	inner join IN070617.hhabenc&pre_index_yr._r14229 hha
	on mbsf.bene_id = hha.bene_id
	;
	
	create table hha_index as
	select mbsf.bene_id
		, mbsf.storm
		, mbsf.index_date
		, mbsf.obs_start_date
		, hha.ENC_JOIN_KEY
		, hha.clm_from_dt as service_dt
		, hha.BENE_DSCHRG_DT as service_thru_dt
		, hha.CLM_CHRT_RVW_SW
		, hha.PRNCPAL_DGNS_CD
		, hha.ICD_DGNS_CD1
		, hha.ICD_DGNS_CD2
		, hha.ICD_DGNS_CD3
		, hha.ICD_DGNS_CD4
		, hha.ICD_DGNS_CD5
		, hha.ICD_DGNS_CD6
		, hha.ICD_DGNS_CD7
		, hha.ICD_DGNS_CD8
		, hha.ICD_DGNS_CD9
		, hha.ICD_DGNS_CD10
		, hha.ICD_DGNS_CD11
		, hha.ICD_DGNS_CD12
		, hha.ICD_DGNS_CD13
		, hha.ICD_DGNS_CD14
		, hha.ICD_DGNS_CD15
		, hha.ICD_DGNS_CD16
		, hha.ICD_DGNS_CD17
		, hha.ICD_DGNS_CD18
		, hha.ICD_DGNS_CD19
		, hha.ICD_DGNS_CD20
		, hha.ICD_DGNS_CD21
		, hha.ICD_DGNS_CD22
		, hha.ICD_DGNS_CD23
		, hha.ICD_DGNS_CD24
		, hha.ICD_DGNS_CD25
	from SH070617.&storm._mbsf_elig mbsf
	inner join in070617.hhabenc&index_yr._r14229 hha
	on mbsf.bene_id = hha.bene_id
	;


proc sql;
	create table hha_rev_pre as
	select mbsf.bene_id
		, hha.ENC_JOIN_KEY
		, hha.HCPCS_CD
	from SH070617.&storm._mbsf_elig mbsf
	inner join IN070617.hharenc&pre_index_yr._r14229 hha
	on mbsf.bene_id = hha.bene_id
	;
	
	create table hha_rev_index as
	select mbsf.bene_id
		, hha.ENC_JOIN_KEY
		, hha.HCPCS_CD
	from SH070617.&storm._mbsf_elig mbsf
	inner join in070617.hharenc&index_yr._r14229 hha
	on mbsf.bene_id = hha.bene_id
	;
	
	title "number of benes in MBSF file for &storm.";
	select count(*) as storm_benes
	from SH070617.&storm._mbsf_elig
	;
	
quit;

proc sort data=hha_rev_pre; by bene_id ENC_JOIN_KEY; run;
proc sort data=hha_rev_index; by bene_id ENC_JOIN_KEY; run;
proc sort data=hha_pre; by bene_id ENC_JOIN_KEY; run;
proc sort data=hha_index; by bene_id ENC_JOIN_KEY; run;

data hha_pre_all;
	merge hha_pre(in=a) hha_rev_pre(in=b);
	by bene_id ENC_JOIN_KEY;

	_merge_clms = a;
	_merge_rev = b;
run;

data hha_index_all;
	merge hha_index(in=a) hha_rev_index(in=b);
	by bene_id ENC_JOIN_KEY;

	_merge_clms = a;
	_merge_rev = b;
run;

data hha;
	set hha_pre_all hha_index_all;
run;

proc sql;
	title "number of benes after combining and merging - hha - for &storm.";
	select count(*) as recs, count(distinct bene_id) as u_benes
	from hha
	;
quit;

data hha; 
	set hha;
	days_admit_to_index = intck("days", service_dt, index_date);
	days_dc_to_index = intck("days", service_thru_dt, index_date);
	within_dt_admit = ((obs_start_date <= service_dt) and (service_dt < index_date)); /* admission falls in window */
	within_dt_dc =  ((obs_start_date <= service_thru_dt) and (service_thru_dt < index_date)); /* or discharge falls in window */


 * per updated specs: delete records with null discharge date;
 if service_thru_dt = . then delete;
 if CLM_CHRT_RVW_SW in("Y") then delete;

run;

proc freq data=hha;
	title "check coding for &storm";
	tables CLM_CHRT_RVW_SW within_dt_admit*within_dt_dc _merge_clms*_merge_rev / list missing;
run;


data SH070617.&storm._hha_enc_pre;
set hha;

    * rename dx variables for consistency;
    array d(*) $ PRNCPAL_DGNS_CD ICD_DGNS_CD1--ICD_DGNS_CD25;
    array dx(*) $ dx1-dx26;

    do i=1 to dim(d);
        dx(i) = d(i);
    end;

	drop PRNCPAL_DGNS_CD ICD_DGNS_CD: i ;
	where within_dt_admit = 1 or within_dt_dc = 1;
run;


proc freq data=SH070617.&storm._hha_enc_pre;
	format service_dt service_thru_dt monyy7.;
	tables CLM_CHRT_RVW_SW service_dt service_thru_dt within_dt_admit*within_dt_dc / list missing;
run;

proc contents data=SH070617.&storm._hha_enc_pre varnum;
title "All hha Claims for &storm. - SH070617.&storm._hha_enc_pre"; 
run;

proc print data=SH070617.&storm._hha_enc_pre (obs=10); run;
%end;
%mend;

%hha_enc_storm(allison);
%hha_enc_storm(charley);
%hha_enc_storm(florence);
%hha_enc_storm(frances);
%hha_enc_storm(harvey);
%hha_enc_storm(ike);
%hha_enc_storm(irene);
%hha_enc_storm(irma);
%hha_enc_storm(ivan);
%hha_enc_storm(katrina);
%hha_enc_storm(matthew);
%hha_enc_storm(michael);
%hha_enc_storm(rita);
%hha_enc_storm(sandy);
%hha_enc_storm(wilma);



