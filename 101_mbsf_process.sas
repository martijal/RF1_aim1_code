
/*start-header
################################################################################
# Type of File     : SAS
#
# Program Name     : 101_mbsf_process.sas
#			
# Program Path     : sasCCW\Files\dua_070617_jma617\code
#
# Programmed By    : Jonathan Martindale
#
# Date Created     : 4Dec2024	
#
# Project Title    : Bell-Davis RF1
#
# Purpose          : Process MBSF eligibility files for all years of project
#
# Input files      : IN070617.MBSF_AB00_R14229 - IN070617.MBSF_AB05_R14229
#					 IN070617.MBSF_ABCD06_R14229 - IN070617.MBSF_ABCD19_R14229
#
# Output file      : SH070617.bene_elig_YYYY
#
#################################################################################
end-header*/
*options ls=120 ps=64 nocenter nodate nonumber pagesize=6500 nofullstimer mprint msglevel=i;


%macro check_mbsf;
%do i=0 %to 5;
proc contents data=IN070617.MBSF_AB0&i._R14229; run;
%end;

%do i=6 %to 9;
proc contents data=IN070617.MBSF_ABCD0&i._R14229; run;
%end;

%do i=10 %to 19;
proc contents data=IN070617.MBSF_ABCD&i._R14229; run;
%end;

%mend;
/*%check_mbsf*/

%macro mbsf_ab_process(yr, year, st_month, end_month);


/* 
Function purpose: select demographic variables and create monthly eligibility indicators
                  for a single year of the MBSF file. 


Expected output:  file named elig&yr. with 1) demographic info, 2) yearly ESRD, death, and US indicators,
                  and 3) monthly FFS, HMO,  and Dual Status indicators. Monthly indicators are number 
                  of months from Jan2016, the first month of data in this study.

Params:           yr = 2-digit year 
                  year = 4-digit year
                  st_month = month, indexed on jan2000=1 (e.g. for 2000: st_month=1; 2001: st_month=13)
                  end_month = month, indexed on jan2000=1 (e.g. for 2000: end_month=12; 2001: end_month=24)
                  */

data denom; 
    set IN070617.MBSF_AB&yr._R14229
				(keep=bene_id state_code bene_county_cd bene_zip_cd 
                bene_birth_dt bene_death_dt 
                bene_sex_ident_cd rti_race_cd bene_esrd_ind
                bene_mdcr_entlmt_buyin_ind_01-bene_mdcr_entlmt_buyin_ind_12
                bene_hmo_ind_01-bene_hmo_ind_12
                );

	format zip5_&year. $5.;
	zip5_&year. = substr(bene_zip_cd, 1, 5);

    * update names;
    rename bene_zip_cd=zip9_&year.
           state_code=state_code_&year.
		   bene_county_cd=county_cd_&year.
           bene_death_dt=bene_death_dt_&year.
           bene_birth_dt=bene_birth_dt_&year.
           bene_sex_ident_cd=sex_ident_cd_&year.
           rti_race_cd=rti_race_cd_&year.
           bene_esrd_ind=esrd_ind_&year.;

    * add all benes indicator and esrd indicator;
    attrib bene_abcd length=3 label="Medicare beneficiary";

    * set abcd to 1 for all bene;
    bene_abcd = 1;


    * Creating monthly binary variables for Part A/B, HMO, Dual enrollment;
    array oab (12) $ bene_mdcr_entlmt_buyin_ind_01-bene_mdcr_entlmt_buyin_ind_12;
    array ohmo (12) $ bene_hmo_ind_01-bene_hmo_ind_12;

    array B_ab (12) FFS_&st_month.-FFS_&end_month.;
    array BHMO (12) HMO_&st_month.-HMO_&end_month.;
    array BDual (12) Dual_&st_month.-Dual_&end_month.;
	array Bptd (12) ptd_&st_month.-ptd_&end_month.;
	array Blis (12) lis_&st_month.-lis_&end_month.;
    array newstatecnty (12) $ state_cnty_fips_cd_&st_month.-state_cnty_fips_cd_&end_month.;

    do a=1 to 12;
        BDual(a)=0; B_AB(a)=0; BHMO(a)=0; Bptd(a)=0; Blis(a)=0;
        if oab(a) in('3', 'C') and ohmo(a) in ('0', '4') then B_AB(a)=1;
        if ohmo(a) in('1', '2' ,'A' ,'B' ,'C') then BHMO(a)=1;
    end;
    drop a;

