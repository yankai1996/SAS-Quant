
libname twoDsprd "C:\TEMP\sprd\REG2DSE";
libname rd_cty "C:\TEMP\sprd\RD-country";
libname sprd "C:\TEMP\sprd";
libname db "V:\data_for_kai";
libname nnnDS "V:\data_for_kai\WSDS20190215";


dm 'log;clear;';
%let pwd = "C:\TEMP\displace\20190311\pvgosprd25";
x md &pwd;
x cd &pwd;
libname pwd &pwd;


data pvgosprd; set twoDsprd.pvgosprd; run;

data pvgosprd; set pvgosprd25; 
*if country~="US";
if country in ("AU", "BD", "CH", "CN", "FN", "FR", "GR", "HK", "IN", "IS", 
"IT", "JP", "KO", "MY","SD", "SG", "SW", "TA", "TK", "UK", "US");
run;
/*
data countrysprd; 
merge rd_cty.country:;
*merge rd_cty.country_ew_sprd(in=a) rd_cty.country_ew_slope(in=b) rd_cty.country_vw_sprd(in=c) rd_cty.country_vw_slope(in=d);
by country portyear;
*if a & b & c & d;
run;
*/



%macro twoDtest(lhsdata, lhs, rhs, output);

data &lhsdata; set rd_cty.&lhsdata;
mthyr=portyear;
portyear=floor(mthyr/100);
if mthyr-portyear*100<7 then portyear=portyear-1;
keep country mthyr portyear &lhs;
proc sort; by country portyear;
run;


data testdata; merge &lhsdata(in=a) pvgosprd(in=b);
by country portyear;
if a and b;
proc sort; by mthyr;
run;

proc sql;
create table testdata as
select country, mthyr, 1 as globe, &lhs-avg(&lhs) as &lhs, pvgo1-avg(pvgo1) as pvgo1,
	pvgo2-avg(pvgo2) as pvgo2, pvgo3-avg(pvgo3) as pvgo3, pe-avg(pe) as pe
from testdata
group by mthyr
;
quit;

proc sort data=testdata; by country mthyr; run;

%winsor(dsetin=testdata, dsetout=testdata2, byvar=mthyr, vars=&lhs &rhs, type=delete, pctl=5 95);

%REG2DSE(&lhs, &rhs, country, mthyr, 0, testdata2, &output);

/*
data pwd.&output; set &output; run;
ods tagsets.tablesonlylatex file="&output..tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=&output; run; quit;
ods tagsets.tablesonlylatex close;
*/
%mend twoDtest;


dm 'log;clear;';
%let pwd = "C:\TEMP\displace\20190311\truncate-mthyr";
x md &pwd;
x cd &pwd;
libname pwd &pwd;


%macro pvgo2test(lhsdata, lhs, output);

%twoDtest(&lhsdata, &lhs, pvgo2, output1);
%twoDtest(&lhsdata, &lhs, pe, output2);
%twoDtest(&lhsdata, &lhs, pvgo2 pe, output3);

data output; set output1 output2 output3; run;

ods tagsets.tablesonlylatex file="&output..tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=output; run; quit;
ods tagsets.tablesonlylatex close;

%mend pvgo2test;


%pvgo2test(country_ew_sprd, retsprd, ew_sprd);
%pvgo2test(country_vw_sprd, retsprd, vw_sprd);
%pvgo2test(country_ew_slope, slope, ew_slope);
%pvgo2test(country_vw_slope, slope, vw_slope);


%macro pvgotest(lhsdata, lhs, output);

%twoDtest(&lhsdata, &lhs, pvgo1, output1);
%twoDtest(&lhsdata, &lhs, pvgo2, output2);
%twoDtest(&lhsdata, &lhs, pvgo3, output3);

data output; set output1 output2 output3; run;

ods tagsets.tablesonlylatex file="&output..tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=output; run; quit;
ods tagsets.tablesonlylatex close;

%mend pvgotest;

%pvgotest(country_ew_sprd, retsprd, ew_sprd);
%pvgotest(country_vw_sprd, retsprd, vw_sprd);
%pvgotest(country_ew_slope, slope, ew_slope);
%pvgotest(country_vw_slope, slope, vw_slope);




proc means data=testdata3;
run;


proc reg data=testdata;
model retsprd = pvgo2 / noint;
run;


%twoDtest(country_ew_sprd, retsprd, pvgo2, output1);


%winsor(dsetin=testdata, dsetout=testdata3, byvar=mthyr, vars=retsprd pvgo1 pvgo2 pvgo3, type=delete, pctl=2.5 97.5);
proc means data=testdata3;
run;

