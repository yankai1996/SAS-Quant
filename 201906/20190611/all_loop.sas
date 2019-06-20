
libname bk "V:\data_for_kai\pvgo_pe_bk";

/*********** pvogsprd abd pesprd************/
*%macro pvgo_pe(high1, low1, high2, low2, high3, low3, high4, low4);
%macro pvgo_pe(high1, low1, high2, low2);

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
pvgo2=coalesce(pvgo_old, pvgo_new);
*pvgo2=pvgo_new;
*pe=coalesce(pe_old, pe_new);
pe=pe_new;
if pe<=&low2 or pe>=&high2 then pe=.;
*if pe<5 or pe>40 then pe=.;
*if pe>45 then pe=.;
keep country portyear pvgo2 pe;
run;

%mend pvgo_pe;
*%pvgo_pe(75,25,40,5);

/*********** MACRO twoDtest ************/
%macro twoDtest(lhsdata, lhs, rhs, wstype, wsby, output);

data testdata; set &lhsdata;
mthyr=portyear;
*if mthyr<201707;
portyear=floor(mthyr/100);
if mthyr-portyear*100<7 then portyear=portyear-1;
keep country mthyr portyear &lhs;
proc sort; by country portyear;
run;

data testdata; merge testdata(in=a) pvgo_pe(in=b);
by country portyear;
if a and b;
globe=1;
*pe=pe/100;
*if -3<&lhs<3;
proc sort; by mthyr;
run;

%winsor(dsetin=testdata, dsetout=testdata2, byvar=&wsby, vars=&lhs &rhs, type=&wstype, pctl=1 99);

proc sql;
create table testdata3 as
select country, mthyr, globe, &lhs-avg(&lhs) as &lhs, 
	pvgo2-avg(pvgo2) as pvgo2, pe-avg(pe) as pe 
from testdata2
group by mthyr
;
quit;


%MYREG2DSE(&lhs, &rhs, country, mthyr, 0, testdata3, &output);

data &output; set &output;
lhs="&lhsdata";
run;

%mend twoDtest;


/*********** rhstest ew/vw_sprd/slope ************/
%macro rhstest(rhs, wstype, wsby, ijkl);

%twoDtest(ew_sprd, retsprd, &rhs, &wstype, &wsby, tout1);
%twoDtest(vw_sprd, retsprd, &rhs, &wstype, &wsby, tout2);
%twoDtest(ew_slope, slope, &rhs, &wstype, &wsby, tout3);
%twoDtest(vw_slope, slope, &rhs, &wstype, &wsby, tout4);

data output&ijkl; set tout:;
id=&ijkl;
type="&wstype";
by="&wsby";
run;

%mend rhstest;


/*********** test PVGO/PE sprd range ************/
%macro rangetest(high1, low1, high2, low2, i);

%pvgo_pe(&high1, &low1, &high2, &low2);

%do j = 1 %to 2;
	%if &j=1 %then %let wstype=winsor; 
	%else %let wstype=delete;
	%do k = 1 %to 3;
		%if &k=1 %then %let wsby=portyear;
		%else %if &k=2 %then %let wsby=country;
		%else %let wsby=globe;
		*%rhstest(pvgo2, &wstype, &wsby, &i&j&k.1);
		%rhstest(pe, &wstype, &wsby, &i&j&k.2);
		*%mthtest(pe, &wstype, &wsby, &i&j&k.2);
		*%rhstest(pvgo2 pe, &wstype, &wsby, &i&j&k.3);
	%end;
%end;
/*
dm 'log;clear;';*/

%mend rangetest;
*%rangetest(75, 25, 40, 5, 1);


%macro all_loop(finalname);

%do i = 1 %to 3;
	%if &i=1 %then %do; 
		%let high1=90;
		%let low1=10;
		%let high2=100;
		%let low2=5;
	%end; %else %if &i=2 %then %do;
		%let high1=80;
		%let low1=20;
		%let high2=70;
		%let low2=5;
	%end; %else %do; 
		%let high1=75;
		%let low1=25;
		%let high2=40;
		%let low2=5;
	%end;
	%rangetest(&high1, &low1, &high2, &low2, &i);
%end;

data final;
retain id range type by lhs; set output:;
proc sort; by id lhs;
run;

data pwd.&finalname; set final;
run;

%mend all_loop;


%macro lhstest();

libname pwd "C:\TEMP\displace\20190611";

%do index=1 %to 4;
	%if &index=1 %then %do;
		%let wsby=country portyear;
		%let wstype=delete;
		%let finalname=k4_truncate_country_portyear;
	%end; %else %if &index=2 %then %do;
		%let wsby=portyear;
		%let wstype=delete;
		%let finalname=k4_truncate_portyear;
	%end; %else %if &index=3 %then %do;
		%let wsby=country portyear;
		%let wstype=winsor;
		%let finalname=k4_winsor_country_portyear;
	%end; %else %do;
		%let wsby=portyear;
		%let wstype=winsor;
		%let finalname=k4_winsor_portyear;
	%end;

	%onewaytest(&wsby, &wstype);
	%all_loop(&finalname);

%end;

%mend lhstest;

%lhstest();

/*
data k4_truncate_country_portyear; set pwd.k4_truncate_country_portyear;
if id>3000;
run;

data k4_winsor_country_portyear; set pwd.k4_winsor_country_portyear;
if id>3000;
run;

data out; set tmp4.k4_truncate_country_portyear;
if id=3232;
run;

data out8; set pwd.k4_winsor_country_portyear;
if id>3230;
run;

%macro toTex(name);
x cd "C:\TEMP\displace\20190606";
ods tagsets.tablesonlylatex file="&name..tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=&name; run; quit;
ods tagsets.tablesonlylatex close;
%mend toTex;

%toTex(out);
%toTex(out8);
*/

proc univariate data=pvgo_pe;
 var pe;
run;