run;

* check the recode;
proc freq data=denom;
    title "checking recode of monthly enrollment indicators in &year.";
    tables  FFS_&st_month.*hmo_&st_month.*bene_mdcr_entlmt_buyin_ind_01*bene_hmo_ind_01
			Dual_&st_month. ptd_&st_month. lis_&st_month.
            / list missing;
run;


data elig&yr. (keep=bene_id 
        rti_race_cd_&year. 
        sex_ident_cd_&year. 
        bene_birth_dt_&year. 
        bene_death_dt_&year. 
        esrd_ind_&year.
        zip5_&year.
		zip9_&year.
        state_code_&year.

        FFS_&st_month.-FFS_&end_month. 
        HMO_&st_month.-HMO_&end_month.
        Dual_&st_month.-Dual_&end_month. 
        state_cnty_fips_cd_&st_month.-state_cnty_fips_cd_&end_month.
		ptd_&st_month.-ptd_&end_month.
		lis_&st_month.-lis_&end_month.
        );
    set denom ;
run;


proc sort data=elig&yr.;
    title ;
    by bene_id;
run;

data SH070617.bene_elig_&year.;
    set elig&yr.;
run;

* data checks;
proc contents data=SH070617.bene_elig_&year. varnum; 
    title "contents of updated MBSF file for &year. "; 
run;

proc print data=SH070617.bene_elig_&year.(obs=10); run;

proc freq data=SH070617.bene_elig_&year.;
	title "rates for basic demographics for &year.";
	tables sex_ident_cd_&year. rti_race_cd_&year. esrd_ind_&year. ;
run;

proc sql;
    title "Number of benes in eligibility file in &year. ";
    select count(*) as cnt_benes, count(distinct bene_id) as u_cnt_benes
    from SH070617.bene_elig_&year.;
quit;


%mend;


%macro mbsf_abcd_process(yr, year, st_month, end_month);
/* 
Function purpose: select demographic variables and create monthly eligibility indicators
                  for a single year of the MBSF file. 


Expected output:  file named elig&yr. with 1) demographic info, 2) yearly ESRD, death, and US indicators,
                  and 3) monthly FFS, HMO,  and Dual Status indicators. Monthly indicators are number 
                  of months from Jan2016, the first month of data in this study.

Params:           yr = 2-digit year 
                  year = 4-digit year
                  st_month = month, indexed on jan2000=1 (e.g. for 2000: st_month=1; 2001: st_month=13)
                  end_month = month, indexed on jan2000=1 (e.g. for 2000: end_month=12; 2001: end_month=24)
                  */

data denom; 
    set IN070617.MBSF_ABCD&yr._R14229
				(keep=bene_id state_code county_cd zip_cd 
                bene_birth_dt bene_death_dt 
                sex_ident_cd rti_race_cd esrd_ind
                state_cnty_fips_cd_01-state_cnty_fips_cd_12
                mdcr_entlmt_buyin_ind_01-mdcr_entlmt_buyin_ind_12
                hmo_ind_01-hmo_ind_12
                dual_stus_cd_01-dual_stus_cd_12
				ptd_cntrct_id_01-ptd_cntrct_id_12
				cst_shr_grp_cd_01-cst_shr_grp_cd_12
                );

    * update names;
    rename zip_cd=zip5_&year.
           state_code=state_code_&year.
		   county_cd=county_cd_&year.
           bene_death_dt=bene_death_dt_&year.
           bene_birth_dt=bene_birth_dt_&year.
           sex_ident_cd=sex_ident_cd_&year.
           rti_race_cd=rti_race_cd_&year.
           esrd_ind=esrd_ind_&year.;

    * add all benes indicator and esrd indicator;
    attrib bene_abcd length=3 label="Medicare beneficiary";

    * set abcd to 1 for all bene;
    bene_abcd = 1;


    * Creating monthly binary variables for Part A/B, HMO, Dual enrollment;
    array oab (12) $ mdcr_entlmt_buyin_ind_01-mdcr_entlmt_buyin_ind_12;
    array ohmo (12) $ hmo_ind_01-hmo_ind_12;
    array odual (12) $ dual_stus_cd_01-dual_stus_cd_12;
    array ostatecnty (12) $ state_cnty_fips_cd_01-state_cnty_fips_cd_12;
	array optd (12) $ ptd_cntrct_id_01-ptd_cntrct_id_12;
	array olis (12) $ cst_shr_grp_cd_01-cst_shr_grp_cd_12;

	array mid_ptd (12) $ mid_ptd_01-mid_ptd_12;

    array B_ab (12) FFS_&st_month.-FFS_&end_month.;
    array BHMO (12) HMO_&st_month.-HMO_&end_month.;
    array BDual (12) Dual_&st_month.-Dual_&end_month.;
	array Bptd (12) ptd_&st_month.-ptd_&end_month.;
	array Blis (12) lis_&st_month.-lis_&end_month.;
    array newstatecnty (12) $ state_cnty_fips_cd_&st_month.-state_cnty_fips_cd_&end_month.;

    do a=1 to 12;
        BDual(a)=0; B_AB(a)=0; BHMO(a)=0; Bptd(a)=0; Blis(a)=0;
        if oab(a) in('3', 'C') and ohmo(a) in ('0', '4') then B_AB(a)=1;
        if ohmo(a) in('1', '2' ,'A' ,'B' ,'C') then BHMO(a)=1;
        if odual(a) in('02', '04', '08' ) then BDual(a)=1;
		mid_ptd(a) = substr(optd(a), 1, 1);
		if mid_ptd(a) in('H', 'R', 'S') then Bptd(a) = 1;
		if olis(a) in('01', '02', '03') then blis(a)=1;
		newstatecnty(a) = ostatecnty(a);
    end;
    drop a;

