
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

%winsor(dsetin=testdata, dsetout=testdata2, byvar=portyear, vars=&lhs, type=delete, pctl=8 92);
data testdata2; set testdata2;
keep mthyr country &lhs;
proc sort; by mthyr country;
run;
%winsor(dsetin=testdata, dsetout=testdata3, byvar=portyear, vars=pvgo2, type=delete, pctl=5 95);
data testdata3; set testdata3;
keep mthyr country pvgo2;
proc sort; by mthyr country;
run;
proc sort data=testdata; by country; run;
%winsor(dsetin=testdata, dsetout=testdata4, byvar=country, vars=pe, type=delete, pctl=8 92);
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

data myreg1; set myreg1; id=1; run;
data myreg2; set myreg2; id=2; run;
data myreg3; set myreg3; id=3; run;

data &output; set myreg:;
lhs="&lhsdata";
run;

%mend twoDtest;


/*
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
x cd "C:\TEMP\displace\20190621";
ods tagsets.tablesonlylatex file="stat3.tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=pwd.stat3; run; quit;
ods tagsets.tablesonlylatex close;
ods tagsets.tablesonlylatex file="stat4.tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=pwd.stat4; run; quit;
ods tagsets.tablesonlylatex close;
*/

/*
proc means data=testdata5; 
var slope pvgo2 pe;
run;
*/


data junk; set pwd.final3;
proc sort; by lhs id;
run;
