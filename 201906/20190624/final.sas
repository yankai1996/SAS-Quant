
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
keep country portyear pvgo2 pe;
run;

%mend pvgo_pe;



/*********** MACRO twoDtest ************/
%macro twoDtest(lhsdata, lhs, output);

data testdata; set &lhsdata;
mthyr=portyear;
portyear=floor(mthyr/100);
if mthyr-portyear*100<7 then portyear=portyear-1;
keep country mthyr portyear &lhs;
proc sort; by country portyear;
run;

data testdata; merge testdata(in=a) pvgo_pe(in=b);
by country portyear;
if a and b;
*if 1989<=portyear;
globe=1;
&lhs=&lhs*100;
proc sort; by mthyr;
run;

%winsor(dsetin=testdata, dsetout=testdata2, byvar=portyear, vars=&lhs, type=delete, pctl=10 90);
data testdata2; set testdata2;
keep mthyr portyear country &lhs;
proc sort; by mthyr country;
run;
%winsor(dsetin=testdata, dsetout=testdata3, byvar=portyear, vars=pvgo2, type=winsor, pctl=5 95);
data testdata3; set testdata3;
keep mthyr country pvgo2;
proc sort; by mthyr country;
run;
proc sort data=testdata; by country; run;
%winsor(dsetin=testdata, dsetout=testdata4, byvar=country, vars=pe, type=winsor, pctl=10 90);
data testdata4; set testdata4;
keep mthyr country pe;
proc sort; by mthyr country;
run;

data testdata5; merge testdata2(in=a) testdata3 testdata4;
by mthyr country;
if a;
globe=1;
run;

proc means data=testdata5 noprint;
var &lhs pvgo2 pe;
output out=stat&output;
run;
proc transpose data=stat&output out=stat&output;
var &lhs pvgo2 pe;
id _stat_;
run;
data stat&output; set stat&output;
lhs="&lhsdata";
run;

proc sql;
create table testdata6 as
select country, mthyr, globe, &lhs-avg(&lhs) as &lhs, 
	pvgo2-avg(pvgo2) as pvgo2, pe-avg(pe) as pe 
from testdata5
group by mthyr
;
quit;


%MYREG2DSE(&lhs, pvgo2, country, mthyr, 0, testdata6, myreg1);
%MYREG2DSE(&lhs, pe, country, mthyr, 0, testdata6, myreg2);
%MYREG2DSE(&lhs, pvgo2 pe, country, mthyr, 0, testdata6, myreg3);


data testdata5; set testdata5;
%do year=1981 %to 2018;
year&year=0;
if portyear=&year then year&year=1;
%end;
run;

proc reg data=testdata5 noprint rsquare outest=rsquare;
model &lhs=pvgo2 year:;
model &lhs=pe year:;
model &lhs=pvgo2 pe year:;
quit;

data rsquare; set rsquare;
if _model_="MODEL1" then id=1;
if _model_="MODEL2" then id=2;
if _model_="MODEL3" then id=3;
keep id _RSQ_;
run;


data myreg1; set myreg1; id=1; run;
data myreg2; set myreg2; id=2; run;
data myreg3; set myreg3; id=3; run;

data &output; set myreg:;
lhs="&lhsdata";
if parameter="R-Square" then delete;
run;
data &output; merge &output rsquare;
by id;
run;

%mend twoDtest;


/*
libname pwd "C:\TEMP\displace\20190624";
%onewaytest(country portyear, winsor);
%pvgo_pe(75, 25);
*/
%twoDtest(ew_sprd, retsprd, output1);
%twoDtest(vw_sprd, retsprd, output2);
%twoDtest(ew_slope, slope, output3);
%twoDtest(vw_slope, slope, output4);


data pwd.final4;
retain id lhs; set output:;
proc sort; by id lhs;
run;

data pwd.stat4; 
retain lhs; set statoutput:;
run;

/*
x cd "C:\TEMP\displace\20190624";
ods tagsets.tablesonlylatex file="finalR.tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=pwd.final4; run; quit;
ods tagsets.tablesonlylatex close;
ods tagsets.tablesonlylatex file="stat.tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=pwd.stat4; run; quit;
ods tagsets.tablesonlylatex close;
*/

/*
proc means data=testdata5; 
var slope pvgo2 pe;
run;

%macro yearly();

data junk; set testdata5;
%do year=1981 %to 2018;
year&year=0;
if portyear=&year then year&year=1;
%end;
run;

%mend;

%yearly();

proc reg data=junk noprint rsquare outest=est;
model slope=pvgo2 year:;
quit;
/*
