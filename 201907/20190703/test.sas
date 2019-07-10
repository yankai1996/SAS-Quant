
libname bk "V:\data_for_kai\pvgo_pe_bk";

*%macro pvgo_pe(high1, low1, high2, low2);
%macro pvgo_pe(high1, low1);

data pvgo_old; set bk.old_pvgo_bk;
pvgo_old=dec&high1-dec&low1;
keep country portyear pvgo_old;
run;

data pvgo_new; set bk.new_pvgo_bk;
pvgo_new=dec&high1-dec&low1;
keep country portyear pvgo_new;
run;

data pe_old; set bk.old_pe_bk;
pe_old=dec&high1-dec&low1;
keep country portyear pe_old;
run;

data pe_new; set bk.new_pe_bk;
pe_new=dec&high1-dec&low1;
keep country portyear pe_new;
proc sort; by country portyear;
run;

data pvgo_pe; merge pvgo_old pvgo_new pe_old pe_new;
by country portyear;
*pvgo2=coalesce(pvgo_old, pvgo_new);
pvgo2=pvgo_new;
pe=coalesce(pe_old, pe_new);
*pe=pe_new;
*if pe<=&low2 or pe>=&high2 then pe=.;
if country in ("AU", "BD", "CH", "CN", "FN", "FR", "GR", "HK", "IN", "IS", 
"IT", "JP", "KO", "MY","SD", "SG", "SW", "TA", "TK", "UK", "US");
keep country portyear pvgo2 pe;
run;

%mend pvgo_pe;

%pvgo_pe(75, 25);


data agret2; set sub;
keep code portyear country RD MC;
proc sort nodup; by code portyear;
run;
data agret2; set agret2;
by code portyear;
lagMC=lag(MC);
if first.code then lagMC=.;
rhs1=RD/MC;
rhs2=RD/(MC-lagMC);
run;

data agret3; set sub;
proc sort; by code portyear;
run;
data agret3; merge agret3 agret2;
by code portyear;
run;

proc means data=agret3 noprint;
var rhs1 rhs2;
output out=stat1 std=rhs1 rhs2;
run;


proc means data=testdata6 noprint;
var pvgo2 pe;
output out=stat2 std=pvgo2 pe;
run;

data stat0; merge stat1 stat2;
drop _type_ _freq_;
run;


x cd "C:\TEMP\displace\20190703";
ods tagsets.tablesonlylatex file="stat.tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=stat0; run; quit;
ods tagsets.tablesonlylatex close;
