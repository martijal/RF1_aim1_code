

/*start-header
################################################################################
# Type of File     : SAS
#
# Program Name     : 121_bene_adrd_bo.sas
#			
# Program Path     : sasCCW\Files\dua_070617_jma617\code
#
# Programmed By    : Jonathan Martindale
#
# Date Created     : 13Mar2025	
#
# Project Title    : Bell-Davis RF1
#
# Purpose          : Process ADRD claims for Part B (carrier) and Outpt
#
#
# Input file       : SH070617.&storm._carrier_&source._ad_sd;
#					 SH070617.&storm._outpt_&source._ad_sd;
#
# Output files     : SH070617.&storm._bo_&source._ad_b
#
################################################################################
end-header*/

%macro adrd_bo_process(storm, source);

data prtb (keep=bene_id service_dt service_thru_dt ADRD_Dx data_source);
  set SH070617.&storm._carrier_&source._ad_sd;
  length data_source $1.;
  label data_source = "Data Source: B for carrier, O for outpatient." ;
  data_source = 'B';
run;


data outpt (keep=bene_id service_dt service_thru_dt ADRD_Dx data_source);
  set SH070617.&storm._outpt_&source._ad_sd;
  length data_source $1.;
  label data_source = "Data Source: B for carrier, O for outpatient." ;
  data_source = 'O';
run;


data prtb_outpt;
  set prtb outpt;
run;


proc freq data=prtb_outpt;
    title; 
    tables data_source / list missing; 
run;


proc sort data=prtb_outpt; by bene_id service_dt data_source; run;


data prtb_outpt;
  set prtb_outpt;
  rowid = monotonic(); 
run;

proc sql;
  create table bo1 as
  select bene_id, rowid as rowid1, service_dt as service_dt1
  from prtb_outpt;
quit;

proc sql;
  create table bo2 as
  select bene_id, rowid as rowid2, service_dt as service_dt2
  from prtb_outpt;
quit;


proc sql;
  create table bo12 as
  select a.bene_id, a.rowid1, a.service_dt1, b.rowid2, b.service_dt2, 
  ((b.service_dt2 - a.service_dt1) + 1) as interval 
  from bo1 a, bo2 b
  where a.bene_id = b.bene_id
    and b.service_dt2 - a.service_dt1 >= 7 /* required lower limit */
  order by bene_id,rowid1,rowid2;
quit;

proc means data=bo12;
	title "check interval for &storm. on bo12";
	var interval;
run;


proc sql; 
  /* subset to unique bene_id-row_id*/
  create table bo1_match as
  select distinct bene_id, rowid1
  from bo12
  ;

  create table bo2_match as
  select distinct bene_id, rowid2
  from bo12
  ;

quit;


* merge claims back on by row_id;
proc sql;
  create table bo_final_1 as
  select a.*
  from prtb_outpt a, bo1_match b
  where a.bene_id=b.bene_id
    and a.rowid=b.rowid1;
quit;


proc sql;
  create table bo_final_2 as
  select a.*
  from prtb_outpt a, bo2_match b
  where a.bene_id=b.bene_id
    and a.rowid=b.rowid2;
quit;

data bo_final (drop=rowid);
  set bo_final_1 bo_final_2;
run;

proc sort data=bo_final nodup; by bene_id service_dt; run;


proc print data=prtb_outpt (obs=30); 
	title "check pre-merge - prtb_outpt";
run;

proc print data=bo12 (obs=30); 
	title "check post-merge - bo12";
run;

proc print data=bo_final (obs=30); 
	title "check final - bo_final";
run;



* save data and check numbers; 
data SH070617.&storm._bo_&source._ad_sd (keep=bene_id 
                                    service_dt 
                                    service_thru_dt
                                    ADRD_Dx
                                    );
  set bo_final;
run;

data SH070617.&storm._bo_&source._ad_b (keep=bene_id ADRD_Dx);
	set SH070617.&storm._outpt_&source._ad_sd;
	by bene_id;
	if first.bene_id then output;
run;


proc contents data=SH070617.&storm._bo_&source._ad_b;
	title "Final bene-level file for &storm. and &source.";
run;

proc sql;
	title "check numbers from combined outpt-carrier - prtb_outpt";
	select count(*) as recs, count(distinct bene_id) as u_benes
	from prtb_outpt
	;

	title "check numbers from final servicedt file - SH070617.&storm._outpt_&source._ad_sd";
	select count(*) as recs, count(distinct bene_id) as u_benes
	from SH070617.&storm._outpt_&source._ad_sd
	;

	title "check numbers from final bene-level file - SH070617.&storm._bo_&source._ad_b";
	select count(*) as recs, count(distinct bene_id) as u_benes
	from SH070617.&storm._bo_&source._ad_b
	;
quit;

%mend;
/*%adrd_bo_process(storm, source);*/

%adrd_bo_process(allison, claims);
%adrd_bo_process(charley, claims);
%adrd_bo_process(florence, claims);
%adrd_bo_process(florence, enc);
%adrd_bo_process(frances, claims);
%adrd_bo_process(harvey, claims);
%adrd_bo_process(harvey, enc);
%adrd_bo_process(ike, claims);
%adrd_bo_process(irene, claims);
%adrd_bo_process(irma, claims);
%adrd_bo_process(irma, enc);
%adrd_bo_process(ivan, claims);
%adrd_bo_process(katrina, claims);
%adrd_bo_process(matthew, claims);
%adrd_bo_process(matthew, enc);
%adrd_bo_process(michael, claims);
%adrd_bo_process(michael, enc);
%adrd_bo_process(rita, claims);
%adrd_bo_process(sandy, claims);
%adrd_bo_process(wilma, claims);
