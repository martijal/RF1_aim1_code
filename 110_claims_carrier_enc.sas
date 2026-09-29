

/*start-header
################################################################################
# Type of File     : SAS
#
# Program Name     : 108_claims_carrier_enc.sas
#			
# Program Path     : sasCCW\Files\dua_070617_jma617\code
#
# Programmed By    : Jonathan Martindale
#
# Date Created     : 05Feb2025	
#
# Project Title    : Bell-Davis RF1
#
# Purpose          : Process carrier files for each storm to pull diagnosis codes to be used for ADRD identification, Elixhauser, and CFI
#
# Input files      : SH070617.hurricanes
#					 SH070617.[storm]_mbsf_elig
#					 in070617.carrierclms[year]_r14229
#
# Output file      : SH070617.[storm]_carrier_enc_pre
#
#################################################################################
end-header*/
proc contents data=in070617.carbenc15_r14229 varnum; run;
proc contents data=in070617.carlenc15_r14229 varnum; run;

%macro carrier_enc_storm(storm);

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
proc freq data=in070617.carbenc&pre_index_yr._r14229;
	format clm_from_dt clm_thru_dt year4.;
	tables clm_from_dt clm_thru_dt / missing;
run;


proc sql;
	create table carrier_pre as
	select mbsf.bene_id
		, mbsf.storm
		, mbsf.index_date
		, mbsf.obs_start_date
		, carrier.ENC_JOIN_KEY
		, carrier.clm_from_dt as service_dt
		, carrier.clm_thru_dt as service_thru_dt
		, carrier.CLM_CHRT_RVW_SW
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
		, carrier.ICD_DGNS_CD13
	from SH070617.&storm._mbsf_elig mbsf
	inner join IN070617.carbenc&pre_index_yr._r14229 carrier
	on mbsf.bene_id = carrier.bene_id
	;
	
	create table carrier_index as
	select mbsf.bene_id
		, mbsf.storm
		, mbsf.index_date
		, mbsf.obs_start_date
		, carrier.ENC_JOIN_KEY
		, carrier.clm_from_dt as service_dt
		, carrier.clm_thru_dt as service_thru_dt
		, carrier.CLM_CHRT_RVW_SW
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
		, carrier.ICD_DGNS_CD13
	from SH070617.&storm._mbsf_elig mbsf
	inner join in070617.carbenc&index_yr._r14229 carrier
	on mbsf.bene_id = carrier.bene_id
	;


proc sql;
	create table carrier_line_pre as
	select mbsf.bene_id
		, carrier.ENC_JOIN_KEY
		, carrier.HCPCS_CD
	from SH070617.&storm._mbsf_elig mbsf
	inner join IN070617.carlenc&pre_index_yr._r14229 carrier
	on mbsf.bene_id = carrier.bene_id
	;
	
	create table carrier_line_index as
	select mbsf.bene_id
		, carrier.ENC_JOIN_KEY
		, carrier.HCPCS_CD
	from SH070617.&storm._mbsf_elig mbsf
	inner join in070617.carlenc&index_yr._r14229 carrier
	on mbsf.bene_id = carrier.bene_id
	;
	
	title "number of benes in MBSF file for &storm.";
	select count(*) as storm_benes
	from SH070617.&storm._mbsf_elig
	;
	
quit;

proc sort data=carrier_line_pre; by bene_id ENC_JOIN_KEY; run;
proc sort data=carrier_line_index; by bene_id ENC_JOIN_KEY; run;
proc sort data=carrier_pre; by bene_id ENC_JOIN_KEY; run;
proc sort data=carrier_index; by bene_id ENC_JOIN_KEY; run;

data carrier_pre_all;
	merge carrier_pre(in=a) carrier_line_pre(in=b);
	by bene_id ENC_JOIN_KEY;

	_merge_clms = a;
	_merge_rev = b;
run;

data carrier_index_all;
	merge carrier_index(in=a) carrier_line_index(in=b);
	by bene_id ENC_JOIN_KEY;

	_merge_clms = a;
	_merge_rev = b;
run;

data carrier;
	set carrier_pre_all carrier_index_all;
run;

proc sql;
	title "number of benes after combining and merging - carrier - for &storm.";
	select count(*) as recs, count(distinct bene_id) as u_benes
	from carrier
	;
quit;

data carrier; 
	set carrier;
	days_admit_to_index = intck("days", service_dt, index_date);
	days_dc_to_index = intck("days", service_thru_dt, index_date);
	within_dt_admit = ((obs_start_date <= service_dt) and (service_dt < index_date)); /* admission falls in window */
	within_dt_dc =  ((obs_start_date <= service_thru_dt) and (service_thru_dt < index_date)); /* or discharge falls in window */

 if service_thru_dt = . then service_thru_dt = service_dt;
 if CLM_CHRT_RVW_SW in("Y") then delete;

run;

proc freq data=carrier;
	title "check coding for &storm";
	tables CLM_CHRT_RVW_SW within_dt_admit*within_dt_dc _merge_clms*_merge_rev / list missing;
run;


data SH070617.&storm._carrier_enc_pre;
set carrier;

    * rename dx variables for consistency;
    array d(*) $ ICD_DGNS_CD1--ICD_DGNS_CD13;
    array dx(*) $ dx1-dx13;

    do i=1 to dim(d);
        dx(i) = d(i);
    end;

	drop ICD_DGNS_CD: i ;
	where within_dt_admit = 1 or within_dt_dc = 1;
run;


proc freq data=SH070617.&storm._carrier_enc_pre;
	format service_dt service_thru_dt monyy7.;
	tables CLM_CHRT_RVW_SW service_dt service_thru_dt within_dt_admit*within_dt_dc / list missing;
run;

proc contents data=SH070617.&storm._carrier_enc_pre varnum;
title "All carrier Claims for &storm. - SH070617.&storm._carrier_enc_pre"; 
run;

proc print data=SH070617.&storm._carrier_enc_pre (obs=10); run;
%end;
%mend;

%carrier_enc_storm(allison);
%carrier_enc_storm(charley);
%carrier_enc_storm(florence);
%carrier_enc_storm(frances);
%carrier_enc_storm(harvey);
%carrier_enc_storm(ike);
%carrier_enc_storm(irene);
%carrier_enc_storm(irma);
%carrier_enc_storm(ivan);
%carrier_enc_storm(katrina);
%carrier_enc_storm(matthew);
%carrier_enc_storm(michael);
%carrier_enc_storm(rita);
%carrier_enc_storm(sandy);
%carrier_enc_storm(wilma);



