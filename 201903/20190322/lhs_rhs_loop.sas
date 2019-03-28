
libname rd_cty "C:\TEMP\sprd\RD-country2";
libname sprd "V:\data_for_kai\20190321";

data ag21; set sprd.ag21; run;
data country_ew_sprd; set sprd.country_ew_sprd; run;
data country_vw_sprd; set sprd.country_vw_sprd; run;
data country_ew_slope; set sprd.country_ew_slope; run;
data country_vw_slope; set sprd.country_vw_slope; run;


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

data testdata; set rd_cty.country_&lhsdata;
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

%REG2DSE(&lhs, &rhs, country, mthyr, 0, testdata3, &output);

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



%macro rhs_lhs_loop();

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

%mend rhs_lhs_loop;

dm 'log;clear;';
%rhs_lhs_loop();


%let pwd = "C:\TEMP\displace\20190322";
x md &pwd;
x cd &pwd;
libname pwd &pwd;

data pwd.final; set final;
run;



data junk; set final;
if parameter~="Intercept";
run;
proc univariate data=rd_cty.country_vw_slope; var slope; run;


data junk; merge rd_cty.country_ew_slope(rename=(slope=slope2)) rd_cty.country_vw_slope;
by country portyear;
run;

proc corr; var slope slope2; run;
