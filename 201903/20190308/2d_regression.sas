
libname twoDsprd "C:\TEMP\sprd\REG2DSE";
libname rd_cty "C:\TEMP\sprd\RD-country";
libname sprd "C:\TEMP\sprd";
libname db "V:\data_for_kai";
libname nnnDS "V:\data_for_kai\WSDS20190215";


dm 'log;clear;';
%let pwd = "C:\TEMP\displace\20190308\REG2DSE";
x md &pwd;
x cd &pwd;
libname pwd &pwd;


data pvgosprd; set twoDsprd.pvgosprd; run;

data pvgosprd; set pvgosprd20; 
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

%winsor(dsetin=ag21, dsetout=ag22, byvar=country portyear, vars=pvgo1 pvgo2 pvgo3, type=delete, pctl=20 80);



%macro twoDtest(lhsdata, lhs, rhs, output);
/*
data gobar_country; set twoDsprd.gobar20; 
drop _type_ _freq_; 
run;
*/
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
select country, mthyr, &lhs-avg(&lhs) as &lhs, pvgo1-avg(pvgo1) as pvgo1,
	pvgo2-avg(pvgo2) as pvgo2, pvgo3-avg(pvgo3) as pvgo3, pe-avg(pe) as pe
from testdata
group by mthyr
;
quit;

proc sort data=testdata; by country mthyr; run;

%winsor(dsetin=testdata, dsetout=testdata2, byvar=mthyr, vars=&lhs &rhs, type=delete, pctl=2.5 97.5);

%REG2DSE(&lhs, &rhs, country, mthyr, 0, testdata2, &output);

/*
data pwd.&output; set &output; run;
ods tagsets.tablesonlylatex file="&output..tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=&output; run; quit;
ods tagsets.tablesonlylatex close;
*/
%mend twoDtest;


%twoDtest(country_ew_sprd, retsprd, pvgo2, output);
%twoDtest(country_vw_sprd, slope, pvgo2, output);
%twoDtest(country_ew_sprd, retsprd, pvgo3, output);
%twoDtest(country_ew_sprd, retsprd, pe, output);



proc means data=testdata;
run;


proc reg data=testdata;
model retsprd = pvgo2 / noint;
run;
