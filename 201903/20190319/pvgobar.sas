
libname db "V:\data_for_kai";
libname rd_cty "C:\TEMP\sprd\RD-country2";


proc import out=ctychar
	datafile="V:\data_for_kai\ctychar_20160518.xlsx"
	dbms=excel replace;
run;


data pvgosprdAB; set ctychar;
if country in ("AU", "BD", "CH", "CN", "FN", "FR", "GR", "HK", "IN", "IS", 
"IT", "JP", "KO", "MY","SD", "SG", "SW", "TA", "TK", "UK", "US");
pvgo=pvgobar2;
pe=pebar;
keep country portyear pvgo pe;
run;


data pvgosprdCD; set pvgosprdABCD;
if portyear>2011;
run;
data pvgosprd; set pvgosprdAB pvgosprdCD;
proc sort; by country portyear;
run;


%macro twoDtest(lhsdata, lhs, rhs, output);

data testdata; set rd_cty.&lhsdata;
mthyr=portyear;
portyear=floor(mthyr/100);
if mthyr-portyear*100<7 then portyear=portyear-1;
keep country mthyr portyear &lhs;
proc sort; by country portyear;
run;

data testdata; merge testdata(in=a) pvgosprd(in=b);
by country portyear;
if a and b;
globe=1;
proc sort; by mthyr;
run;

%winsor(dsetin=testdata, dsetout=testdata2, byvar=globe, vars=&rhs, type=delete, pctl=20 80);

%winsor(dsetin=testdata2, dsetout=testdata2, byvar=globe, vars=&lhs, type=delete, pctl=1 99);


proc sql;
create table testdata3 as
select country, mthyr, globe, &lhs-avg(&lhs) as &lhs, &rhs-avg(&rhs) as &rhs 
from testdata2
group by mthyr
;
quit;
/*
data testdata3; set testdata3; 
if -1<&rhs<1; 
*if -0.5<&lhs<0.5;
run;*/

%REG2DSE(&lhs, &rhs, country, mthyr, 0, testdata3, &output);

/*
proc reg data=testdata3;
model &lhs = &rhs / noint;
ods output parameterestimates=&output;
quit;

/*
data pwd.&output; set &output; run;
ods tagsets.tablesonlylatex file="&output..tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=&output; run; quit;
ods tagsets.tablesonlylatex close;
*/
%mend twoDtest;


%twoDtest(country_ew_sprd, retsprd, pvgo, output1);
%twoDtest(country_vw_sprd, retsprd, pvgo, output2);
%twoDtest(country_ew_slope, slope, pvgo, output3);
%twoDtest(country_vw_slope, slope, pvgo, output4);

%let output=outputNnnDS20;

data &output; set output1 output2 output3 output4;
proc print; 
run;



proc reg data=testdata3;
model retsprd = pvgo / noint;
ods output parameterestimates=output0;
quit;



dm 'log;clear;';
%let pwd = "C:\TEMP\displace\20190318";
x md &pwd;
x cd &pwd;
libname pwd &pwd;


%macro lhssum(filename, var);

data junk; set rd_cty.&filename;
if country in ("AU", "BD", "CH", "CN", "FN", "FR", "GR", "HK", "IN", "IS", 
"IT", "JP", "KO", "MY","SD", "SG", "SW", "TA", "TK", "UK", "US");
run;

proc means data=junk; 
var portyear &var;
output out=&filename._sum;
run;

data pwd.&filename._sum; set &filename._sum; run;

%mend lhssum;

%lhssum(country_ew_sprd, retsprd);
%lhssum(country_vw_sprd, retsprd);
%lhssum(country_ew_slope, slope);
%lhssum(country_vw_slope, slope);
