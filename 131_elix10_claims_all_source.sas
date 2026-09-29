

/*start-header
################################################################################
# Type of File     : SAS
#
# Program Name     : 131_elix10_claims_all_source.sas
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
# Output file      : SH070617.[storm]_elix10_[source]_[claims/enc]
#
#################################################################################
end-header*/


%macro elix10_process(storm, file, source);

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

/* limit to datasets where we will need to run ICD10 */
%if &pre_index_year. >= 2015 %then %do;

/* read in the &source. file for &file. */
data &file.;
	set SH070617.&storm._&file._&source._pre (keep=bene_id service_dt service_thru_dt dx:);
run;

proc sort data=&file. nodup; by bene_id; run;


data &file._elix(keep=bene_id service_dt service_thru_dt include
                CMR_ALCOHOLLIVER_MLD
                CMR_CBVD_POA 
                CMR_CBVD_SQLA
                CMR_CBVD_SQLAPARALYSIS
                CMR_DRUG_ABUSEPSYCHOSES
                CMR_HFHTN_CX
                CMR_HFHTN_CXRENLFL_SEV
                CMR_HTN_CXRENLFL_SEV
                CMR_VALVE_AUTOIMMUNE
                CMR_AIDS
                CMR_ALCOHOL
                CMR_ANEMDEF
                CMR_AUTOIMMUNE
                CMR_BLDLOSS
                CMR_CANCER_LEUK
                CMR_CANCER_LYMPH
                CMR_CANCER_METS
                CMR_CANCER_NSITU
                CMR_CANCER_SOLID
                CMR_CBVD
                CMR_COAG
                CMR_DEMENTIA
                CMR_DEPRESS
                CMR_DIAB_CX
                CMR_DIAB_UNCX
                CMR_DRUG_ABUSE
                CMR_HF
                CMR_HTN_CX
                CMR_HTN_UNCX
                CMR_LIVER_MLD
                CMR_LIVER_SEV
                CMR_LUNG_CHRONIC
                CMR_NEURO_MOVT
                CMR_NEURO_OTH
                CMR_NEURO_SEIZ
                CMR_OBESE
                CMR_PARALYSIS
                CMR_PERIVASC
                CMR_PSYCHOSES
                CMR_PULMCIRC
                CMR_RENLFL_MOD
                CMR_RENLFL_SEV
                CMR_THYROID_HYPO
                CMR_THYROID_OTH
                CMR_ULCER_PEPTIC
                CMR_VALVE
                CMR_WGHTLOSS) ;
    set &file.;


    format service_dt date9.;
    format service_thru_dt date9.;
    label 
        service_dt = "Date of Elixhauser Comorbidity Dx"
        service_thru_dt = "Discharge Date of Elixhauser Comorbidity Dx"
        yr = "Year of claim"
        ;

    array d(*) $ dx:;

	ARRAY COM1 (47)  CMR_ALCOHOLLIVER_MLD
                        CMR_CBVD_POA 
                        CMR_CBVD_SQLA
                        CMR_CBVD_SQLAPARALYSIS
                        CMR_DRUG_ABUSEPSYCHOSES
                        CMR_HFHTN_CX
                        CMR_HFHTN_CXRENLFL_SEV
                        CMR_HTN_CXRENLFL_SEV
                        CMR_VALVE_AUTOIMMUNE
                        CMR_AIDS
                        CMR_ALCOHOL
                        CMR_ANEMDEF
                        CMR_AUTOIMMUNE
                        CMR_BLDLOSS
                        CMR_CANCER_LEUK
                        CMR_CANCER_LYMPH
                        CMR_CANCER_METS
                        CMR_CANCER_NSITU
                        CMR_CANCER_SOLID
                        CMR_CBVD
                        CMR_COAG
                        CMR_DEMENTIA
                        CMR_DEPRESS
                        CMR_DIAB_CX
                        CMR_DIAB_UNCX
                        CMR_DRUG_ABUSE
                        CMR_HF
                        CMR_HTN_CX
                        CMR_HTN_UNCX
                        CMR_LIVER_MLD
                        CMR_LIVER_SEV
                        CMR_LUNG_CHRONIC
                        CMR_NEURO_MOVT
                        CMR_NEURO_OTH
                        CMR_NEURO_SEIZ
                        CMR_OBESE
                        CMR_PARALYSIS
                        CMR_PERIVASC
                        CMR_PSYCHOSES
                        CMR_PULMCIRC
                        CMR_RENLFL_MOD
                        CMR_RENLFL_SEV
                        CMR_THYROID_HYPO
                        CMR_THYROID_OTH
                        CMR_ULCER_PEPTIC
                        CMR_VALVE
                        CMR_WGHTLOSS
                        ;

	ARRAY COM2 (47) $ 19 A1-A47
	                 ('ALCOHOLLIVER_MLD'
                        'CBVD_POA '
                        'CBVD_SQLA'
                        'CBVD_SQLAPARALYSIS'
                        'DRUG_ABUSEPSYCHOSES'
                        'HFHTN_CX'
                        'HFHTN_CXRENLFL_SEV'
                        'HTN_CXRENLFL_SEV'
                        'VALVE_AUTOIMMUNE'
                        'AIDS'
                        'ALCOHOL'
                        'ANEMDEF'
                        'AUTOIMMUNE'
                        'BLDLOSS'
                        'CANCER_LEUK'
                        'CANCER_LYMPH'
                        'CANCER_METS'
                        'CANCER_NSITU'
                        'CANCER_SOLID'
                        'CBVD'
                        'COAG'
                        'DEMENTIA'
                        'DEPRESS'
                        'DIAB_CX'
                        'DIAB_UNCX'
                        'DRUG_ABUSE'
                        'HF'
                        'HTN_CX'
                        'HTN_UNCX'
                        'LIVER_MLD'
                        'LIVER_SEV'
                        'LUNG_CHRONIC'
                        'NEURO_MOVT'
                        'NEURO_OTH'
                        'NEURO_SEIZ'
                        'OBESE'
                        'PARALYSIS'
                        'PERIVASC'
                        'PSYCHOSES'
                        'PULMCIRC'
                        'RENLFL_MOD'
                        'RENLFL_SEV'
                        'THYROID_HYPO'
                        'THYROID_OTH'
                        'ULCER_PEPTIC'
                        'VALVE'
                        'WGHTLOSS') ; 
	LENGTH   CMR_ALCOHOLLIVER_MLD
                CMR_CBVD_POA 
                CMR_CBVD_SQLA
                CMR_CBVD_SQLAPARALYSIS
                CMR_DRUG_ABUSEPSYCHOSES
                CMR_HFHTN_CX
                CMR_HFHTN_CXRENLFL_SEV
                CMR_HTN_CXRENLFL_SEV
                CMR_VALVE_AUTOIMMUNE
                CMR_AIDS
                CMR_ALCOHOL
                CMR_ANEMDEF
                CMR_AUTOIMMUNE
                CMR_BLDLOSS
                CMR_CANCER_LEUK
                CMR_CANCER_LYMPH
                CMR_CANCER_METS
                CMR_CANCER_NSITU
                CMR_CANCER_SOLID
                CMR_CBVD
                CMR_COAG
                CMR_DEMENTIA
                CMR_DEPRESS
                CMR_DIAB_CX
                CMR_DIAB_UNCX
                CMR_DRUG_ABUSE
                CMR_HF
                CMR_HTN_CX
                CMR_HTN_UNCX
                CMR_LIVER_MLD
                CMR_LIVER_SEV
                CMR_LUNG_CHRONIC
                CMR_NEURO_MOVT
                CMR_NEURO_OTH
                CMR_NEURO_SEIZ
                CMR_OBESE
                CMR_PARALYSIS
                CMR_PERIVASC
                CMR_PSYCHOSES
                CMR_PULMCIRC
                CMR_RENLFL_MOD
                CMR_RENLFL_SEV
                CMR_THYROID_HYPO
                CMR_THYROID_OTH
                CMR_ULCER_PEPTIC
                CMR_VALVE
                CMR_WGHTLOSS
                 3 ;

	/****************************************************/
	/* Initialize  COM1 to 0 and assigns the variable   */
	/*  name from COM1 as the VALUE of COM2             */
	/****************************************************/
	DO I = 1 TO 47;
	  COM1(I) = 0;
	END;

    include = 0;

    DO I = 1 TO dim(d); 
      IF d(I) NE " " THEN DO;
        DXVALUE = PUT(d(I),$COMFMT.);
        IF DXVALUE NE " " THEN DO;
          include = 1;
          DO J = 1 TO 47;
            IF DXVALUE = COM2(J) THEN DO;
			  COM1(J) = 1;
			END;
          END;
        END;
      END;
    END;

	/****************************************************/
	/* Update conditions that use temp flags            */
	/****************************************************/
    if CMR_ALCOHOLLIVER_MLD=1 then do;
        CMR_ALCOHOL=1;
        CMR_LIVER_MLD=1;
    end;

    if CMR_CBVD_POA=1 or CMR_CBVD_SQLA=1 then CMR_CBVD=1;

    if CMR_CBVD_SQLAPARALYSIS then do;
        CMR_CBVD=1;
        CMR_PARALYSIS=1;
    end;

    if CMR_DRUG_ABUSEPSYCHOSES=1 then do;
        CMR_DRUG_ABUSE=1;
		CMR_PSYCHOSES=1;
    end;

    if CMR_HFHTN_CX=1 then do;
        CMR_HF=1;
		CMR_HTN_CX=1;
    end;

    if CMR_HFHTN_CXRENLFL_SEV=1 then do;
        CMR_HF=1;
        CMR_RENLFL_SEV=1;
	    CMR_HTN_CX=1;
    end;

    if CMR_HTN_CXRENLFL_SEV=1 then do;
        CMR_RENLFL_SEV=1;
		CMR_HTN_CX=1;
    end;

    if CMR_VALVE_AUTOIMMUNE=1 then do;
        CMR_AUTOIMMUNE=1;
		CMR_VALVE=1;
    end;

    LABEL
        CMR_AIDS         = 'Acquired immune deficiency syndrome' 
        CMR_ALCOHOL      = 'Alcohol abuse'    
        CMR_ANEMDEF      = 'Deficiency anemias'      
        CMR_AUTOIMMUNE   = 'Autoimmune conditions'
        CMR_BLDLOSS      = 'Chronic blood loss anemia'   
        CMR_CANCER_LEUK  = 'Leukemia'
        CMR_CANCER_LYMPH = 'Lymphoma'
        CMR_CANCER_METS  = 'Metastatic cancer'
        CMR_CANCER_NSITU = 'Solid tumor without metastasis, in situ'
        CMR_CANCER_SOLID = 'Solid tumor without metastasis, malignant' 
        CMR_CBVD         = 'Cerebrovascular disease'
        CMR_HF           = 'Heart failure'
        CMR_COAG         = 'Coagulopathy' 
        CMR_DEMENTIA     = 'Dementia'
        CMR_DEPRESS      = 'Depression'
        CMR_DIAB_CX      = 'Diabetes with chronic complications'
        CMR_DIAB_UNCX    = 'Diabetes without chronic complications'
        CMR_DRUG_ABUSE   = 'Drug abuse'
        CMR_HTN_CX       = 'Hypertension, complicated' 
        CMR_HTN_UNCX     = 'Hypertension, uncomplicated'
        CMR_LIVER_MLD    = 'Liver disease, mild'
        CMR_LIVER_SEV    = 'Liver disease, moderate to severe'
        CMR_LUNG_CHRONIC = 'Chronic pulmonary disease'
        CMR_NEURO_MOVT   = 'Neurological disorders affecting movement'
        CMR_NEURO_OTH    = 'Other neurological disorders' 
        CMR_NEURO_SEIZ   = 'Seizures and epilepsy'            
        CMR_OBESE        = 'Obesity'    
        CMR_PARALYSIS    = 'Paralysis'
        CMR_PERIVASC     = 'Peripheral vascular disease'
        CMR_PSYCHOSES    = 'Psychoses'
        CMR_PULMCIRC     = 'Pulmonary circulation disease'    
        CMR_RENLFL_MOD   = 'Renal failure, moderate'
        CMR_RENLFL_SEV   = 'Renal failure, severe' 
        CMR_THYROID_HYPO = 'Hypothyroidism'
        CMR_THYROID_OTH  = 'Other thyroid disorders'
        CMR_ULCER_PEPTIC = 'Peptic ulcer disease x bleeding'     
        CMR_VALVE        = 'Valvular disease'
        CMR_WGHTLOSS     = 'Weight loss'         
        ;

