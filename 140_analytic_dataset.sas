

/*start-header
################################################################################
# Type of File     : SAS
#
# Program Name     : 140_analytic_dataset.sas
#			
# Program Path     : sasCCW\Files\dua_070617_jma617\code
#
# Programmed By    : Jonathan Martindale
#
# Date Created     : 04Jun2025	
#
# Date Updated     : 24Sep2025 - Fixed NDI cause of death categories not being read in for storms prior to 2015. Added second categorization of COD (cod2)
#
# Project Title    : Bell-Davis RF1
#
# Purpose          : Join all data into final analytic datasets by storm and overall
#

# Input files      : SH070617.hurricanes
#					 SH070617.[storm]_mbsf_elig
#					 SH070617.[storm]_frailty_score
#					 SH070617.[storm]_elix_agg_claims[enc]
#					 SH070617.[storm]_mds_bene_pre
#					 SH070617.[storm]_ndi_claims_post
#					 SH070617.[storm]_adrd_flags
#					 SH070617.[storm]_exposure_data
#					 SH070617.ruca2010
#
# Output file      : SH070617.[storm]_full_cohort
#					 SH070617.all_storms_full_cohort
#
#################################################################################
end-header*/

proc print data=SH070617.allison_mbsf_elig (obs=15);
    var zip5_index;
run;

proc contents data=SH070617.allison_mbsf_elig;
run;

proc print data=SH070617.allison_exposure_data_final (obs=15);
    var geoid;
run;

proc contents data=SH070617.allison_exposure_data_final;
run;

%macro analytic(storm);

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

/* check for need to incorporate MA elixhauser */
%if &pre_index_year < 2015 %then %do;

proc sql;
	create table SH070617.&storm._full_cohort as
	select mbsf.*
		, adrd.adrd
		, ndi.ndi_death_dt
		, ndi.ndi_state_death_cd
		, ndi.icd_code
		, ndi.cod_adrd
		, ndi.cod_cvd
		, ndi.cod_cbvd
		, ndi.cod_cancer
		, ndi.cod_pneumonia
		, ndi.cod_chron_resp
		, ndi.cod_genitourinary
		, ndi.cod_gastrointestinal
		, ndi.cod_injury
		, cfi.score as cfi_score
		, cfi_noadrd.score as cfi_score_no_adrd
		, mds.mds_pre
		, elix.CMR_AIDS_R
		, elix.CMR_ALCOHOL_R
		, elix.CMR_ANEMDEF_R
		, elix.CMR_AUTOIMMUNE_R
		, elix.CMR_BLDLOSS_R
		, elix.CMR_CANCER_R
		, elix.CMR_CBVD_R
		, elix.CMR_COAG_R
		, elix.CMR_DEPRESS_R
		, elix.CMR_DIAB_R
		, elix.CMR_DRUG_ABUSE_R
		, elix.CMR_HF_R
		, elix.CMR_HTN_R
		, elix.CMR_LIVER_R
		, elix.CMR_LUNG_CHRONIC_R
		, elix.CMR_NEURO_R
		, elix.CMR_OBESE_R
		, elix.CMR_PARALYSIS_R
		, elix.CMR_PERIVASC_R
		, elix.CMR_PSYCHOSES_R
		, elix.CMR_PULMCIRC_R
		, elix.CMR_RENLFL_R
		, elix.CMR_THYROID_R
		, elix.CMR_ULCER_PEPTIC_R
		, elix.CMR_VALVE_R
		, elix.CMR_WGHTLOSS_R
		, exp.geoid
		, exp.total_prcp_mm
		, exp.total_prcp_in
		, exp.total_prcp_ge_75mm
		, exp.vmax_sust_knots
		, exp.vmax_sust_mph
		, exp.vmax_sust_gt_34kt
		, exp.vmax_sust_gt_64kt
		, exp.vmax_sust_above_34kt_dur
		, exp.dist_from_storm_min
		, exp.dist_from_storm_le_100km
		, exp.nearest_date as storm_nearest_date
		, exp.any_major_exposure
		, exp.z_storm_total_prcp
		, exp.z_storm_vmax_sust
		, exp.z_storm_dist_from_storm_min
		, exp.z_all_total_prcp
		, exp.z_all_vmax_sust
		, exp.z_all_dist_from_storm_min
        , exp.z_storm_min_wind_above_34kt
        , exp.z_all_min_wind_above_34kt
		, ruca.ruca3cat
		, ruca.ruca1
	from SH070617.&storm._mbsf_elig mbsf
	left join SH070617.&storm._adrd_flags adrd
		on mbsf.bene_id = adrd.bene_id
	left join SH070617.&storm._ndi_claims_post ndi
		on mbsf.bene_id = ndi.bene_id
	left join SH070617.&storm._claims_frailty_score cfi
		on mbsf.bene_id = cfi.bene_id
	left join SH070617.&storm._claimscfi_alt cfi_noadrd
		on mbsf.bene_id = cfi_noadrd.bene_id
	left join SH070617.&storm._mds_bene_pre mds
		on mbsf.bene_id = mds.bene_id
	left join SH070617.&storm._elix_agg_claims elix
		on mbsf.bene_id = elix.bene_id
	left join SH070617.&storm._exposure_data_final exp
		on mbsf.zip5_index = exp.geoid
	left join SH070617.ruca2010 ruca
		on mbsf.zip5_index = ruca.zip_code
	;
