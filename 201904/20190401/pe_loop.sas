
%let pwd="C:\TEMP\displace\20190328\4k-obs\nochange";
*%let pwd="C:\TEMP\displace\20190328";
x cd &pwd;
libname pwd &pwd;
libname sprd "C:\TEMP\displace\201903\20190328\4k-obs\nochange";

data ag21; set sprd.ag21; run;


/*********** MACRO pvogsprd ************/
%macro pvgosprd(input, output, pvgo, low);

proc sort data=&input; by country portyear;
proc univariate data=&input noprint;
by country portyear;
var &pvgo PE;
output out=&output pctlpre=&pvgo pe pctlpts=0 to 100 by &low;
run;

%let high = %eval(100-&low);

data &output; set &output;
if country in ("AU", "BD", "CH", "CN", "FN", "FR", "GR", "HK", "IN", "IS", 
"IT", "JP", "KO", "MY","SD", "SG", "SW", "TA", "TK", "UK", "US");
&pvgo=&pvgo&high-&pvgo&low;
pe=pe&high-pe&low;
keep country portyear &pvgo pe;
run;

%mend pvgosprd;


/*********** MACRO twoDtest ************/
%macro twoDtest(lhsdata, lhs, rhs, wstype, wsby, output);

data testdata; set sprd.country_&lhsdata;
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
pe=pe/100;
proc sort; by mthyr;
run;

%winsor(dsetin=testdata, dsetout=testdata2, byvar=&wsby, vars=&lhs &rhs, type=&wstype, pctl=1 99);

proc sql;
create table testdata3 as
select country, mthyr, globe, &lhs-avg(&lhs) as &lhs, &rhs-avg(&rhs) as &rhs 
from testdata2
group by mthyr
;
quit;

%MYREG2DSE(&lhs, &rhs, country, mthyr, 0, testdata3, &output);

data &output; set &output;
lhs="&lhsdata";
run;

%mend twoDtest;
/*
%pvgosprd(ag21, pvgosprd, pvgo2, 25);
%twoDtest(ew_sprd, retsprd, pe, winsor, globe, out3);
*/

/*********** MACRO petest ************/
%macro petest(range, wstype, wsby, id);

*%pvgosprd(ag21, pvgosprd, pvgo2, &range);

%twoDtest(ew_sprd, retsprd, pe, &wstype, &wsby, out1);
%twoDtest(vw_sprd, retsprd, pe, &wstype, &wsby, out2);
%twoDtest(ew_slope, slope, pe, &wstype, &wsby, out3);
%twoDtest(vw_slope, slope, pe, &wstype, &wsby, out4);

data output&id; set out1 out2 out3 out4;
id=&id;
range=&range;
type="&wstype";
by="&wsby";
run;

%mend petest;


%macro pe_loop();

/****************************
i: pvgo sprd range 90-10, 80-20, or 75-25
j: pvgo1, pvgo2, pvgo3
k: lhs winsor or truncate
l: winsor by portyear, country, or globe
****************************/

%do i = 3 %to 3;
	%if &i=1 %then %do; %let range=10; %end;
	%else %if &i=2 %then %do; %let range=20; %end;
	%else %do; %let range=25; %end;
	%do j = 1 %to 2;
		%if &j=1 %then %do; %let wstype=winsor; %end; 
		%else %do; %let wstype=delete; %end;
		%do k = 1 %to 3;
			%if &k=1 %then %do; %let wsby=portyear; %end;
			%else %if &k=2 %then %do; %let wsby=country; %end;
			%else %do; %let wsby=globe; %end;
			%let id=%eval(100*&i + 10*&j + &k);
			%petest(&range, &wstype, &wsby, &id);
		%end;
	%end;
%end;

data final;
retain id range type by lhs; set output:;
proc sort; by id lhs;
run;
/*
data pwd.final; set final;
run;
*/
%mend pe_loop;

dm 'log;clear;';
%pe_loop();

/*

data pwd.final; set final;
run;


data junk; set pwd.final;
if tstat>1.7;
proc sort; by lhs;
proc means; by lhs;
run;

*/

libname dir "C:\TEMP\displace\20190329";
x cd "C:\TEMP\displace\20190401";

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

data test; set dir.&obs._&type._&by;
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
	%end;
	%let type=x;
	%let by=x;
	%let out=stat&i.00;
	%summarize2(&obs, &type, &by, &out);
%end;

data outstat; set stat:;
proc sort; by obs type by;
run;

%mend count;

%count();



ods tagsets.tablesonlylatex file="outstat.tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=outstat; run; quit;
ods tagsets.tablesonlylatex close;

