

/*start-header
################################################################################
# Type of File     : SAS
#
# Program Name     : 111_claims_outpt_enc.sas
#			
# Program Path     : sasCCW\Files\dua_070617_jma617\code
#
# Programmed By    : Jonathan Martindale
#
# Date Created     : 05Feb2025	
#
# Project Title    : Bell-Davis RF1
#
# Purpose          : Process outpt files for each storm to pull diagnosis codes to be used for ADRD identification, Elixhauser, and CFI
#
# Input files      : SH070617.hurricanes
#					 SH070617.[storm]_mbsf_elig
#					 SH070617.[storm]_[file]_[source]_ad_b (file = medpar, bo, hha, hospice, [ip, snf]); 
#
# Output file      : SH070617.[storm]_adrd_flags
#
#################################################################################
end-header*/


%macro bene_adrd(storm);

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

/* create adrd_flags for storms prior to 2016 */
%if &index_year < 2016 %then %do;
proc sql;
	create table &storm._adrd as
	select mbsf.bene_id
		, mbsf.ffs_pre
		, mbsf.ma_pre
		, mbsf.death_pre
		, mbsf.age66p
		, mbsf.no_moving_pre
		, mbsf.no_moving_post
		, mbsf.death_post
		, bo.adrd_dx as adrd_bo_ffs
		, hha.adrd_dx as adrd_hha_ffs
		, hosp.adrd_dx as adrd_hospice_ffs
		, med.adrd_dx as adrd_medpar
	from SH070617.&storm._mbsf_elig mbsf
	left join SH070617.&storm._bo_claims_ad_b bo
		on mbsf.bene_id = bo.bene_id
	left join SH070617.&storm._hha_claims_ad_b hha
		on mbsf.bene_id = hha.bene_id
	left join SH070617.&storm._hospice_claims_ad_b hosp
		on mbsf.bene_id = hosp.bene_id
	left join SH070617.&storm._medpar_claims_ad_b med
		on mbsf.bene_id = med.bene_id
	;
quit;


data &storm._adrd_flags;
	set &storm._adrd;

	if adrd_bo_ffs = . then adrd_bo_ffs = 0;
	if adrd_hha_ffs = . then adrd_hha_ffs = 0;
	if adrd_hospice_ffs = . then adrd_hospice_ffs = 0;
	if adrd_medpar = . then adrd_medpar = 0;

	adrd_bo_ma = 0; adrd_hha_ma = 0; adrd_ip_ma = 0; adrd_snf_ma = 0; 

	adrd_ffs = max(adrd_bo_ffs, adrd_hha_ffs, adrd_hospice_ffs, adrd_medpar);

	/* since no MA data, set flags to 0 */
	adrd_ma = 0;
	ma_pre = 0;

	adrd = 0;
	if ffs_pre = 1 and adrd_ffs = 1 then adrd = 1;
	if ma_pre = 1 and adrd_ma = 1 then adrd = 1;

	label adrd_bo_ffs = "adrd identified in BO FFS claims. 1/0"
		adrd_hha_ffs = "adrd identified in HHA FFS claims. 1/0"
		adrd_hospice_ffs = "adrd identified in Hospice claims. 1/0"
		adrd_medpar = "adrd identified in MedPAR claims. 1/0"
		adrd_bo_ma = "adrd identified in BO MA claims. 1/0"
		adrd_hha_ma = "adrd identified in HHA MA claims. 1/0"
		adrd_ip_ma = "adrd identified in Inpatient FFA claims. 1/0"
		adrd_snf_ma = "adrd identified in SNF MA claims. 1/0"
		adrd_ffs = "adrd identified in any FFS source or MedPAR. 1/0"
		adrd_ma = "adrd identified in any MA source or MedPAR. 1/0"
		adrd = "adrd identified in any FFS or MA source (inc MedPAR). 1/0"
		;
run;
%end;

