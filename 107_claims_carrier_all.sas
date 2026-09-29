

/*start-header
################################################################################
# Type of File     : SAS
#
# Program Name     : 106_claims_carrier_ffs_all.sas
#			
# Program Path     : sasCCW\Files\dua_070617_jma617\code
#
# Programmed By    : Jonathan Martindale
#
# Date Created     : 20Feb2025	
#
# Project Title    : Bell-Davis RF1
#
# Purpose          : Process carrier files for each storm to pull diagnosis codes to be used for ADRD identification, Elixhauser, and CFI
#
# Input files      : SH070617.hurricanes
#					 SH070617.[storm]_mbsf_elig
#					 in070617.BCARCLMS00_R14229 - in070617.BCARCLMS19_R14229
#					 in070617.BCARLINE00_R14229 - in070617.BCARLINE19_R14229
#
# Output file      : SH070617.[storm]_carrier_claims_pre
#
#################################################################################
end-header*/



%macro carrier_storm(storm);

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
	create table carrier_line_pre as
	select mbsf.bene_id
		, mbsf.storm
		, mbsf.index_date
		, mbsf.obs_start_date
		, carrier.clm_id
		, carrier.LINE_ICD_DGNS_CD
		, carrier.LINE_1ST_EXPNS_DT
		, carrier.LINE_PRCSG_IND_CD
		, carrier.LINE_ALOWD_CHRG_AMT
		, carrier.HCPCS_CD
		, carrier.BETOS_CD
	from SH070617.&storm._mbsf_elig mbsf
	inner join IN070617.BCARLINE&pre_index_yr._r14229 carrier
	on mbsf.bene_id = carrier.bene_id
	;

	create table carrier_clms_pre as
	select mbsf.bene_id
		, mbsf.storm
		, mbsf.index_date
		, mbsf.obs_start_date
		, carrier.clm_id
		, carrier.clm_from_dt as service_dt
		, carrier.CLM_THRU_DT as service_thru_dt
		, carrier.ICD_DGNS_CD1
		, carrier.ICD_DGNS_CD2
		, carrier.ICD_DGNS_CD3
		, carrier.ICD_DGNS_CD4
		, carrier.ICD_DGNS_CD5
		, carrier.ICD_DGNS_CD6
		, carrier.ICD_DGNS_CD7
		, carrier.ICD_DGNS_CD8
		, carrier.ICD_DGNS_CD9
		, carrier.ICD_DGNS_CD10
		, carrier.ICD_DGNS_CD11
		, carrier.ICD_DGNS_CD12
	from SH070617.&storm._mbsf_elig mbsf
	inner join IN070617.BCARCLMS&pre_index_yr._r14229 carrier
	on mbsf.bene_id = carrier.bene_id
	;


	create table carrier_line_index as
	select mbsf.bene_id
		, mbsf.storm
		, mbsf.index_date
		, mbsf.obs_start_date
		, carrier.clm_id
		, carrier.LINE_ICD_DGNS_CD
		, carrier.LINE_1ST_EXPNS_DT
		, carrier.LINE_PRCSG_IND_CD
		, carrier.LINE_ALOWD_CHRG_AMT
		, carrier.HCPCS_CD
		, carrier.BETOS_CD
	from SH070617.&storm._mbsf_elig mbsf
	inner join IN070617.BCARLINE&index_yr._r14229 carrier
	on mbsf.bene_id = carrier.bene_id
	;
	
	create table carrier_clms_index as
	select mbsf.bene_id
		, mbsf.storm
		, mbsf.index_date
		, mbsf.obs_start_date
		, carrier.clm_id
		, carrier.clm_from_dt as service_dt
		, carrier.CLM_THRU_DT as service_thru_dt
		, carrier.ICD_DGNS_CD1
		, carrier.ICD_DGNS_CD2
		, carrier.ICD_DGNS_CD3
		, carrier.ICD_DGNS_CD4
		, carrier.ICD_DGNS_CD5
		, carrier.ICD_DGNS_CD6
		, carrier.ICD_DGNS_CD7
		, carrier.ICD_DGNS_CD8
		, carrier.ICD_DGNS_CD9
		, carrier.ICD_DGNS_CD10
		, carrier.ICD_DGNS_CD11
		, carrier.ICD_DGNS_CD12
	from SH070617.&storm._mbsf_elig mbsf
	inner join in070617.BCARCLMS&index_yr._r14229 carrier
	on mbsf.bene_id = carrier.bene_id
	;
