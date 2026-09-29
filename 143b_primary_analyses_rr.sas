

/*start-header
################################################################################
# Type of File     : SAS
#
# Program Name     : 143_primary_analyses.sas
#			
# Program Path     : sasCCW\Files\dua_070617_jma617\code
#
# Programmed By    : Jonathan Martindale
#
# Date Created     : 04Jun2025	
#
# Project Title    : Bell-Davis RF1
#
# Purpose          : Primary analyses for paper - Aim 1
#
# Input files      : SH070617.all_storms_full_cohort
#
# Output file      : 
#
#################################################################################
end-header*/
ods graphics on;

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


data cohort_all;
	set SH070617.all_storms_full_cohort;

    cfi_score_no_adrd = cfi_score_no_adrd*100;
    
	where death_pre = 0 
		and age66p = 1 
		and no_moving_pre = 1 
		and (ffs_pre = 1 or ma_pre = 1) 
		and adrd = 1 
		and mds_pre = 0
        and no_miss = 1
        and complete_exp_data = 1
        and ruca3cat ^= 99;
		;
run;

proc contents data=cohort_all; run;

proc sort data=cohort_all;
    by bene_id index_date;
run;

data cohort;
    set cohort_all;
    by bene_id;
    if first.bene_id then output;
run;

data SH070617.all_storms_first_elig;
    set cohort;
run;

proc sql;
    title "final cohort, limited to only the first instance of eligibility";
    select count(*) as recs
        , count(distinct bene_id) as u_benes
    from cohort
    ;
quit;

proc contents data=cohort; run;



/* TABLE 1 - all */
%macro table1_all(suffix);