/* create adrd_flags for storms prior to 2016 */
%if &index_year >= 2016 %then %do;
proc sql;
	create table &storm._adrd as
	select mbsf.bene_id
		, mbsf.ffs_pre
		, mbsf.ma_pre
		, mbsf.death_pre
		, mbsf.age66p
		, mbsf.no_moving_pre
		, mbsf.no_moving_post
		, mbsf.death_post
		, bo.adrd_dx as adrd_bo_ffs
		, hha.adrd_dx as adrd_hha_ffs
		, hosp.adrd_dx as adrd_hospice_ffs
		, med.adrd_dx as adrd_medpar
		, bo_enc.adrd_dx as adrd_bo_ma
		, hha_enc.adrd_dx as adrd_hha_ma
		, ip_enc.adrd_dx as adrd_ip_ma
		, snf_enc.adrd_dx as adrd_snf_ma
	from SH070617.&storm._mbsf_elig mbsf
	left join SH070617.&storm._bo_claims_ad_b bo
		on mbsf.bene_id = bo.bene_id
	left join SH070617.&storm._hha_claims_ad_b hha
		on mbsf.bene_id = hha.bene_id
	left join SH070617.&storm._hospice_claims_ad_b hosp
		on mbsf.bene_id = hosp.bene_id
	left join SH070617.&storm._medpar_claims_ad_b med
		on mbsf.bene_id = med.bene_id
		
	left join SH070617.&storm._bo_enc_ad_b bo_enc
		on mbsf.bene_id = bo_enc.bene_id
	left join SH070617.&storm._hha_enc_ad_b hha_enc
		on mbsf.bene_id = hha_enc.bene_id
	left join SH070617.&storm._ip_enc_ad_b ip_enc
		on mbsf.bene_id = ip_enc.bene_id
	left join SH070617.&storm._snf_enc_ad_b snf_enc
		on mbsf.bene_id = snf_enc.bene_id
	;
quit;


data &storm._adrd_flags;
	set &storm._adrd;

	if adrd_bo_ffs = . then adrd_bo_ffs = 0;
	if adrd_hha_ffs = . then adrd_hha_ffs = 0;
	if adrd_hospice_ffs = . then adrd_hospice_ffs = 0;
	if adrd_medpar = . then adrd_medpar = 0;

	if adrd_bo_ma = . then adrd_bo_ma = 0;
	if adrd_hha_ma = . then adrd_hha_ma = 0;
	if adrd_ip_ma = . then adrd_ip_ma = 0;
	if adrd_snf_ma = . then adrd_snf_ma = 0;

	adrd_ffs = max(adrd_bo_ffs, adrd_hha_ffs, adrd_hospice_ffs, adrd_medpar);
	adrd_ma = max(adrd_bo_ma, adrd_hha_ma, adrd_ip_ma, adrd_snf_ma);

	adrd = 0;
	if ffs_pre = 1 and adrd_ffs = 1 then adrd = 1;
	if ma_pre = 1 and adrd_ma = 1 then adrd = 1;

	label adrd_bo_ffs = "adrd identified in BO FFS claims. 1/0"
		adrd_hha_ffs = "adrd identified in HHA FFS claims. 1/0"
		adrd_hospice_ffs = "adrd identified in Hospice claims. 1/0"
		adrd_medpar = "adrd identified in MedPAR claims. 1/0"
		adrd_bo_ma = "adrd identified in BO MA claims. 1/0"
		adrd_hha_ma = "adrd identified in HHA MA claims. 1/0"
		adrd_ip_ma = "adrd identified in Inpatient FFA claims. 1/0"
		adrd_snf_ma = "adrd identified in SNF MA claims. 1/0"
		adrd_ffs = "adrd identified in any FFS source or MedPAR. 1/0"
		adrd_ma = "adrd identified in any MA source or MedPAR. 1/0"
		adrd = "adrd identified in any FFS or MA source (inc MedPAR). 1/0"
		;
run;
%end;



proc freq data=&storm._adrd_flags;
	title "check ADRD sources for &storm.";
	tables adrd: 
	adrd_ffs*adrd_bo_ffs*adrd_hha_ffs*adrd_hospice_ffs*adrd_medpar
	adrd_ma*adrd_bo_ma*adrd_hha_ma*adrd_ip_ma*adrd_snf_ma*adrd_medpar
	adrd*ffs_pre*ma_pre*adrd_ffs*adrd_ma
	/ list missing;
run;

proc contents data=&storm._adrd_flags; title "final ADRD_flags for &storm"; run;

proc sql;
	title "total benes from SH070617.&storm._mbsf_elig";
	select count(*) as recs, count(distinct bene_id) as u_benes
	from SH070617.&storm._mbsf_elig
	;

	title "Post-merge total benes from &storm._adrd_flags";
	select count(*) as recs, count(distinct bene_id) as u_benes
	from &storm._adrd_flags
	;