quit;

/* sort, merge, and append datasets */
proc sort data=carrier_line_index; by bene_id clm_id; run;
proc sort data=carrier_clms_index; by bene_id clm_id; run;
proc sort data=carrier_line_pre; by bene_id clm_id; run;
proc sort data=carrier_clms_pre; by bene_id clm_id; run;

data carrier_pre;
	merge carrier_line_pre(in=a) carrier_clms_pre(in=b);
	by bene_id clm_id;

	_merge_line = a;
	_merge_clms = b;
run;

data carrier_index;
	merge carrier_line_index(in=a) carrier_clms_index(in=b);
	by bene_id clm_id;

	_merge_line = a;
	_merge_clms = b;
run;

proc freq data=carrier_pre;
	title "check carrier_pre merge for &storm.";
	tables _merge_line*_merge_clms / list missing;
run;

proc freq data=carrier_index;
	title "check carrier_index merge for &storm.";
	tables _merge_line*_merge_clms / list missing;
run;

data carrier;
	set carrier_pre carrier_index;
run;

proc sql;	
	title "number of benes in MBSF file for &storm.";
	select count(*) as storm_benes
	from SH070617.&storm._mbsf_elig
	;
	
	title "number of benes in file for &storm. - carrier";
	select count(*) as recs, count(distinct bene_id) as u_benes
	from carrier
	;

quit;


data carrier; 
	set carrier;
	

	if service_dt = . then service_dt = LINE_1ST_EXPNS_DT;
	if service_thru_dt = . then service_thru_dt = service_dt;

	days_admit_to_index = intck("days", service_dt, index_date);
	days_dc_to_index = intck("days", service_thru_dt, index_date);
	within_dt_admit = ((obs_start_date <= service_dt) and (service_dt < index_date)); /* admission falls in window */
	within_dt_dc =  ((obs_start_date <= service_thru_dt) and (service_thru_dt < index_date)); /* or discharge falls in window */

	if line_prcsg_ind_cd in("I", "M", "R") or line_alowd_chrg_amt <= 0 then delete;
run;

proc freq data=carrier;
	title "check claim type and date calculations for &storm.";
	tables line_prcsg_ind_cd within_dt_admit*within_dt_dc
	 / list missing;
run;


data SH070617.&storm._carrier_claims_pre;
set carrier;

    * rename dx variables for consistency;
    array d(*) $ LINE_ICD_DGNS_CD ICD_DGNS_CD1--ICD_DGNS_CD12;
    array dx(*) $ dx1-dx13;

    do i=1 to dim(d);
        dx(i) = d(i);
    end;

	drop LINE_ICD_DGNS_CD ICD_DGNS_CD: i ;
	where (within_dt_admit = 1 or within_dt_dc = 1);
run;



proc freq data=SH070617.&storm._carrier_claims_pre;
	format service_dt service_thru_dt monyy7.;
	tables  service_dt service_thru_dt within_dt_admit*within_dt_dc / list missing;
run;

proc contents data=SH070617.&storm._carrier_claims_pre varnum;
title "All carrier Claims for &storm. - SH070617.&storm._carrier_claims_pre"; 
run;

proc print data=SH070617.&storm._carrier_claims_pre (obs=10); run;

%mend;

%carrier_storm(allison);
%carrier_storm(charley);
%carrier_storm(florence);
%carrier_storm(frances);
%carrier_storm(harvey);
%carrier_storm(ike);
%carrier_storm(irene);
%carrier_storm(irma);
%carrier_storm(ivan);
%carrier_storm(katrina);
%carrier_storm(matthew);
%carrier_storm(michael);
%carrier_storm(rita);
%carrier_storm(sandy);
%carrier_storm(wilma);



