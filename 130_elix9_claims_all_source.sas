

/*start-header
################################################################################
# Type of File     : SAS
#
# Program Name     : 130_elix9_claims_all_source.sas
#			
# Program Path     : sasCCW\Files\dua_070617_jma617\code
#
# Programmed By    : Jonathan Martindale
#
# Date Created     : 12Mar2025	
#
# Project Title    : Bell-Davis RF1
#
# Purpose          : Process elix claims from Medpar, HHA, and Hospice files for each storm
#
# Input files      : SH070617.hurricanes
#					 SH070617.SH070617.[storm]_[source]_[claims/enc]_pre
#
# Output file      : SH070617.[storm]_elix9_[source]_[claims/enc]
#
#################################################################################
end-header*/


%macro elix9_process(storm, file, source);

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

/* limit to datasets where we will need to run ICD9 */
%if &pre_index_year. <= 2015 %then %do;

/* read in the &source. file for &file. */
data &file.;
	set SH070617.&storm._&file._&source._pre (keep=bene_id service_dt service_thru_dt dx:);
run;

proc sort data=&file. nodup; by bene_id; run;


data &file._elix 
(keep=bene_id service_dt service_thru_dt include 
			HTN_C CHF VALVE PULMCIRC PERIVASC PARA NEURO CHRNLUNG DM DMCX HYPOTHY RENLFAIL LIVER
			ULCER AIDS LYMPH METS TUMOR ARTH COAG OBESE WGHTLOSS LYTES BLDLOSS ANEMDEF ALCOHOL
			DRUG PSYCH DEPRESS 
   HTNPREG_ 
   HTNWOCHF_ 
   HTNWCHF_ 
   HRENWORF_ 
   HRENWRF_  
   HHRWOHRF_ 
   HHRWCHF_ 
   HHRWRF_ 
   HHRWHRF_
   OHTNPREG_
   HTN
   HTNCX
   DXVALUE
			) 
            ;
    set &file.;

    * calndar year of claim - admit date;
    yr=year(service_dt);

    format service_dt date9.;
    format service_thru_dt date9.;
    label 
        service_dt = "Date of Elixhauser Comorbidity Dx"
        service_thru_dt = "Discharge Date of Elixhauser Comorbidity Dx"
        yr = "Year of claim"
        ;

    array d(*) $ dx:;

	ARRAY COM1 (30)  CHF      VALVE    PULMCIRC PERIVASC
	                 HTN      HTNCX    PARA     NEURO    CHRNLUNG
	                 DM       DMCX     HYPOTHY  RENLFAIL LIVER
	                 ULCER    AIDS     LYMPH    METS     TUMOR
	                 ARTH     COAG     OBESE    WGHTLOSS LYTES
	                 BLDLOSS  ANEMDEF  ALCOHOL  DRUG     PSYCH
	                 DEPRESS ;

	ARRAY COM2 (30) $ 8 A1-A30
	                 ("CHF"     "VALVE"   "PULMCIRC" "PERIVASC" 
	                 "HTN"     "HTNCX"   "PARA"     "NEURO"     "CHRNLUNG" 
	                 "DM"      "DMCX"    "HYPOTHY"  "RENLFAIL"  "LIVER" 
	                 "ULCER"   "AIDS"    "LYMPH"    "METS"      "TUMOR" 
	                 "ARTH"    "COAG"    "OBESE"    "WGHTLOSS"  "LYTES" 
	                 "BLDLOSS" "ANEMDEF" "ALCOHOL"  "DRUG"      "PSYCH" 
	                 "DEPRESS") ; 

	LENGTH   CHF      VALVE    PULMCIRC PERIVASC
	         HTN      HTNCX    PARA     NEURO    CHRNLUNG
	         DM       DMCX     HYPOTHY  RENLFAIL LIVER
	         ULCER    AIDS     LYMPH    METS     TUMOR
	         ARTH     COAG     OBESE    WGHTLOSS LYTES
	         BLDLOSS  ANEMDEF  ALCOHOL  DRUG     PSYCH
	         DEPRESS 3 ;

	/****************************************************/
	/* Initialize  COM1 to 0 and assigns the variable   */
	/*  name from COM1 as the VALUE of COM2             */
	/****************************************************/
	DO I = 1 TO 30;
	  COM1(I) = 0;
	END;

    /***************************************************/
    /* Looking at the secondary DXs and using formats, */
    /* create DXVALUE to define each comorbidity group */
    /*                                                 */
    /* If DXVALUE is equal to the comorbidity name in  */
    /* array COM2 then a value of 1 is assigned to the */
    /* corresponding comorbidity group in array COM1   */
    /***************************************************/
   HTNPREG_  = 0;
   HTNWOCHF_ = 0;
   HTNWCHF_  = 0;
   HRENWORF_ = 0;
   HRENWRF_  = 0;
   HHRWOHRF_ = 0;
   HHRWCHF_  = 0;
   HHRWRF_   = 0;
   HHRWHRF_  = 0;
   OHTNPREG_ = 0;
   include 	 = 0;

   DO I = 1 TO dim(d); 
      IF d(I) NE " " THEN DO;
         DXVALUE = PUT(d(I),$RCOMFMT.);
         IF DXVALUE NE " " THEN DO;
		    include = 1;
            DO J = 1 TO 30;
               IF DXVALUE = COM2(J) THEN DO;
				 COM1(J) = 1;
			   END;
            END;			 
			
		   /*********************************************/
		   /* Create detailed hypertension flags that   */
		   /* cover combinations of Congestive Heart    */
		   /* Failure, Hypertension Complicated, and    */
		   /* Renal Failure. These will be used in con- */
		   /* junction with DRG values to set the HTNCX,*/
		   /* CHF, and RENLFAIL comorbidities.          */
		   /*********************************************/
		   SELECT(DXVALUE);
		      WHEN ("HTNPREG")     HTNPREG_  = 1;
		      WHEN ("HTNWOCHF")    HTNWOCHF_ = 1;
		      WHEN ("HTNWCHF")     HTNWCHF_  = 1;
		      WHEN ("HRENWORF")    HRENWORF_ = 1;
		      WHEN ("HRENWRF")     HRENWRF_  = 1;
		      WHEN ("HHRWOHRF")    HHRWOHRF_ = 1;
		      WHEN ("HHRWCHF")     HHRWCHF_  = 1;
		      WHEN ("HHRWRF")      HHRWRF_   = 1;
		      WHEN ("HHRWHRF")     HHRWHRF_  = 1;
		      WHEN ("OHTNPREG")    OHTNPREG_ = 1;
		      OTHERWISE;
		   END;
         END;
      END;
    END;

	/*******************************************/
	/* Initialize Hypertension, CHF, and Renal */
	/* Comorbidity flags to 1 using the detail */
	/* hypertension flags.                     */
	/*******************************************/
	IF HTNPREG_  THEN HTNCX = 1;
	IF HTNWOCHF_ THEN HTNCX = 1;
	IF HTNWCHF_  THEN DO;
	   HTNCX    = 1;
       CHF      = 1;
	END;
	IF HRENWORF_ THEN HTNCX = 1;
	IF HRENWRF_  THEN DO;
	   HTNCX    = 1;
       RENLFAIL = 1;
	END;
	IF HHRWOHRF_ THEN HTNCX = 1;
    IF HHRWCHF_  THEN DO;
	   HTNCX    = 1;
	   CHF      = 1;
	END;
	IF HHRWRF_   THEN DO;
	   HTNCX    = 1;
       RENLFAIL = 1;
	END;
	IF HHRWHRF_  THEN DO;
	   HTNCX    = 1;
	   CHF      = 1;
	   RENLFAIL = 1;
	END;
	IF OHTNPREG_ THEN HTNCX = 1;

   /*************************************/
   /*  Combine HTN and HTNCX into HTN_C */
   /*************************************/
   ATTRIB HTN_C LENGTH=3 LABEL='Hypertension';

   IF HTN=1 OR HTNCX=1 THEN HTN_C=1;
   ELSE HTN_C=0;


    LABEL  CHF        = 'Congestive heart failure'
           VALVE      = 'Valvular disease'
           PULMCIRC   = 'Pulmonary circulation disease'
           PERIVASC   = 'Peripheral vascular disease'
           PARA       = 'Paralysis'
           NEURO      = 'Other neurological disorders'
           CHRNLUNG   = 'Chronic pulmonary disease'
           DM         = 'Diabetes w/o chronic complications'
           DMCX       = 'Diabetes w/ chronic complications'
           HYPOTHY    = 'Hypothyroidism'
           RENLFAIL   = 'Renal failure'
           LIVER      = 'Liver disease'
           ULCER      = 'Peptic ulcer Disease x bleeding'
           AIDS       = 'Acquired immune deficiency syndrome'
           LYMPH      = 'Lymphoma'
           METS       = 'Metastatic cancer'
           TUMOR      = 'Solid tumor w/out metastasis'
           ARTH       = 'Rheumatoid arthritis/collagen vas'
           COAG       = 'Coagulopthy'
           OBESE      = 'Obesity'
           WGHTLOSS   = 'Weight loss'
           LYTES      = 'Fluid and electrolyte disorders'
           BLDLOSS    = 'Chronic blood loss anemia'
           ANEMDEF    = 'Deficiency Anemias'
           ALCOHOL    = 'Alcohol abuse'
           DRUG       = 'Drug abuse'
           PSYCH      = 'Psychoses'
           DEPRESS    = 'Depression'
           ;
