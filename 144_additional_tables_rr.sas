
/*start-header
################################################################################
# Type of File     : SAS
#
# Program Name     : 144_additional_tables_rr.sas
#			
# Program Path     : sasCCW\Files\dua_070617_jma617\code
#
# Programmed By    : Jonathan Martindale
#
# Date Created     : 06Aug2026	
#
# Project Title    : Bell-Davis RF1
#
# Purpose          : generate additional output tables and run sensitivity analyses
#
# Input files      : SH070617.all_storms_first_elig
#
# Output file      : 
#
#################################################################################
end-header*/
ods graphics on;

proc contents data=SH070617.all_storms_first_elig; run;

proc format; 
    value rain_wind_time_fmt
        0 = "No high rain or wind time"
        1 = "High rain or wind time or both"
        ;

    value rain_wind_time2_fmt
        0 = "No high rain or wind time"
        1 = "High rain OR wind time"
        2 = "High rain AND wind time"
        ;

    value cod_fmt
        0 = "no death"
        1 = "ADRD"
        2 = "Cardiovascular Disease"
        3 = "Cerebrovascular disease"
        4 = "Cancer"
        5 = "Pneumonia"
        6 = "Chronic Respiratory Disease"
        7 = "Genitourinary diseases"
        8 = "Gastrointestinal diseases"
        9 = "Injuries"
        10 = "All other"
        ;

run;


data cohort;
	set SH070617.all_storms_first_elig;

    format m_post_index0-m_post_index12 date9.;
    array a_dates(*) m_post_index0-m_post_index11;
    array a2_dates(*) m_post_index1-m_post_index12;
    array a_death_months(*) death_month1-death_month12;

    m_post_index0 = index_date;

    do i = 1 to 12;
        a2_dates(i) = intnx("month", index_date, i, "S");
    end;

    do i = 1 to 12;
        if death_post_ndi = 1 then do;
            a_death_months(i) = (a_dates(i) <= ndi_death_dt < a2_dates(i));
        end;
    end;

    where ruca3cat ^= 99;
run;


/* Storm Table */
%macro storm_table(storm, row_num);

proc sql;

	create table row&row_num. as
	select "&storm" as storm format=$256.
        , min(index_date) as index_date_min format=date9.
        , max(index_date) as index_date_max format=date9.
		, max(vmax_sust_mph) as max_sust_wind_mph
		, max(vmax_sust_mph) as max_sust_wind_mph
        , max(vmax_sust_above_34kt_dur) as max_dur_trop_storm_wind
		, max(total_prcp_in) as max_prcp_in
		, count(distinct zip5_index) as n_zip
        , sum(death_post_ndi) as n_adrd_deaths
	from cohort
    where lowcase(storm) in("&storm.")
	;
quit;

%mend;

%storm_table(allison, 1);
%storm_table(charley, 2);
%storm_table(florence, 3);
%storm_table(frances, 4);
%storm_table(harvey, 5);
%storm_table(ike, 6);
%storm_table(irene, 7);
%storm_table(irma, 8);
%storm_table(ivan, 9);
%storm_table(katrina, 10);
%storm_table(matthew, 11);
%storm_table(michael, 12);
%storm_table(rita, 13);
%storm_table(sandy, 14);
%storm_table(wilma, 15);

data storm_info;
    format index_date_min index_date_max date9.;
    set row1-row15;
run;

proc print data=storm_info; title "storm info table"; run;

proc export data=storm_info
	dbms=xlsx
	outfile="/sas/vrdc/users/jma617/files/dua_070617_jma617/results/storm_tables_rr.xlsx"
	replace;
	sheet="storm_tables";
run;





