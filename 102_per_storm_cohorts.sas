
/*start-header
################################################################################
# Type of File     : SAS
#
# Program Name     : 102_per_storm_cohorts.sas
#			
# Program Path     : sasCCW\Files\dua_070617_jma617\code
#
# Programmed By    : Jonathan Martindale
#
# Date Created     : 27Jan2025	
#
# Updates          : 25 August 2025 - Updated bene_death_dt = MIN(bene_death_dt_&pre_index_year., bene_death_dt_&index_year., bene_death_dt_&post_index_year.) (instead of max())
#
# Project Title    : Bell-Davis RF1
#
# Purpose          : Process MBSF eligibility files for each storm to identify cohorts of interest
#
# Input files      : SH070617.bene_elig_2000 - SH070617.bene_elig_2019
#
# Output file      : SH070617.&storm._mbsf_elig
#
#################################################################################
end-header*/
*options ls=120 ps=64 nocenter nodate nonumber pagesize=6500 nofullstimer mprint msglevel=i;


/* proc sort data=sh070617.hurricanes; by year storm state_code; run; */
/* proc contents data=SH070617.hurricanes; run; */
/* proc print data=SH070617.hurricanes; run; */
/* proc sql; */
/* 	select distinct storm, year */
/* 	from SH070617.hurricanes */
/* 	; */
/* quit; */


%macro mbsf_elig_storm(storm);

proc sql;
select quote(state_code) into: state_list separated by ' , ' 
from SH070617.hurricanes hurr
where lowcase(hurr.storm) in("&storm")
;

select max(storm_index_month)
	, max(obs_start_month)
	, max(obs_end_month)
	, max(year(index_date))
	, max(year(obs_start_date))
	, max(year(obs_end_date))
	into :index_month trimmed
		, :start_month trimmed
		, :end_month trimmed
		, :index_year trimmed
		, :pre_index_year trimmed
		, :post_index_year trimmed
from SH070617.hurricanes hurr
where lowcase(hurr.storm) in("&storm")
;
quit;

%put &state_list.;
%put &index_month.;
%put &start_month.;
%put &end_month.;
%put &index_year.;
%put &pre_index_year.;
%put &post_index_year.;


/* find benes living in affected states in the year prior to storm */
data mbsf_pre;
	set SH070617.bene_elig_&pre_index_year.;
	where state_code_&pre_index_year. in(&state_list);
run;

proc freq data=mbsf_pre;
	tables state_code_&pre_index_year. / list missing;
run;

proc print data=SH070617.hurricanes;
	where lowcase(storm) in("&storm");
run;

data storm;
	set SH070617.hurricanes;
	where lowcase(storm) in("&storm");
run;
	

proc sql;
	create table mbsf_pre_state as
	select storm.storm
		, storm.year as year_of_storm
		, storm.state_abbr
		, storm.state_code
		, storm.storm_state
		, exp.nearest_date_central as index_date
		, (exp.nearest_date_central - 365) as obs_start_date format=date9.
		, (exp.nearest_date_central + 364) as obs_end_date format=date9.
		, mbsf.*
		from mbsf_pre mbsf
		left join storm
		  on mbsf.state_code_&pre_index_year. = storm.state_code
        left join SH070617.&storm._exposure_data exp
            on mbsf.zip5_&pre_index_year. = exp.geoid
	;
	
	title "check number of benes PRE merge of hurricane data - mbsf_pre";
	select count(*) as recs, count(distinct bene_id) as u_benes
	from mbsf_pre
	;
	
	title "check number of benes POST merge - mbsf_pre_state";
	select count(*) as recs, count(distinct bene_id) as u_benes
	from mbsf_pre_state
	;
quit;



/* sort and merge index and post years onto data */
proc sort data=mbsf_pre_state; by bene_id; run;
proc sort data=SH070617.bene_elig_&index_year.; by bene_id; run;
proc sort data=SH070617.bene_elig_&post_index_year.; by bene_id; run;

data mbsf_all; 
	merge mbsf_pre_state (in=a) 
		  SH070617.bene_elig_&index_year.
		  SH070617.bene_elig_&post_index_year.
		  ;
	by bene_id;
	if a;
run;

proc sql;
	title "check number of benes POST merge with other years";
	select count(*) as recs, count(distinct bene_id) as u_benes
	from mbsf_all
	;
quit;



