

/*start-header
################################################################################
# Type of File     : SAS
#
# Program Name     : 108_claims_ip_enc.sas
#			
# Program Path     : sasCCW\Files\dua_070617_jma617\code
#
# Programmed By    : Jonathan Martindale
#
# Date Created     : 05Feb2025	
#
# Project Title    : Bell-Davis RF1
#
# Purpose          : Process ip files for each storm to pull diagnosis codes to be used for ADRD identification, Elixhauser, and CFI
#
# Input files      : SH070617.hurricanes
#					 SH070617.[storm]_mbsf_elig
#					 in070617.ipclms[year]_r14229
#
# Output file      : SH070617.[storm]_ip_enc_pre
#
#################################################################################
end-header*/
proc contents data=in070617.ipbenc15_r14229 varnum; run;
proc contents data=in070617.iprenc15_r14229 varnum; run;

%macro ip_enc_storm(storm);

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
proc freq data=in070617.ipbenc&pre_index_yr._r14229;
	format clm_from_dt bene_dschrg_dt year4.;
	tables clm_from_dt bene_dschrg_dt / missing;
run;


proc sql;
	create table ip_pre as
	select mbsf.bene_id
		, mbsf.storm
		, mbsf.index_date
		, mbsf.obs_start_date
		, ip.ENC_JOIN_KEY
		, ip.clm_from_dt as service_dt
		, ip.bene_dschrg_dt as service_thru_dt
		, ip.CLM_CHRT_RVW_SW
		, ip.ADMTG_DGNS_CD
		, ip.ICD_DGNS_CD1
		, ip.ICD_DGNS_CD2
		, ip.ICD_DGNS_CD3
		, ip.ICD_DGNS_CD4
		, ip.ICD_DGNS_CD5
		, ip.ICD_DGNS_CD6
		, ip.ICD_DGNS_CD7
		, ip.ICD_DGNS_CD8
		, ip.ICD_DGNS_CD9
		, ip.ICD_DGNS_CD10
		, ip.ICD_DGNS_CD11
		, ip.ICD_DGNS_CD12
		, ip.ICD_DGNS_CD13
		, ip.ICD_DGNS_CD14
		, ip.ICD_DGNS_CD15
		, ip.ICD_DGNS_CD16
		, ip.ICD_DGNS_CD17
		, ip.ICD_DGNS_CD18
		, ip.ICD_DGNS_CD19
		, ip.ICD_DGNS_CD20
		, ip.ICD_DGNS_CD21
		, ip.ICD_DGNS_CD22
		, ip.ICD_DGNS_CD23
		, ip.ICD_DGNS_CD24
		, ip.ICD_DGNS_CD25
	from SH070617.&storm._mbsf_elig mbsf
	inner join IN070617.ipbenc&pre_index_yr._r14229 ip
	on mbsf.bene_id = ip.bene_id
	;
	
	create table ip_index as
	select mbsf.bene_id
		, mbsf.storm
		, mbsf.index_date
		, mbsf.obs_start_date
		, ip.ENC_JOIN_KEY
		, ip.clm_from_dt as service_dt
		, ip.bene_dschrg_dt as service_thru_dt
		, ip.CLM_CHRT_RVW_SW
		, ip.ADMTG_DGNS_CD
		, ip.ICD_DGNS_CD1
		, ip.ICD_DGNS_CD2
		, ip.ICD_DGNS_CD3
		, ip.ICD_DGNS_CD4
		, ip.ICD_DGNS_CD5
		, ip.ICD_DGNS_CD6
		, ip.ICD_DGNS_CD7
		, ip.ICD_DGNS_CD8
		, ip.ICD_DGNS_CD9
		, ip.ICD_DGNS_CD10
		, ip.ICD_DGNS_CD11
		, ip.ICD_DGNS_CD12
		, ip.ICD_DGNS_CD13
		, ip.ICD_DGNS_CD14
		, ip.ICD_DGNS_CD15
		, ip.ICD_DGNS_CD16
		, ip.ICD_DGNS_CD17
		, ip.ICD_DGNS_CD18
		, ip.ICD_DGNS_CD19
		, ip.ICD_DGNS_CD20
		, ip.ICD_DGNS_CD21
		, ip.ICD_DGNS_CD22
		, ip.ICD_DGNS_CD23
		, ip.ICD_DGNS_CD24
		, ip.ICD_DGNS_CD25
	from SH070617.&storm._mbsf_elig mbsf
	inner join in070617.ipbenc&index_yr._r14229 ip
	on mbsf.bene_id = ip.bene_id
	;


