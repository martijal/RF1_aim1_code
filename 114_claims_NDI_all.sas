

/*start-header
################################################################################
# Type of File     : SAS
#
# Program Name     : 106_claims_ndi_ffs_all.sas
#			
# Program Path     : sasCCW\Files\dua_070617_jma617\code
#
# Programmed By    : Jonathan Martindale
#
# Date Created     : 20Feb2025	
#
# Date Updated     : 25Sep2025 - Added in proposal COD categories (cod2)	
# Date Updated     : 14Oct2025 - Added in updated COD categories and commented out prior two sets of categories	
#
# Project Title    : Bell-Davis RF1
#
# Purpose          : Process ndi files for each storm to pull diagnosis codes to be used for ADRD identification, Elixhauser, and CFI
#
# Input files      : SH070617.hurricanes
#					 SH070617.[storm]_mbsf_elig
#					 in070617.MBSF_NDI00_R14229 - in070617.MBSF_NDI19_R14229
#					 in070617.ndiLINE00_R14229 - in070617.ndiLINE19_R14229
#
# Output file      : SH070617.[storm]_ndi_claims_post
#
#################################################################################
end-header*/


%macro ndi_storm(storm);

proc sql;
	create table storm as
	select distinct storm, year as index_year
	from SH070617.hurricanes hurr
	where lowcase(hurr.storm) in("&storm")
	;
quit;

data storm;
	set storm;
	format post_index_yr index_yr $2.;
	
	post_index_year = index_year + 1;
	post_index_year_str = put(post_index_year, 4.);
	index_year_str = put(index_year, 4.);
	
	post_index_yr = substrn(post_index_year_str, 3, 2);
	index_yr = substrn(index_year_str, 3, 2);
	
	drop post_index_year_str index_year_str;
run;

proc print data=storm; title "Metadata/parameters for &storm"; run;
proc contents data=storm; run;
	
proc sql noprint;
select index_yr
	, post_index_yr
	, index_year
	, post_index_year
	into  :index_yr trimmed
		, :post_index_yr trimmed
		, :index_year trimmed
		, :post_index_year trimmed
from storm
;
quit;

proc sql;
	create table ndi_clms_post as
	select mbsf.bene_id
		, mbsf.storm
		, mbsf.index_date
		, mbsf.obs_end_date
		, ndi.ndi_death_dt
		, ndi.ndi_state_death_cd
		, ndi.icd_code
		, ndi.record_cond_1
		, ndi.record_cond_2
		, ndi.record_cond_3
		, ndi.record_cond_4
		, ndi.record_cond_5
		, ndi.record_cond_6
		, ndi.record_cond_7
		, ndi.record_cond_8
		, ndi.record_cond_9
		, ndi.record_cond_10
		, ndi.record_cond_11
		, ndi.record_cond_12
		, ndi.record_cond_13
		, ndi.record_cond_14
		, ndi.record_cond_15
		, ndi.record_cond_16
		, ndi.record_cond_17
		, ndi.record_cond_18
		, ndi.record_cond_19
		, ndi.record_cond_20
	from SH070617.&storm._mbsf_elig mbsf
	inner join IN070617.MBSF_NDI&post_index_yr._r14229 ndi
	on mbsf.bene_id = ndi.bene_id
	;
	
	create table ndi_clms_index as
	select mbsf.bene_id
		, mbsf.storm
		, mbsf.index_date
		, mbsf.obs_end_date
		, ndi.ndi_death_dt
		, ndi.ndi_state_death_cd
		, ndi.icd_code
		, ndi.record_cond_1
		, ndi.record_cond_2
		, ndi.record_cond_3
		, ndi.record_cond_4
		, ndi.record_cond_5
		, ndi.record_cond_6
		, ndi.record_cond_7
		, ndi.record_cond_8
		, ndi.record_cond_9
		, ndi.record_cond_10
		, ndi.record_cond_11
		, ndi.record_cond_12
		, ndi.record_cond_13
		, ndi.record_cond_14
		, ndi.record_cond_15
		, ndi.record_cond_16
		, ndi.record_cond_17
		, ndi.record_cond_18
		, ndi.record_cond_19
		, ndi.record_cond_20
	from SH070617.&storm._mbsf_elig mbsf
	inner join in070617.MBSF_NDI&index_yr._r14229 ndi
	on mbsf.bene_id = ndi.bene_id
	;
quit;

/* sort, merge, and append datasets */
data ndi;
	set ndi_clms_post ndi_clms_index;
run;

proc sort data=ndi; by bene_id; run;

proc sql;	
	title "number of benes in MBSF file for &storm.";
	select count(*) as storm_benes
	from SH070617.&storm._mbsf_elig
	;
	
	title "number of benes in file for &storm. - ndi";
	select count(*) as recs, count(distinct bene_id) as u_benes
	from ndi
	;

quit;


data ndi; 
	set ndi;
	
	within_dt_death = ((ndi_death_dt >= index_date) and (ndi_death_dt <= obs_end_date));
run;

proc freq data=ndi;
	title "check date calculations for &storm.";
	format ndi_death_dt monyy5.;
	tables within_dt_death within_dt_death*ndi_death_dt
	 / list missing;
