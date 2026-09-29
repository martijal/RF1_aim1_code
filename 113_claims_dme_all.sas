

/*start-header
################################################################################
# Type of File     : SAS
#
# Program Name     : 106_claims_dme_ffs_all.sas
#			
# Program Path     : sasCCW\Files\dua_070617_jma617\code
#
# Programmed By    : Jonathan Martindale
#
# Date Created     : 20Feb2025	
#
# Project Title    : Bell-Davis RF1
#
# Purpose          : Process dme files for each storm to pull diagnosis codes to be used for ADRD identification, Elixhauser, and CFI
#
# Input files      : SH070617.hurricanes
#					 SH070617.[storm]_mbsf_elig
#					 in070617.DMECLMS00_R14229 - in070617.DMECLMS19_R14229
#					 in070617.DMELINE00_R14229 - in070617.DMELINE19_R14229
#
# Output file      : SH070617.[storm]_dme_claims_pre
#
#################################################################################
end-header*/



%macro dme_storm(storm);

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
	create table dme_line_pre as
	select mbsf.bene_id
		, mbsf.storm
		, mbsf.index_date
		, mbsf.obs_start_date
		, dme.clm_id
		, dme.LINE_ICD_DGNS_CD
		, dme.LINE_1ST_EXPNS_DT
		, dme.LINE_PRCSG_IND_CD
		, dme.LINE_ALOWD_CHRG_AMT
		, dme.HCPCS_CD
		, dme.BETOS_CD
	from SH070617.&storm._mbsf_elig mbsf
	inner join IN070617.DMELINE&pre_index_yr._r14229 dme
	on mbsf.bene_id = dme.bene_id
	;

	create table dme_clms_pre as
	select mbsf.bene_id
		, mbsf.storm
		, mbsf.index_date
		, mbsf.obs_start_date
		, dme.clm_id
		, dme.clm_from_dt as service_dt
		, dme.CLM_THRU_DT as service_thru_dt
		, dme.ICD_DGNS_CD1
		, dme.ICD_DGNS_CD2
		, dme.ICD_DGNS_CD3
		, dme.ICD_DGNS_CD4
		, dme.ICD_DGNS_CD5
		, dme.ICD_DGNS_CD6
		, dme.ICD_DGNS_CD7
		, dme.ICD_DGNS_CD8
		, dme.ICD_DGNS_CD9
		, dme.ICD_DGNS_CD10
		, dme.ICD_DGNS_CD11
		, dme.ICD_DGNS_CD12
	from SH070617.&storm._mbsf_elig mbsf
	inner join IN070617.DMECLMS&pre_index_yr._r14229 dme
	on mbsf.bene_id = dme.bene_id
	;


	create table dme_line_index as
	select mbsf.bene_id
		, mbsf.storm
		, mbsf.index_date
		, mbsf.obs_start_date
		, dme.clm_id
		, dme.LINE_ICD_DGNS_CD
		, dme.LINE_1ST_EXPNS_DT
		, dme.LINE_PRCSG_IND_CD
		, dme.LINE_ALOWD_CHRG_AMT
		, dme.HCPCS_CD
		, dme.BETOS_CD
	from SH070617.&storm._mbsf_elig mbsf
	inner join IN070617.DMELINE&index_yr._r14229 dme
	on mbsf.bene_id = dme.bene_id
	;
	
	create table dme_clms_index as
	select mbsf.bene_id
		, mbsf.storm
		, mbsf.index_date
		, mbsf.obs_start_date
		, dme.clm_id
		, dme.clm_from_dt as service_dt
		, dme.CLM_THRU_DT as service_thru_dt
		, dme.ICD_DGNS_CD1
		, dme.ICD_DGNS_CD2
		, dme.ICD_DGNS_CD3
		, dme.ICD_DGNS_CD4
		, dme.ICD_DGNS_CD5
		, dme.ICD_DGNS_CD6
		, dme.ICD_DGNS_CD7
		, dme.ICD_DGNS_CD8
		, dme.ICD_DGNS_CD9
		, dme.ICD_DGNS_CD10
		, dme.ICD_DGNS_CD11
		, dme.ICD_DGNS_CD12
	from SH070617.&storm._mbsf_elig mbsf
	inner join in070617.DMECLMS&index_yr._r14229 dme
	on mbsf.bene_id = dme.bene_id
	;
