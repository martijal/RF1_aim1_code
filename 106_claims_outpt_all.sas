

/*start-header
################################################################################
# Type of File     : SAS
#
# Program Name     : 106_claims_outpt_ffs_all.sas
#			
# Program Path     : sasCCW\Files\dua_070617_jma617\code
#
# Programmed By    : Jonathan Martindale
#
# Date Created     : 17Feb2025	
#
# Project Title    : Bell-Davis RF1
#
# Purpose          : Process outpt files for each storm to pull diagnosis codes to be used for ADRD identification, Elixhauser, and CFI
#
# Input files      : SH070617.hurricanes
#					 SH070617.[storm]_mbsf_elig
#					 in070617.OTPTCLMS00_R14229 - in070617.OTPTCLMS19_R14229
#					 in070617.OTPTREV00_R14229 - in070617.OTPTREV19_R14229
#
# Output file      : SH070617.[storm]_outpt_claims_pre
#
#################################################################################
end-header*/



%macro outpt_storm(storm);

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

proc print data=storm; title "Metadata/parameters for &storm"; run;
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


proc sql;
	create table outpt_rev_pre as
	select mbsf.bene_id
		, mbsf.storm
		, mbsf.index_date
		, mbsf.obs_start_date
		, outpt.clm_id
		, outpt.rev_cntr_dt
		, outpt.rev_cntr
		, outpt.HCPCS_CD
	from SH070617.&storm._mbsf_elig mbsf
	inner join IN070617.OTPTREV&pre_index_yr._r14229 outpt
	on mbsf.bene_id = outpt.bene_id
	;

	create table outpt_clms_pre as
	select mbsf.bene_id
		, mbsf.storm
		, mbsf.index_date
		, mbsf.obs_start_date
		, outpt.clm_id
		, outpt.CLAIM_QUERY_CODE
		, outpt.clm_from_dt as service_dt
		, outpt.CLM_THRU_DT as service_thru_dt
		, outpt.clm_fac_type_cd
		, outpt.clm_srvc_clsfctn_type_cd
		, outpt.prncpal_dgns_cd
		, outpt.ICD_DGNS_CD1
		, outpt.ICD_DGNS_CD2
		, outpt.ICD_DGNS_CD3
		, outpt.ICD_DGNS_CD4
		, outpt.ICD_DGNS_CD5
		, outpt.ICD_DGNS_CD6
		, outpt.ICD_DGNS_CD7
		, outpt.ICD_DGNS_CD8
		, outpt.ICD_DGNS_CD9
		, outpt.ICD_DGNS_CD10
		, outpt.ICD_DGNS_CD11
		, outpt.ICD_DGNS_CD12
		, outpt.ICD_DGNS_CD13
		, outpt.ICD_DGNS_CD14
		, outpt.ICD_DGNS_CD15
		, outpt.ICD_DGNS_CD16
		, outpt.ICD_DGNS_CD17
		, outpt.ICD_DGNS_CD18
		, outpt.ICD_DGNS_CD19
		, outpt.ICD_DGNS_CD20
		, outpt.ICD_DGNS_CD21
		, outpt.ICD_DGNS_CD22
		, outpt.ICD_DGNS_CD23
		, outpt.ICD_DGNS_CD24
		, outpt.ICD_DGNS_CD25
	from SH070617.&storm._mbsf_elig mbsf
	inner join IN070617.OTPTCLMS&pre_index_yr._r14229 outpt
	on mbsf.bene_id = outpt.bene_id
	;


	create table outpt_rev_index as
	select mbsf.bene_id
		, mbsf.storm
		, mbsf.index_date
		, mbsf.obs_start_date
		, outpt.clm_id
		, outpt.rev_cntr_dt
		, outpt.rev_cntr
	from SH070617.&storm._mbsf_elig mbsf
	inner join IN070617.OTPTREV&index_yr._r14229 outpt
	on mbsf.bene_id = outpt.bene_id
	;
	
	create table outpt_clms_index as
	select mbsf.bene_id
		, mbsf.storm
		, mbsf.index_date
		, mbsf.obs_start_date
		, outpt.clm_id
		, outpt.CLAIM_QUERY_CODE
		, outpt.clm_from_dt as service_dt
		, outpt.CLM_THRU_DT as service_thru_dt
		, outpt.prvdr_num
		, outpt.clm_fac_type_cd
		, outpt.clm_srvc_clsfctn_type_cd
		, outpt.prncpal_dgns_cd
		, outpt.ICD_DGNS_CD1
		, outpt.ICD_DGNS_CD2
		, outpt.ICD_DGNS_CD3
		, outpt.ICD_DGNS_CD4
		, outpt.ICD_DGNS_CD5
		, outpt.ICD_DGNS_CD6
		, outpt.ICD_DGNS_CD7
		, outpt.ICD_DGNS_CD8
		, outpt.ICD_DGNS_CD9
		, outpt.ICD_DGNS_CD10
		, outpt.ICD_DGNS_CD11
		, outpt.ICD_DGNS_CD12
		, outpt.ICD_DGNS_CD13
		, outpt.ICD_DGNS_CD14
		, outpt.ICD_DGNS_CD15
		, outpt.ICD_DGNS_CD16
		, outpt.ICD_DGNS_CD17
		, outpt.ICD_DGNS_CD18
		, outpt.ICD_DGNS_CD19
		, outpt.ICD_DGNS_CD20
		, outpt.ICD_DGNS_CD21
		, outpt.ICD_DGNS_CD22
		, outpt.ICD_DGNS_CD23
		, outpt.ICD_DGNS_CD24
		, outpt.ICD_DGNS_CD25
	from SH070617.&storm._mbsf_elig mbsf
	inner join in070617.OTPTCLMS&index_yr._r14229 outpt
	on mbsf.bene_id = outpt.bene_id
	;