run;


proc freq data=&file._elix;
	title "checking proper creation of Elixhauser conditions";
    tables  include CMR_: 
            CMR_ALCOHOLLIVER_MLD*CMR_ALCOHOL*CMR_LIVER_MLD 
            CMR_CBVD*CMR_CBVD_POA*CMR_CBVD_SQLA*CMR_CBVD_SQLAPARALYSIS
            CMR_CBVD_SQLAPARALYSIS*CMR_CBVD*CMR_PARALYSIS
            CMR_DRUG_ABUSEPSYCHOSES*CMR_DRUG_ABUSE*CMR_PSYCHOSES
            CMR_HFHTN_CX*CMR_HF*CMR_HTN_CX
            CMR_HFHTN_CXRENLFL_SEV*CMR_HF*CMR_RENLFL_SEV*CMR_HTN_CX
            CMR_HTN_CXRENLFL_SEV*CMR_RENLFL_SEV*CMR_HTN_CX
            CMR_VALVE_AUTOIMMUNE*CMR_AUTOIMMUNE*CMR_VALVE
            / list missing;
run;

proc print data=&file._elix (obs=10);
    where include=1;
run;



*remove any duplicates;
proc sort nodup data=&file._elix; by bene_id service_dt service_thru_dt;
run; 

/*proc contents data=&file._elix; run;*/
/*proc print data=&file._elix (obs=10); run;*/

