

%pvgosprd(ag21, sprd_new, pvgo2, 25);


proc import out=junk2
	file="V:\data_for_kai\ctychar_20160518.xlsx"
	dbms=excel replace;
sheet="sheet1";
getnames=yes;
run;

data old; set junk2;
pe_old=pebar;
keep country portyear pe_old;
proc sort; by country portyear;
run;


data new; set sprd_new;
pe_new=pe;
keep country portyear pe_new;
proc sort; by country portyear;
run;


data merged; merge old new;
by country portyear;
if country in ("AU", "BD", "CH", "CN", "FN", "FR", "GR", "HK", "IN", "IS", 
"IT", "JP", "KO", "MY","SD", "SG", "SW", "TA", "TK", "UK", "US");
run;

proc corr data=merged out=corr;
by country;
var pe_old pe_new;
run;

libname pwd "C:\TEMP\displace\20190401";

data pwd.pe_old; set final;
run;
data pwd.corr; set corr;
run;


data pvgosprd; set merged;
pe=coalesce(pe_old, pe_new);
drop pe_:;
run;



data pwd.pe_augment; set final;
run;


data ag21; set ag21;
if country in ("AU", "BD", "CH", "CN", "FN", "FR", "GR", "HK", "IN", "IS", 
"IT", "JP", "KO", "MY","SD", "SG", "SW", "TA", "TK", "UK", "US");
run;

data UK; set ag21;
if country="UK";
keep code country year p_updated csh mc2;
run;

data xUK; set ag21;
if country~="UK";
keep code country year p_updated csh mc2;
run;

proc means data=UK; run;

proc means data=ag21;
by country;
var p_updated csh mc2;
output out=mc2;
run;

data junk; set ag21;
if country="US";
*if ta~=taus;
if p_updated>1000;
proc sort; by code portyear;
*proc means;
run;

data junk2; set mc2;
if _STAT_="MEAN";
run;

data pwd.mc2; set mc2;
run;
