
*libname rd_cty "C:\TEMP\displace\20190326\4000";
libname sprd "V:\data_for_kai\20190321";

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

data testdata; set pwd.country_&lhsdata;
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


/*********** MACRO mytest ************/
%macro mytest(range, pvgo, wstype, wsby, id);

%pvgosprd(ag21, pvgosprd, &pvgo, &range);

%twoDtest(ew_sprd, retsprd, &pvgo, &wstype, &wsby, out1);
%twoDtest(vw_sprd, retsprd, &pvgo, &wstype, &wsby, out2);
%twoDtest(ew_slope, slope, &pvgo, &wstype, &wsby, out3);
%twoDtest(vw_slope, slope, &pvgo, &wstype, &wsby, out4);

data output&id; set out1 out2 out3 out4;
id=&id;
range=&range;
type="&wstype";
by="&wsby";
run;

%mend mytest;



%macro pvgo_loop();

/****************************
i: pvgo sprd range 90-10, 80-20, or 75-25
j: pvgo1, pvgo2, pvgo3
k: lhs winsor or truncate
l: winsor by portyear, country, or globe
****************************/

%do i = 1 %to 3;
	%if &i=1 %then %do; %let range=10; %end;
	%else %if &i=2 %then %do; %let range=20; %end;
	%else %do; %let range=25; %end;
	%do j = 1 %to 3;
		%let pvgo=pvgo&j;
		%do k = 1 %to 2;
			%if &k=1 %then %do; %let wstype=winsor; %end; 
			%else %do; %let wstype=delete; %end;
			%do l = 1 %to 3;
				%if &l=1 %then %do; %let wsby=portyear; %end;
				%else %if &l=2 %then %do; %let wsby=country; %end;
				%else %do; %let wsby=globe; %end;
				%let id=%eval(1000*&i + 100*&j + 10*&k + &l);
				%mytest(&range, &pvgo, &wstype, &wsby, &id);
			%end;
		%end;
	%end;
%end;

data final;
retain id range type by lhs; set output:;
proc sort; by id lhs;
run;

%mend pvgo_loop;

dm 'log;clear;';
%pvgo_loop();

/*

data pwd.final; set final;
run;


data junk; set pwd.final;
if tstat>1.7;
proc sort; by lhs;
proc means; by lhs;
run;

*/


%macro count();

%do i=1 %to 2;
	%if &i=1 %then %let obs=4k;
	%else %let obs=5k;
	%do j=1 %to 2;
		%if &j=1 %then %let type=winsor2.5;
		%else %let type=truncate2.5;
		%do k=1 %to 2;
			%if &k=1 %then %let by=country-portyear;
			%else %let by=portyear;
			%let out=stat&i&j&k;
			libname dir "C:\TEMP\displace\20190327\&obs-obs\&type-&by";
			data test; set dir.final;
			if tstat>1.7;
			proc sort; by lhs;
			proc means noprint; by lhs; var tstat;
			output out=&out n=n;
			proc transpose data=&out out=&out;
			var n; id lhs;
			run;
			data &out; retain obs type by;
			drop _NAME_;
			set &out;
			obs="&obs";
			type=put("&type", $11.);
			by="&by";
			run;
		%end;
	%end;
%end;

data outstat; set stat:;
proc sort; by obs type by;
run;

%mend count;

%count();



ods tagsets.tablesonlylatex file="outstat.tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=outstat; run; quit;
ods tagsets.tablesonlylatex close;
