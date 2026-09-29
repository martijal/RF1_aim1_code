
/*start-header
################################################################################
# Type of File     : SAS
#
# Program Name     : 146_psmatch_rr.sas
#			
# Program Path     : sasCCW\Files\dua_070617_jma617\code
#
# Programmed By    : Jonathan Martindale
#
# Date Created     : 14Aug2026	
#
# Project Title    : Bell-Davis RF1
#
# Purpose          : ps-matched sensitivity analyses. PS match at storm-zip to account for clustering
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

    /* create new storm-zip identifier for ps-matching */
    length storm_zip $25.;
    storm_zip = catx("-", storm, zip5_index);

    where ruca3cat ^= 99;
run;


/* aggregate to storm-zip level for matching */
proc sql;
    create table zip_storm_cohort as 
    select storm_zip
    , storm
    , high_rain_by_wind_time
    , mean(age) as mean_age
    , mean(male) as pct_male
    , mean(white) as pct_white_race
    , mean(black) as pct_black_race
    , mean(hispanic) as pct_hispanic_race
    , mean(othrace) as pct_oth_race
    , mean(cfi_score_no_adrd) as mean_cfi
    , mean(dual_pre) as pct_dual
    , mean(ffs_pre) as pct_ffs
    , max(ruca3cat) as ruca3cat
    from cohort
    group by storm_zip, storm, high_rain_by_wind_time
    ;
quit;

proc freq data=cohort;
    title "check original numbers by exposure";
    tables high_rain_by_wind_time / missing;
run;

proc freq data=zip_storm_cohort;
    title "check zip-aggregated numbers by exposure";
    tables high_rain_by_wind_time (ruca3cat storm)*high_rain_by_wind_time / missing;
run;

proc sort data=zip_storm_cohort; by high_rain_by_wind_time; run;

proc means data=zip_storm_cohort n mean std min p25 median p75 max;
    by high_rain_by_wind_time;
    var mean_age 
        pct_male 
        pct_white_race 
        pct_black_race 
        pct_hispanic_race
        pct_oth_race
        mean_cfi
        pct_dual
        pct_ffs
        ;
run;


proc psmatch data=zip_storm_cohort region=cs;
    title "ps-matching";

    /* Categorical matching variables */
    class high_rain_by_wind_time ruca3cat storm;

    /* Model the probability of exposure */
    psmodel high_rain_by_wind_time(treated='1') =
        mean_age 
        pct_male 
        pct_white_race 
        pct_black_race 
        pct_hispanic_race
        pct_oth_race
        mean_cfi
        pct_dual
        pct_ffs
        ruca3cat 
        storm
        ;

    /* 1:1 nearest-neighbor matching without replacement */
    match method=greedy(k=1)
        stat=lps
        caliper=0.20
        exact=(storm ruca3cat)
        ;

    /* check balance before and after matching */
    assess lps
        var=(
            mean_age 
            pct_male 
            pct_white_race 
            pct_black_race 
            pct_hispanic_race
            pct_oth_race
            mean_cfi
            pct_dual
            pct_ffs
        )
        / plots=(boxplot barchart)
        ;

    /* save matched observations and matched-set identifiers */
    output out(obs=match)=matched_storm_zip
        matchid=_geo_match_id
        ;
run;



/* merge geo-matched IDs back onto original cohort */
proc sort data=cohort; by storm_zip; run;

proc sort data=matched_storm_zip
    out=geo_matches(keep=storm_zip _geo_match_id);
    by storm_zip;
run;

data cohort_matched;
    merge cohort(in=a)
          geo_matches(in=b)
          ;
    by storm_zip;
    if a and b;
run;


/* check zips included  from pre-post match */
proc sql;
    title "number of zipcodes and benes from original cohort";
    select high_rain_by_wind_time
        , count(*) as benes
        , count(distinct storm_zip) as u_storm_zip
    from cohort
    group by high_rain_by_wind_time
    ;

    title "number of zipcodes and benes from matched cohort";
    select high_rain_by_wind_time 
        , count(*) as benes
        , count(distinct storm_zip) as u_storm_zip
    from cohort_matched
    group by high_rain_by_wind_time
    ;