proc sql;
    select count(*)
        into :n
    from cohort
    
    ;

	create table row1 as
	select "Sample Size" as description format=$256.
		, count(*) as freq_&suffix.
		, count(*) / &n. as pct_&suffix.
	from cohort
    
	;

	create table row2 as
	select "Exposure" as description format=$256.
		, count(*) as freq_&suffix.
		, count(*) / &n. as pct_&suffix.
	from cohort
    
	;

	create table row3 as
	select "Exposed to high wind time, No. (%)" as description format=$256.
		, sum(z_all_high_wind_time) as freq_&suffix.
		, sum(z_all_high_wind_time) / &n. as pct_&suffix.
	from cohort
    
	;
    
	create table row4 as
	select "Exposed to high rain, No. (%)" as description format=$256.
		, sum(z_all_high_prcp) as freq_&suffix.
		, sum(z_all_high_prcp) / &n. as pct_&suffix.
	from cohort
    
	;
        
	create table row5 as
	select "Mean wind time exposure (Unstandardized in minutes)" as description format=$256.
		, mean(vmax_sust_above_34kt_dur) as freq_&suffix.
		, std(vmax_sust_above_34kt_dur) as pct_&suffix.
	from cohort
    
	;
        
	create table row6 as
	select "Mean wind time exposure (Standardized)" as description format=$256.
		, mean(z_all_min_wind_above_34kt) as freq_&suffix.
		, std(z_all_min_wind_above_34kt) as pct_&suffix.
	from cohort
    
	;

	create table row7 as
	select "Mean rain exposure (Unstandardized in inches)" as description format=$256.
		, mean(total_prcp_in) as freq_&suffix.
		, std(total_prcp_in) as pct_&suffix.
	from cohort
    
	;
        
	create table row8 as
	select "Mean rain exposure (Standardized)" as description format=$256.
		, mean(z_all_total_prcp) as freq_&suffix.
		, std(z_all_total_prcp) as pct_&suffix.
	from cohort
    
	;

	create table row9 as
	select "Sociodemographic Characteristics" as description format=$256.
		, count(*) as freq_&suffix.
		, count(*) / &n. as pct_&suffix.
	from cohort
    
	;

	create table row10 as
	select "Mean age in years (SD)" as description format=$256.
		, mean(age) as freq_&suffix.
		, std(age) as pct_&suffix.
	from cohort
    
	;

	create table row11 as
	select "Age category in years, No. (%)" as description format=$256.
		, count(*) as freq_&suffix.
		, count(*) / &n. as pct_&suffix.
	from cohort
    
	;

	create table row12 as
	select "66 to 74" as description format=$256.
		, sum(age6674) as freq_&suffix.
		, sum(age6674) / &n. as pct_&suffix.
	from cohort
    
	;

	create table row13 as
	select "75 to 84" as description format=$256.
		, sum(age7584) as freq_&suffix.
		, sum(age7584) / &n. as pct_&suffix.
	from cohort
    
	;

	create table row14 as
	select "85 or older" as description format=$256.
		, sum(age85p) as freq_&suffix.
		, sum(age85p) / &n. as pct_&suffix.
	from cohort
    
	;

	create table row15 as
	select "Sex, No. (%)" as description format=$256.
		, count(*) as freq_&suffix.
		, count(*) / &n. as pct_&suffix.
	from cohort
    
	;

	create table row16 as
	select "Male" as description format=$256.
		, sum(male) as freq_&suffix.
		, sum(male) / &n. as pct_&suffix.
	from cohort
    
	;

	create table row17 as
	select "Female" as description format=$256.
		, sum(female) as freq_&suffix.
		, sum(female) / &n. as pct_&suffix.
	from cohort
    
	;

	create table row18 as
	select "Race/Ethnicity, No. (%)" as description format=$256.
		, count(*) as freq_&suffix.
		, count(*) / &n. as pct_&suffix.
	from cohort
    
	;

	create table row19 as
	select "Non-Hispanic White" as description format=$256.
		, sum(white) as freq_&suffix.
		, sum(white) / &n. as pct_&suffix.
	from cohort
    
	;

	create table row20 as
	select "Non-Hispanic Black" as description format=$256.
		, sum(black) as freq_&suffix.
		, sum(black) / &n. as pct_&suffix.
	from cohort
    
	;

	create table row21 as
	select "Latino/Hispanic" as description format=$256.
		, sum(hispanic) as freq_&suffix.
		, sum(hispanic) / &n. as pct_&suffix.
	from cohort
    
	;

	create table row22 as
	select "Other" as description format=$256.
		, sum(othrace) as freq_&suffix.
		, sum(othrace) / &n. as pct_&suffix.
	from cohort
    
	;

	create table row23 as
	select "Rurality, No. (%)" as description format=$256.
		, count(*) as freq_&suffix.
		, count(*) / &n. as pct_&suffix.
	from cohort
    
	;

	create table row24 as
	select "Metropolitan" as description format=$256.
		, sum(ruca_metropolitan) as freq_&suffix.
		, sum(ruca_metropolitan) / &n. as pct_&suffix.
	from cohort
    
	;

	create table row25 as
	select "Micropolitan" as description format=$256.
		, sum(ruca_micropolitan) as freq_&suffix.
		, sum(ruca_micropolitan) / &n. as pct_&suffix.
	from cohort
    
	;

	create table row26 as
	select "Small Town/Rural" as description format=$256.
		, sum(ruca_rural) as freq_&suffix.
		, sum(ruca_rural) / &n. as pct_&suffix.
	from cohort
    
	;

	create table row27 as
	select "Missing rurality data" as description format=$256.
		, sum(ruca_missing) as freq_&suffix.
		, sum(ruca_missing) / &n. as pct_&suffix.
	from cohort
    
	;

	create table row28 as
	select "Healthcare Insurance" as description format=$256.
		, count(*) as freq_&suffix.
		, count(*) / &n. as pct_&suffix.
	from cohort
    
	;
    
	create table row29 as
	select "Dual eligibility status, No. (%)" as description format=$256.
		, count(*) as freq_&suffix.
		, count(*) / &n. as pct_&suffix.
	from cohort
    
	;

	create table row30 as
	select "NA - prior to 2006" as description format=$256.
		, sum(dual_elig_na) as freq_&suffix.
		, sum(dual_elig_na) / &n. as pct_&suffix.
	from cohort
    
	;

	create table row31 as
	select "Dual eligible - 2006 and later" as description format=$256.
		, sum(dual_elig_yes) as freq_&suffix.
		, sum(dual_elig_yes) / &n. as pct_&suffix.
	from cohort
    
	;

	create table row32 as
	select "Medicare only - 2006 and later" as description format=$256.
		, sum(dual_elig_no) as freq_&suffix.
		, sum(dual_elig_no) / &n. as pct_&suffix.
	from cohort
    
	;

	create table row33 as
	select "Insurance enrollment status, No. (%)" as description format=$256.
		, count(*) as freq_&suffix.
		, count(*) / &n. as pct_&suffix.
	from cohort
    
	;

	create table row34 as
	select "Medicare Advantage - 2015 and later" as description format=$256.
		, sum(ma_pre) as freq_&suffix.
		, sum(ma_pre) / &n. as pct_&suffix.
	from cohort
    
	;

	create table row35 as
	select "Fee-for-service" as description format=$256.
		, sum(ffs_pre) as freq_&suffix.
		, sum(ffs_pre) / &n. as pct_&suffix.
	from cohort
    
	;

	create table row36 as
	select "Health status" as description format=$256.
		, count(*) as freq_&suffix.
		, count(*) / &n. as pct_&suffix.
	from cohort
    
	;

	create table row37 as
	select "Elixhauser mean number of conditions (SD)" as description format=$256.
		, mean(num_elix_pre) as freq_&suffix.
		, std(num_elix_pre) as pct_&suffix.
	from cohort
    
	;

	create table row38 as
	select "Elixhauser median number of conditions (IQR)" as description format=$256.
		, median(num_elix_pre) as freq_&suffix.
		, sum(num_elix_pre) / &n. as pct_&suffix.
	from cohort
    
	;

	create table row39 as
	select "No. of Elixhauser co-morbidities, No. (%)" as description format=$256.
		, count(*) as freq_&suffix.
		, count(*) / &n. as pct_&suffix.
	from cohort
    
	;

	create table row40 as
	select "0 co-morbidities" as description format=$256.
		, sum(elix_low) as freq_&suffix.
		, sum(elix_low) / &n. as pct_&suffix.
	from cohort
    
	;

	create table row41 as
	select "1-2 co-morbidities" as description format=$256.
		, sum(elix_med) as freq_&suffix.
		, sum(elix_med) / &n. as pct_&suffix.
	from cohort
    
	;

	create table row42 as
	select "3+ co-morbidities" as description format=$256.
		, sum(elix_hi) as freq_&suffix.
		, sum(elix_hi) / &n. as pct_&suffix.
	from cohort
    
	;

	create table row43 as
	select "CFI score, mean (SD)" as description format=$256.
		, mean(cfi_score) as freq_&suffix.
		, std(cfi_score) as pct_&suffix.
	from cohort
    
	;

	create table row44 as
	select "Adapted CFI score, mean (SD)" as description format=$256.
		, mean(cfi_score_no_adrd) as freq_&suffix.
		, std(cfi_score_no_adrd) as pct_&suffix.
	from cohort
    
	;

	create table row45 as
	select "Adapted CFI score categories, No. (%)" as description format=$256.
		, count(*) as freq_&suffix.
		, count(*) / &n. as pct_&suffix.
	from cohort
    
	;

	create table row46 as
	select "Robust (<0.15)" as description format=$256.
		, sum(cfi_robust) as freq_&suffix.
		, sum(cfi_robust) / &n. as pct_&suffix.
	from cohort
    
	;

	create table row47 as
	select "Prefrail (0.15-0.24)" as description format=$256.
		, sum(cfi_prefrail) as freq_&suffix.
		, sum(cfi_prefrail) / &n. as pct_&suffix.
	from cohort
    
	;

	create table row48 as
	select "Mildly Frail (0.25-0.34)" as description format=$256.
		, sum(cfi_mild) as freq_&suffix.
		, sum(cfi_mild) / &n. as pct_&suffix.
	from cohort
    
	;

	create table row49 as
	select "Moderate-to-severly frail (>=0.35)" as description format=$256.
		, sum(cfi_mod_severe) as freq_&suffix.
		, sum(cfi_mod_severe) / &n. as pct_&suffix.
	from cohort
    
	;