data mbsf_flags;
	set mbsf_all;
	
	format bene_birth_dt bene_death_dt date9.;
	
	/* update ZIP */
	zip9_pre = zip9_&pre_index_year.;
	zip9_index = zip9_&index_year.;
	zip9_post = zip9_&post_index_year.;
	zip5_pre = zip5_&pre_index_year.;
	zip5_index = zip5_&index_year.;
	zip5_post = zip5_&post_index_year.;
	
	/* update race/sex */
	rti_race_cd = rti_race_cd_&index_year.;
    sex_ident_cd = sex_ident_cd_&index_year.;
    
    white=(rti_race_cd='1');
	black=(rti_race_cd='2');
	hispanic=(rti_race_cd='5');
	othrace=(white=0 and black=0 and hispanic=0); /* unknown, asian/pacific islander, AIAN */
	
	if white=1 then race4c=1;
	if black=1 then race4c=2;
	if hispanic=1 then race4c=3;
	if othrace=1 then race4c=4;
	
	male=(sex_ident_cd='1');
	
	/* update birthdate and age */
	bene_birth_dt = bene_birth_dt_&index_year.;
	age = int(intck("DAYS", bene_birth_dt , index_date) / 365.25);
	age66p = (age >= 66);
	
	/* Update date of death and death variables */
	bene_death_dt = min(bene_death_dt_&pre_index_year., bene_death_dt_&index_year., bene_death_dt_&post_index_year.);

	/* update moving variables */
	no_moving_pre = (zip5_&pre_index_year. = zip5_&index_year.);
	no_moving_post = (zip5_&index_year. = zip5_&post_index_year.);
	
	death_pre = 0; death_post = 0;
	if bene_death_dt ^= . then do;
		if bene_death_dt < index_date then death_pre = 1;
		if (bene_death_dt >= index_date) and (bene_death_dt <= obs_end_date) then do;
			death_post = 1;
			days_to_death = intck("days", index_date, bene_death_dt);
			months_to_death = intck("months", index_date, bene_death_dt);
		end;
        if year(bene_death_dt) < &post_index_year. then no_moving_post = 1;
	end;
	
	
	/* update coverage variables */
	ffs_pre_mos = sum(of ffs_&start_month. - ffs_&index_month.);
	ffs_post_mos = sum(of ffs_&index_month. - ffs_&end_month.);
	ffs_pre = (ffs_pre_mos = 13);
	ffs_post = (ffs_post_mos = 13);
	
	ma_pre_mos = sum(of hmo_&start_month. - hmo_&index_month.);
	ma_post_mos = sum(of hmo_&index_month. - hmo_&end_month.);
	ma_pre = (ma_pre_mos = 13);
	ma_post = (ma_post_mos = 13);
		
	ptd_pre_mos = sum(of ptd_&start_month. - ptd_&index_month.);
	ptd_post_mos = sum(of ptd_&index_month. - ptd_&end_month.);
	ptd_pre = (ptd_pre_mos = 13);
	ptd_post = (ptd_post_mos = 13);
	
	dual_pre_mos = sum(of dual_&start_month. - dual_&index_month.);
	dual_post_mos = sum(of dual_&index_month. - dual_&end_month.);
	dual_pre = (sum(of dual_&start_month. - dual_&index_month.) >= 1);
	dual_post = (sum(of dual_&index_month. - dual_&end_month.) >= 1);
	
	lis_pre_mos = sum(of lis_&start_month. - lis_&index_month.);
	lis_post_mos = sum(of lis_&index_month. - lis_&end_month.);
	lis_pre = (sum(of lis_&start_month. - lis_&index_month.) >= 1);
	lis_post = (sum(of lis_&index_month. - lis_&end_month.) >= 1);

	if death_post = 1 then do;
		if (ffs_post_mos >= (months_to_death + 1)) then ffs_post = 1;
		if (ma_post_mos >= (months_to_death + 1)) then ma_post = 1;
		if (ptd_post_mos >= (months_to_death + 1)) then ptd_post = 1;
	end;

	label rti_race_cd = "Research Triangle Institute (RTI) Race Code"
          sex_ident_cd = "Beneficiary Sex"
		  race4c='Race 4 cat:W/B/H/Othr'
		  white='NH White ind 0/1'
		  black='NH Black ind 0/1'
		  Hispanic='Hispanic ind 0/1'
		  othrace='Other race ind 0/1'
		  male= 'Sex Male 0/1'
          zip5_pre = "ZIP code in year prior to storm"
		  zip5_index = "ZIP code in index year"
		  zip5_post = "ZIP code in year post storm"
          zip9_pre = "ZIP9 code in year prior to storm"
		  zip9_index = "ZIP9 code in index year"
		  zip9_post = "ZIP9 code in year post storm"
		  bene_birth_dt = "Bene DOB"
		  bene_death_dt = "Bene DOD"
		  age = "age in years on index date"
		  age66p = "age 66+ on index date"
		  death_pre = "Bene died prior to index date. 1/0"
		  death_post = "Bene died within 365 days of index date (inclusive). 1/0"
		  days_to_death = "Number of days between index date and DOD"
		  months_to_death = "Number of months between index date and DOD"
		  no_moving_pre = "Bene did not change ZIP codes between pre-index year and index year. 1/0"
		  no_moving_post = "Bene did not change ZIP codes between index year and post-index year. 1/0"
		  
		FFS_pre_mos = "Number of months of FFS coverage in 1 year pre-index"
		FFS_post_mos = "Number of months of FFS coverage in 1 year post-index"
		FFS_pre = "Bene had full FFS coverage for 1 year pre-index. 1/0"
		FFS_post = "Bene had full FFS coverage for 1 year post-index. 1/0"
		
		ma_pre_mos = "Number of months of MA coverage in 1 year pre-index"
		ma_post_mos = "Number of months of MA coverage in 1 year post-index"
		ma_pre = "Bene had full MA coverage for 1 year pre-index. 1/0"
		ma_post = "Bene had full MA coverage for 1 year post-index. 1/0"
		
		PTD_pre_mos = "Number of months of PTD coverage in 1 year pre-index"
		PTD_post_mos = "Number of months of PTD coverage in 1 year post-index"
		PTD_pre = "Bene had full PTD coverage for 1 year pre-index. 1/0"
		PTD_post = "Bene had full PTD coverage for 1 year post-index. 1/0"
		
		dual_pre = "Bene had any dual eligibility in 1 year pre-index. 1/0"
		dual_post = "Bene had any dual eligibility in 1 year post-index. 1/0"
		lis_pre = "Bene had any lis eligibility in 1 year pre-index. 1/0"
		lis_post = "Bene had any lis eligibility in 1 year post-index. 1/0"	
		dual_pre_mos = "Number of months of dual eligibility in 1 year pre-index"
		dual_post_mos = "Number of months of dual eligibility in 1 year post-index"
		lis_pre_mos = "Number of months of lis eligibility in 1 year pre-index"
		lis_post_mos = "Number of months of lis eligibility in 1 year post-index"	
		
		storm = "Name of the storm"
		year_of_storm = "Calendar year of storm"
		state_abbr = "State abbreviation where bene lived in calendar year prior to storm"
		state_code = "SSA state code where bene lived in calendar year prior to storm"
		storm_state = "Identifier of storm and state"
		;
