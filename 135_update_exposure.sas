
proc print data=SH070617.allison_exposure_data (obs=5); run;


%macro update_exp(storm);


proc sort data=SH070617.&storm._exposure_data; by geoid; run;

data exp;
	set SH070617.&storm._exposure_data;
	length storm $15.;
    length geoid $5.;
	storm = "&storm.";

	/* update precipitation */
	total_prcp_in = mean_prcp_in*4;
	total_prcp_mm = mean_prcp_mm*4;

	/* add indicators for &storm. */
	total_prcp_ge_75mm = (total_prcp_mm >= 75);

	vmax_sust_gt_34kt = ((vmax_sust_knots) > 34);
	vmax_sust_gt_64kt = ((vmax_sust_knots) > 64);

	dist_from_storm_le_100km = (dist_from_storm_min <= 100);

	any_major_exposure = max(vmax_sust_gt_34kt, total_prcp_ge_75mm, dist_from_storm_le_100km);

	drop dist_from_storm_min_datetime vmax_sust_max_datetime;
run;

proc stdize data=exp (keep=geoid total_prcp_in vmax_sust_mph dist_from_storm_min vmax_sust_above_34kt_dur) out=zscores method=std;
	title "scales for &storm.";
	var total_prcp_in vmax_sust_mph dist_from_storm_min vmax_sust_above_34kt_dur;
run;

proc sql;
	create table exposure_final_&storm. as
	select exp.*
		, z.total_prcp_in as z_storm_total_prcp
		, z.vmax_sust_mph as z_storm_vmax_sust
		, z.dist_from_storm_min as z_storm_dist_from_storm_min
        , z.vmax_sust_above_34kt_dur as z_storm_min_wind_above_34kt
	from exp as exp
		left join zscores z
		on exp.geoid = z.geoid
	;
quit;

%mend;

%update_exp(allison);
%update_exp(charley);
%update_exp(florence);
%update_exp(frances);
%update_exp(harvey);
%update_exp(ike);
%update_exp(irene);
%update_exp(irma);
%update_exp(ivan);
%update_exp(katrina);
%update_exp(matthew);
%update_exp(michael);
%update_exp(rita);
%update_exp(sandy);
%update_exp(wilma);


data all_storms;
	set exposure_final_: ;
run;

proc stdize data=all_storms (keep=geoid storm total_prcp_in vmax_sust_mph dist_from_storm_min vmax_sust_above_34kt_dur) out=zscores method=std;
	title "scales for all combined storms";
	var total_prcp_in vmax_sust_mph dist_from_storm_min vmax_sust_above_34kt_dur;
run;

proc sql;
	create table exposure_all_storms as
	select all_storms.*
		, z.total_prcp_in as z_all_total_prcp
		, z.vmax_sust_mph as z_all_vmax_sust
		, z.dist_from_storm_min as z_all_dist_from_storm_min
        , z.vmax_sust_above_34kt_dur as z_all_min_wind_above_34kt
	from all_storms
		left join zscores z
		on all_storms.geoid = z.geoid
		and all_storms.storm = z.storm
	;
quit;

data exposure_all_storms;
	set exposure_all_storms;

	if total_prcp_in = . then do;
		z_storm_total_prcp = .;
		z_all_total_prcp = .;
	end;
	if vmax_sust_mph = . then do;
		z_storm_vmax_sust = .;
		z_all_vmax_sust = .;
	end;
	if dist_from_storm_min = . then do;
		z_storm_dist_from_storm_min = .;
		z_all_dist_from_storm_min = .;
	end;

	label z_all_total_prcp = "zscore (all storms) total precipitation. -2 thru +1 days storm nearest approach"
		z_storm_total_prcp = "zscore (per storm) total precipitation. -2 thru +1 days storm nearest approach"
		z_all_vmax_sust = "zscore (all storms) max sustained wind speed"
		z_all_dist_from_storm_min = "zscore (all storms) minimum distance from storm nearest approach"
		total_prcp_ge_75mm = "total precipitation >= 75mm. -2 thru +1 days storm nearest approach"
		vmax_sust_gt_34kt = "tropical storm sustained wind speeds (>34kt). 1/0"
		vmax_sust_gt_64kt = "hurricane sustained wind speeds (>64kt). 1/0"
		z_storm_vmax_sust = "zscore (per storm) max sustained wind speed"
		dist_from_storm_le_100km = "storm nearest approach of <=100km. 1/0"
		z_storm_dist_from_storm_min = "zscore (per storm) minimum distance from storm nearest approach"
		any_major_exposure = "any of Anderson exposures (75mm rain, 34kt wind, 100km nearest approach). 1/0"
        z_storm_min_wind_above_34kt = "zscore (per storm) minutes of max sustained wind speed above 34 knotts"
        z_all_min_wind_above_34kt = "zscore (all storms) minutes of max sustained wind speed above 34 knotts"
		;
run;

proc means data=exposure_all_storms n nmiss mean std; 
	title "exposure_all_storms - means and standard deviations";
	var total_prcp_in vmax_sust_mph dist_from_storm_min vmax_sust_above_34kt_dur z_: ;
run;


%macro update_exp2(storm);
data SH070617.&storm._exposure_data_final;
	set exposure_all_storms;
    length geoid $5.;
	where storm = "&storm.";
run;

proc contents data=SH070617.&storm._exposure_data_final varnum;
	title "final exposure dataset for &storm.";
run;

proc freq data= SH070617.&storm._exposure_data_final;
	tables storm / missing;
run;

proc means data=SH070617.&storm._exposure_data_final n nmiss mean std; 
	title "&storm. - means and standard deviations";
	var total_prcp_in vmax_sust_mph dist_from_storm_min vmax_sust_above_34kt_dur z_: ;
run;
%mend;

%update_exp2(allison);
%update_exp2(charley);
%update_exp2(florence);
%update_exp2(frances);
%update_exp2(harvey);
%update_exp2(ike);
%update_exp2(irene);
%update_exp2(irma);
%update_exp2(ivan);
%update_exp2(katrina);
%update_exp2(matthew);
%update_exp2(michael);
%update_exp2(rita);
%update_exp2(sandy);
%update_exp2(wilma);