quit;


data table1_&suffix.;
    format description $256. freq_&suffix. best8. pct_&suffix best8.;
    set row1-row49;
run;

%mend table1_all;

%macro table1(exposure, exp_val, suffix);

proc sql;
    select count(*)
        into :n
    from cohort
    where &exposure. in(&exp_val.)
    ;

	create table row1 as
	select "Sample Size" as description format=$256.
		, count(*) as freq_&suffix.
		, count(*) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row2 as
	select "Exposure" as description format=$256.
		, count(*) as freq_&suffix.
		, count(*) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row3 as
	select "Exposed to high wind time, No. (%)" as description format=$256.
		, sum(z_all_high_wind_time) as freq_&suffix.
		, sum(z_all_high_wind_time) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;
    
	create table row4 as
	select "Exposed to high rain, No. (%)" as description format=$256.
		, sum(z_all_high_prcp) as freq_&suffix.
		, sum(z_all_high_prcp) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;
        
	create table row5 as
	select "Mean wind time exposure (Unstandardized in minutes)" as description format=$256.
		, mean(vmax_sust_above_34kt_dur) as freq_&suffix.
		, std(vmax_sust_above_34kt_dur) as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;
        
	create table row6 as
	select "Mean wind time exposure (Standardized)" as description format=$256.
		, mean(z_all_min_wind_above_34kt) as freq_&suffix.
		, std(z_all_min_wind_above_34kt) as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row7 as
	select "Mean rain exposure (Unstandardized in inches)" as description format=$256.
		, mean(total_prcp_in) as freq_&suffix.
		, std(total_prcp_in) as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;
        
	create table row8 as
	select "Mean rain exposure (Standardized)" as description format=$256.
		, mean(z_all_total_prcp) as freq_&suffix.
		, std(z_all_total_prcp) as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row9 as
	select "Sociodemographic Characteristics" as description format=$256.
		, count(*) as freq_&suffix.
		, count(*) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row10 as
	select "Mean age in years (SD)" as description format=$256.
		, mean(age) as freq_&suffix.
		, std(age) as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row11 as
	select "Age category in years, No. (%)" as description format=$256.
		, count(*) as freq_&suffix.
		, count(*) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row12 as
	select "66 to 74" as description format=$256.
		, sum(age6674) as freq_&suffix.
		, sum(age6674) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row13 as
	select "75 to 84" as description format=$256.
		, sum(age7584) as freq_&suffix.
		, sum(age7584) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row14 as
	select "85 or older" as description format=$256.
		, sum(age85p) as freq_&suffix.
		, sum(age85p) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row15 as
	select "Sex, No. (%)" as description format=$256.
		, count(*) as freq_&suffix.
		, count(*) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row16 as
	select "Male" as description format=$256.
		, sum(male) as freq_&suffix.
		, sum(male) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row17 as
	select "Female" as description format=$256.
		, sum(female) as freq_&suffix.
		, sum(female) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row18 as
	select "Race/Ethnicity, No. (%)" as description format=$256.
		, count(*) as freq_&suffix.
		, count(*) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row19 as
	select "Non-Hispanic White" as description format=$256.
		, sum(white) as freq_&suffix.
		, sum(white) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row20 as
	select "Non-Hispanic Black" as description format=$256.
		, sum(black) as freq_&suffix.
		, sum(black) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row21 as
	select "Latino/Hispanic" as description format=$256.
		, sum(hispanic) as freq_&suffix.
		, sum(hispanic) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row22 as
	select "Other" as description format=$256.
		, sum(othrace) as freq_&suffix.
		, sum(othrace) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row23 as
	select "Rurality, No. (%)" as description format=$256.
		, count(*) as freq_&suffix.
		, count(*) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row24 as
	select "Metropolitan" as description format=$256.
		, sum(ruca_metropolitan) as freq_&suffix.
		, sum(ruca_metropolitan) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row25 as
	select "Micropolitan" as description format=$256.
		, sum(ruca_micropolitan) as freq_&suffix.
		, sum(ruca_micropolitan) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row26 as
	select "Small Town/Rural" as description format=$256.
		, sum(ruca_rural) as freq_&suffix.
		, sum(ruca_rural) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row27 as
	select "Missing rurality data" as description format=$256.
		, sum(ruca_missing) as freq_&suffix.
		, sum(ruca_missing) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row28 as
	select "Healthcare Insurance" as description format=$256.
		, count(*) as freq_&suffix.
		, count(*) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;
    
	create table row29 as
	select "Dual eligibility status, No. (%)" as description format=$256.
		, count(*) as freq_&suffix.
		, count(*) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row30 as
	select "NA - prior to 2006" as description format=$256.
		, sum(dual_elig_na) as freq_&suffix.
		, sum(dual_elig_na) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row31 as
	select "Dual eligible - 2006 and later" as description format=$256.
		, sum(dual_elig_yes) as freq_&suffix.
		, sum(dual_elig_yes) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row32 as
	select "Medicare only - 2006 and later" as description format=$256.
		, sum(dual_elig_no) as freq_&suffix.
		, sum(dual_elig_no) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row33 as
	select "Insurance enrollment status, No. (%)" as description format=$256.
		, count(*) as freq_&suffix.
		, count(*) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row34 as
	select "Medicare Advantage - 2015 and later" as description format=$256.
		, sum(ma_pre) as freq_&suffix.
		, sum(ma_pre) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row35 as
	select "Fee-for-service" as description format=$256.
		, sum(ffs_pre) as freq_&suffix.
		, sum(ffs_pre) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row36 as
	select "Health status" as description format=$256.
		, count(*) as freq_&suffix.
		, count(*) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row37 as
	select "Elixhauser mean number of conditions (SD)" as description format=$256.
		, mean(num_elix_pre) as freq_&suffix.
		, std(num_elix_pre) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row38 as
	select "Elixhauser median number of conditions (IQR)" as description format=$256.
		, median(num_elix_pre) as freq_&suffix.
		, sum(num_elix_pre) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row39 as
	select "No. of Elixhauser co-morbidities, No. (%)" as description format=$256.
		, count(*) as freq_&suffix.
		, count(*) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row40 as
	select "0 co-morbidities" as description format=$256.
		, sum(elix_low) as freq_&suffix.
		, sum(elix_low) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row41 as
	select "1-2 co-morbidities" as description format=$256.
		, sum(elix_med) as freq_&suffix.
		, sum(elix_med) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row42 as
	select "3+ co-morbidities" as description format=$256.
		, sum(elix_hi) as freq_&suffix.
		, sum(elix_hi) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row43 as
	select "CFI score, mean (SD)" as description format=$256.
		, mean(cfi_score) as freq_&suffix.
		, std(cfi_score) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row44 as
	select "Adapted CFI score, mean (SD)" as description format=$256.
		, mean(cfi_score_no_adrd) as freq_&suffix.
		, std(cfi_score_no_adrd) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row45 as
	select "Adapted CFI score categories, No. (%)" as description format=$256.
		, count(*) as freq_&suffix.
		, count(*) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row46 as
	select "Robust (<0.15)" as description format=$256.
		, sum(cfi_robust) as freq_&suffix.
		, sum(cfi_robust) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row47 as
	select "Prefrail (0.15-0.24)" as description format=$256.
		, sum(cfi_prefrail) as freq_&suffix.
		, sum(cfi_prefrail) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row48 as
	select "Mildly Frail (0.25-0.34)" as description format=$256.
		, sum(cfi_mild) as freq_&suffix.
		, sum(cfi_mild) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

	create table row49 as
	select "Moderate-to-severly frail (>=0.35)" as description format=$256.
		, sum(cfi_mod_severe) as freq_&suffix.
		, sum(cfi_mod_severe) / &n. as pct_&suffix.
	from cohort
    where &exposure. in(&exp_val.)
	;

