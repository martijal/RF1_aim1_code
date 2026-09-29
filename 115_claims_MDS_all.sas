

/*start-header
################################################################################
# Type of File     : SAS
#
# Program Name     : 115_claims_MDS_all.sas
#			
# Program Path     : sasCCW\Files\dua_070617_jma617\code
#
# Programmed By    : Jonathan Martindale
#
# Date Created     : 02Jun2025	
#
# Project Title    : Bell-Davis RF1
#
# Purpose          : Process ndi files for each storm to pull diagnosis codes to be used for ADRD identification, Elixhauser, and CFI
#
# Input files      : SH070617.hurricanes
#					 SH070617.[storm]_mbsf_elig
#					 in070617.mds_asmt[yr]_r14229
#					 in070617.mds3_asmt[yr]_r14229
#
# Output file      : SH070617.[storm]_mds_claims_pre
#
#################################################################################
end-header*/



%macro mds_storm(storm);

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


%if &pre_index_year < 2010 %then %do;
proc freq data=in070617.mds_asmt&pre_index_yr._r14229; 
	title "MDS dates for &pre_index_yr. - &storm.";
	format target_date AB1_ENTRY_DT year4.;
	tables target_date AB1_ENTRY_DT / missing;
run;


proc sql;
	create table mds_pre as
	select mbsf.bene_id
		, mbsf.storm
		, mbsf.index_date
		, mbsf.obs_start_date
		, mds.target_date
		, mds.AB1_ENTRY_DT as entry_date
	from SH070617.&storm._mbsf_elig mbsf
	inner join in070617.mds_asmt&pre_index_yr._r14229 mds
	on mbsf.bene_id = mds.bene_id
	;
	
	create table mds_index as
	select mbsf.bene_id
		, mbsf.storm
		, mbsf.index_date
		, mbsf.obs_start_date
		, mds.target_date
		, mds.AB1_ENTRY_DT as entry_date
	from SH070617.&storm._mbsf_elig mbsf
	inner join in070617.mds_asmt&index_yr._r14229 mds
	on mbsf.bene_id = mds.bene_id
	;
quit;

data mds;
	set mds_pre mds_index;
run;

%end;

%if &pre_index_year > 2010 %then %do;
proc freq data=in070617.mds_asmt3&pre_index_yr._r14229; 
	title "MDS3 dates for &pre_index_yr. - &storm.";
	format TRGT_DT A1600_ENTRY_DT year4.;
	tables TRGT_DT A1600_ENTRY_DT / missing;
run;


proc sql;
	create table mds3_pre as
	select mbsf.bene_id
		, mbsf.storm
		, mbsf.index_date
		, mbsf.obs_start_date
		, mds.TRGT_DT as target_date
		, mds.A1600_ENTRY_DT as entry_date
	from SH070617.&storm._mbsf_elig mbsf
	inner join in070617.mds_asmt3&pre_index_yr._r14229 mds
	on mbsf.bene_id = mds.bene_id
	;
	
	create table mds3_index as
	select mbsf.bene_id
		, mbsf.storm
		, mbsf.index_date
		, mbsf.obs_start_date
		, mds.TRGT_DT as target_date
		, mds.A1600_ENTRY_DT as entry_date
	from SH070617.&storm._mbsf_elig mbsf
	inner join in070617.mds_asmt3&index_yr._r14229 mds
	on mbsf.bene_id = mds.bene_id
	;
quit;

data mds;
	set mds3_pre mds3_index;
run;

%end;


%if &pre_index_year = 2010 %then %do;
proc freq data=in070617.mds_asmt3&pre_index_yr._r14229; 
	title "MDS3 dates for &pre_index_yr. - &storm.";
	format TRGT_DT A1600_ENTRY_DT year4.;
	tables TRGT_DT A1600_ENTRY_DT / missing;
run;

proc freq data=in070617.mds_asmt&pre_index_yr._r14229; 
	title "MDS dates for &pre_index_yr. - &storm.";
	format target_date AB1_ENTRY_DT year4.;
	tables target_date AB1_ENTRY_DT / missing;
