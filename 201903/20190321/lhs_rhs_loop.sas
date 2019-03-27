
libname rd_cty "C:\TEMP\sprd\RD-country2";

/*********** MACRO pvogsprd ************/
%macro pvgosprd(input, output, pvgo, i);

proc sort data=&input; by country portyear;
proc univariate data=&input noprint;
by country portyear;
var &pvgo PE;
output out=&output pctlpre=&pvgo pe pctlpts=0 to 100 by &i;
run;

%let j = %eval(100-&i);

data &output; set &output;
if country in ("AU", "BD", "CH", "CN", "FN", "FR", "GR", "HK", "IN", "IS", 
"IT", "JP", "KO", "MY","SD", "SG", "SW", "TA", "TK", "UK", "US");
&pvgo=&pvgo&j-&pvgo&i;
pe=pe&j-pe&i;
keep country portyear &pvgo pe;
run;

%mend pvgosprd;


/*********** MACRO twoDtest ************/
%macro twoDtest(lhsdata, lhs, rhs, output);

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

%winsor(dsetin=testdata, dsetout=testdata2, byvar=globe, vars=&rhs, type=delete, pctl=20 80);
%winsor(dsetin=testdata2, dsetout=testdata2, byvar=globe, vars=&lhs, type=delete, pctl=1 99);

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
%macro mytest(range, pvgo, id);

%pvgosprd(ag21, pvgosprd, &pvgo, &range);

%twoDtest(ew_sprd, retsprd, &pvgo, out1);
%twoDtest(vw_sprd, retsprd, &pvgo, out2);
%twoDtest(ew_slope, slope, &pvgo, out3);
%twoDtest(vw_slope, slope, &pvgo, out4);

data output&id; set out1 out2 out3 out4;
id=&id;
range=&range;
run;

%mend mytest;



%macro rhs_lhs_loop();

/****************************
i: lhs sprd range 90-10, 80-20, or 75-25
j:  pvgo1, pvgo2, pvgo3
****************************/

%do i = 1 %to 3;
	%if &i=1 %then %do; %let range=10; %end;
	%else %if &i=2 %then %do; %let range=20; %end;
	%else %do; %let range=25; %end;
	%do j = 1 %to 3;
		%let pvgo=pvgo&j;
		%let id=%eval(10*&i + &j);
		%mytest(&range, &pvgo, &id);
		/*test*/
		/*
		data output&id; 
		id=&id; range=&range;pvgo="&pvgo";
		run;
		*/
	%end;
%end;

data final;
retain id lhs range; set output:;
proc sort; by id lhs;
run;

%mend rhs_lhs_loop;

/*dm 'log;clear;';*/
%rhs_lhs_loop();
