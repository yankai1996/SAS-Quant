
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
if &n1<=n<&n2;

proc sort; by &sort portyear;
proc rank data=sub group=&ngroup out=rank;
var rhs; by &sort portyear; ranks r;

data rank; set rank; r=r+1;
run;
proc sort; by portyear &sort r;

proc means data=rank noprint; by portyear &sort r;
var rhs &ret; weight &weighting1;
output out=rhs1 mean=rhs ret;
run;

data bot; set rhs1; if r in (1); bot1=rhs; bot2=ret; keep &sort portyear bot1 bot2; proc sort; by &sort portyear;
data top; set rhs1; if r in (&ngroup); top1=rhs; top2=ret; keep &sort portyear top1 top2; proc sort; by &sort portyear;

data sprd&ngroup; merge bot top;
by &sort portyear;
rhssprd = top1-bot1;
retsprd = top2-bot2;
stdsprd = retsprd/rhssprd;
keep &sort portyear rhssprd retsprd stdsprd;
run;
%mend;

/*------------------------------------------------------------------------------- */
/* Country summary stats; need to adjust the standard erros (neweywest)
therefore have to do a GMM (SAS sucks), but nests the regular summary stats
use only 1 lrhs in kernel=(bart, %eval(lrhss+1), 0);

output: should be some times series of zero cost strategy
sort: indicates it is neutral by what, country? region? or world?
outstat: output the statistics
/*------------------------------------------------------------------------------- */

%macro NWavg(output, sort, lags, outstat);
proc model data=&output;
by &sort;
parms rhssprdbar retsprdbar slopebar; exogenous rhssprd retsprd slope;
instruments / intonly;
rhssprd = rhssprdbar;
retsprd = retsprdbar;
stdsprd = stdsprdbar;
slope = slopebar;
/* fit rhssprd retsprd stdsprd slope / gmm kernel=(bart, %eval(2), 0); */
fit retsprd slope / gmm kernel=(bart, %eval(1+&lags), 0);
ods output parameterestimates=param0;
quit;

data &outstat; set param0;
if probt<0.1 then p='*  ';
if probt<0.05 then p='** ';
if probt<0.01 then p='***';
tvalue=put(tvalue,7.3);
est=put(estimate, 12.3);
prob=put(probt,7.3);
stder=put(stderr, 7.3);
T=compress('('||tvalue||')');
drop EstType est StdErr probt DF T _type_;  /*may keep these information */
run;

proc sort data=&outstat;
by parameter;
run;
%mend;

/*------------------------------------------------------------------------------- */
/* Calculate the rhs effects	taking the above two already defined

input: can be either local currency or USD data
ret: return can be either local currency or USD
sort: indicates it is neutral by what, country? region? or world?
weighting1:	for Spread calculations, either equal or value
weighting2:	for Slope calculations, either equal or relative market value to the cross section
output: should be some times series of zero cost strategy
outstat: output the statistics
/*------------------------------------------------------------------------------- */

%macro rhseffect(input, ret, sort, weighting1, weighting2, output, lags, outstat);

/*%sprd(&input, 10, 50, &ret, &sort, &weighting1, 3);
%sprd(&input, 50, 100000, &ret, &sort, &weighting1, 5);
data sprd; set sprd3 sprd5;
/*
%sprd(&input, 10, 100000, &ret, &sort, &weighting1, 1);
data sprd; set sprd1;
*/

/*%sprd(&input, 1, 30, &ret, &sort, &weighting1, 3);
%sprd(&input, 30, 100000, &ret, &sort, &weighting1, 5);

%sprd(&input, 4, 49, &ret, &sort, &weighting1, 3);
*/
%sprd(&input, 50, 100000, &ret, &sort, &weighting1, 5);
*%sprd(&input, 51, 100000, &ret, &sort, &weighting1, 10);
/*data sprd; set sprd3 sprd5;
/*data sprd; set sprd10; */
data sprd; set sprd5;


proc sort; by &sort portyear;
run;

/* rhs predictive regression slope */


%winsor(dsetin=sub, dsetout=sub, byvar=&sort portyear, vars=rhs, type=winsor, pctl=1 99);

proc sort data=sub; by &sort portyear;
run;
proc reg data=sub noprint outest=coef edf;
model &ret=rhs;
by &sort portyear;
weight &weighting2;
run;
data coef; set coef;
slope=rhs;
keep &sort portyear slope;
run;

/* all measures of rhs effect
/* combines the sort based and slope
/* now the portfolio year is from t to t+12
/* in reality is from t+6 to t+18 */

data &output; merge sprd coef;
by &sort portyear;
/* if (slope ne . and retsprd ne . and rhssprd ne .); */
expostyear = portyear + 1;
proc sort; by &sort;
run;

/* Country summary stats */
%NWavg(&output, &sort, &lags, &outstat);
%mend;