quit;


data table1_&suffix.;
    format description $256. freq_&suffix. best8. pct_&suffix best8.;
    set row1-row49;
run;

%mend table1;

%table1_all(suffix = all);
%table1(high_rain_by_wind_time, 0, not_exposed);
%table1(high_rain_by_wind_time, 1, exposed);

data table1;
    merge table1_all table1_not_exposed table1_exposed;
run;

proc print data=table1; run;

proc export data=table1
	dbms=xlsx
	outfile="/sas/vrdc/users/jma617/files/dua_070617_jma617/results/table1_rr.xlsx"
	replace;
	sheet="table1";
run;

proc sort data=cohort; by high_rain_by_wind_time; run;

proc freq data=cohort;
    title "Table 1 categorical variables and p-values";
    tables (z_all_high_wind_time 
            z_all_high_prcp
            age3cat
            male
            race4c
            ruca3cat
            dual_pre
            ma_pre
            elix3cat
            cfi4cat
            )*high_rain_by_wind_time 
            z_all_high_wind_time*z_all_high_prcp  
            / chisq missing;
run;


proc univariate data=cohort;
    title "Table 1 continuous variables - overall";
    var vmax_sust_above_34kt_dur 
        z_all_min_wind_above_34kt
        total_prcp_in
        z_all_high_wind_time
        age
        num_elix_pre
        cfi_score
        cfi_score_no_adrd
    ;