proc freq data=&file._elix; 
    title "Check when claims are from";
    tables service_dt service_thru_dt / list missing; 
    format service_dt service_thru_dt monyy7.;
run;


* copy dataset to output folder;
data SH070617.&storm._elix10_&file._&source.(keep=bene_id service_dt service_thru_dt include
                                    CMR_AIDS
                                    CMR_ALCOHOL
                                    CMR_ANEMDEF
                                    CMR_AUTOIMMUNE
                                    CMR_BLDLOSS
                                    CMR_CANCER_LEUK
                                    CMR_CANCER_LYMPH
                                    CMR_CANCER_METS
                                    CMR_CANCER_NSITU
                                    CMR_CANCER_SOLID
                                    CMR_CBVD
                                    CMR_COAG
                                    CMR_DEMENTIA
                                    CMR_DEPRESS
                                    CMR_DIAB_CX
                                    CMR_DIAB_UNCX
                                    CMR_DRUG_ABUSE
                                    CMR_HF
                                    CMR_HTN_CX
                                    CMR_HTN_UNCX
                                    CMR_LIVER_MLD
                                    CMR_LIVER_SEV
                                    CMR_LUNG_CHRONIC
                                    CMR_NEURO_MOVT
                                    CMR_NEURO_OTH
                                    CMR_NEURO_SEIZ
                                    CMR_OBESE
                                    CMR_PARALYSIS
                                    CMR_PERIVASC
                                    CMR_PSYCHOSES
                                    CMR_PULMCIRC
                                    CMR_RENLFL_MOD
                                    CMR_RENLFL_SEV
                                    CMR_THYROID_HYPO
                                    CMR_THYROID_OTH
                                    CMR_ULCER_PEPTIC
                                    CMR_VALVE
                                    CMR_WGHTLOSS) ;
  set &file._elix;
  where include=1;