quit;

	
proc sql;
	create table row1 as
	select "All benes identified for &storm. - &index_year." as description format=$256.
		, count(*) as Benes
		, "None" as restriction format=$256.
	from &storm._adrd_flags
	;
	
	create table row2 as
	select "And alive on date of storm" as description format=$256.
		, count(*) as Benes
		, "where death_pre = 0" as restriction format=$256.
	from &storm._adrd_flags
	where death_pre = 0
	;
	
	create table row3 as
	select "And age 66+ on date of storm" as description format=$256.
		, count(*) as Benes
		, "where death_pre = 0 and age66p = 1" as restriction format=$256.
	from &storm._adrd_flags
	where death_pre = 0 and age66p = 1
	;
	
	create table row4 as
	select "And did not move in pre-index year to index year" as description format=$256.
		, count(*) as Benes
		, "where death_pre = 0 and age66p = 1 and no_moving_pre = 1" as restriction format=$256.
	from &storm._adrd_flags
	where death_pre = 0 and age66p = 1 and no_moving_pre = 1
	;

	create table row5 as
	select "And did not move in index year to post-index year" as description format=$256.
		, count(*) as Benes
		, "where death_pre = 0 and age66p = 1 and no_moving_pre = 1 and no_moving_post = 1" as restriction format=$256.
	from &storm._adrd_flags
	where death_pre = 0 and age66p = 1 and no_moving_pre = 1 and no_moving_post = 1
	;

	create table row6 as
	select "And bene has FFS coverage in year prior to index date" as description format=$256.
		, count(*) as Benes
		, "where death_pre = 0 and age66p = 1 and no_moving_pre = 1 and no_moving_post = 1 and ffs_pre/ma_pre = 1" as restriction format=$256.
	from &storm._adrd_flags
	where death_pre = 0 and age66p = 1 and no_moving_pre = 1 and no_moving_post = 1 and (ffs_pre = 1 or ma_pre = 1)
	;

	create table row7 as
	select "And bene has ADRD Dx in year prior to index date" as description format=$256.
		, count(*) as Benes
		, "where death_pre = 0 and age66p = 1 and no_moving_pre = 1 and no_moving_post = 1 and ffs_pre/ma_pre = 1 and adrd = 1" as restriction format=$256.
	from &storm._adrd_flags
	where death_pre = 0 and age66p = 1 and no_moving_pre = 1 and no_moving_post = 1 and (ffs_pre = 1 or ma_pre = 1) and adrd = 1
	;

	create table row8 as
	select "And died in year post-index" as description format=$256.
		, count(*) as Benes
		, "where death_pre = 0 and age66p = 1 and no_moving_pre = 1 and no_moving_post = 1 and ffs_pre/ma_pre = 1 and adrd = 1 and death_post = 1" as restriction format=$256.
	from &storm._adrd_flags
	where death_pre = 0 and age66p = 1 and no_moving_pre = 1 and no_moving_post = 1 and (ffs_pre = 1 or ma_pre = 1) and adrd = 1 and death_post = 1
	;

quit;


data restrictions;
	format description $256. benes best8. restriction $256.;
	set row1-row8;
run;

data restrictions;
	set restrictions;
	retain description benes n_removed pct_of_last restriction;

	lag_benes = lag(benes);
	n_removed = lag_benes - benes;
	pct_of_last = benes/lag_benes;

	drop lag_benes;
run;

proc print data=restrictions; title "restrictions for &storm."; 
	var description benes n_removed pct_of_last description;
run;


data SH070617.&storm._adrd_flags (keep=bene_id adrd adrd_ma adrd_ffs);
	set &storm._adrd_flags;
run;

proc contents data=SH070617.&storm._adrd_flags;
	title "final ADRD flags fro &storm - SH070617.&storm._adrd_flags";
run;


%mend;

%bene_adrd(allison);
%bene_adrd(charley);
%bene_adrd(florence);
%bene_adrd(frances);
%bene_adrd(harvey);
%bene_adrd(ike);
%bene_adrd(irene);
%bene_adrd(irma);
%bene_adrd(ivan);
%bene_adrd(katrina);
%bene_adrd(matthew);
%bene_adrd(michael);
%bene_adrd(rita);
%bene_adrd(sandy);
%bene_adrd(wilma);