run;

proc univariate data=cohort;
    title "Table 1 continuous variables - by exposure";
    class high_rain_by_wind_time;
    var vmax_sust_above_34kt_dur 
        z_all_min_wind_above_34kt
        total_prcp_in
        z_all_high_wind_time
        age
        num_elix_pre
        cfi_score
        cfi_score_no_adrd
    ;
run;

proc npar1way data=cohort wilcoxon;
    class high_rain_by_wind_time;
    var vmax_sust_above_34kt_dur 
        z_all_min_wind_above_34kt
        total_prcp_in
        z_all_high_wind_time
        age
        num_elix_pre
        cfi_score
        cfi_score_no_adrd
        ;
run;




/* Table 2 */
proc freq data=cohort; 
    title1 "Table 2";
    title2 "check cause of death coding";
    format cod cod_fmt. high_rain_by_wind_time rain_wind_time_fmt.;
    tables storm*(death_post_ndi cod high_rain_by_wind_time)
        / missing; 
run;


proc freq data=cohort; 
    title2 "check death rates by exposure";
    format cod cod_fmt. high_rain_by_wind_time rain_wind_time_fmt.;
    tables death_post_ndi*high_rain_by_wind_time
        (cod cod_adrd cod_cvd cod_cbvd cod_cancer cod_pneumonia cod_chron_resp cod_genitourinary cod_gastrointestinal cod_injury cod_other)*high_rain_by_wind_time
        / chisq missing; 