run;

proc freq data=&file._elix;
    title "checking proper creation of Elixhauser conditions";
    tables HTN: / list missing;
run;

proc print data=&file._elix (obs=10);
    where include=1;
run;


proc sql;
    title "check original file - SH070617.&storm._&file._&source._pre";
	select count(*) as recs, count(distinct bene_id) as u_benes
	from SH070617.&storm._&file._&source._pre
	;

    title "check elixhauser file";
	select count(*) as recs, count(distinct bene_id) as u_benes
	from &file._elix
	;


    title "check elixhauser file, where include=1 (at least one condition)";
	select count(*) as recs, count(distinct bene_id) as u_benes
	from &file._elix
	where include = 1
	;
quit;


*remove any duplicates;
proc sort nodup data=&file._elix; by bene_id service_dt service_thru_dt;
run; 

proc contents data=&file._elix; title; run;
proc print data=&file._elix (obs=10); run;


proc sql;
    title1 "Elix9 Dx. with no DC date in";
    select count(*) as null_&file._elix_dt
    from &file._elix
    where service_thru_dt is null;
quit;

proc freq data=&file._elix;
    title1 'Dx Count by Elixhauser9 condition';
    title2 'ICD-9-CM 2012-2015 definitions';
    table include  
		 CHF      VALVE    PULMCIRC PERIVASC
         HTN_C    PARA     NEURO    CHRNLUNG DM
         DMCX     HYPOTHY  RENLFAIL LIVER    ULCER
         AIDS     LYMPH    METS     TUMOR    ARTH
         COAG     OBESE    WGHTLOSS LYTES    BLDLOSS
         ANEMDEF  ALCOHOL  DRUG     PSYCH    DEPRESS / list missing;
