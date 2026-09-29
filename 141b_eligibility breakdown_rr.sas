

/*start-header
################################################################################
# Type of File     : SAS
#
# Program Name     : 141_eligibility_breakdown.sas
#			
# Program Path     : sasCCW\Files\dua_070617_jma617\code
#
# Programmed By    : Jonathan Martindale
#
# Date Created     : 04Jun2025	
#
# Date Updated     : 20Oct2025 - Updated death and missingness variables	
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
#
# Output file      : SH070617.[storm]_full_cohort
#					 SH070617.all_storms_full_cohort
#
#################################################################################
end-header*/

/* Per storm check */
%macro elig_breakdown(storm);
proc sql;
	create table row1 as
	select "All benes identified for &storm." as description format=$256.
		, count(*) as recs
        , count(distinct bene_id) as u_benes
		, "None" as restriction format=$256.
	from sh070617.&storm._full_cohort
	;
	
	create table row2 as
	select "And alive on date of storm" as description format=$256.
		, count(*) as recs
        , count(distinct bene_id) as u_benes
		, "where death_pre = 0" as restriction format=$256.
	from sh070617.&storm._full_cohort
	where death_pre = 0
	;
	
	create table row3 as
	select "And age 66+ on date of storm" as description format=$256.
		, count(*) as recs
        , count(distinct bene_id) as u_benes
		, "where death_pre = 0 and age66p = 1" as restriction format=$256.
	from sh070617.&storm._full_cohort
	where death_pre = 0 and age66p = 1
	;
	
	create table row4 as
	select "And did not move in pre-index year to index year" as description format=$256.
		, count(*) as recs
        , count(distinct bene_id) as u_benes
		, "where death_pre = 0 and age66p = 1 and no_moving_pre = 1" as restriction format=$256.
	from sh070617.&storm._full_cohort
	where death_pre = 0 and age66p = 1 and no_moving_pre = 1
	;

	create table row5 as
	select "And did not move in index year to post-index year" as description format=$256.
		, count(*) as recs
        , count(distinct bene_id) as u_benes
		, "where death_pre = 0 and age66p = 1 and no_moving_pre = 1 and no_moving_post = 1" as restriction format=$256.
	from sh070617.&storm._full_cohort
	where death_pre = 0 and age66p = 1 and no_moving_pre = 1 and no_moving_post = 1
	;

	create table row6 as
	select "And bene has FFS coverage in year prior to index date" as description format=$256.
		, count(*) as recs
        , count(distinct bene_id) as u_benes
		, "where death_pre = 0 and age66p = 1 and no_moving_pre = 1 and no_moving_post = 1 and ffs_pre/ma_pre = 1" as restriction format=$256.
	from sh070617.&storm._full_cohort
	where death_pre = 0 and age66p = 1 and no_moving_pre = 1 and no_moving_post = 1 and (ffs_pre = 1 or ma_pre = 1)
	;

	create table row7 as
	select "And bene has ADRD Dx in year prior to index date" as description format=$256.
		, count(*) as recs
        , count(distinct bene_id) as u_benes
		, "where death_pre = 0 and age66p = 1 and no_moving_pre = 1 and no_moving_post = 1 and ffs_pre/ma_pre = 1 and adrd = 1" as restriction format=$256.
	from sh070617.&storm._full_cohort
	where death_pre = 0 and age66p = 1 and no_moving_pre = 1 and no_moving_post = 1 and (ffs_pre = 1 or ma_pre = 1) and adrd = 1
	;

	create table row8 as
	select "And no nursing home stay" as description format=$256.
		, count(*) as recs
        , count(distinct bene_id) as u_benes
		, "where death_pre = 0 and age66p = 1 and no_moving_pre = 1 and no_moving_post = 1 and ffs_pre/ma_pre = 1 and adrd = 1 and mds_pre = 0" as restriction format=$256.
	from sh070617.&storm._full_cohort
	where death_pre = 0 and age66p = 1 and no_moving_pre = 1 and no_moving_post = 1 and (ffs_pre = 1 or ma_pre = 1) and adrd = 1 and mds_pre = 0
	;

	create table row9 as
	select "And complete exposure data" as description format=$256.
		, count(*) as recs
        , count(distinct bene_id) as u_benes
		, "where death_pre = 0 and age66p = 1 and no_moving_pre = 1 and no_moving_post = 1 and ffs_pre/ma_pre = 1 and adrd = 1 and mds_pre = 0 and complete_exp_data = 1" as restriction format=$256.
	from sh070617.&storm._full_cohort
	where death_pre = 0 and age66p = 1 and no_moving_pre = 1 and no_moving_post = 1 and (ffs_pre = 1 or ma_pre = 1) and adrd = 1 and mds_pre = 0 and complete_exp_data = 1
	;

	create table row10 as
	select "And no missingness" as description format=$256.
		, count(*) as recs
        , count(distinct bene_id) as u_benes
		, "where death_pre = 0 and age66p = 1 and no_moving_pre = 1 and no_moving_post = 1 and ffs_pre/ma_pre = 1 and adrd = 1 and mds_pre = 0 and complete_exp_data = 1 and no_miss = 1" as restriction format=$256.
	from sh070617.&storm._full_cohort
	where death_pre = 0 and age66p = 1 and no_moving_pre = 1 and no_moving_post = 1 and (ffs_pre = 1 or ma_pre = 1) and adrd = 1 and mds_pre = 0 and complete_exp_data = 1 and (no_miss = 1 and ruca3cat ^= 99)
    ;
	

	create table row11 as
	select "Complete exposure data and died in year post-index" as description format=$256.
		, count(*) as recs
        , count(distinct bene_id) as u_benes
		, "where death_pre = 0 and age66p = 1 and no_moving_pre = 1 and no_moving_post = 1 and ffs_pre/ma_pre = 1 and adrd = 1 and mds_pre = 0 and complete_exp_data = 1 and death_post_ndi = 1" as restriction format=$256.
	from sh070617.&storm._full_cohort
	where death_pre = 0 and age66p = 1 and no_moving_pre = 1 and no_moving_post = 1 and (ffs_pre = 1 or ma_pre = 1) and adrd = 1 and mds_pre = 0 and complete_exp_data = 1 and death_post_ndi = 1
	;