proc sql;
	create table ip_rev_pre as
	select mbsf.bene_id
		, ip.ENC_JOIN_KEY
		, ip.HCPCS_CD
	from SH070617.&storm._mbsf_elig mbsf
	inner join IN070617.iprenc&pre_index_yr._r14229 ip
	on mbsf.bene_id = ip.bene_id
	;
	
	create table ip_rev_index as
	select mbsf.bene_id
		, ip.ENC_JOIN_KEY
		, ip.HCPCS_CD
	from SH070617.&storm._mbsf_elig mbsf
	inner join in070617.iprenc&index_yr._r14229 ip
	on mbsf.bene_id = ip.bene_id
	;
	
	title "number of benes in MBSF file for &storm.";
	select count(*) as storm_benes
	from SH070617.&storm._mbsf_elig
	;
	
quit;

proc sort data=ip_rev_pre; by bene_id ENC_JOIN_KEY; run;
proc sort data=ip_rev_index; by bene_id ENC_JOIN_KEY; run;
proc sort data=ip_pre; by bene_id ENC_JOIN_KEY; run;
proc sort data=ip_index; by bene_id ENC_JOIN_KEY; run;

data ip_pre_all;
	merge ip_pre(in=a) ip_rev_pre(in=b);
	by bene_id ENC_JOIN_KEY;

	_merge_clms = a;
	_merge_rev = b;
run;

data ip_index_all;
	merge ip_index(in=a) ip_rev_index(in=b);
	by bene_id ENC_JOIN_KEY;

	_merge_clms = a;
	_merge_rev = b;
run;

data ip;
	set ip_pre_all ip_index_all;
run;

proc sql;
	title "number of benes after combining and merging - ip - for &storm.";
	select count(*) as recs, count(distinct bene_id) as u_benes
	from ip
	;
quit;

data ip; 
	set ip;
	days_admit_to_index = intck("days", service_dt, index_date);
	days_dc_to_index = intck("days", service_thru_dt, index_date);
	within_dt_admit = ((obs_start_date <= service_dt) and (service_dt < index_date)); /* admission falls in window */
	within_dt_dc =  ((obs_start_date <= service_thru_dt) and (service_thru_dt < index_date)); /* or discharge falls in window */


 * per updated specs: delete records with null discharge date;
 if service_thru_dt = . then delete;
 if CLM_CHRT_RVW_SW in("Y") then delete;

run;

proc freq data=ip;
	title "check coding for &storm";
	tables CLM_CHRT_RVW_SW within_dt_admit*within_dt_dc _merge_clms*_merge_rev / list missing;
run;


data SH070617.&storm._ip_enc_pre;
set ip;

    * rename dx variables for consistency;
    array d(*) $ ADMTG_DGNS_CD ICD_DGNS_CD1--ICD_DGNS_CD25;
    array dx(*) $ dx1-dx26;

    do i=1 to dim(d);
        dx(i) = d(i);
    end;

	drop ADMTG_DGNS_CD ICD_DGNS_CD: i ;
	where within_dt_admit = 1 or within_dt_dc = 1;
run;


proc freq data=SH070617.&storm._ip_enc_pre;
	format service_dt service_thru_dt monyy7.;
	tables CLM_CHRT_RVW_SW service_dt service_thru_dt within_dt_admit*within_dt_dc / list missing;
run;

proc contents data=SH070617.&storm._ip_enc_pre varnum;
title "All ip Claims for &storm. - SH070617.&storm._ip_enc_pre"; 
run;

proc print data=SH070617.&storm._ip_enc_pre (obs=10); run;
%end;
%mend;

%ip_enc_storm(allison);
%ip_enc_storm(charley);
%ip_enc_storm(florence);
%ip_enc_storm(frances);
%ip_enc_storm(harvey);
%ip_enc_storm(ike);
%ip_enc_storm(irene);
%ip_enc_storm(irma);
%ip_enc_storm(ivan);
%ip_enc_storm(katrina);
%ip_enc_storm(matthew);
%ip_enc_storm(michael);
%ip_enc_storm(rita);
%ip_enc_storm(sandy);
%ip_enc_storm(wilma);