run;

/* proc print data=mbsf_flags (obs=5); */
/* 	title "check FFS recode"; */
/* 	var bene_id FFS_pre FFS_pre_mos */
/* 		FFS_post FFS_post_mos */
/* 		ffs_&start_month. - ffs_&end_month. */
/* 		; */
/* run; */
/*  */
/* proc print data=mbsf_flags (obs=5); */
/* 	title "check MA recode"; */
/* 	var bene_id MA_pre MA_pre_mos */
/* 		MA_post MA_post_mos */
/* 		hmo_&start_month. - hmo_&end_month. */
/* 		; */
/* run; */
/*  */
/* proc print data=mbsf_flags (obs=5); */
/* 	title "check part D recode"; */
/* 	var bene_id PTD_pre PTD_pre_mos */
/* 		PTD_post PTD_post_mos */
/* 		PTD_&start_month. - PTD_&end_month. */
/* 		; */
/* run; */
/*  */
/*  */
/* proc freq data=mbsf_flags; */
/* 	title "check numbers on recode - no restrictions"; */
/* 	tables  */
/* 		age66p */
/* 		no_moving_pre*no_moving_post */
/* 		sex_ident_cd*male */
/* 		death_pre*death_post */
/* 		rti_race_cd*race4c */
/* 		FFS_pre*FFS_pre_mos */
/* 		FFS_post*FFS_post_mos */
/* 		MA_pre*MA_pre_mos */
/* 		MA_post*MA_post_mos */
/* 		ptd_pre*ptd_pre_mos */
/* 		ptd_post*ptd_post_mos */
/* 		dual_pre*dual_pre_mos */
/* 		dual_post*dual_post_mos */
/* 		lis_pre*lis_pre_mos */
/* 		lis_post*lis_post_mos */
/* 		/ list missing; */
/* run; */
/*  */
/* proc print data=mbsf_flags (obs=10); */
/* 	var bene_id no_moving_pre no_moving_post zip:; */
/* run; */
/*  */
/* proc means data=mbsf_flags; */
/* 	var age FFS_pre_mos FFS_post_mos MA_pre_mos MA_post_mos ptd_pre_mos ptd_post_mos days_to_death; */
/* run; */
/*  */
/* proc freq data=mbsf_flags; */
/* 	title "check numbers on recode - no death post"; */
/* 	tables  */
/* 		FFS_post*FFS_post_mos */
/* 		MA_post*MA_post_mos */
/* 		ptd_post*ptd_post_mos */
/* 		dual_post*dual_post_mos */
/* 		lis_post*lis_post_mos */
/* 		/ list missing; */
/* 		where death_post = 0; */
/* run; */
/*  */
/* proc freq data=mbsf_flags; */
/* 	title "check numbers on recode - YES death post"; */
/* 	tables  */
/* 		FFS_post*FFS_post_mos*months_to_death */
/* 		MA_post*MA_post_mos*months_to_death */
/* 		ptd_post*ptd_post_mos*months_to_death */
/* 		dual_post*dual_post_mos*months_to_death */
/* 		lis_post*lis_post_mos*months_to_death */
/* 		/ list missing; */
/* 		where death_post = 1; */
/* run; */