run;


data SH070617.&storm._ndi_claims_post;
	set ndi;

	icd_3digit = substr(icd_code, 1, 3);
    icd_4digit = substr(icd_code, 1, 4);



	cod_adrd = ((icd_3digit = "F00") 
        or (icd_3digit = "F01") 
        or (icd_3digit = "G30")
        or (icd_4digit = "F020")
        or (icd_4digit = "F039")
        or (icd_4digit = "G318")
        or (icd_4digit = "G319"))
        ;
    cod_cvd = (("I00" <= icd_3digit <= "I59")
        or ("I70" <= icd_3digit <= "I99")
        or ("R00" <= icd_3digit <= "R01")
        or ("Q20" <= icd_3digit <= "Q28"))
        ;
    cod_cbvd = ("I60" <= icd_3digit <= "I69")
        ;
    cod_cancer = ("C00" <= icd_3digit <= "C96")
        ;
    cod_pneumonia = ("J09" <= icd_3digit <= "J22")
        ;
    cod_chron_resp = ("J40" <= icd_3digit <= "J47")
        ;
    cod_genitourinary = (("N00" <= icd_3digit <= "N98")
        or ("R30" <= icd_3digit <= "R39"))
        ;
    cod_gastrointestinal = (("K00" <= icd_3digit <= "K93")
        or ("R10" <= icd_3digit <= "R19"))
        ;
    cod_injury = (("V00" <= icd_3digit <= "X40")
		or ("X43" <= icd_3digit <= "X44") 
		or ("X46" <= icd_3digit <= "X99")
		or ("Y00" <= icd_3digit <= "Y89"))
        ;


/*    cod2_adrd = (icd_3digit = "G30");*/
/*    cod2_flu_pneuomnia = ("J09" <= icd_3digit <= "J18");*/
/*    cod2_accidents = (("V01" <= icd_3digit <= "X59") */
/*		or ("Y86" <= icd_3digit <= "Y86"));*/
/*    cod2_falls = ("W00" <= icd_3digit <= "W19");*/
/*    cod2_malnutrition = ("E40" <= icd_3digit <= "E64");*/
/*    cod2_cardio = ("I00" <= icd_3digit <= "I78");*/
/*    cod2_cerebro = ("I60" <= icd_3digit <= "I69");*/
/*    cod2_cancer = ("C00" <= icd_3digit <= "C97");*/
/*    cod2_resp = ("J40" <= icd_3digit <= "J47");*/
/**/
/*    cod_adrd = (icd_3digit = "G30");*/
/*    cod_cancer = (("C00" <= icd_3digit <= "C99") or ("D00" <= icd_3digit <= "D49"));*/
/*	cod_cdvd = ("I00" <= icd_3digit <= "I99");*/
/*	cod_inf = (("A00" <= icd_3digit <= "B99") */
/*		or ("G00" <= icd_3digit <= "G05") */
/*		or (icd_3digit = "G14") */
/*		or ("N70" <= icd_3digit <= "N74"));*/
/*	cod_injury = (("V00" <= icd_3digit <= "X40") */
/*		or ("X43" <= icd_3digit <= "X44") */
/*		or ("X46" <= icd_3digit <= "X99")*/
/*		or ("Y00" <= icd_3digit <= "Y89"));*/
/*	cod_neuro = (("F00" <= icd_3digit <= "F99") */
/*		or ("G06" <= icd_3digit <= "G13") */
/*		or ("G15" <= icd_3digit <= "G29")*/
/*		or ("G31" <= icd_3digit <= "G98")*/
/*		or ("X41" <= icd_3digit <= "X42")*/
/*		or (icd_3digit = "X45"));*/
/*	cod_resp = (("H62" <= icd_3digit <= "H67") */
/*		or ("J00" <= icd_3digit <= "J99"));*/


	where (within_dt_death = 1);
run;


proc contents data=SH070617.&storm._ndi_claims_post varnum;
title "All ndi Claims for &storm. - SH070617.&storm._ndi_claims_post"; 
run;

proc freq data=SH070617.&storm._ndi_claims_post;
	title "check date calculations for final file - SH070617.&storm._ndi_claims_post";
	format ndi_death_dt monyy5.;
	tables within_dt_death within_dt_death*ndi_death_dt
	 / list missing;
run;

proc freq data=SH070617.&storm._ndi_claims_post;
    title "check ADRD Codes";
    tables icd_3digit icd_4digit / missing;
    where cod_adrd=1;
run;

proc freq data=SH070617.&storm._ndi_claims_post;
    title "check CVD Codes";
    tables icd_3digit / missing;
    where cod_cvd=1;
run;

proc print data=SH070617.&storm._ndi_claims_post (obs=10); run;

%mend;

%ndi_storm(allison);
%ndi_storm(charley);
%ndi_storm(florence);
%ndi_storm(frances);
%ndi_storm(harvey);
%ndi_storm(ike);
%ndi_storm(irene);
%ndi_storm(irma);
%ndi_storm(ivan);
%ndi_storm(katrina);
%ndi_storm(matthew);
%ndi_storm(michael);
%ndi_storm(rita);
%ndi_storm(sandy);
%ndi_storm(wilma);



