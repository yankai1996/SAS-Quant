
libname db "V:\data_for_kai";
libname nnnDS "V:\data_for_kai\WSDS20190215";

proc import out=ex
	datafile="V:\data_for_kai\20190521\Export 21_05_2019 08_58.xlsx"
	dbms=xlsx replace;
getnames=yes;
sheet="Results";
run;


proc import out=ex
	datafile="Y:\Downloads\Export 22_05_2019 09_24.xlsx"
	dbms=xlsx replace;
getnames=yes;
sheet="Results";
run;


data agret0; set nnnDS.agret0;
if mthyr>200400;
if ta~=. and emp~=.;
run;

data agret0; set agret0;
*if code~=130062;
if country="GERMANY";
run;


proc import out=mini
	datafile="Y:\Downloads\Export 22_05_2019 05_09.txt"
	dbms=csv replace;
getnames=yes;
run;

data junk10; set agret0;
if code="287943";
run;

data junk99; set nnnDS.retm;
if dscd="779678";
run;