run;

proc contents data=SH070617.&storm._elix10_&file._&source.; 
title "checking final file - SH070617.&storm._elix10_&file._&source.";
run;
proc print data=SH070617.&storm._elix10_&file._&source. (obs=10); run;


proc sql;
    title "check original file - SH070617.&storm._&file._&source._pre";
	select count(*) as recs, count(distinct bene_id) as u_benes
	from SH070617.&storm._&file._&source._pre
	;

    title "check elixhauser file";
	select count(*) as recs, count(distinct bene_id) as u_benes
	from SH070617.&storm._elix10_&file._&source.
	;


    title "check elixhauser file, where include=1 (at least one condition)";
	select count(*) as recs, count(distinct bene_id) as u_benes
	from SH070617.&storm._elix10_&file._&source.
	where include = 1
	;
quit;

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
    from SH070617.&storm._elix10_&file._&source. 
    where &vrbl. = 1
    ;

    insert into comob
        values("&vrbl.", &clms., &benes.)
        ;
quit;

%mend;

%check_comob(CMR_AIDS)          %check_comob(CMR_ALCOHOL)       %check_comob(CMR_ANEMDEF)
%check_comob(CMR_AUTOIMMUNE)    %check_comob(CMR_BLDLOSS)       %check_comob(CMR_CANCER_LEUK)
%check_comob(CMR_CANCER_LYMPH)  %check_comob(CMR_CANCER_METS)   %check_comob(CMR_CANCER_NSITU)
%check_comob(CMR_CANCER_SOLID)  %check_comob(CMR_CBVD)          %check_comob(CMR_COAG)
%check_comob(CMR_DEMENTIA)      %check_comob(CMR_DEPRESS)       %check_comob(CMR_DIAB_CX)
%check_comob(CMR_DIAB_UNCX)     %check_comob(CMR_DRUG_ABUSE)    %check_comob(CMR_HF)
%check_comob(CMR_HTN_CX)        %check_comob(CMR_HTN_UNCX)      %check_comob(CMR_LIVER_MLD)
%check_comob(CMR_LIVER_SEV)     %check_comob(CMR_LUNG_CHRONIC)  %check_comob(CMR_NEURO_MOVT)
%check_comob(CMR_NEURO_OTH)     %check_comob(CMR_NEURO_SEIZ)    %check_comob(CMR_OBESE)
%check_comob(CMR_PARALYSIS)     %check_comob(CMR_PERIVASC)      %check_comob(CMR_PSYCHOSES)
%check_comob(CMR_PULMCIRC)      %check_comob(CMR_RENLFL_MOD)    %check_comob(CMR_RENLFL_SEV)
%check_comob(CMR_THYROID_HYPO)  %check_comob(CMR_THYROID_OTH)   %check_comob(CMR_ULCER_PEPTIC)
%check_comob(CMR_VALVE)         %check_comob(CMR_WGHTLOSS);