run;

* check the recode;
proc freq data=denom;
    title "checking recode of monthly enrollment indicators in &year.";
    tables  FFS_&st_month.*hmo_&st_month.*mdcr_entlmt_buyin_ind_01*hmo_ind_01
    		dual_&st_month.*dual_stus_cd_01
			ptd_&st_month.*mid_ptd_01
			lis_&st_month.*cst_shr_grp_cd_01
            / list missing;
run;


data elig&yr. (keep=bene_id 
        rti_race_cd_&year. 
        sex_ident_cd_&year. 
        bene_birth_dt_&year. 
        bene_death_dt_&year. 
        esrd_ind_&year.
        zip5_&year.
        state_code_&year.

        FFS_&st_month.-FFS_&end_month. 
        HMO_&st_month.-HMO_&end_month.
        Dual_&st_month.-Dual_&end_month. 
        state_cnty_fips_cd_&st_month.-state_cnty_fips_cd_&end_month.
		ptd_&st_month.-ptd_&end_month.
		lis_&st_month.-lis_&end_month.
        );
    set denom ;
run;


proc sort data=elig&yr.;
    title ;
    by bene_id;
run;

data SH070617.bene_elig_&year.;
    set elig&yr.;
run;

* data checks;
proc contents data=SH070617.bene_elig_&year. varnum; 
    title "contents of updated MBSF file for &year. "; 
run;

proc print data=SH070617.bene_elig_&year.(obs=10); run;

proc freq data=SH070617.bene_elig_&year.;
	title "rates for basic demographics for &year.";
	tables sex_ident_cd_&year. rti_race_cd_&year. esrd_ind_&year. ;
run;

proc sql;
    title "Number of benes in eligibility file in &year. ";
    select count(*) as cnt_benes, count(distinct bene_id) as u_cnt_benes
    from SH070617.bene_elig_&year.;
quit;


%mend;

%mbsf_ab_process(00, 2000, 1, 12);
%mbsf_ab_process(01, 2001, 13, 24);
%mbsf_ab_process(02, 2002, 25, 36);
%mbsf_ab_process(03, 2003, 37, 48);
%mbsf_ab_process(04, 2004, 49, 60);
%mbsf_ab_process(05, 2005, 61, 72);
%mbsf_abcd_process(06, 2006, 73, 84);
%mbsf_abcd_process(07, 2007, 85, 96);
%mbsf_abcd_process(08, 2008, 97, 108);
%mbsf_abcd_process(09, 2009, 109, 120);
%mbsf_abcd_process(10, 2010, 121, 132);
%mbsf_abcd_process(11, 2011, 133, 144);
%mbsf_abcd_process(12, 2012, 145, 156);
%mbsf_abcd_process(13, 2013, 157, 168);
%mbsf_abcd_process(14, 2014, 169, 180);
%mbsf_abcd_process(15, 2015, 181, 192);
%mbsf_abcd_process(16, 2016, 193, 204);
%mbsf_abcd_process(17, 2017, 205, 216);
%mbsf_abcd_process(18, 2018, 217, 228);
%mbsf_abcd_process(19, 2019, 229, 240);


