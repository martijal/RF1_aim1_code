

/*start-header
################################################################################
# Type of File     : SAS
#
# Program Name     : 103_claims_medpar_all.sas
#			
# Program Path     : sasCCW\Files\dua_070617_jma617\code
#
# Programmed By    : Jonathan Martindale
#
# Date Created     : 05Feb2025	
#
# Project Title    : Bell-Davis RF1
#
# Purpose          : Process MedPAR files for each storm to pull diagnosis codes to be used for ADRD identification, Elixhauser, and CFI
#
# Input files      : SH070617.bene_elig_2000 - SH070617.bene_elig_2019
#
# Output file      : SH070617.bene_elig_YYYY
#
#################################################################################
end-header*/



proc contents data=sh070617.hurricanes; run;
proc print data=sh070617.hurricanes (obs=5); run;


%macro medpar_storm(storm);

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

proc print data=storm; run;
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

proc freq data=IN070617.medpar&pre_index_yr._r14229;
	format ADMSN_DT DSCHRG_DT year4.;
	tables ADMSN_DT DSCHRG_DT / missing;
run;


proc sql;
	create table medpar_pre as
	select mbsf.bene_id
		, mbsf.storm
		, mbsf.index_date
		, mbsf.obs_start_date
		, medpar.ADMSN_DT as service_dt
		, medpar.DSCHRG_DT as service_thru_dt
		, medpar.PRVDR_NUM 
		, medpar.PRVDR_NUM_SPCL_UNIT_CD
		, medpar.SS_LS_SNF_IND_CD
		, medpar.dgns_1_cd
		, medpar.dgns_2_cd
		, medpar.dgns_3_cd
		, medpar.dgns_4_cd
		, medpar.dgns_5_cd
		, medpar.dgns_6_cd
		, medpar.dgns_7_cd
		, medpar.dgns_8_cd
		, medpar.dgns_9_cd
		, medpar.dgns_10_cd
		, medpar.dgns_11_cd
		, medpar.dgns_12_cd
		, medpar.dgns_13_cd
		, medpar.dgns_14_cd
		, medpar.dgns_15_cd
		, medpar.dgns_16_cd
		, medpar.dgns_17_cd
		, medpar.dgns_18_cd
		, medpar.dgns_19_cd
		, medpar.dgns_20_cd
		, medpar.dgns_21_cd
		, medpar.dgns_22_cd
		, medpar.dgns_23_cd
		, medpar.dgns_24_cd
		, medpar.dgns_25_cd
	from SH070617.&storm._mbsf_elig mbsf
	inner join IN070617.medpar&pre_index_yr._r14229 medpar
	on mbsf.bene_id = medpar.bene_id
	;
	
	create table medpar_index as
	select mbsf.bene_id
		, mbsf.storm
		, mbsf.index_date
		, mbsf.obs_start_date
		, medpar.ADMSN_DT as service_dt
		, medpar.DSCHRG_DT as service_thru_dt
		, medpar.PRVDR_NUM 
		, medpar.PRVDR_NUM_SPCL_UNIT_CD
		, medpar.SS_LS_SNF_IND_CD
		, medpar.dgns_1_cd
		, medpar.dgns_2_cd
		, medpar.dgns_3_cd
		, medpar.dgns_4_cd
		, medpar.dgns_5_cd
		, medpar.dgns_6_cd
		, medpar.dgns_7_cd
		, medpar.dgns_8_cd
		, medpar.dgns_9_cd
		, medpar.dgns_10_cd
		, medpar.dgns_11_cd
		, medpar.dgns_12_cd
		, medpar.dgns_13_cd
		, medpar.dgns_14_cd
		, medpar.dgns_15_cd
		, medpar.dgns_16_cd
		, medpar.dgns_17_cd
		, medpar.dgns_18_cd
		, medpar.dgns_19_cd
		, medpar.dgns_20_cd
		, medpar.dgns_21_cd
		, medpar.dgns_22_cd
		, medpar.dgns_23_cd
		, medpar.dgns_24_cd
		, medpar.dgns_25_cd
	from SH070617.&storm._mbsf_elig mbsf
	inner join IN070617.medpar&index_yr._r14229 medpar
	on mbsf.bene_id = medpar.bene_id
	;
	
	title "number of benes in MBSF file for &storm.";
	select count(*) as storm_benes
	from SH070617.&storm._mbsf_elig
	;
	
	title "number of benes in pre-index year for &storm. - medpar_pre";
	select count(*) as recs, count(distinct bene_id) as u_benes
	from medpar_pre
	;
	
	title "number of benes in index year for &storm. - medpar_index";
	select count(*) as recs, count(distinct bene_id) as u_benes
	from medpar_index
	;