quit;

%end;


/* check for need to incorporate MA elixhauser */
%if &pre_index_year >= 2015 %then %do;
proc sql;
	create table cohort_&storm. as
	select mbsf.*
		, adrd.adrd
		, ndi.ndi_death_dt
		, ndi.ndi_state_death_cd
		, ndi.icd_code
		, ndi.cod_adrd
		, ndi.cod_cvd
		, ndi.cod_cbvd
		, ndi.cod_cancer
		, ndi.cod_pneumonia
		, ndi.cod_chron_resp
		, ndi.cod_genitourinary
		, ndi.cod_gastrointestinal
		, ndi.cod_injury
		, cfi.score as cfi_score
		, ma_cfi.score as ma_cfi_score
		, cfi_noadrd.score as cfi_score_no_adrd
		, ma_cfi_noadrd.score as ma_cfi_score_no_adrd
		, mds.mds_pre
		, elix.CMR_AIDS_R
		, elix.CMR_ALCOHOL_R
		, elix.CMR_ANEMDEF_R
		, elix.CMR_AUTOIMMUNE_R
		, elix.CMR_BLDLOSS_R
		, elix.CMR_CANCER_R
		, elix.CMR_CBVD_R
		, elix.CMR_COAG_R
		, elix.CMR_DEPRESS_R
		, elix.CMR_DIAB_R
		, elix.CMR_DRUG_ABUSE_R
		, elix.CMR_HF_R
		, elix.CMR_HTN_R
		, elix.CMR_LIVER_R
		, elix.CMR_LUNG_CHRONIC_R
		, elix.CMR_NEURO_R
		, elix.CMR_OBESE_R
		, elix.CMR_PARALYSIS_R
		, elix.CMR_PERIVASC_R
		, elix.CMR_PSYCHOSES_R
		, elix.CMR_PULMCIRC_R
		, elix.CMR_RENLFL_R
		, elix.CMR_THYROID_R
		, elix.CMR_ULCER_PEPTIC_R
		, elix.CMR_VALVE_R
		, elix.CMR_WGHTLOSS_R
		, ma_elix.CMR_AIDS_R as MA_CMR_AIDS_R
		, ma_elix.CMR_ALCOHOL_R as MA_CMR_ALCOHOL_R
		, ma_elix.CMR_ANEMDEF_R as MA_CMR_ANEMDEF_R
		, ma_elix.CMR_AUTOIMMUNE_R as MA_CMR_AUTOIMMUNE_R
		, ma_elix.CMR_BLDLOSS_R as MA_CMR_BLDLOSS_R
		, ma_elix.CMR_CANCER_R as MA_CMR_CANCER_R
		, ma_elix.CMR_CBVD_R as MA_CMR_CBVD_R
		, ma_elix.CMR_COAG_R as MA_CMR_COAG_R
		, ma_elix.CMR_DEPRESS_R as MA_CMR_DEPRESS_R
		, ma_elix.CMR_DIAB_R as MA_CMR_DIAB_R
		, ma_elix.CMR_DRUG_ABUSE_R as MA_CMR_DRUG_ABUSE_R
		, ma_elix.CMR_HF_R as MA_CMR_HF_R
		, ma_elix.CMR_HTN_R as MA_CMR_HTN_R
		, ma_elix.CMR_LIVER_R as MA_CMR_LIVER_R
		, ma_elix.CMR_LUNG_CHRONIC_R as MA_CMR_LUNG_CHRONIC_R
		, ma_elix.CMR_NEURO_R as MA_CMR_NEURO_R
		, ma_elix.CMR_OBESE_R as MA_CMR_OBESE_R
		, ma_elix.CMR_PARALYSIS_R as MA_CMR_PARALYSIS_R
		, ma_elix.CMR_PERIVASC_R as MA_CMR_PERIVASC_R
		, ma_elix.CMR_PSYCHOSES_R as MA_CMR_PSYCHOSES_R
		, ma_elix.CMR_PULMCIRC_R as MA_CMR_PULMCIRC_R
		, ma_elix.CMR_RENLFL_R as MA_CMR_RENLFL_R
		, ma_elix.CMR_THYROID_R as MA_CMR_THYROID_R
		, ma_elix.CMR_ULCER_PEPTIC_R as MA_CMR_ULCER_PEPTIC_R
		, ma_elix.CMR_VALVE_R as MA_CMR_VALVE_R
		, ma_elix.CMR_WGHTLOSS_R as MA_CMR_WGHTLOSS_R
		, exp.geoid
		, exp.total_prcp_mm
		, exp.total_prcp_in
		, exp.total_prcp_ge_75mm
		, exp.vmax_sust_knots
		, exp.vmax_sust_mph
		, exp.vmax_sust_gt_34kt
		, exp.vmax_sust_gt_64kt
		, exp.vmax_sust_above_34kt_dur
		, exp.dist_from_storm_min
		, exp.dist_from_storm_le_100km
		, exp.nearest_date as storm_nearest_date
		, exp.any_major_exposure
		, exp.z_storm_total_prcp
		, exp.z_storm_vmax_sust
		, exp.z_storm_dist_from_storm_min
		, exp.z_all_total_prcp
		, exp.z_all_vmax_sust
		, exp.z_all_dist_from_storm_min
        , exp.z_storm_min_wind_above_34kt
        , exp.z_all_min_wind_above_34kt
		, ruca.ruca3cat
		, ruca.ruca1
	from SH070617.&storm._mbsf_elig mbsf
	left join SH070617.&storm._adrd_flags adrd
		on mbsf.bene_id = adrd.bene_id
	left join SH070617.&storm._ndi_claims_post ndi
		on mbsf.bene_id = ndi.bene_id
	left join SH070617.&storm._claims_frailty_score cfi
		on mbsf.bene_id = cfi.bene_id
	left join SH070617.&storm._claimscfi_alt cfi_noadrd
		on mbsf.bene_id = cfi_noadrd.bene_id
	left join SH070617.&storm._enc_frailty_score ma_cfi
		on mbsf.bene_id = ma_cfi.bene_id
	left join SH070617.&storm._enccfi_alt ma_cfi_noadrd
		on mbsf.bene_id = ma_cfi_noadrd.bene_id
	left join SH070617.&storm._mds_bene_pre mds
		on mbsf.bene_id = mds.bene_id
	left join SH070617.&storm._elix_agg_claims elix
		on mbsf.bene_id = elix.bene_id
	left join SH070617.&storm._elix_agg_enc ma_elix
		on mbsf.bene_id = ma_elix.bene_id
	left join SH070617.&storm._exposure_data_final exp
		on mbsf.zip5_index = exp.geoid
	left join SH070617.ruca2010 ruca
		on mbsf.zip5_index = ruca.zip_code
	;
