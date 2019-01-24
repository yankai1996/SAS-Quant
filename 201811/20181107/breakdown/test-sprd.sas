
options noxwait;

* %include 'winsor.sas';



libname disp "C:\TEMP\displace";

option notes;

/* options nonotes nosource nosource2 errors=0;*/

%let temps=20141030;
%let rhs=rdbe11;
%let nobs=50;
%let input=disp.agret0;
%let n1=50;
%let n=1000;
%let n2=10000000;
%let Ngrp1=5;
%let Ngrp2=3;
%let rankvar1=rhs;
%let rankvar2=mv_us;
%let ret=ret_us;
%let weighting1=equal;
*%let weighting1=weighting1;
%let neutral=world;
%let agg=world;
%let timevar=portyear;
%let output=summary521;
%let sort=country;
%let ngroup=10;


/* data agret0; set disp.agret0; run;

/*------------------------------------------------------------------------------- */
/* -------------------  One Way Sorting --------------------------------------------
/* rank firms into tercile/quintile/deciles based on rhs;
/* compute rhsspread, retspread, and stdspread

input: can be either local currency or USD data
n1: size of a cross section
n2: size of a cross section
	if the number of firms is between 30 and 50, form terciles
	if the number of firms is between 50 and 100, form quintiles
	if the number of firms is between 100 and 10000, form deciles
ret: return can be either local currency or USD
sort: indicates it is neutral by what, country? region? or world?
weighting1:	for Spread calculations, either equal or value
weighting2:	for Slope calculations, either equal or relative market value to the cross section
ngroup: generally each group will have at least 10 firms
-------------------------------------------------------------------------------- */

%macro sprd(input, n1, n2, ret, sort, weighting1, ngroup);
data sub; set &input;
n=1000;
weighting1=1;
if &n1<=n<&n2;

proc sort; by &sort portyear;
proc rank data=sub group=&ngroup out=rank;
var rhs; by &sort portyear; ranks r;

proc datasets library=work;
delete sub;

data rank; set rank; r=r+1;
run;
proc sort; by portyear &sort r;

proc means data=rank noprint; by portyear &sort r;
var rhs &ret; weight &weighting1;
output out=rhs1 mean=rhs ret;
run;

proc datasets library=work;
delete rank;

data bot; set rhs1; if r in (1); bot1=rhs; bot2=ret; keep &sort portyear bot1 bot2; proc sort; by &sort portyear;
data top; set rhs1; if r in (&ngroup); top1=rhs; top2=ret; keep &sort portyear top1 top2; proc sort; by &sort portyear;
run;

data sprd&ngroup; merge bot top;
by &sort portyear;
rhssprd = top1-bot1;
retsprd = top2-bot2;
stdsprd = retsprd/rhssprd;
keep &sort portyear rhssprd retsprd stdsprd;


run;
%mend;

%sprd(&input, &n1, &n2, &ret, &sort, &weighting1, &ngroup);