%macro monthly_deaths(cod_var, cod_name);
proc sql;
	create table row1 as
	select "&cod_name." as description format=$256.
        , sum(death_month1) as death_month1
        , sum(death_month2) as death_month2
        , sum(death_month3) as death_month3
        , sum(death_month4) as death_month4
        , sum(death_month5) as death_month5
        , sum(death_month6) as death_month6
        , sum(death_month7) as death_month7
        , sum(death_month8) as death_month8
        , sum(death_month9) as death_month9
        , sum(death_month10) as death_month10
        , sum(death_month11) as death_month11
        , sum(death_month12) as death_month12
	from cohort
    where (high_rain_by_wind_time = 1 and &cod_var. = 1)
	;

	create table row2 as
	select "Male, 66-74" as description format=$256.
        , sum(death_month1) as death_month1
        , sum(death_month2) as death_month2
        , sum(death_month3) as death_month3
        , sum(death_month4) as death_month4
        , sum(death_month5) as death_month5
        , sum(death_month6) as death_month6
        , sum(death_month7) as death_month7
        , sum(death_month8) as death_month8
        , sum(death_month9) as death_month9
        , sum(death_month10) as death_month10
        , sum(death_month11) as death_month11
        , sum(death_month12) as death_month12
	from cohort
    where (high_rain_by_wind_time = 1 and &cod_var. = 1
        and female = 0 and age6674 = 1)
	;

	create table row3 as
	select "Male, 75-84" as description format=$256.
        , sum(death_month1) as death_month1
        , sum(death_month2) as death_month2
        , sum(death_month3) as death_month3
        , sum(death_month4) as death_month4
        , sum(death_month5) as death_month5
        , sum(death_month6) as death_month6
        , sum(death_month7) as death_month7
        , sum(death_month8) as death_month8
        , sum(death_month9) as death_month9
        , sum(death_month10) as death_month10
        , sum(death_month11) as death_month11
        , sum(death_month12) as death_month12
	from cohort
    where (high_rain_by_wind_time = 1 and &cod_var. = 1
        and female = 0 and age7584 = 1)
	;

	create table row4 as
	select "Male, 85+" as description format=$256.
        , sum(death_month1) as death_month1
        , sum(death_month2) as death_month2
        , sum(death_month3) as death_month3
        , sum(death_month4) as death_month4
        , sum(death_month5) as death_month5
        , sum(death_month6) as death_month6
        , sum(death_month7) as death_month7
        , sum(death_month8) as death_month8
        , sum(death_month9) as death_month9
        , sum(death_month10) as death_month10
        , sum(death_month11) as death_month11
        , sum(death_month12) as death_month12
	from cohort
    where (high_rain_by_wind_time = 1 and &cod_var. = 1
        and female = 0 and age85p = 1)
	;


	create table row5 as
	select "Female, 66-74" as description format=$256.
        , sum(death_month1) as death_month1
        , sum(death_month2) as death_month2
        , sum(death_month3) as death_month3
        , sum(death_month4) as death_month4
        , sum(death_month5) as death_month5
        , sum(death_month6) as death_month6
        , sum(death_month7) as death_month7
        , sum(death_month8) as death_month8
        , sum(death_month9) as death_month9
        , sum(death_month10) as death_month10
        , sum(death_month11) as death_month11
        , sum(death_month12) as death_month12
	from cohort
    where (high_rain_by_wind_time = 1 and &cod_var. = 1
        and female = 1 and age6674 = 1)
	;

	create table row6 as
	select "Female, 75-84" as description format=$256.
        , sum(death_month1) as death_month1
        , sum(death_month2) as death_month2
        , sum(death_month3) as death_month3
        , sum(death_month4) as death_month4
        , sum(death_month5) as death_month5
        , sum(death_month6) as death_month6
        , sum(death_month7) as death_month7
        , sum(death_month8) as death_month8
        , sum(death_month9) as death_month9
        , sum(death_month10) as death_month10
        , sum(death_month11) as death_month11
        , sum(death_month12) as death_month12
	from cohort
    where (high_rain_by_wind_time = 1 and &cod_var. = 1
        and female = 1 and age7584 = 1)
	;

	create table row7 as
	select "Female, 85+" as description format=$256.
        , sum(death_month1) as death_month1
        , sum(death_month2) as death_month2
        , sum(death_month3) as death_month3
        , sum(death_month4) as death_month4
        , sum(death_month5) as death_month5
        , sum(death_month6) as death_month6
        , sum(death_month7) as death_month7
        , sum(death_month8) as death_month8
        , sum(death_month9) as death_month9
        , sum(death_month10) as death_month10
        , sum(death_month11) as death_month11
        , sum(death_month12) as death_month12
	from cohort
    where (high_rain_by_wind_time = 1 and &cod_var. = 1
        and female = 1 and age85p = 1)
	;
quit;

data &cod_var.;
    format description $256.;
    set row1-row7;
run;

/*proc print data=cod_&cod_name.; run;*/
%mend;

%monthly_deaths(death_post_ndi, AllDeaths);
%monthly_deaths(cod_adrd, ADRD);
%monthly_deaths(cod_cvd, CardiovascularDisease);
%monthly_deaths(cod_cbvd, CerebrovascularDisease);
%monthly_deaths(cod_cancer, Cancers);
%monthly_deaths(cod_pneumonia, Pneumonia);
%monthly_deaths(cod_chron_resp, ChronicRespiratoryDisease);
%monthly_deaths(cod_genitourinary, GenitourinaryDeseases);
%monthly_deaths(cod_gastrointestinal, GastrointestinalDiseases);
%monthly_deaths(cod_injury, Injuries);
%monthly_deaths(cod_other, AllOther);


data monthly_death_counts;
    format description $256.;
    set death_post_ndi
        cod_adrd
        cod_cvd
        cod_cbvd
        cod_cancer
        cod_pneumonia
        cod_chron_resp
        cod_genitourinary
        cod_gastrointestinal
        cod_injury
        cod_other
        ;