quit;


data SH070617.&storm._full_cohort;
	set cohort_&storm.;

	/* update CMR data if bene has MA */
	array elix (*) CMR_: cfi_score cfi_score_no_adrd;
	array ma_elix (*) MA_CMR_: ma_cfi_score ma_cfi_score_no_adrd;

	if ma_pre = 1 then do;
		do i=1 to dim(elix);
			elix(i) = ma_elix(i);
		end;
	end;

	drop i ma_cmr_: ma_cfi_score ma_cfi_score_no_adrd;
run;

%end;


/* final cleaning */
data SH070617.&storm._full_cohort;
	set SH070617.&storm._full_cohort;


    if ndi_death_dt ^= . then do;
		if (ndi_death_dt >= index_date) and (ndi_death_dt <= obs_end_date) then do;
			death_post_ndi = 1;
			days_to_death_ndi = intck("days", index_date, ndi_death_dt);
		end;
	end;

	/* updated elixhauser numbers */
	array a (*) CMR_: mds_pre;

	do i=1 to dim(a);
		if a(i) = . then a(i) = 0;
	end; 

	days_follow_up = 364;
    death_post_ndi = 0;
    days_to_death_ndi = .;

    if ndi_death_dt ^= . then do;
		if (ndi_death_dt >= index_date) and (ndi_death_dt <= obs_end_date) then do;
			death_post_ndi = 1;
			days_to_death_ndi = intck("days", index_date, ndi_death_dt);
		end;
	end;

    days_death_diff = days_to_death - days_to_death_ndi;

    array a_cod (*) cod_adrd cod_cvd cod_cbvd cod_cancer cod_pneumonia cod_chron_resp cod_genitourinary cod_gastrointestinal cod_injury;
    do i=1 to dim(a_cod);
        if a_cod(i) = . then a_cod(i) = 0;
    end;

    cod = 0;
    if death_post_ndi = 1 then do;
        cod = 10;
        if cod_adrd = 1 then cod = 1;
        if cod_cvd = 1 then cod = 2;
        if cod_cbvd = 1 then cod = 3;
        if cod_cancer = 1 then cod = 4;
        if cod_pneumonia = 1 then cod = 5;
        if cod_chron_resp = 1 then cod = 6;
        if cod_genitourinary = 1 then cod = 7;
        if cod_gastrointestinal = 1 then cod = 8;
        if cod_injury = 1 then cod = 9;
    end;

    cod_other = (cod=10);

    z_all_high_prcp = (z_all_total_prcp >= 1); 
    z_all_high_wind = (z_all_vmax_sust >= 1);
    z_all_high_wind_time = (z_all_min_wind_above_34kt >= 1);


    age6674 = (age >= 66 and age < 75);
    age7584 = (age >= 75 and age < 85);
    age85p = (age >= 85);

    if age6674 = 1 then age3cat = 1;
    if age7584 = 1 then age3cat = 2;
    if age85p = 1 then age3cat = 3;

    female = (male = 0);

	if death_post_ndi = 1 then days_follow_up = days_to_death_ndi;

    high_rain_by_wind_time = 0;
    if z_all_high_prcp = 1 or z_all_high_wind_time = 1 then high_rain_by_wind_time = 1;

    if ruca1 = . then ruca1 = 99;
    if ruca1 = 99 then ruca3cat = 99;

    ruca_metropolitan = (ruca3cat = 1);
    ruca_micropolitan = (ruca3cat = 2);
    ruca_rural = (ruca3cat = 3);
    ruca_missing = (ruca3cat = 99);

    if year_of_storm < 2007 then dual_pre = 99;
    dual_elig_yes = (dual_pre = 1);
    dual_elig_no = (dual_pre = 0);
    dual_elig_na = (dual_pre = 99);


    num_elix_pre = sum(of CMR_:);
    elix3cat = 0;
    if num_elix_pre in(1, 2) then elix3cat = 1;
    else if num_elix_pre >= 3 then elix3cat = 2;

    elix_low = (elix3cat = 0);
    elix_med = (elix3cat = 1);
    elix_hi = (elix3cat = 2);

    cfi_robust = (cfi_score_no_adrd < 0.15);
    cfi_prefrail = (0.15 <= cfi_score_no_adrd < 0.25);
    cfi_mild = (0.25 <= cfi_score_no_adrd < 0.35);
    cfi_mod_severe = (cfi_score_no_adrd >= 0.35);

    cfi4cat = 1;
    if cfi_prefrail = 1 then cfi4cat = 2;
    if cfi_mild = 1 then cfi4cat = 3;
    if cfi_mod_severe = 1 then cfi4cat = 4;

    length zip_year $10.;
    zip_year = cats(zip5_index, year_of_storm);

	complete_exp_data = (nmiss(z_all_total_prcp, z_all_min_wind_above_34kt) = 0);

	/* create missing indicator */
	nmiss = nmiss(race4c
	,	male
	,	age
	,	death_pre
	,	death_post
	,	no_moving_pre
	,	no_moving_post
	,	ffs_pre
	,	ma_pre
	,	dual_pre
	,	adrd
	,	cfi_score
	,	mds_pre
	,	CMR_AIDS_R
	,	CMR_ALCOHOL_R
	,	CMR_ANEMDEF_R
	,	CMR_AUTOIMMUNE_R
	,	CMR_BLDLOSS_R
	,	CMR_CANCER_R
	,	CMR_CBVD_R
	,	CMR_COAG_R
	,	CMR_DEPRESS_R
	,	CMR_DIAB_R
	,	CMR_DRUG_ABUSE_R
	,	CMR_HF_R
	,	CMR_HTN_R
	,	CMR_LIVER_R
	,	CMR_LUNG_CHRONIC_R
	,	CMR_NEURO_R
	,	CMR_OBESE_R
	,	CMR_PARALYSIS_R
	,	CMR_PERIVASC_R
	,	CMR_PSYCHOSES_R
	,	CMR_PULMCIRC_R
	,	CMR_RENLFL_R
	,	CMR_THYROID_R
	,	CMR_ULCER_PEPTIC_R
	,	CMR_VALVE_R
	,	CMR_WGHTLOSS_R
	,	ruca3cat
	,	ruca1
		);

	no_miss = (nmiss = 0);

	label complete_exp_data = "Have both rain and wind exposure data for ZIP code. 1/0"
		  nmiss = "number of missing covariates"
		  no_miss = "no missing covariates. 1/0"
		  cfi_score = "Claims-Based Frailty Index score"
	;

	drop i zip9:;