quit;

/* sort, merge, and append datasets */
proc sort data=outpt_rev_index; by bene_id clm_id; run;
proc sort data=outpt_clms_index; by bene_id clm_id; run;
proc sort data=outpt_rev_pre; by bene_id clm_id; run;
proc sort data=outpt_clms_pre; by bene_id clm_id; run;

data outpt_pre;
	merge outpt_rev_pre(in=a) outpt_clms_pre(in=b);
	by bene_id clm_id;

	_merge_rev = a;
	_merge_clms = b;
run;

data outpt_index;
	merge outpt_rev_index(in=a) outpt_clms_index(in=b);
	by bene_id clm_id;

	_merge_rev = a;
	_merge_clms = b;
run;

proc freq data=outpt_pre;
	title "check outpt_pre merge for &storm.";
	tables _merge_rev*_merge_clms / list missing;
run;

proc freq data=outpt_index;
	title "check outpt_index merge for &storm.";
	tables _merge_rev*_merge_clms / list missing;
run;

data outpt;
	set outpt_pre outpt_index;
run;

proc sql;	
	title "number of benes in MBSF file for &storm.";
	select count(*) as storm_benes
	from SH070617.&storm._mbsf_elig
	;
	
	title "number of benes in file for &storm. - outpt";
	select count(*) as recs, count(distinct bene_id) as u_benes
	from outpt
	;

quit;


data outpt; 
	set outpt;
	bill_type = clm_fac_type_cd || clm_srvc_clsfctn_type_cd;

	RHC_FQHC = 0; CAH_opt2 = 0;
	if bill_type in("71", "73", "77") then RHC_FQHC=1;
	if bill_type in("13", "85") and ('0960' <= rev_cntr <= '0989') then CAH_opt2=1;

	if service_dt = . then service_dt = REV_CNTR_DT;
	if service_thru_dt = . then service_thru_dt = service_dt;

	days_admit_to_index = intck("days", service_dt, index_date);
	days_dc_to_index = intck("days", service_thru_dt, index_date);
	within_dt_admit = ((obs_start_date <= service_dt) and (service_dt < index_date)); /* admission falls in window */
	within_dt_dc =  ((obs_start_date <= service_thru_dt) and (service_thru_dt < index_date)); /* or discharge falls in window */

/*	where CLAIM_QUERY_CODE in("3");*/
run;

proc freq data=outpt;
	tables CLAIM_QUERY_CODE within_dt_admit*within_dt_dc
		RHC_FQHC CAH_opt2 / list missing;
run;


data SH070617.&storm._outpt_claims_pre;
set outpt;

    * rename dx variables for consistency;
    array d(*) $ prncpal_dgns_cd ICD_DGNS_CD1--ICD_DGNS_CD25;
    array dx(*) $ dx1-dx26;

    do i=1 to dim(d);
        dx(i) = d(i);
    end;

	drop ICD_DGNS_CD: i ;
	where CLAIM_QUERY_CODE in("3") and (within_dt_admit = 1 or within_dt_dc = 1);
run;



proc freq data=SH070617.&storm._outpt_claims_pre;
	format service_dt service_thru_dt monyy7.;
	tables CLAIM_QUERY_CODE service_dt service_thru_dt within_dt_admit*within_dt_dc / list missing;
run;

proc contents data=SH070617.&storm._outpt_claims_pre varnum;
title "All outpt Claims for &storm. - SH070617.&storm._outpt_claims_pre"; 
run;

proc print data=SH070617.&storm._outpt_claims_pre (obs=10); run;

%mend;

%outpt_storm(allison);
%outpt_storm(charley);
%outpt_storm(florence);
%outpt_storm(frances);
%outpt_storm(harvey);
%outpt_storm(ike);
%outpt_storm(irene);
%outpt_storm(irma);
%outpt_storm(ivan);
%outpt_storm(katrina);
%outpt_storm(matthew);
%outpt_storm(michael);
%outpt_storm(rita);
%outpt_storm(sandy);
%outpt_storm(wilma);