run;

proc freq data=cohort; 
    title2 "check death rates by exposure where death_post_ndi=1";
    format cod cod_fmt. high_rain_by_wind_time rain_wind_time_fmt.;
    tables 
        (cod cod_adrd cod_cvd cod_cbvd cod_cancer cod_pneumonia cod_chron_resp cod_genitourinary cod_gastrointestinal cod_injury cod_other)*high_rain_by_wind_time
        / chisq missing; 
    where death_post_ndi=1;
run;

proc sort data=cohort; by descending high_rain_by_wind_time; run;

/* full cohort only */
proc sql;
    create table n_epitab_all as
    select "all storms" as storm
        , count(*) as sample_size
    from cohort
    ;

    create table noexp_epitab_all as
    select "all storms" as storm
        , count(*) as count_group_noexp
        , sum(death_post_ndi) as count_death_noexp
    from cohort
    where high_rain_by_wind_time = 0
    group by high_rain_by_wind_time
    ;

    create table exp_epitab_all as
    select "all storms" as storm
        , count(*) as count_group_exp
        , sum(death_post_ndi) as count_death_exp
    from cohort
    where high_rain_by_wind_time = 1
    group by high_rain_by_wind_time
    ;


    create table combo_epitab as
    select high_rain_by_wind_time
        , sum(death_post_ndi) as count_death
        , count(*) as count_group
    from cohort
    group by high_rain_by_wind_time
    order by high_rain_by_wind_time desc
    ;
quit;

data epitab_all;
    merge n_epitab_all noexp_epitab_all exp_epitab_all;
run;

proc freq data=cohort order=data;
    title2 "crosstab for full cohort";
    format cod cod_fmt. high_rain_by_wind_time rain_wind_time_fmt.;
    tables high_rain_by_wind_time*death_post_ndi / riskdiff missing;
run;

proc stdrate data=combo_epitab
             method=mh(af)
             stat=risk
             effect
             ;
    population group(order=data exposed='1')=high_rain_by_wind_time
        event=count_death total=count_group
        ;
run;


%macro table2_epitab(storm);

proc sql;
    create table n_epitab_all as
    select "&storm." as storm
        , count(*) as sample_size
    from cohort
    where lowcase(storm) in("&storm.")
    ;

    create table noexp_epitab_all as
    select "&storm." as storm
        , count(*) as count_group_noexp
        , sum(death_post_ndi) as count_death_noexp
    from cohort
    where high_rain_by_wind_time = 0 and lowcase(storm) in("&storm.")
    group by high_rain_by_wind_time
    ;

    create table exp_epitab_all as
    select "&storm." as storm
        , count(*) as count_group_exp
        , sum(death_post_ndi) as count_death_exp
    from cohort
    where high_rain_by_wind_time = 1 and lowcase(storm) in("&storm.")
    group by high_rain_by_wind_time
    ;

    create table combo_epitab as
    select high_rain_by_wind_time
        , sum(death_post_ndi) as count_death
        , count(*) as count_group
    from cohort
    where lowcase(storm) in("&storm.")
    group by high_rain_by_wind_time
    order by high_rain_by_wind_time desc
    ;