quit;


data medpar;
	set medpar_pre medpar_index;
run;

data medpar; 
	set medpar;
	days_admit_to_index = intck("days", service_dt, index_date);
	days_dc_to_index = intck("days", service_thru_dt, index_date);
	within_dt_admit = ((obs_start_date <= service_dt) and (service_dt < index_date)); /* admission falls in window */
	within_dt_dc =  ((obs_start_date <= service_thru_dt) and (service_thru_dt < index_date)); /* or discharge falls in window */
run;

proc freq data=medpar;
	tables within_dt_admit*within_dt_dc / list missing;
run;


data SH070617.&storm._medpar_claims_pre;
set medpar;
	length prov_type $3;
	prov34=substr(prvdr_num,3,2);
	prov3=substr(prvdr_num,3,1);
	if (PROV3='0' OR PROV34='13')
		AND SS_LS_SNF_IND_CD^='N' and PRVDR_NUM_SPCL_UNIT_CD=' ' and LOS_DAY_CNT<=365 
	then do;
	  if PROV3='0' then prov_type='ACH';			*Acute Care Hospital;
	  else if PROV34='13' then prov_type = 'CAH';	*Critical Access Hospital;
	end;
	else if substr(prvdr_num,3,2) IN ('20') 
		then prov_type = 'LTC';			*Long-Term Care Hospital;
	else if substr(prvdr_num,3,2) IN ('30') 
		then prov_type = 'REH';			*Rehab Hospital;                        
	else if substr(prvdr_num,3,2) IN ('19') 
		then prov_type = 'RNH';			*Religious nonmedical health institution;
	else if substr(prvdr_num,3,2) IN ('33') 
		then prov_type = 'CHL';			*Children Hospital;
	else if substr(prvdr_num,3,2) IN ('40','41') 
		then prov_type = 'PSY';			*Psychiatric Hosptial; 
	else if SUBSTR(prvdr_num,3,2) IN 
			('50','51','52','53','54','55',
			 '56','57','58','59','60','61',
			 '62','63','64') 
		then prov_type='SNF';			*Skilled Nursing Facility;
	else if prov_type=' '  
			and PRVDR_NUM_SPCL_UNIT_CD in ('U','W','Y','Z') 
		then prov_type='SWN';			*Swing Bed Hospital;
	else if prov_type=' ' 
			and SS_LS_SNF_IND_CD='N' 
		then prov_type='SNF';			*Skilled Nursing Facility;
	else prov_type='OTH';
	
    * rename dx variables for consistency;
    array d(*) $ dgns_1_cd--dgns_25_cd;
    array dx(*) $ dx1-dx25;

    do i=1 to dim(d);
        dx(i) = d(i);
    end;

	drop dgns_: i ;
	where within_dt_admit = 1 or within_dt_dc = 1;
run;



proc freq data=SH070617.&storm._medpar_claims_pre;
	format service_dt service_thru_dt year4.;
	tables prov_type service_dt service_thru_dt within_dt_admit*within_dt_dc / list missing;
run;

proc contents data=SH070617.&storm._medpar_claims_pre varnum;
title "All Medpar Claims for &storm. - SH070617.&storm._medpar_claims_pre"; 
run;

proc print data=SH070617.&storm._medpar_claims_pre (obs=10); run;

%mend;

%medpar_storm(allison);
%medpar_storm(charley);
%medpar_storm(florence);
%medpar_storm(frances);
%medpar_storm(harvey);
%medpar_storm(ike);
%medpar_storm(irene);
%medpar_storm(irma);
%medpar_storm(ivan);
%medpar_storm(katrina);
%medpar_storm(matthew);
%medpar_storm(michael);
%medpar_storm(rita);
%medpar_storm(sandy);
%medpar_storm(wilma);



