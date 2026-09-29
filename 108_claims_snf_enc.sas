

/*start-header
################################################################################
# Type of File     : SAS
#
# Program Name     : 108_claims_snf_enc.sas
#			
# Program Path     : sasCCW\Files\dua_070617_jma617\code
#
# Programmed By    : Jonathan Martindale
#
# Date Created     : 05Feb2025	
#
# Project Title    : Bell-Davis RF1
#
# Purpose          : Process snf files for each storm to pull diagnosis codes to be used for ADRD identification, Elixhauser, and CFI
#
# Input files      : SH070617.hurricanes
#					 SH070617.[storm]_mbsf_elig
#					 in070617.snfclms[year]_r14229
#
# Output file      : SH070617.[storm]_snf_enc_pre
#
#################################################################################
end-header*/


%macro snf_enc_storm(storm);

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
proc freq data=in070617.snfbenc&pre_index_yr._r14229;
	format clm_from_dt bene_dschrg_dt year4.;
	tables clm_from_dt bene_dschrg_dt / missing;
run;


proc sql;
	create table snf_pre as
	select mbsf.bene_id
		, mbsf.storm
		, mbsf.index_date
		, mbsf.obs_start_date
		, snf.ENC_JOIN_KEY
		, snf.clm_from_dt as service_dt
		, snf.bene_dschrg_dt as service_thru_dt
		, snf.CLM_CHRT_RVW_SW
		, snf.ADMTG_DGNS_CD
		, snf.ICD_DGNS_CD1
		, snf.ICD_DGNS_CD2
		, snf.ICD_DGNS_CD3
		, snf.ICD_DGNS_CD4
		, snf.ICD_DGNS_CD5
		, snf.ICD_DGNS_CD6
		, snf.ICD_DGNS_CD7
		, snf.ICD_DGNS_CD8
		, snf.ICD_DGNS_CD9
		, snf.ICD_DGNS_CD10
		, snf.ICD_DGNS_CD11
		, snf.ICD_DGNS_CD12
		, snf.ICD_DGNS_CD13
		, snf.ICD_DGNS_CD14
		, snf.ICD_DGNS_CD15
		, snf.ICD_DGNS_CD16
		, snf.ICD_DGNS_CD17
		, snf.ICD_DGNS_CD18
		, snf.ICD_DGNS_CD19
		, snf.ICD_DGNS_CD20
		, snf.ICD_DGNS_CD21
		, snf.ICD_DGNS_CD22
		, snf.ICD_DGNS_CD23
		, snf.ICD_DGNS_CD24
		, snf.ICD_DGNS_CD25
	from SH070617.&storm._mbsf_elig mbsf
	inner join IN070617.snfbenc&pre_index_yr._r14229 snf
	on mbsf.bene_id = snf.bene_id
	;
	
	create table snf_index as
	select mbsf.bene_id
		, mbsf.storm
		, mbsf.index_date
		, mbsf.obs_start_date
		, snf.ENC_JOIN_KEY
		, snf.clm_from_dt as service_dt
		, snf.bene_dschrg_dt as service_thru_dt
		, snf.CLM_CHRT_RVW_SW
		, snf.ADMTG_DGNS_CD
		, snf.ICD_DGNS_CD1
		, snf.ICD_DGNS_CD2
		, snf.ICD_DGNS_CD3
		, snf.ICD_DGNS_CD4
		, snf.ICD_DGNS_CD5
		, snf.ICD_DGNS_CD6
		, snf.ICD_DGNS_CD7
		, snf.ICD_DGNS_CD8
		, snf.ICD_DGNS_CD9
		, snf.ICD_DGNS_CD10
		, snf.ICD_DGNS_CD11
		, snf.ICD_DGNS_CD12
		, snf.ICD_DGNS_CD13
		, snf.ICD_DGNS_CD14
		, snf.ICD_DGNS_CD15
		, snf.ICD_DGNS_CD16
		, snf.ICD_DGNS_CD17
		, snf.ICD_DGNS_CD18
		, snf.ICD_DGNS_CD19
		, snf.ICD_DGNS_CD20
		, snf.ICD_DGNS_CD21
		, snf.ICD_DGNS_CD22
		, snf.ICD_DGNS_CD23
		, snf.ICD_DGNS_CD24
		, snf.ICD_DGNS_CD25
	from SH070617.&storm._mbsf_elig mbsf
	inner join in070617.snfbenc&index_yr._r14229 snf
	on mbsf.bene_id = snf.bene_id
	;