data SH070617.&storm._mbsf_elig
	(keep=
	storm
	year_of_storm
	state_abbr
	state_code
	storm_state
	index_date
	obs_start_date
	obs_end_date
	bene_id
	rti_race_cd 
	sex_ident_cd 
	race4c
	white
	black
	Hispanic
	othrace
	male
	zip9_pre 
	zip9_index 
	zip9_post
	zip5_pre 
	zip5_index 
	zip5_post
	bene_birth_dt 
	bene_death_dt 
	age 
	age66p 
	death_pre 
	death_post 
	days_to_death 
	months_to_death 
	no_moving_pre 
	no_moving_post 
	FFS_pre_mos 
	FFS_post_mos 
	FFS_pre 
	FFS_post 
	ma_pre_mos 
	ma_post_mos 
	ma_pre 
	ma_post 
	PTD_pre_mos 
	PTD_post_mos 
	PTD_pre 
	PTD_post 
	dual_pre 
	dual_post 
	lis_pre 
	lis_post 
	dual_pre_mos
	dual_post_mos
	lis_pre_mos
	lis_post_mos
	);
	set mbsf_flags;
run;

proc contents data=SH070617.&storm._mbsf_elig varnum; run;
proc print data=SH070617.&storm._mbsf_elig (obs=5); run;
	
proc means data=SH070617.&storm._mbsf_elig;
    title "check days to death where death_pre = 0 and age66p = 1 and no_moving_pre = 1 and no_moving_post = 1";
    var days_to_death;
    where death_pre = 0 and age66p = 1 and no_moving_pre = 1 and no_moving_post = 1;
run;

proc sql;
	create table row1 as
	select "All benes identified for &storm. - &index_year." as description format=$256.
		, count(*) as Benes
		, "None" as restriction format=$256.
	from SH070617.&storm._mbsf_elig
	;
	
	create table row2 as
	select "And alive on date of storm" as description format=$256.
		, count(*) as Benes
		, "where death_pre = 0" as restriction format=$256.
	from SH070617.&storm._mbsf_elig
	where death_pre = 0
	;
	
	create table row3 as
	select "And age 66+ on date of storm" as description format=$256.
		, count(*) as Benes
		, "where death_pre = 0 and age66p = 1" as restriction format=$256.
	from SH070617.&storm._mbsf_elig
	where death_pre = 0 and age66p = 1
	;
	
	create table row4 as
	select "And did not move in pre-index year to index year" as description format=$256.
		, count(*) as Benes
		, "where death_pre = 0 and age66p = 1 and no_moving_pre = 1" as restriction format=$256.
	from SH070617.&storm._mbsf_elig
	where death_pre = 0 and age66p = 1 and no_moving_pre = 1
	;

	create table row5 as
	select "And did not move in index year to post-index year" as description format=$256.
		, count(*) as Benes
		, "where death_pre = 0 and age66p = 1 and no_moving_pre = 1 and no_moving_post = 1" as restriction format=$256.
	from SH070617.&storm._mbsf_elig
	where death_pre = 0 and age66p = 1 and no_moving_pre = 1 and no_moving_post = 1
	;

	create table row6 as
	select "And died in year post-index" as description format=$256.
		, count(*) as Benes
		, "where death_pre = 0 and age66p = 1 and no_moving_pre = 1 and no_moving_post = 1 and death_post = 1" as restriction format=$256.
	from SH070617.&storm._mbsf_elig
	where death_pre = 0 and age66p = 1 and no_moving_pre = 1 and no_moving_post = 1 and death_post = 1
	;
quit;

data restrictions;
	format description $256. benes best8. restriction $256.;
	set row1-row6;
run;

proc print data=restrictions; title "restictions for &storm."; run;

%mend;

%mbsf_elig_storm(allison);
%mbsf_elig_storm(charley);
%mbsf_elig_storm(florence);
%mbsf_elig_storm(frances);
%mbsf_elig_storm(harvey);
%mbsf_elig_storm(ike);
%mbsf_elig_storm(irene);
%mbsf_elig_storm(irma);
%mbsf_elig_storm(ivan);
%mbsf_elig_storm(katrina);
%mbsf_elig_storm(matthew);
%mbsf_elig_storm(michael);
%mbsf_elig_storm(rita);
%mbsf_elig_storm(sandy);
%mbsf_elig_storm(wilma);



  
