

/*start-header
################################################################################
# Type of File     : SAS
#
# Program Name     : 120_bene_adrd_med_hha_hsp.sas
#			
# Program Path     : sasCCW\Files\dua_070617_jma617\code
#
# Programmed By    : Jonathan Martindale
#
# Date Created     : 12Mar2025	
#
# Project Title    : Bell-Davis RF1
#
# Purpose          : Process ADRD claims from Medpar, HHA, and Hospice files for each storm
#
# Input files      : SH070617.hurricanes
#					 SH070617.[storm]_mbsf_elig
#					 in070617.snfclms[year]_r14229
#
# Output file      : SH070617.[storm]_[source]_[claims/enc]_pre
#
#################################################################################
end-header*/
%let DemDx9=( '2900', '2901',' 29010', '29011', '29012', '29013' ,'2902', '29020', '29021', '2903', '2904', '29040',
  '29041', '29042', '29043', '2941', '29410', '29411', '2942', '29420', '29421', '331', '3310', '33111', '33119',
  '33182', '2908', '2940', '3312', '3317', '3318', '33189', '797');

*ICD10;
%let DemDx10=('F0150','F0151','F0280','F0281','F0390', 'F0391', 'G300', 'G301', 'G308', 'G309', 'G3101','G3109', 'G3183',
 'F04','G311','G312','R4181');


%let storm=allison;
%let source=claims;
%let file=medpar;


proc contents data=SH070617.&storm._&file._&source._pre varnum;
title "All Medpar Claims for &storm. - SH070617.&storm._&file._&source._pre"; 
run;



%macro adrd_process(storm, file, source);
/* read in the &source. file for &file. */
data &file.;
	set SH070617.&storm._&file._&source._pre (keep=bene_id service_dt service_thru_dt dx:);
run;

proc sort data=&file. nodup; by bene_id; run;


data &file._adrd_dx (keep=bene_id service_dt service_thru_dt ADRD_Dx ICD_Dx);
	set &file.;

	attrib ICD_Dx length=$5 label="ADRD ICD9/10 Dx";
	attrib ADRD_Dx length=3 label="Presense of ADRD diagnosis. 1/0";

	ADRD_Dx = 0;

	array dx_vars(*) $ dx: ;

	do i=1 to dim(dx_vars);
		if dx_vars(i) in &DemDx10. or dx_vars(i) in &DemDx9. then ADRD_Dx=1;

		/* output each dx for data checks */
		if ADRD_Dx=1 then do;
			ICD_dx=dx_vars(i);
			output;
		end;

		/* reset ADRD_Dx */
		adrd_dx = 0;
	end;
run;


proc freq data=&file._adrd_dx;
	title "check diagnoses";
	tables adrd_dx icd_dx*adrd_dx / nopercent norow;
run;


/* create intermediate file with service date for ADRD claims */
proc sort data=&file._adrd_dx (keep=bene_id service_dt service_thru_dt ADRD_Dx) 
	nodupkey 
	out=SH070617.&storm._&file._&source._ad_sd; 
	by bene_id service_dt service_thru_dt; 
run;


data SH070617.&storm._&file._&source._ad_b (keep=bene_id ADRD_Dx);
	set &file._adrd_dx;
	by bene_id;

	if first.bene_id then output;
run;


proc contents data=SH070617.&storm._&file._&source._ad_b;
	title "For storm &storm. - check bene-level ADRD file - SH070617.&storm._&file._&source._ad_b";
run;

proc sql;
	title "number of benes and claims from source claim file - SH070617.&storm._&file._&source._pre";
	select count(*) as recs, count(distinct bene_id) as u_benes
	from SH070617.&storm._&file._&source._pre
	;

	title "number of benes and claims with ADRD from int file - &file._adrd_dx";
	select count(*) as recs, count(distinct bene_id) as u_benes
	from &file._adrd_dx
	;

	title "number of benes and claims with ADRD from servdt file - SH070617.&storm._&file._&source._ad_sd";
	select count(*) as recs, count(distinct bene_id) as u_benes
	from SH070617.&storm._&file._&source._ad_sd
	;

	title "number of benes in final bene-level ADRD file - SH070617.&storm._&file._&source._ad_b";
	select count(*) as recs, count(distinct bene_id) as u_benes
	from SH070617.&storm._&file._&source._ad_b
	;
quit;


%mend;

/*adrd_process(storm, file, source);*/