proc sql;
	create table snf_rev_pre as
	select mbsf.bene_id
		, snf.ENC_JOIN_KEY
		, snf.HCPCS_CD
	from SH070617.&storm._mbsf_elig mbsf
	inner join IN070617.snfrenc&pre_index_yr._r14229 snf
	on mbsf.bene_id = snf.bene_id
	;
	
	create table snf_rev_index as
	select mbsf.bene_id
		, snf.ENC_JOIN_KEY
		, snf.HCPCS_CD
	from SH070617.&storm._mbsf_elig mbsf
	inner join in070617.snfrenc&index_yr._r14229 snf
	on mbsf.bene_id = snf.bene_id
	;
	
	title "number of benes in MBSF file for &storm.";
	select count(*) as storm_benes
	from SH070617.&storm._mbsf_elig
	;
	
quit;

proc sort data=snf_rev_pre; by bene_id ENC_JOIN_KEY; run;
proc sort data=snf_rev_index; by bene_id ENC_JOIN_KEY; run;
proc sort data=snf_pre; by bene_id ENC_JOIN_KEY; run;
proc sort data=snf_index; by bene_id ENC_JOIN_KEY; run;

data snf_pre_all;
	merge snf_pre(in=a) snf_rev_pre(in=b);
	by bene_id ENC_JOIN_KEY;

	_merge_clms = a;
	_merge_rev = b;
run;

data snf_index_all;
	merge snf_index(in=a) snf_rev_index(in=b);
	by bene_id ENC_JOIN_KEY;

	_merge_clms = a;
	_merge_rev = b;
run;

data snf;
	set snf_pre_all snf_index_all;
run;

proc sql;
	title "number of benes after combining and merging - snf - for &storm.";
	select count(*) as recs, count(distinct bene_id) as u_benes
	from snf
	;
quit;

data snf; 
	set snf;
	days_admit_to_index = intck("days", service_dt, index_date);
	days_dc_to_index = intck("days", service_thru_dt, index_date);
	within_dt_admit = ((obs_start_date <= service_dt) and (service_dt < index_date)); /* admission falls in window */
	within_dt_dc =  ((obs_start_date <= service_thru_dt) and (service_thru_dt < index_date)); /* or discharge falls in window */


 * per updated specs: delete records with null discharge date;
 if service_thru_dt = . then delete;
 if CLM_CHRT_RVW_SW in("Y") then delete;

run;

proc freq data=snf;
	title "check coding for &storm";
	tables CLM_CHRT_RVW_SW within_dt_admit*within_dt_dc _merge_clms*_merge_rev / list missing;
run;


data SH070617.&storm._snf_enc_pre;
set snf;

    * rename dx variables for consistency;
    array d(*) $ ADMTG_DGNS_CD ICD_DGNS_CD1--ICD_DGNS_CD25;
    array dx(*) $ dx1-dx26;

    do i=1 to dim(d);
        dx(i) = d(i);
    end;

	drop ADMTG_DGNS_CD ICD_DGNS_CD: i ;
	where within_dt_admit = 1 or within_dt_dc = 1;
run;


proc freq data=SH070617.&storm._snf_enc_pre;
	format service_dt service_thru_dt monyy7.;
	tables CLM_CHRT_RVW_SW service_dt service_thru_dt within_dt_admit*within_dt_dc / list missing;
run;

proc contents data=SH070617.&storm._snf_enc_pre varnum;
title "All snf Claims for &storm. - SH070617.&storm._snf_enc_pre"; 
run;

proc print data=SH070617.&storm._snf_enc_pre (obs=10); run;
%end;
%mend;

%snf_enc_storm(allison);
%snf_enc_storm(charley);
%snf_enc_storm(florence);
%snf_enc_storm(frances);
%snf_enc_storm(harvey);
%snf_enc_storm(ike);
%snf_enc_storm(irene);
%snf_enc_storm(irma);
%snf_enc_storm(ivan);
%snf_enc_storm(katrina);
%snf_enc_storm(matthew);
%snf_enc_storm(michael);
%snf_enc_storm(rita);
%snf_enc_storm(sandy);
%snf_enc_storm(wilma);