run;

/* final checks */
proc contents data=SH070617.&storm._full_cohort varnum; 
	title "final cohort file for &storm.";
run;

proc means data=SH070617.&storm._full_cohort n nmiss; run;

proc freq data=SH070617.&storm._full_cohort;
	title "&storm. - missingness where otherwise eligible";
	tables no_miss;
	where death_pre = 0 
		and age66p = 1 
		and no_moving_pre = 1 
		and no_moving_post = 1 
		and (ffs_pre = 1 or ma_pre = 1) 
		and adrd = 1 
		and mds_pre = 0
		and complete_exp_data = 1
		;
run;

%mend;

%analytic(allison);
%analytic(charley);
%analytic(florence);
%analytic(frances);
%analytic(harvey);
%analytic(ike);
%analytic(irene);
%analytic(irma);
%analytic(ivan);
%analytic(katrina);
%analytic(matthew);
%analytic(michael);
%analytic(rita);
%analytic(sandy);
%analytic(wilma);


data sh070617.all_storms_full_cohort;
	set sh070617.allison_full_cohort
		sh070617.charley_full_cohort
		sh070617.florence_full_cohort
		sh070617.frances_full_cohort
		sh070617.harvey_full_cohort
		sh070617.ike_full_cohort
		sh070617.irene_full_cohort
		sh070617.irma_full_cohort
		sh070617.ivan_full_cohort
		sh070617.katrina_full_cohort
		sh070617.matthew_full_cohort
		sh070617.michael_full_cohort
		sh070617.rita_full_cohort
		sh070617.wilma_full_cohort
		sh070617.sandy_full_cohort
		;
run;

/* final checks */
proc contents data=SH070617.all_storms_full_cohort varnum; 
	title "final cohort file for ALL STORMS";
run;

proc means data=SH070617.all_storms_full_cohort n nmiss; run;

proc freq data=SH070617.all_storms_full_cohort;
	title "ALL STORMS - missingness where otherwise eligible";
	tables storm*no_miss;
	where death_pre = 0 
		and age66p = 1 
		and no_moving_pre = 1 
		and no_moving_post = 1 
		and (ffs_pre = 1 or ma_pre = 1) 
		and adrd = 1 
		and mds_pre = 0
		and complete_exp_data = 1
		;
run;