proc print data=comob;
    title "comorbidity counts in file - SH070617.&storm._elix10_&file._&source.";
run;
%end;
%mend;

/*elix10_process(storm, file, source);*/

%elix10_process(allison, medpar, claims);
%elix10_process(allison, hha, claims);
%elix10_process(allison, hospice, claims);
%elix10_process(allison, outpt, claims);
%elix10_process(allison, carrier, claims);

%elix10_process(charley, medpar, claims);
%elix10_process(charley, hha, claims);
%elix10_process(charley, hospice, claims);
%elix10_process(charley, outpt, claims);
%elix10_process(charley, carrier, claims);

%elix10_process(florence, medpar, claims);
%elix10_process(florence, hha, claims);
%elix10_process(florence, hospice, claims);
%elix10_process(florence, outpt, claims);
%elix10_process(florence, carrier, claims);
%elix10_process(florence, hha, enc);
%elix10_process(florence, ip, enc);
%elix10_process(florence, snf, enc);
%elix10_process(florence, carrier, enc);
%elix10_process(florence, outpt, enc);

%elix10_process(frances, medpar, claims);
%elix10_process(frances, hha, claims);
%elix10_process(frances, hospice, claims);
%elix10_process(frances, outpt, claims);
%elix10_process(frances, carrier, claims);