quit;

/* sort, merge, and append datasets */
proc sort data=dme_line_index; by bene_id clm_id; run;
proc sort data=dme_clms_index; by bene_id clm_id; run;
proc sort data=dme_line_pre; by bene_id clm_id; run;
proc sort data=dme_clms_pre; by bene_id clm_id; run;

data dme_pre;
	merge dme_line_pre(in=a) dme_clms_pre(in=b);
	by bene_id clm_id;

	_merge_line = a;
	_merge_clms = b;
run;

data dme_index;
	merge dme_line_index(in=a) dme_clms_index(in=b);
	by bene_id clm_id;

	_merge_line = a;
	_merge_clms = b;
run;

proc freq data=dme_pre;
	title "check dme_pre merge for &storm.";
	tables _merge_line*_merge_clms / list missing;
run;

proc freq data=dme_index;
	title "check dme_index merge for &storm.";
	tables _merge_line*_merge_clms / list missing;
run;

data dme;
	set dme_pre dme_index;
run;

proc sql;	
	title "number of benes in MBSF file for &storm.";
	select count(*) as storm_benes
	from SH070617.&storm._mbsf_elig
	;
	
	title "number of benes in file for &storm. - dme";
	select count(*) as recs, count(distinct bene_id) as u_benes
	from dme
	;

quit;


data dme; 
	set dme;
	

	if service_dt = . then service_dt = LINE_1ST_EXPNS_DT;
	if service_thru_dt = . then service_thru_dt = service_dt;

	days_admit_to_index = intck("days", service_dt, index_date);
	days_dc_to_index = intck("days", service_thru_dt, index_date);
	within_dt_admit = ((obs_start_date <= service_dt) and (service_dt < index_date)); /* admission falls in window */
	within_dt_dc =  ((obs_start_date <= service_thru_dt) and (service_thru_dt < index_date)); /* or discharge falls in window */

	if line_prcsg_ind_cd in("I", "M", "R") or line_alowd_chrg_amt <= 0 then delete;
run;

proc freq data=dme;
	title "check claim type and date calculations for &storm.";
	tables line_prcsg_ind_cd within_dt_admit*within_dt_dc
	 / list missing;
run;


data SH070617.&storm._dme_claims_pre;
set dme;

    * rename dx variables for consistency;
    array d(*) $ LINE_ICD_DGNS_CD ICD_DGNS_CD1--ICD_DGNS_CD12;
    array dx(*) $ dx1-dx13;

    do i=1 to dim(d);
        dx(i) = d(i);
    end;

	drop LINE_ICD_DGNS_CD ICD_DGNS_CD: i ;
	where (within_dt_admit = 1 or within_dt_dc = 1);
run;



proc freq data=SH070617.&storm._dme_claims_pre;
	format service_dt service_thru_dt monyy7.;
	tables  service_dt service_thru_dt within_dt_admit*within_dt_dc / list missing;
run;

proc contents data=SH070617.&storm._dme_claims_pre varnum;
title "All dme Claims for &storm. - SH070617.&storm._dme_claims_pre"; 
run;

proc print data=SH070617.&storm._dme_claims_pre (obs=10); run;

%mend;

%dme_storm(allison);
%dme_storm(charley);
%dme_storm(florence);
%dme_storm(frances);
%dme_storm(harvey);
%dme_storm(ike);
%dme_storm(irene);
%dme_storm(irma);
%dme_storm(ivan);
%dme_storm(katrina);
%dme_storm(matthew);
%dme_storm(michael);
%dme_storm(rita);
%dme_storm(sandy);
%dme_storm(wilma);