quit;


data restrictions;
	format description $256. u_benes best8. restriction $256.;
	set row1-row11;
run;

data restrictions;
	set restrictions;
	retain description recs n_removed_recs pct_of_last_recs u_benes n_removed_benes pct_of_last_benes restriction;

	lag_u_benes = lag(u_benes);
	n_removed_benes = lag_u_benes - u_benes;
	pct_of_last_benes = u_benes/lag_u_benes;

	lag_recs = lag(recs);
	n_removed_recs = lag_recs - recs;
	pct_of_last_recs = recs/lag_recs;

	drop lag_u_benes lag_recs;
run;

proc print data=restrictions; title "restrictions for &storm."; 
	var description recs n_removed_recs pct_of_last_recs u_benes n_removed_benes pct_of_last_benes restriction;
run;

proc export data=restrictions
	dbms=xlsx
	outfile="/sas/vrdc/users/jma617/files/dua_070617_jma617/results/elig_breakdown_20260213.xlsx"
	replace;
	sheet="&storm";
run;

%mend;

%elig_breakdown(allison);
%elig_breakdown(charley);
%elig_breakdown(florence);
%elig_breakdown(frances);
%elig_breakdown(harvey);
%elig_breakdown(ike);
%elig_breakdown(irene);
%elig_breakdown(irma);
%elig_breakdown(ivan);
%elig_breakdown(katrina);
%elig_breakdown(matthew);
%elig_breakdown(michael);
%elig_breakdown(rita);
%elig_breakdown(sandy);
%elig_breakdown(wilma);
%elig_breakdown(all_storms);