%elix10_process(harvey, medpar, claims);
%elix10_process(harvey, hha, claims);
%elix10_process(harvey, hospice, claims);
%elix10_process(harvey, outpt, claims);
%elix10_process(harvey, carrier, claims);
%elix10_process(harvey, hha, enc);
%elix10_process(harvey, ip, enc);
%elix10_process(harvey, snf, enc);
%elix10_process(harvey, carrier, enc);
%elix10_process(harvey, outpt, enc);

%elix10_process(ike, medpar, claims);
%elix10_process(ike, hha, claims);
%elix10_process(ike, hospice, claims);
%elix10_process(ike, outpt, claims);
%elix10_process(ike, carrier, claims);

%elix10_process(irene, medpar, claims);
%elix10_process(irene, hha, claims);
%elix10_process(irene, hospice, claims);
%elix10_process(irene, outpt, claims);
%elix10_process(irene, carrier, claims);

%elix10_process(irma, medpar, claims);
%elix10_process(irma, hha, claims);
%elix10_process(irma, hospice, claims);
%elix10_process(irma, outpt, claims);
%elix10_process(irma, carrier, claims);
%elix10_process(irma, hha, enc);
%elix10_process(irma, ip, enc);
%elix10_process(irma, snf, enc);
%elix10_process(irma, carrier, enc);
%elix10_process(irma, outpt, enc);

%elix10_process(ivan, medpar, claims);
%elix10_process(ivan, hha, claims);
%elix10_process(ivan, hospice, claims);
%elix10_process(ivan, outpt, claims);
%elix10_process(ivan, carrier, claims);

%elix10_process(katrina, medpar, claims);
%elix10_process(katrina, hha, claims);
%elix10_process(katrina, hospice, claims);
%elix10_process(katrina, outpt, claims);
%elix10_process(katrina, carrier, claims);

%elix10_process(matthew, medpar, claims);
%elix10_process(matthew, hha, claims);
%elix10_process(matthew, hospice, claims);
%elix10_process(matthew, outpt, claims);
%elix10_process(matthew, carrier, claims);
%elix10_process(matthew, hha, enc);
%elix10_process(matthew, ip, enc);
%elix10_process(matthew, snf, enc);
%elix10_process(matthew, carrier, enc);
%elix10_process(matthew, outpt, enc);

%elix10_process(michael, medpar, claims);
%elix10_process(michael, hha, claims);
%elix10_process(michael, hospice, claims);
%elix10_process(michael, outpt, claims);
%elix10_process(michael, carrier, claims);
%elix10_process(michael, hha, enc);
%elix10_process(michael, ip, enc);
%elix10_process(michael, snf, enc);
%elix10_process(michael, carrier, enc);
%elix10_process(michael, outpt, enc);

%elix10_process(rita, medpar, claims);
%elix10_process(rita, hha, claims);
%elix10_process(rita, hospice, claims);
%elix10_process(rita, outpt, claims);
%elix10_process(rita, carrier, claims);

%elix10_process(sandy, medpar, claims);
%elix10_process(sandy, hha, claims);
%elix10_process(sandy, hospice, claims);
%elix10_process(sandy, outpt, claims);
%elix10_process(sandy, carrier, claims);

%elix10_process(wilma, medpar, claims);
%elix10_process(wilma, hha, claims);
%elix10_process(wilma, hospice, claims);
%elix10_process(wilma, outpt, claims);
%elix10_process(wilma, carrier, claims);