run;

proc print data=monthly_death_counts; title "monthly death counts by cause of death"; run;


proc export data=monthly_death_counts
	dbms=xlsx
	outfile="/sas/vrdc/users/jma617/files/dua_070617_jma617/results/monthly_death_counts_rr.xlsx"
	replace;
	sheet="monthly_deaths";
run;


**************************************************;
* 3-month follow-up for sensitivity analyses;
**************************************************;
data cohort_3mo;
	set SH070617.all_storms_first_elig;

    days_follow_up = 90;
    death_post_ndi = 0;
    days_to_death_ndi = 0;

    if ndi_death_dt ^= . then do;
		if (ndi_death_dt >= index_date) and (ndi_death_dt <= index_date + 90) then do;
			death_post_ndi = 1;
			days_to_death_ndi = intck("days", index_date, ndi_death_dt);
			days_follow_up = intck("days", index_date, ndi_death_dt);
		end;
	end;

	where ruca3cat ^= 99;
run;

proc contents data=cohort_3mo; run;

proc sort data=cohort_3mo; by death_post_ndi; run;
proc means data=cohort_3mo;
    class death_post_ndi;
    var days_follow_up days_to_death_ndi;
run;

/* Table 3 - Hazard Ratios */
%macro test_cod(exposure_vars, data);
proc phreg data=&data. covs(aggregate);
	title1 "T3: ALL CAUSE Mortality - Exposure: &exposure_vars.";
    title2 "Unadjusted estimates - with COVS(aggregate) and CLUSTER on zip_year";
    format high_rain_by_wind_time rain_wind_time_fmt.;
	class cod(ref=FIRST) zip_year z_all_high_wind(ref=FIRST) male (ref=FIRST) race4c (ref=FIRST) dual_pre (ref=FIRST) ffs_pre (ref=FIRST) ruca3cat (ref=FIRST)
        high_rain_by_wind_time(ref="No high rain or wind time");
	model days_follow_up*death_post_ndi(0) = &exposure_vars.;
    id zip_year;
run;

proc phreg data=&data. covs(aggregate);
    title2 "Adjusted estimates - with COVS(aggregate) and CLUSTER on zip_year";
    format high_rain_by_wind_time rain_wind_time_fmt.;
	class cod(ref=FIRST) zip_year z_all_high_wind(ref=FIRST) male (ref=FIRST) race4c (ref=FIRST) dual_pre (ref=FIRST) ffs_pre (ref=FIRST) ruca3cat (ref=FIRST)
        high_rain_by_wind_time(ref="No high rain or wind time");
	model days_follow_up*death_post_ndi(0) = &exposure_vars. age male race4c cfi_score_no_adrd dual_pre ffs_pre ruca3cat;
    id zip_year;
run;

%do i=1 %to 10;
proc phreg data=&data. covs(aggregate);
	title1 "T3: Exp: &exposure_vars.. Event of interest value = &i.";
    title2 "Unadjusted estimates - with COVS(aggregate) and CLUSTER on zip_year";
    format high_rain_by_wind_time rain_wind_time_fmt.;
	class cod(ref=FIRST) zip_year z_all_high_wind(ref=FIRST) male (ref=FIRST) race4c (ref=FIRST) dual_pre (ref=FIRST) ffs_pre (ref=FIRST) ruca3cat (ref=FIRST)
        high_rain_by_wind_time(ref="No high rain or wind time");
	model days_follow_up*cod(0) = &exposure_vars. / eventcode=&i ;
    id zip_year;
run;


proc phreg data=&data. covs(aggregate);
    title2 "Adjusted estimates - with COVS(aggregate) and CLUSTER on zip_year";
    format high_rain_by_wind_time rain_wind_time_fmt.;
	class cod(ref=FIRST) zip_year z_all_high_wind(ref=FIRST) male (ref=FIRST) race4c (ref=FIRST) dual_pre (ref=FIRST) ffs_pre (ref=FIRST) ruca3cat (ref=FIRST)
        high_rain_by_wind_time(ref="No high rain or wind time");
	model days_follow_up*cod(0) = &exposure_vars. age male race4c cfi_score_no_adrd dual_pre ffs_pre ruca3cat / eventcode=&i ;
    id zip_year;
run;
%end;

%mend;

%test_cod(high_rain_by_wind_time, cohort_3mo)


data SH070617.all_storms_first_elig_3mo (keep=bene_id days_follow_up cod high_rain_by_wind_time age male race4c cfi_score_no_adrd dual_pre ffs_pre ruca3cat zip_year _geo_match_id);
    set cohort_3mo;
run;


proc export data=SH070617.all_storms_first_elig_3mo 
	dbms=xlsx
	outfile="/sas/vrdc/users/jma617/files/dua_070617_jma617/results/all_storms_first_elig_3mo.xlsx"
	replace;
run;