%adrd_process(allison, medpar, claims);
%adrd_process(allison, hha, claims);
%adrd_process(allison, hospice, claims);
%adrd_process(allison, outpt, claims);
%adrd_process(allison, carrier, claims);

%adrd_process(charley, medpar, claims);
%adrd_process(charley, hha, claims);
%adrd_process(charley, hospice, claims);
%adrd_process(charley, outpt, claims);
%adrd_process(charley, carrier, claims);

%adrd_process(florence, medpar, claims);
%adrd_process(florence, hha, claims);
%adrd_process(florence, hospice, claims);
%adrd_process(florence, outpt, claims);
%adrd_process(florence, carrier, claims);
%adrd_process(florence, hha, enc);
%adrd_process(florence, ip, enc);
%adrd_process(florence, snf, enc);
%adrd_process(florence, carrier, enc);
%adrd_process(florence, outpt, enc);

%adrd_process(frances, medpar, claims);
%adrd_process(frances, hha, claims);
%adrd_process(frances, hospice, claims);
%adrd_process(frances, outpt, claims);
%adrd_process(frances, carrier, claims);

%adrd_process(harvey, medpar, claims);
%adrd_process(harvey, hha, claims);
%adrd_process(harvey, hospice, claims);
%adrd_process(harvey, outpt, claims);
%adrd_process(harvey, carrier, claims);
%adrd_process(harvey, hha, enc);
%adrd_process(harvey, ip, enc);
%adrd_process(harvey, snf, enc);
%adrd_process(harvey, carrier, enc);
%adrd_process(harvey, outpt, enc);

%adrd_process(ike, medpar, claims);
%adrd_process(ike, hha, claims);
%adrd_process(ike, hospice, claims);
%adrd_process(ike, outpt, claims);
%adrd_process(ike, carrier, claims);

%adrd_process(irene, medpar, claims);
%adrd_process(irene, hha, claims);
%adrd_process(irene, hospice, claims);
%adrd_process(irene, outpt, claims);
%adrd_process(irene, carrier, claims);

%adrd_process(irma, medpar, claims);
%adrd_process(irma, hha, claims);
%adrd_process(irma, hospice, claims);
%adrd_process(irma, outpt, claims);
%adrd_process(irma, carrier, claims);
%adrd_process(irma, hha, enc);
%adrd_process(irma, ip, enc);
%adrd_process(irma, snf, enc);
%adrd_process(irma, carrier, enc);
%adrd_process(irma, outpt, enc);

%adrd_process(ivan, medpar, claims);
%adrd_process(ivan, hha, claims);
%adrd_process(ivan, hospice, claims);
%adrd_process(ivan, outpt, claims);
%adrd_process(ivan, carrier, claims);

%adrd_process(katrina, medpar, claims);
%adrd_process(katrina, hha, claims);
%adrd_process(katrina, hospice, claims);
%adrd_process(katrina, outpt, claims);
%adrd_process(katrina, carrier, claims);

%adrd_process(matthew, medpar, claims);
%adrd_process(matthew, hha, claims);
%adrd_process(matthew, hospice, claims);
%adrd_process(matthew, outpt, claims);
%adrd_process(matthew, carrier, claims);
%adrd_process(matthew, hha, enc);
%adrd_process(matthew, ip, enc);
%adrd_process(matthew, snf, enc);
%adrd_process(matthew, carrier, enc);
%adrd_process(matthew, outpt, enc);

%adrd_process(michael, medpar, claims);
%adrd_process(michael, hha, claims);
%adrd_process(michael, hospice, claims);
%adrd_process(michael, outpt, claims);
%adrd_process(michael, carrier, claims);
%adrd_process(michael, hha, enc);
%adrd_process(michael, ip, enc);
%adrd_process(michael, snf, enc);
%adrd_process(michael, carrier, enc);
%adrd_process(michael, outpt, enc);

%adrd_process(rita, medpar, claims);
%adrd_process(rita, hha, claims);
%adrd_process(rita, hospice, claims);
%adrd_process(rita, outpt, claims);
%adrd_process(rita, carrier, claims);

%adrd_process(sandy, medpar, claims);
%adrd_process(sandy, hha, claims);
%adrd_process(sandy, hospice, claims);
%adrd_process(sandy, outpt, claims);
%adrd_process(sandy, carrier, claims);

%adrd_process(wilma, medpar, claims);
%adrd_process(wilma, hha, claims);
%adrd_process(wilma, hospice, claims);
%adrd_process(wilma, outpt, claims);
%adrd_process(wilma, carrier, claims);
