

/*start-header
################################################################################
# Type of File     : SAS
#
# Program Name     : 116_bene_MDS_all.sas
#			
# Program Path     : sasCCW\Files\dua_070617_jma617\code
#
# Programmed By    : Jonathan Martindale
#
# Date Created     : 03Jun2025	
#
# Project Title    : Bell-Davis RF1
#
# Purpose          : Collapse MDS data down to bene-level
#
# Input files      : SH070617.[storm]_mds_claims_pre
#
# Output file      : SH070617.[storm]_mds_bene_pre
#
#################################################################################
end-header*/



%macro mds_agg_storm(storm);

proc sql;
	create table SH070617.&storm._mds_bene_pre as
	select bene_id
		 , max(mds_pre) as mds_pre
	from SH070617.&storm._mds_claims_pre
	group by bene_id
	order by bene_id
	;
quit;

data SH070617.&storm._mds_bene_pre;
	set SH070617.&storm._mds_bene_pre;
	label mds_pre = "Any MDS stay in baseline period. 1/0"
	;
run;

proc contents data=SH070617.&storm._mds_bene_pre varnum;
	title "final bene-level MDS data - SH070617.&storm._mds_bene_pre";
run;


proc sql;
	title "number of benes for &storm.";
	select count(*) as recs, count(distinct bene_id) as u_benes
	from SH070617.&storm._mbsf_elig
	;

	title "number of benes in bene-level MDS file - SH070617.&storm._mds_bene_pre";
	select count(*) as recs, count(distinct bene_id) as u_benes
	from SH070617.&storm._mds_bene_pre
	;
quit;


%mend;

%mds_agg_storm(allison);
%mds_agg_storm(charley);
%mds_agg_storm(florence);
%mds_agg_storm(frances);
%mds_agg_storm(harvey);
%mds_agg_storm(ike);
%mds_agg_storm(irene);
%mds_agg_storm(irma);
%mds_agg_storm(ivan);
%mds_agg_storm(katrina);
%mds_agg_storm(matthew);
%mds_agg_storm(michael);
%mds_agg_storm(rita);
%mds_agg_storm(sandy);
%mds_agg_storm(wilma);