quit;

/* check numbers for cause of death */
proc freq data=cohort_matched;
    title "cause of death in matched cohort by exposure";
    tables cod*high_rain_by_wind_time /  missing;
run;


/* Table 3 - Hazard Ratios */
%macro test_cod(data, exposure_vars);
proc phreg data=&data. covs(aggregate);
	title1 "T3: ALL CAUSE Mortality - Exposure: &exposure_vars.";
    title2 "Unadjusted estimates - with COVS(aggregate) and CLUSTER on _geo_match_id";
    format high_rain_by_wind_time rain_wind_time_fmt.;
	class cod(ref=FIRST) _geo_match_id z_all_high_wind(ref=FIRST) male (ref=FIRST) race4c (ref=FIRST) dual_pre (ref=FIRST) ffs_pre (ref=FIRST) ruca3cat (ref=FIRST)
        high_rain_by_wind_time(ref="No high rain or wind time");
	model days_follow_up*death_post_ndi(0) = &exposure_vars.;
    id _geo_match_id;
run;

proc phreg data=&data. covs(aggregate);
    title2 "Adjusted estimates - with COVS(aggregate) and CLUSTER on _geo_match_id";
    format high_rain_by_wind_time rain_wind_time_fmt.;
	class cod(ref=FIRST) _geo_match_id z_all_high_wind(ref=FIRST) male (ref=FIRST) race4c (ref=FIRST) dual_pre (ref=FIRST) ffs_pre (ref=FIRST) ruca3cat (ref=FIRST)
        high_rain_by_wind_time(ref="No high rain or wind time");
	model days_follow_up*death_post_ndi(0) = &exposure_vars. age male race4c cfi_score_no_adrd dual_pre ffs_pre ruca3cat;
    id _geo_match_id;
run;

%do i=1 %to 10;
proc phreg data=&data. covs(aggregate);
	title1 "T3: Exp: &exposure_vars.. Event of interest value = &i.";
    title2 "Unadjusted estimates - with COVS(aggregate) and CLUSTER on _geo_match_id";
    format high_rain_by_wind_time rain_wind_time_fmt.;
	class cod(ref=FIRST) _geo_match_id z_all_high_wind(ref=FIRST) male (ref=FIRST) race4c (ref=FIRST) dual_pre (ref=FIRST) ffs_pre (ref=FIRST) ruca3cat (ref=FIRST)
        high_rain_by_wind_time(ref="No high rain or wind time");
	model days_follow_up*cod(0) = &exposure_vars. / eventcode=&i ;
    id _geo_match_id;
run;


proc phreg data=&data. covs(aggregate);
    title2 "Adjusted estimates - with COVS(aggregate) and CLUSTER on _geo_match_id";
    format high_rain_by_wind_time rain_wind_time_fmt.;
	class cod(ref=FIRST) _geo_match_id z_all_high_wind(ref=FIRST) male (ref=FIRST) race4c (ref=FIRST) dual_pre (ref=FIRST) ffs_pre (ref=FIRST) ruca3cat (ref=FIRST)
        high_rain_by_wind_time(ref="No high rain or wind time");
	model days_follow_up*cod(0) = &exposure_vars. age male race4c cfi_score_no_adrd dual_pre ffs_pre ruca3cat / eventcode=&i ;
    id _geo_match_id;
run;
%end;

%mend;

/*%test_cod(cohort_matched, high_rain_by_wind_time)*/


data SH070617.all_storms_first_elig_matched (keep=bene_id days_follow_up cod high_rain_by_wind_time age male race4c cfi_score_no_adrd dual_pre ffs_pre ruca3cat zip_year _geo_match_id);
    set cohort_matched;
run;


proc export data=SH070617.all_storms_first_elig_matched 
	dbms=xlsx
	outfile="/sas/vrdc/users/jma617/files/dua_070617_jma617/results/all_storms_first_elig_matched.xlsx"
	replace;
run;
