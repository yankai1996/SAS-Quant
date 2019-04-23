
libname daily "T:\SASData3";

data rhsdata; merge daily.irisk_country daily.dvol daily.short;
by country portyear;
dvol=dvol/MC_sum;
drop MC_sum;
run;


/*********** MACRO twoDtest ************/
%macro twoDtest(lhsdata, lhs, rhs, wstype, wsby, output);

data lhsdata; set sprd.country_&lhsdata;
mthyr=portyear;
*if mthyr<201707;
portyear=floor(mthyr/100);
if mthyr-portyear*100<7 then portyear=portyear-1;
keep country mthyr portyear &lhs;
proc sort; by country portyear;
run;

data testdata; merge lhsdata(in=a) rhsdata(in=b);
by country portyear;
if a & b;
globe=1;
proc sort; by mthyr;
run;

*%winsor(dsetin=testdata, dsetout=testdata2, byvar=&wsby, vars=&lhs &rhs, type=&wstype, pctl=1 99);

%MYREG2DSE(&lhs, &rhs, country, mthyr, 0, testdata, &output);

data &output; set &output;
lhs="&lhsdata";
run;

%mend twoDtest;


/*********** MACRO rhstest ************/
%macro rhstest(rhs, wstype, wsby, ijk);

%twoDtest(ew_sprd, retsprd, &rhs, &wstype, &wsby, tout1);
%twoDtest(vw_sprd, retsprd, &rhs, &wstype, &wsby, tout2);
%twoDtest(ew_slope, slope, &rhs, &wstype, &wsby, tout3);
%twoDtest(vw_slope, slope, &rhs, &wstype, &wsby, tout4);

data output&ijk; set tout:;
id=&ijk;
type="&wstype";
by="&wsby";
run;

%mend rhstest;


/*********** MACRO batchtest ************/
%macro batchtest(wstype, wsby, ij);

%rhstest(short, &wstype, &wsby, &ij.1);
%rhstest(irisk, &wstype, &wsby, &ij.2);
%rhstest(dvol, &wstype, &wsby, &ij.3);
%rhstest(short irisk dvol, &wstype, &wsby, &ij.4);

dm 'log;clear;';

%mend batchtest;


%macro all_loop(finalname);

/****************************
j: lhs winsor or truncate
k: winsor by portyear, country, or globe
****************************/

%do i = 1 %to 2;
	%if &i=1 %then %let wstype=winsor; 
	%else %let wstype=delete;
	%do j = 1 %to 3;
		%if &j=1 %then %let wsby=portyear;
		%else %if &j=2 %then %let wsby=country;
		%else %let wsby=globe;
		%batchtest(&wstype, &wsby, &i&j);
	%end;
%end;

data final;
retain id range type by lhs; set output:;
proc sort; by id lhs;
run;

data pwd.&finalname; set final;
run;

%mend all_loop;


%macro allcases();

%let root=C:\TEMP\displace\20190409;
libname pwd "C:\TEMP\displace\20190417";

%do dirindex=7 %to 10;
	%if &dirindex=1 %then %do;
		libname sprd "&root\4k-obs\nochange";
		%let finalname=k4_x_x;
	%end; %else %if &dirindex=2 %then %do;
		libname sprd "&root\4k-obs\truncate1-country-portyear";
		%let finalname=k4_truncate_country_portyear;
	%end; %else %if &dirindex=3 %then %do;
		libname sprd "&root\4k-obs\truncate1-portyear";
		%let finalname=k4_truncate_portyear;
	%end; %else %if &dirindex=4 %then %do;
		libname sprd "&root\4k-obs\winsor1-country-portyear";
		%let finalname=k4_winsor_country_portyear;
	%end; %else %if &dirindex=5 %then %do;
		libname sprd "&root\4k-obs\winsor1-portyear";
		%let finalname=k4_winsor_portyear;
	/*%end; %else %if &dirindex=6 %then %do;
		libname sprd "&root\5k-obs\nochange";
		%let finalname=k5_x_x;*/
	%end; %else %if &dirindex=7 %then %do;
		libname sprd "&root\5k-obs\truncate1-country-portyear";
		%let finalname=k5_truncate_country_portyear;
	%end; %else %if &dirindex=8 %then %do;
		libname sprd "&root\5k-obs\truncate1-portyear";
		%let finalname=k5_truncate_portyear;
	%end; %else %if &dirindex=9 %then %do;
		libname sprd "&root\5k-obs\winsor1-country-portyear";
		%let finalname=k5_winsor_country_portyear;
	%end; %else %do;
		libname sprd "&root\5k-obs\winsor1-portyear";
		%let finalname=k5_winsor_portyear;
	%end;  

	%all_loop(&finalname);
	
%end;

%mend allcases;

%allcases();


/*

data pwd.final; set final;
run;


data junk; set pwd.final;
if tstat>1.7;
proc sort; by lhs;
proc means; by lhs;
run;

*/


%macro summarize(obs, type, by, out);

data test; set dir.&obs._&type._&by;
if Estimates>0;
proc means noprint; by range;
var Estimates;
output out=&out n=n;
proc transpose out=&out; var n; id range;
run;
data &out; retain obs type by;
drop _NAME_;
set &out;
obs="4k";
if "&obs"="k5" then obs="5k";
type=put("&type", $11.);
by=put("&by", $16.);
run;

%mend summarize;


%macro summarize2(obs, type, by, out);

data test; set pwd.&obs._&type._&by;
if tstat>1.7;
proc sort; by lhs;
proc means noprint; by range;
var Estimates;
by lhs;
output out=&out n=n;
run;
proc transpose out=&out; var n; id lhs;
run;
data &out; retain obs type by;
drop _NAME_;
set &out;
obs="4k";
if "&obs"="k5" then obs="5k";
type=put("&type", $11.);
by=put("&by", $16.);
run;

%mend summarize2;


%macro count();

libname pwd "C:\TEMP\displace\20190412";

%do i=1 %to 2;
	%if &i=1 %then %let obs=k4;
	%else %let obs=k5;
	%do j=1 %to 2;
		%if &j=1 %then %let type=winsor;
		%else %let type=truncate;
		%do k=1 %to 2;
			%if &k=1 %then %let by=country_portyear;
			%else %let by=portyear;
			%let out=stat&i&j&k;
			%summarize2(&obs, &type, &by, &out);
		%end;
	%end;/*
	%let type=x;
	%let by=x;
	%let out=stat&i.00;
	%summarize2(&obs, &type, &by, &out);*/
%end;

data outstat; set stat:;
proc sort; by obs type by;
run;

data pwd.outstat; set outstat; run;

%mend count;

%count();



%let dir="C:\TEMP\displace\20190402\PE-unlimited";
x cd &dir;
libname dir &dir;

ods tagsets.tablesonlylatex file="outstat.tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=dir.outstat; run; quit;
ods tagsets.tablesonlylatex close;




data pwd.best; set pwd.k4_winsor_portyear;
if id in (3222, 3224, 3226);
run;

x cd "C:\TEMP\displace\20190412";
ods tagsets.tablesonlylatex file="best.tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=pwd.best; run; quit;
ods tagsets.tablesonlylatex close;