run;


proc sql;
	create table mds_pre as
	select mbsf.bene_id
		, mbsf.storm
		, mbsf.index_date
		, mbsf.obs_start_date
		, mds.target_date
		, mds.AB1_ENTRY_DT as entry_date
	from SH070617.&storm._mbsf_elig mbsf
	inner join in070617.mds_asmt&pre_index_yr._r14229 mds
	on mbsf.bene_id = mds.bene_id
	;
	

	create table mds3_pre as
	select mbsf.bene_id
		, mbsf.storm
		, mbsf.index_date
		, mbsf.obs_start_date
		, mds.TRGT_DT as target_date
		, mds.A1600_ENTRY_DT as entry_date
	from SH070617.&storm._mbsf_elig mbsf
	inner join in070617.mds_asmt3&pre_index_yr._r14229 mds
	on mbsf.bene_id = mds.bene_id
	;
	
	create table mds3_index as
	select mbsf.bene_id
		, mbsf.storm
		, mbsf.index_date
		, mbsf.obs_start_date
		, mds.TRGT_DT as target_date
		, mds.A1600_ENTRY_DT as entry_date
	from SH070617.&storm._mbsf_elig mbsf
	inner join in070617.mds_asmt3&index_yr._r14229 mds
	on mbsf.bene_id = mds.bene_id
	;
quit;

data mds;
	set mds_pre mds3_pre mds3_index;
run;

%end;


data mds; 
	set mds;
	
	mds_pre = 1;

	/* update entry date to attempt most complete capture of any stay */
	if entry_date = . then entry_date = target_date;

	days_admit_to_index = intck("days", entry_date, index_date);
	days_dc_to_index = intck("days", target_date, index_date);
	within_dt_admit = ((obs_start_date <= entry_date) and (entry_date < index_date)); /* admission falls in window */
	within_dt_dc =  ((obs_start_date <= target_date) and (target_date < index_date)); /* or discharge falls in window */
	within_dt_capture = ((entry_date < obs_start_date) and (target_date > index_date)); /* admit prior to start, dc after index */ 


run;

proc freq data=mds;
	title "check coding for &storm";
	tables within_dt_admit*within_dt_dc*within_dt_capture / list missing;
run;


data SH070617.&storm._mds_claims_pre;
	set mds;
	where within_dt_capture = 1 or within_dt_admit = 1 or within_dt_dc = 1;

	label entry_date = "date of MDS entry. Set to Target Date when missing"
		  target_date = "date of MDS assessment"
		  mds_pre = "MDS claim in pre period. 1/0"
		  ;

run;


proc freq data=SH070617.&storm._mds_claims_pre;
	format target_date entry_date year4.;
	tables target_date*entry_date within_dt_admit*within_dt_dc*within_dt_capture / list missing;
run;

proc contents data=SH070617.&storm._mds_claims_pre varnum;
	title "All mds Claims for &storm. - SH070617.&storm._mds_claims_pre"; 
run;

proc print data=SH070617.&storm._mds_claims_pre (obs=10); run;

proc sql;
	title "number of benes for &storm.";
	select count(*) as recs, count(distinct bene_id) as u_benes
	from SH070617.&storm._mbsf_elig
	;

	title "number of benes in full MDS file - SH070617.&storm._mds_claims_pre";
	select count(*) as recs, count(distinct bene_id) as u_benes
	from SH070617.&storm._mds_claims_pre
	;
quit;

%mend;

%mds_storm(allison);
%mds_storm(charley);
%mds_storm(florence);
%mds_storm(frances);
%mds_storm(harvey);
%mds_storm(ike);
%mds_storm(irene);
%mds_storm(irma);
%mds_storm(ivan);
%mds_storm(katrina);
%mds_storm(matthew);
%mds_storm(michael);
%mds_storm(rita);
%mds_storm(sandy);
%mds_storm(wilma);




