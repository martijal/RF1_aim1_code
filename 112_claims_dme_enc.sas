

/*start-header
################################################################################
# Type of File     : SAS
#
# Program Name     : 111_claims_dme_enc.sas
#			
# Program Path     : sasCCW\Files\dua_070617_jma617\code
#
# Programmed By    : Jonathan Martindale
#
# Date Created     : 05Feb2025	
#
# Project Title    : Bell-Davis RF1
#
# Purpose          : Process dme files for each storm to pull diagnosis codes to be used for ADRD identification, Elixhauser, and CFI
#
# Input files      : SH070617.hurricanes
#					 SH070617.[storm]_mbsf_elig
#					 in070617.dmebenc&pre_index_yr._r14229
#					 in070617.dmelenc&pre_index_yr._r14229
#
# Output file      : SH070617.[storm]_dme_enc_pre
#
#################################################################################
end-header*/

proc contents data=in070617.DMEBENC15_R14229 varnum; run;
proc contents data=in070617.DMELENC15_R14229 varnum; run;

%macro dme_enc_storm(storm);

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
proc freq data=in070617.dmebenc&pre_index_yr._r14229;
	format clm_from_dt clm_thru_dt year4.;
	tables clm_from_dt clm_thru_dt / missing;
run;


proc sql;
	create table dme_pre as
	select mbsf.bene_id
		, mbsf.storm
		, mbsf.index_date
		, mbsf.obs_start_date
		, dme.ENC_JOIN_KEY
		, dme.clm_from_dt as service_dt
		, dme.clm_thru_dt as service_thru_dt
		, dme.CLM_CHRT_RVW_SW
		, dme.PRNCPAL_DGNS_CD
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
		, dme.ICD_DGNS_CD13
	from SH070617.&storm._mbsf_elig mbsf
	inner join IN070617.dmebenc&pre_index_yr._r14229 dme
	on mbsf.bene_id = dme.bene_id
	;
	
	create table dme_index as
	select mbsf.bene_id
		, mbsf.storm
		, mbsf.index_date
		, mbsf.obs_start_date
		, dme.ENC_JOIN_KEY
		, dme.clm_from_dt as service_dt
		, dme.clm_thru_dt as service_thru_dt
		, dme.CLM_CHRT_RVW_SW
		, dme.PRNCPAL_DGNS_CD
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
		, dme.ICD_DGNS_CD13
	from SH070617.&storm._mbsf_elig mbsf
	inner join in070617.dmebenc&index_yr._r14229 dme
	on mbsf.bene_id = dme.bene_id
	;


proc sql;
	create table dme_rev_pre as
	select mbsf.bene_id
		, dme.ENC_JOIN_KEY
		, dme.HCPCS_CD
	from SH070617.&storm._mbsf_elig mbsf
	inner join IN070617.dmelenc&pre_index_yr._r14229 dme
	on mbsf.bene_id = dme.bene_id
	;
	
	create table dme_rev_index as
	select mbsf.bene_id
		, dme.ENC_JOIN_KEY
		, dme.HCPCS_CD
	from SH070617.&storm._mbsf_elig mbsf
	inner join in070617.dmelenc&index_yr._r14229 dme
	on mbsf.bene_id = dme.bene_id
	;
	
	title "number of benes in MBSF file for &storm.";
	select count(*) as storm_benes
	from SH070617.&storm._mbsf_elig
	;
	
quit;

proc sort data=dme_rev_pre; by bene_id ENC_JOIN_KEY; run;
proc sort data=dme_rev_index; by bene_id ENC_JOIN_KEY; run;
proc sort data=dme_pre; by bene_id ENC_JOIN_KEY; run;
proc sort data=dme_index; by bene_id ENC_JOIN_KEY; run;

data dme_pre_all;
	merge dme_pre(in=a) dme_rev_pre(in=b);
	by bene_id ENC_JOIN_KEY;

	_merge_clms = a;
	_merge_rev = b;
run;

data dme_index_all;
	merge dme_index(in=a) dme_rev_index(in=b);
	by bene_id ENC_JOIN_KEY;

	_merge_clms = a;
	_merge_rev = b;
run;

data dme;
	set dme_pre_all dme_index_all;
run;

proc sql;
	title "number of benes after combining and merging - dme - for &storm.";
	select count(*) as recs, count(distinct bene_id) as u_benes
	from dme
	;
quit;

data dme; 
	set dme;
	days_admit_to_index = intck("days", service_dt, index_date);
	days_dc_to_index = intck("days", service_thru_dt, index_date);
	within_dt_admit = ((obs_start_date <= service_dt) and (service_dt < index_date)); /* admission falls in window */
	within_dt_dc =  ((obs_start_date <= service_thru_dt) and (service_thru_dt < index_date)); /* or discharge falls in window */

run;

proc freq data=dme;
	title "check coding for &storm";
	tables CLM_CHRT_RVW_SW within_dt_admit*within_dt_dc _merge_clms*_merge_rev / list missing;
run;


data SH070617.&storm._dme_enc_pre;
set dme;

    * rename dx variables for consistency;
    array d(*) $ PRNCPAL_DGNS_CD ICD_DGNS_CD1--ICD_DGNS_CD13;
    array dx(*) $ dx1-dx14;

    do i=1 to dim(d);
        dx(i) = d(i);
    end;

	drop PRNCPAL_DGNS_CD ICD_DGNS_CD: i ;
	where within_dt_admit = 1 or within_dt_dc = 1;
run;


proc freq data=SH070617.&storm._dme_enc_pre;
	format service_dt service_thru_dt monyy7.;
	tables CLM_CHRT_RVW_SW service_dt service_thru_dt within_dt_admit*within_dt_dc / list missing;
run;

proc contents data=SH070617.&storm._dme_enc_pre varnum;
title "All dme Claims for &storm. - SH070617.&storm._dme_enc_pre"; 
run;

proc print data=SH070617.&storm._dme_enc_pre (obs=10); run;
%end;
%mend;

%dme_enc_storm(allison);
%dme_enc_storm(charley);
%dme_enc_storm(florence);
%dme_enc_storm(frances);
%dme_enc_storm(harvey);
%dme_enc_storm(ike);
%dme_enc_storm(irene);
%dme_enc_storm(irma);
%dme_enc_storm(ivan);
%dme_enc_storm(katrina);
%dme_enc_storm(matthew);
%dme_enc_storm(michael);
%dme_enc_storm(rita);
%dme_enc_storm(sandy);
%dme_enc_storm(wilma);