quit;

data epitab_&storm.;
    merge n_epitab_all noexp_epitab_all exp_epitab_all;
run;


proc freq data=cohort order=data;
    title2 "crosstab for &storm.";
    format cod cod_fmt. high_rain_by_wind_time rain_wind_time_fmt.;
    tables high_rain_by_wind_time*death_post_ndi / riskdiff missing;
    where lowcase(storm) in("&storm.")
    ;
run;
 

proc stdrate data=combo_epitab
             method=mh(af)
             stat=risk
             effect
             ;
    population group(order=data exposed='1')=high_rain_by_wind_time
        event=count_death total=count_group
        ;
run;

%mend;

%table2_epitab(allison);
%table2_epitab(charley);
%table2_epitab(florence);
%table2_epitab(frances);
%table2_epitab(harvey);
%table2_epitab(ike);
%table2_epitab(irene);
%table2_epitab(irma);
%table2_epitab(ivan);
%table2_epitab(katrina);
%table2_epitab(matthew);
%table2_epitab(michael);
%table2_epitab(rita);
%table2_epitab(sandy);
%table2_epitab(wilma);

data table2;
    set epitab_: ;
run;

data table2;
    set table2;
    mortality_exp = (count_death_exp/count_group_exp)*1000;
    mortality_noexp = (count_death_noexp/count_group_noexp)*1000;
    n_attrib_death = int(((count_death_exp/count_group_exp) - (count_death_noexp/count_group_noexp))*sample_size);
run;

proc print data=table2; title "Table 2"; run;

proc export data=table2
	dbms=xlsx
	outfile="/sas/vrdc/users/jma617/files/dua_070617_jma617/results/table2_rr.xlsx"
	replace;
	sheet="table2";
run;


%macro table2_epitab_cod(cod_var);

proc sql;
    create table n_epitab_all as
    select "&cod_var." as COD
        , count(*) as sample_size
    from cohort
    ;

    create table noexp_epitab_all as
    select "&cod_var." as COD
        , count(*) as count_group_noexp
        , sum(&cod_var.) as count_death_noexp
    from cohort
    where high_rain_by_wind_time = 0
    group by high_rain_by_wind_time
    ;

    create table exp_epitab_all as
    select "&cod_var." as COD
        , count(*) as count_group_exp
        , sum(&cod_var.) as count_death_exp
    from cohort
    where high_rain_by_wind_time = 1
    group by high_rain_by_wind_time
    ;

/*    create table combo_epitab as*/
/*    select high_rain_by_wind_time*/
/*        , sum(&cod_var.) as count_death*/
/*        , count(*) as count_group*/
/*    from cohort*/
/*    group by high_rain_by_wind_time*/
/*    order by high_rain_by_wind_time desc*/
/*    ;*/
quit;

data cod_epitab_&cod_var.;
    merge n_epitab_all noexp_epitab_all exp_epitab_all;
run;


/*proc freq data=cohort order=data;*/
/*    title2 "crosstab for &cod_var.";*/
/*    format cod cod_fmt. high_rain_by_wind_time rain_wind_time_fmt.;*/
/*    tables high_rain_by_wind_time*death_post_ndi / riskdiff missing;*/
/*    ;*/
/*run;*/
/* */
/**/
/*proc stdrate data=combo_epitab*/
/*             method=mh(af)*/
/*             stat=risk*/
/*             effect*/
/*             ;*/
/*    population group(order=data exposed='1')=high_rain_by_wind_time*/
/*        event=count_death total=count_group*/
/*        ;*/
/*run;*/

%mend;

%table2_epitab_cod(death_post_ndi);
%table2_epitab_cod(cod_adrd);
%table2_epitab_cod(cod_cvd);
%table2_epitab_cod(cod_cbvd);
%table2_epitab_cod(cod_cancer);
%table2_epitab_cod(cod_pneumonia);
%table2_epitab_cod(cod_chron_resp);
%table2_epitab_cod(cod_genitourinary);
%table2_epitab_cod(cod_gastrointestinal);
%table2_epitab_cod(cod_injury);
%table2_epitab_cod(cod_other);

