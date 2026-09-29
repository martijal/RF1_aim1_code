

/*start-header
################################################################################
# Type of File     : SAS
#
# Program Name     : 105_claims_hospice_all.sas
#			
# Program Path     : sasCCW\Files\dua_070617_jma617\code
#
# Programmed By    : Jonathan Martindale
#
# Date Created     : 05Feb2025	
#
# Project Title    : Bell-Davis RF1
#
# Purpose          : Process hospice files for each storm to pull diagnosis codes to be used for ADRD identification, Elixhauser, and CFI
#
# Input files      : SH070617.hurricanes
#					 SH070617.[storm]_mbsf_elig
#					 in070617.hspcclms[year]_r14229
#
# Output file      : SH070617.[storm]_hospice_claims_pre
#
#################################################################################
end-header*/

proc contents data=sh070617.hurricanes; run;
proc print data=sh070617.hurricanes (obs=5); run;

proc contents data=in070617.hspcclms00_r14229; run;
proc print data=in070617.hspcclms00_r14229 (obs=5); run;

proc contents data=in070617.hspcclms19_r14229; run;
proc print data=in070617.hspcclms19_r14229 (obs=5); run;

%macro hospice_storm(storm);

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

proc print data=storm; title "metadata/params for &storm."; run;
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

proc freq data=in070617.hspcclms&pre_index_yr._r14229;
	format clm_from_dt CLM_THRU_DT year4.;
	tables clm_from_dt CLM_THRU_DT / missing;
run;


proc sql;
	create table hospice_pre as
	select mbsf.bene_id
		, mbsf.storm
		, mbsf.index_date
		, mbsf.obs_start_date
		, hospice.clm_from_dt as service_dt
		, hospice.CLM_THRU_DT as service_thru_dt
		, hospice.CLAIM_QUERY_CODE
		, hospice.ICD_DGNS_CD1
		, hospice.ICD_DGNS_CD2
		, hospice.ICD_DGNS_CD3
		, hospice.ICD_DGNS_CD4
		, hospice.ICD_DGNS_CD5
		, hospice.ICD_DGNS_CD6
		, hospice.ICD_DGNS_CD7
		, hospice.ICD_DGNS_CD8
		, hospice.ICD_DGNS_CD9
		, hospice.ICD_DGNS_CD10
		, hospice.ICD_DGNS_CD11
		, hospice.ICD_DGNS_CD12
		, hospice.ICD_DGNS_CD13
		, hospice.ICD_DGNS_CD14
		, hospice.ICD_DGNS_CD15
		, hospice.ICD_DGNS_CD16
		, hospice.ICD_DGNS_CD17
		, hospice.ICD_DGNS_CD18
		, hospice.ICD_DGNS_CD19
		, hospice.ICD_DGNS_CD20
		, hospice.ICD_DGNS_CD21
		, hospice.ICD_DGNS_CD22
		, hospice.ICD_DGNS_CD23
		, hospice.ICD_DGNS_CD24
		, hospice.ICD_DGNS_CD25
	from SH070617.&storm._mbsf_elig mbsf
	inner join IN070617.hspcclms&pre_index_yr._r14229 hospice
	on mbsf.bene_id = hospice.bene_id
	;
	
	create table hospice_index as
	select mbsf.bene_id
		, mbsf.storm
		, mbsf.index_date
		, mbsf.obs_start_date
		, hospice.clm_from_dt as service_dt
		, hospice.CLM_THRU_DT as service_thru_dt
		, hospice.CLAIM_QUERY_CODE
		, hospice.ICD_DGNS_CD1
		, hospice.ICD_DGNS_CD2
		, hospice.ICD_DGNS_CD3
		, hospice.ICD_DGNS_CD4
		, hospice.ICD_DGNS_CD5
		, hospice.ICD_DGNS_CD6
		, hospice.ICD_DGNS_CD7
		, hospice.ICD_DGNS_CD8
		, hospice.ICD_DGNS_CD9
		, hospice.ICD_DGNS_CD10
		, hospice.ICD_DGNS_CD11
		, hospice.ICD_DGNS_CD12
		, hospice.ICD_DGNS_CD13
		, hospice.ICD_DGNS_CD14
		, hospice.ICD_DGNS_CD15
		, hospice.ICD_DGNS_CD16
		, hospice.ICD_DGNS_CD17
		, hospice.ICD_DGNS_CD18
		, hospice.ICD_DGNS_CD19
		, hospice.ICD_DGNS_CD20
		, hospice.ICD_DGNS_CD21
		, hospice.ICD_DGNS_CD22
		, hospice.ICD_DGNS_CD23
		, hospice.ICD_DGNS_CD24
		, hospice.ICD_DGNS_CD25
	from SH070617.&storm._mbsf_elig mbsf
	inner join in070617.hspcclms&index_yr._r14229 hospice
	on mbsf.bene_id = hospice.bene_id
	;
	
	title "number of benes in MBSF file for &storm.";
	select count(*) as storm_benes
	from SH070617.&storm._mbsf_elig
	;
	
	title "number of benes in pre-index year for &storm. - hospice_pre";
	select count(*) as recs, count(distinct bene_id) as u_benes
	from hospice_pre
	;
	
	title "number of benes in index year for &storm. - hospice_index";
	select count(*) as recs, count(distinct bene_id) as u_benes
	from hospice_index
	;
quit;


data hospice;
	set hospice_pre hospice_index;
run;

data hospice; 
	set hospice;
	days_admit_to_index = intck("days", service_dt, index_date);
	days_dc_to_index = intck("days", service_thru_dt, index_date);
	within_dt_admit = ((obs_start_date <= service_dt) and (service_dt < index_date)); /* admission falls in window */
	within_dt_dc =  ((obs_start_date <= service_thru_dt) and (service_thru_dt < index_date)); /* or discharge falls in window */

/*	where CLAIM_QUERY_CODE in("3");*/
run;

proc freq data=hospice;
	tables CLAIM_QUERY_CODE within_dt_admit*within_dt_dc / list missing;
run;


data SH070617.&storm._hospice_claims_pre;
set hospice;

    * rename dx variables for consistency;
    array d(*) $ ICD_DGNS_CD1--ICD_DGNS_CD25;
    array dx(*) $ dx1-dx25;

    do i=1 to dim(d);
        dx(i) = d(i);
    end;

	drop ICD_DGNS_CD: i ;
	where CLAIM_QUERY_CODE in("3") and (within_dt_admit = 1 or within_dt_dc = 1);
run;



proc freq data=SH070617.&storm._hospice_claims_pre;
	format service_dt service_thru_dt monyy7.;
	tables CLAIM_QUERY_CODE service_dt service_thru_dt within_dt_admit*within_dt_dc / list missing;
run;

proc contents data=SH070617.&storm._hospice_claims_pre varnum;
title "All hospice Claims for &storm. - SH070617.&storm._hospice_claims_pre"; 
run;

proc print data=SH070617.&storm._hospice_claims_pre (obs=10); run;

%mend;

%hospice_storm(allison);
%hospice_storm(charley);
%hospice_storm(florence);
%hospice_storm(frances);
%hospice_storm(harvey);
%hospice_storm(ike);
%hospice_storm(irene);
%hospice_storm(irma);
%hospice_storm(ivan);
%hospice_storm(katrina);
%hospice_storm(matthew);
%hospice_storm(michael);
%hospice_storm(rita);
%hospice_storm(sandy);
%hospice_storm(wilma);