run;


proc freq data=&file._elix; 
    title "Check when claims are from";
    tables service_dt service_thru_dt / list missing; 
    format service_dt service_thru_dt monyy7.;
run;


* copy dataset to output folder;
data SH070617.&storm._elix9_&file._&source. (keep=bene_id service_dt service_thru_dt 
            include 
			HTN_C CHF VALVE PULMCIRC PERIVASC PARA NEURO CHRNLUNG DM DMCX HYPOTHY RENLFAIL LIVER
			ULCER AIDS LYMPH METS TUMOR ARTH COAG OBESE WGHTLOSS LYTES BLDLOSS ANEMDEF ALCOHOL
			DRUG PSYCH DEPRESS) ;
  set &file._elix;
  where include=1;
run;

proc contents data=SH070617.&storm._elix9_&file._&source.; 
title "checking final file for SH070617.&storm._elix9_&file._&source.";
run;
proc print data=SH070617.&storm._elix9_&file._&source. (obs=10); run;



proc sql;
    create table comob
        (Comob_var char(19),
         claim_cnts num,
         unique_pats num);
quit;


%macro check_comob(vrbl);

proc sql noprint;
    select count(*), count(distinct bene_id)
        into :clms, :benes
    from SH070617.&storm._elix9_&file._&source. 
    where &vrbl. = 1
    ;

    insert into comob
        values("&vrbl.", &clms., &benes.)
        ;
quit;

%mend;


%check_comob(vrbl = CHF)        %check_comob(vrbl = VALVE)      %check_comob(vrbl = PULMCIRC) 
%check_comob(vrbl = PERIVASC)   %check_comob(vrbl = HTN_C)      %check_comob(vrbl = PARA) 
%check_comob(vrbl = NEURO)      %check_comob(vrbl = CHRNLUNG)   %check_comob(vrbl = DM)
%check_comob(vrbl = DMCX)       %check_comob(vrbl = HYPOTHY)    %check_comob(vrbl = RENLFAIL) 
%check_comob(vrbl = LIVER)      %check_comob(vrbl = ULCER)      %check_comob(vrbl = AIDS) 
%check_comob(vrbl = LYMPH)      %check_comob(vrbl = METS)       %check_comob(vrbl = TUMOR) 
%check_comob(vrbl = ARTH)       %check_comob(vrbl = COAG)       %check_comob(vrbl = OBESE)
%check_comob(vrbl = WGHTLOSS)   %check_comob(vrbl = LYTES)      %check_comob(vrbl = BLDLOSS)
%check_comob(vrbl = ANEMDEF)    %check_comob(vrbl = ALCOHOL)    %check_comob(vrbl = DRUG) 
%check_comob(vrbl = PSYCH)      %check_comob(vrbl = DEPRESS)


