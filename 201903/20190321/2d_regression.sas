
libname twoDsprd "C:\TEMP\sprd\REG2DSE";
libname rd_cty "C:\TEMP\sprd\RD-country2";
libname sprd "C:\TEMP\sprd";
libname db "V:\data_for_kai";
libname nnnDS "V:\data_for_kai\WSDS20190215";


dm 'log;clear;';
%let pwd = "C:\TEMP\displace\20190318";
x md &pwd;
x cd &pwd;
libname pwd &pwd;

/*data pvgosprd; set twoDsprd.pvgosprd; run;*/


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

*%REG2DSE(&lhs, &rhs, country, mthyr, 0, testdata3, &output);

/*data testdata3; set testdata3; if -0.5<pvgo<0.5; run;*/

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

data pwd.&output; set &output; run;
ods tagsets.tablesonlylatex file="&output..tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=&output; run; quit;
ods tagsets.tablesonlylatex close;



proc means data=testdata3; run;

data junk3; set testdata3;
if -0.5<pvgo<0.5;
run;

proc reg data=junk3;
model retsprd = pvgo / noint;
ods output parameterestimates=output2;
quit;



data junk; set testdata;
if pvgo>5;
run;


proc univariate data=testdata3; var pvgo; run;
