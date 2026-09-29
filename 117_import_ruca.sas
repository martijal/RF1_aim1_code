

/*start-header
################################################################################
# Type of File     : SAS
#
# Program Name     : 117_import_ruca.sas
#			
# Program Path     : sasCCW\Files\dua_070617_jma617\code
#
# Programmed By    : Jonathan Martindale
#
# Date Created     : 04Jun2025	
#
# Project Title    : Bell-Davis RF1
#
# Purpose          : prelim analyses - exposure exploration
#
# Input files      : RUCA2010zipcode.xlsx
#
# Output file      : ruca2010
#
#################################################################################
end-header*/

proc import 
	datafile="/sas/vrdc/users/jma617/files/dua_070617_jma617/resources/RUCA2010zipcode.xlsx"
	out=ruca
	dbms=xlsx
	replace;
	sheet="data";
	getnames=yes;
run;

proc contents data=ruca; run;

data SH070617.ruca2010;
	set ruca;

	if ruca1 in(1, 2, 3) then ruca3cat = 1;
	else if ruca1 in(4, 5, 6) then ruca3cat = 2;
	else if ruca1 in(7, 8, 9, 10) then ruca3cat = 3;

	label ruca3cat = "RUCA in 3 cats: 1=Metro, 2=Micro/Suburban, 3=Small town/Rural"
		;

run;

proc freq data=SH070617.ruca2010;
	tables ruca3cat*ruca1 / list missing;
run;