proc print data=comob;
	title "comorbidity counts for &storm. in SH070617.&storm._elix9_&file._&source.";
run;
%end;
%mend;

/*elix9_process(storm, file, source);*/


%elix9_process(allison, medpar, claims);
%elix9_process(allison, hha, claims);
%elix9_process(allison, hospice, claims);
%elix9_process(allison, outpt, claims);
%elix9_process(allison, carrier, claims);

%elix9_process(charley, medpar, claims);
%elix9_process(charley, hha, claims);
%elix9_process(charley, hospice, claims);
%elix9_process(charley, outpt, claims);
%elix9_process(charley, carrier, claims);

%elix9_process(florence, medpar, claims);
%elix9_process(florence, hha, claims);
%elix9_process(florence, hospice, claims);
%elix9_process(florence, outpt, claims);
%elix9_process(florence, carrier, claims);
%elix9_process(florence, hha, enc);
%elix9_process(florence, ip, enc);
%elix9_process(florence, snf, enc);
%elix9_process(florence, carrier, enc);
%elix9_process(florence, outpt, enc);

%elix9_process(frances, medpar, claims);
%elix9_process(frances, hha, claims);
%elix9_process(frances, hospice, claims);
%elix9_process(frances, outpt, claims);
%elix9_process(frances, carrier, claims);

%elix9_process(harvey, medpar, claims);
%elix9_process(harvey, hha, claims);
%elix9_process(harvey, hospice, claims);
%elix9_process(harvey, outpt, claims);
%elix9_process(harvey, carrier, claims);
%elix9_process(harvey, hha, enc);
%elix9_process(harvey, ip, enc);
%elix9_process(harvey, snf, enc);
%elix9_process(harvey, carrier, enc);
%elix9_process(harvey, outpt, enc);

%elix9_process(ike, medpar, claims);
%elix9_process(ike, hha, claims);
%elix9_process(ike, hospice, claims);
%elix9_process(ike, outpt, claims);
%elix9_process(ike, carrier, claims);

%elix9_process(irene, medpar, claims);
%elix9_process(irene, hha, claims);
%elix9_process(irene, hospice, claims);
%elix9_process(irene, outpt, claims);
%elix9_process(irene, carrier, claims);

%elix9_process(irma, medpar, claims);
%elix9_process(irma, hha, claims);
%elix9_process(irma, hospice, claims);
%elix9_process(irma, outpt, claims);
%elix9_process(irma, carrier, claims);
%elix9_process(irma, hha, enc);
%elix9_process(irma, ip, enc);
%elix9_process(irma, snf, enc);
%elix9_process(irma, carrier, enc);
%elix9_process(irma, outpt, enc);

%elix9_process(ivan, medpar, claims);
%elix9_process(ivan, hha, claims);
%elix9_process(ivan, hospice, claims);
%elix9_process(ivan, outpt, claims);
%elix9_process(ivan, carrier, claims);

%elix9_process(katrina, medpar, claims);
%elix9_process(katrina, hha, claims);
%elix9_process(katrina, hospice, claims);
%elix9_process(katrina, outpt, claims);
%elix9_process(katrina, carrier, claims);

%elix9_process(matthew, medpar, claims);
%elix9_process(matthew, hha, claims);
%elix9_process(matthew, hospice, claims);
%elix9_process(matthew, outpt, claims);
%elix9_process(matthew, carrier, claims);
%elix9_process(matthew, hha, enc);
%elix9_process(matthew, ip, enc);
%elix9_process(matthew, snf, enc);
%elix9_process(matthew, carrier, enc);
%elix9_process(matthew, outpt, enc);

%elix9_process(michael, medpar, claims);
%elix9_process(michael, hha, claims);
%elix9_process(michael, hospice, claims);
%elix9_process(michael, outpt, claims);
%elix9_process(michael, carrier, claims);
%elix9_process(michael, hha, enc);
%elix9_process(michael, ip, enc);
%elix9_process(michael, snf, enc);
%elix9_process(michael, carrier, enc);
%elix9_process(michael, outpt, enc);

%elix9_process(rita, medpar, claims);
%elix9_process(rita, hha, claims);
%elix9_process(rita, hospice, claims);
%elix9_process(rita, outpt, claims);
%elix9_process(rita, carrier, claims);

%elix9_process(sandy, medpar, claims);
%elix9_process(sandy, hha, claims);
%elix9_process(sandy, hospice, claims);
%elix9_process(sandy, outpt, claims);
%elix9_process(sandy, carrier, claims);

%elix9_process(wilma, medpar, claims);
%elix9_process(wilma, hha, claims);
%elix9_process(wilma, hospice, claims);
%elix9_process(wilma, outpt, claims);
%elix9_process(wilma, carrier, claims);
