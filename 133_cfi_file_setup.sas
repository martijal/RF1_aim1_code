

/*start-header
################################################################################
# Type of File     : SAS
#
# Program Name     : 133_cfi_file_setup
#
# Program Path     : sasccw
#
# Programmed By    : Jonathan Martindale
#
# Date Created     : 17Apr2025
# 
# Project Title    : Bell-Davis RF1
# 
# Purpose		   : Generate CFI-ready datasets for each storm (HCPCS/PX, ICD9, ICD10).
#
# Input files      : SH070617.hurricanes, 
#					SH070617.[storm]_[file]_[source]_pre
#
# Output files     : SH070617.[storm]_[source]_hcpcs_long
#					 SH070617.[storm]_[source]_icd9_long
#					 SH070617.[storm]_[source]_icd10_long
#
################################################################################
end-header*/

*options ls=120 ps=64 nocenter nodate nonumber pagesize=6500 nofullstimer mprint msglevel=i;


%macro cfi_format(storm, source);

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


%macro hcpcs_icd(file);

/* Macro for processing files down to DX and HCPCS codes */
/* pull HCPCS */
data hcpcs_&file._&source.;
	length HCPCS_CD $5.;
	set SH070617.&storm._&file._&source._pre (keep=bene_id service_dt HCPCS_CD);
run;

/* remove duplicates */
proc sort data=hcpcs_&file._&source. nodup;
	by bene_id HCPCS_CD;
run;
	

/* pull ICD diagnoses */
data icd_&file._&source.;
	set SH070617.&storm._&file._&source._pre (keep=bene_id service_dt dx:);
run;

/*  remove duplicates */
proc sort data=icd_&file._&source. nodup;
	by bene_id service_dt;
run;

proc transpose data=icd_&file._&source. 
	out=icd_&file._&source._long
	prefix=dx
	;
	by bene_id service_dt;
	var dx:;
run;

/* drop blanks */
data icd_&file._&source._long;
    set icd_&file._&source._long (rename=(dx1=dx));
    where dx not in("");
run;

/* separate by ICD9 and ICD10 code */
data icd9_&file._&source._long (keep=bene_id service_dt dx);
    set icd_&file._&source._long;
    where service_dt < '01OCT2015'd;
run;

data icd10_&file._&source._long (keep=bene_id service_dt dx);
    set icd_&file._&source._long;
    where service_dt >= '01OCT2015'd;
run;

proc sql;
	title "check numbers from original file - SH070617.&storm._&file._&source._pre";
	select count(*) as recs 
		, count(distinct bene_id) as u_benes
	from SH070617.&storm._&file._&source._pre
	;

	title "check numbers from HCPCS file - hcpcs_&file._&source.";
	select count(*) as recs 
		, count(distinct bene_id) as u_benes
	from hcpcs_&file._&source.
	;

	title "check numbers from ICD file - icd_&file._&source._long";
	select count(*) as recs 
		, count(distinct bene_id) as u_benes
	from icd_&file._&source._long
	;
	
	title "check numbers from ICD9 file - icd9_&file._&source._long";
	select count(*) as recs 
		, count(distinct bene_id) as u_benes
	from icd9_&file._&source._long
	;

	title "check numbers from ICD10 file - icd10_&file._&source._long";
	select count(*) as recs 
		, count(distinct bene_id) as u_benes
	from icd10_&file._&source._long
	;

%mend hcpcs_icd;
/*%macro hcpcs_icd(file);*/

%if "&source." = "claims" %then %do;
	%hcpcs_icd(carrier);
	%hcpcs_icd(outpt);
	%hcpcs_icd(medpar);
	%hcpcs_icd(hha);
	%hcpcs_icd(dme);
%end;

%else %if "&source." = "enc" %then %do;
	%hcpcs_icd(carrier);
	%hcpcs_icd(outpt);
	%hcpcs_icd(ip);
	%hcpcs_icd(snf);
	%hcpcs_icd(hha);
	%hcpcs_icd(dme);
%end;


data SH070617.&storm._&source._hcpcs_long;
	format service_dt date9.;
	set hcpcs_: ;
run;

data SH070617.&storm._&source._icd9_long;
	format service_dt date9.;
	set icd9_: ;
run;

data SH070617.&storm._&source._icd10_long;
	format service_dt date9.;
	set icd10_: ;
run;

proc contents data=SH070617.&storm._&source._hcpcs_long varnum;
	title "check final files for &storm. &source.";
run;

proc contents data=SH070617.&storm._&source._icd9_long varnum; run;
proc contents data=SH070617.&storm._&source._icd10_long varnum; run;

/* remove all datasets in WORK library to ensure we don't 
	accidentally count data from the wrong storm */
proc datasets library=work kill;
quit;

%mend cfi_format;


%cfi_format(allison, claims);

%cfi_format(charley, claims);

%cfi_format(florence, claims);
%cfi_format(florence, enc);

%cfi_format(frances, claims);

%cfi_format(harvey, claims);
%cfi_format(harvey, enc);

%cfi_format(ike, claims);

%cfi_format(irene, claims);

%cfi_format(irma, claims);
%cfi_format(irma, enc);

%cfi_format(ivan, claims);

%cfi_format(katrina, claims);

%cfi_format(matthew, claims);
%cfi_format(matthew, enc);

%cfi_format(michael, claims);
%cfi_format(michael, enc);

%cfi_format(rita, claims);

%cfi_format(sandy, claims);

%cfi_format(wilma, claims);