data table2_cod;
    format cod $20.;
    set cod_epitab_death_post_ndi
        cod_epitab_cod_adrd
        cod_epitab_cod_cvd
        cod_epitab_cod_cbvd
        cod_epitab_cod_cancer
        cod_epitab_cod_pneumonia
        cod_epitab_cod_chron_resp
        cod_epitab_cod_chron_resp
        cod_epitab_cod_genitourinary
        cod_epitab_cod_gastrointestinal
        cod_epitab_cod_injury
        cod_epitab_cod_other;
run;

data table2_cod;
    set table2_cod;
    mortality_exp = (count_death_exp/count_group_exp)*1000;
    mortality_noexp = (count_death_noexp/count_group_noexp)*1000;
    n_attrib_death = int(((count_death_exp/count_group_exp) - (count_death_noexp/count_group_noexp))*sample_size);
run;

proc print data=table2_cod; title "Table 2 - COD"; run;

proc export data=table2_cod
	dbms=xlsx
	outfile="/sas/vrdc/users/jma617/files/dua_070617_jma617/results/table2_rr.xlsx"
	replace;
	sheet="table2_cod";
run;


/* Table 3 - Hazard Ratios */
%macro test_cod(exposure_vars);
proc phreg data=cohort covs(aggregate);
	title1 "T3: ALL CAUSE Mortality - Exposure: &exposure_vars.";
    title2 "Unadjusted estimates - with COVS(aggregate) and CLUSTER on zip_year";
    format high_rain_by_wind_time rain_wind_time_fmt.;
	class cod(ref=FIRST) zip_year z_all_high_wind(ref=FIRST) male (ref=FIRST) race4c (ref=FIRST) dual_pre (ref=FIRST) ffs_pre (ref=FIRST) ruca3cat (ref=FIRST)
        high_rain_by_wind_time(ref="No high rain or wind time");
	model days_follow_up*death_post_ndi(0) = &exposure_vars.;
    id zip_year;
run;

proc phreg data=cohort covs(aggregate);
    title2 "Adjusted estimates - with COVS(aggregate) and CLUSTER on zip_year";
    format high_rain_by_wind_time rain_wind_time_fmt.;
	class cod(ref=FIRST) zip_year z_all_high_wind(ref=FIRST) male (ref=FIRST) race4c (ref=FIRST) dual_pre (ref=FIRST) ffs_pre (ref=FIRST) ruca3cat (ref=FIRST)
        high_rain_by_wind_time(ref="No high rain or wind time");
	model days_follow_up*death_post_ndi(0) = &exposure_vars. age male race4c cfi_score_no_adrd dual_pre ffs_pre ruca3cat;
    id zip_year;
run;

%do i=1 %to 10;
proc phreg data=cohort covs(aggregate);
	title1 "T3: Exp: &exposure_vars.. Event of interest value = &i.";
    title2 "Unadjusted estimates - with COVS(aggregate) and CLUSTER on zip_year";
    format high_rain_by_wind_time rain_wind_time_fmt.;
	class cod(ref=FIRST) zip_year z_all_high_wind(ref=FIRST) male (ref=FIRST) race4c (ref=FIRST) dual_pre (ref=FIRST) ffs_pre (ref=FIRST) ruca3cat (ref=FIRST)
        high_rain_by_wind_time(ref="No high rain or wind time");
	model days_follow_up*cod(0) = &exposure_vars. / eventcode=&i ;
    id zip_year;
run;


proc phreg data=cohort covs(aggregate);
    title2 "Adjusted estimates - with COVS(aggregate) and CLUSTER on zip_year";
    format high_rain_by_wind_time rain_wind_time_fmt.;
	class cod(ref=FIRST) zip_year z_all_high_wind(ref=FIRST) male (ref=FIRST) race4c (ref=FIRST) dual_pre (ref=FIRST) ffs_pre (ref=FIRST) ruca3cat (ref=FIRST)
        high_rain_by_wind_time(ref="No high rain or wind time");
	model days_follow_up*cod(0) = &exposure_vars. age male race4c cfi_score_no_adrd dual_pre ffs_pre ruca3cat / eventcode=&i ;
    id zip_year;
run;
%end;

%mend;

/*%test_cod(high_rain_by_wind_time)*/


