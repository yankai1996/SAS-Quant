
options noxwait;

%include 'winsor.sas';



libname disp "C:\TEMP\displace";

option notes;

/* options nonotes nosource nosource2 errors=0;*/

%let temps=20141030;
%let rhs=rdc3;
%let nobs=50;
%let input=agret0;
%let n1=50;
%let n=1000;
%let n2=10000000;
%let Ngrp1=5;
%let Ngrp2=3;
%let rankvar1=rhs;
%let rankvar2=mv_us;
%let ret=ret_us;
%let weighting1=equal;
%let neutral=world;
%let agg=world;
%let timevar=portyear;
%let output=summary521;
%let sort=country;
%let ngroup=10;

/*
data agret0; set disp.agret0;
drop lagret: pat: cite:;
run;
data mvmois; set disp.mvmois;
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
%sprd(&input, 50, 100000, &ret, &sort, &weighting1, 5);
*/
%sprd(&input, 4, 50, &ret, &sort, &weighting1, 3);
%sprd(&input, 51, 100000, &ret, &sort, &weighting1, 5);
data sprd; set sprd3 sprd5;
  /*  data sprd; set sprd5; */

proc sort; by &sort portyear;
run;

/* rhs predictive regression slope */

proc sort data=&input; by &sort portyear;
run;
proc reg data=&input noprint outest=coef edf;
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

/*------------------------------------------------------------------------------- */
/* combine AG and ret; filters may be imposed
/* for example, throw out AG bigger than 10 or smaller than -10
/*------------------------------------------------------------------------------- */
%macro makerhs(rhs, lb, ub, nobs);
data agret00; set agret0;
/* data agret0; merge ipp.retmonthly2(in=a) ag(in=b) prmonthly ipp.juneret(in=d) ipp.momentum; 
by code portyear; */
rhs = rdc3;
/*if a and b;
*/

if country='US' then ret_us=ret;
/* if rhs ne .;
if ret_us ne .;

*/
if p_us_updated>=p_us_10;
if ret>-1 and ret<10;
if ret_us>-1 and ret_us<10;

/* if rhs>=&lb and rhs=<&ub;  /* remove RHS > 10 and < -10; dont do this on SIZE and BM */
/* keep ret ret_us mthyr code country ctyid portyear ta rhs rdme rdme2 rdme3 rda rdbe cm mc sl ag rd rdc ia slaga ia2 roe roa dte maba tobinq capex lev cfa mpk pvgo1 pvgo2 pvgo3 pvgo4 pvgo5 calret1y calret1y_us opm myroa myroe sg sa empg momen sigma sigma_us ret1y ret1y_us ret2y ret2y_us ret3y ret3y_us ret1m ret1m_us ret1to2y ret1to2y_us ret2to3y ret2to3y_us momenret; */



keep ret ret_us mthyr code country portyear ta rhs cm mc sl rd rdc3 roe roa momenret_mth;
run;
proc sort; by code mthyr;
run;

/*
proc sort data=agret0; by mthyr;
proc univariate data=agret0 noprint;
by mthyr;
var ret ret_us rhs rdme rdme2 rdme3 rdbe rda;
output out=ext p1=p1 p1us p1rhs p1rdme p1rdme2 p1rdme3 p1rdbe p1rda p99=p99 p99us p99rhs p99rdme p99rdme2 p99rdme3 p99rdbe p99rda;
run;


data agret1; merge agret0 ext; by mthyr;
/*if country ~="US" then do;
	if ret1y<=p1 then ret1y=.;
	if ret1y>=p99 then ret1y=.;
	if ret1y_us<=p1us then ret1y_us=.;
	if ret1y_us>=p99us then ret1y_us=.;
end;

if ret<=p1 then ret=.;
if ret>=p99 then ret=.;
if ret_us<=p1us then ret_us=.;
if ret_us>=p99us then ret_us=.;
if rhs<=p1rhs then rhs=p1rhs;
if rhs>=p99rhs then rhs=p99rhs;
proc sort; by code portyear;
run;

proc sql;
 create table agret1 as
 select *
 from agret0
 where code in (select code from work.retannual) and portyear in (select portyear from work.retannual);
quit;
*/
data agret1; set agret00;
/* %winsor(dsetin=agret1, dsetout=agret1, byvar=country, vars=ret_us, type=winsor, pctl=1 99);  */
proc sort; by code mthyr;
run;

data agret1; merge agret1(in=a) mvmois(in=b);
by code mthyr;
if a and b;
/*if mv ne .;  */
run;


/*%winsor(dsetin=agret1, dsetout=agret1, byvar=country, vars=lagmv_us, type=winsor, pctl=1 99);*/

%mend;




%macro mthtest(rhs, lb, ub, nobs, outp);

%makerhs(&rhs, &lb, &ub, &nobs);

/*********************************************************************/
/**************this is new  ******************************************/
data agret1; set agret1;
if rhs~=.;
if rhs>0;
run;
/*********************************************************************/
/* scale within a country */
proc sort data=agret1;
by country mthyr;
run;
proc means data=agret1 noprint; by country mthyr;
var lagmv_us; output out=meanmv mean=mvbar sum=mvsum n=n;
run;

data agret; merge agret1(in=a) meanmv(in=b);
by country mthyr;
if a and b;
ew = 1;
/* mvport = lagmv_us/mvsum;
if rhs~=.;
if rhs>0;
*/
mvport = mvsum/lagmv_us;
portyear_old = portyear;
portyear = mthyr;
/* if portyear_old>1985;  */
if ret_us~=.;
drop _type_ _freq_;
run;

data tem; set agret;
if n>&nobs;
run;

%rhseffect(tem, ret_us, country, ew, ew, outpew, 0, out_us_ew);
/* data outpew; set outpew;
ew&rhs = retsprd;
drop retsprd expostyear;
run;
*/
%rhseffect(tem, ret_us, country, lagmv_us, mvport, outpvw, 0, out_us_vw);
/*data outpvw; set outpvw;
vw&rhs = retsprd;
drop retsprd expostyear;
run;
*/


%mend;



%macro outmthtest(rhs);
%mthtest(&rhs,0,1000000,15);
%mthtest(&rhs,0,1000000,20);
%mthtest(&rhs,0,1000000,50);
data sum; set sum15 sum20 sum50;
run;
ods tagsets.latex file="&rhs..tex" (notop nobot); proc print data=sum; run; quit; ods tagsets.latex close;
%mend;

*%mthtest(rdc3,0,1000000,15);




/*------------------------------------------------------------------------------- */
/* -------------------  two Way Sorting --------------------------------------------
/* rank firms into tercile/quintile/deciles based on AG;
/* rank firms into tercile/quintile/deciles based on ROE;
/* compute agspread

input: can be either local currency or USD data
n1: size of a cross section
n2: size of a cross section
	if the number of firms is between 30 and 50, form terciles
	if the number of firms is between 50 and 100, form quintiles
	if the number of firms is between 100 and 10000, form deciles
Ngrp1: 	tercile/quintile/deciles based on AG
Ngrp2: 	tercile/quintile/deciles based on ROE;
rankvar1: in this project, AG
rankvar2: in this project, ROE
ret: return can be either local currency or USD
weighting: either equal or value
neutral: indicates it is neutral by what, country? region? or world?
agg: how to aggregate? keep country? sum up country? or pooling world?
timevar: time variable -- portyear for now, can be monthly
output: a 3x3, 5x5 or 10x10 table
-------------------------------------------------------------------------------- */


%macro twowaysprd(input, n1, n2, Ngrp1, Ngrp2, rankvar1, rankvar2, ret, weighting, neutral, agg, timevar, output);

/* decide tercile/quintile/decile based on the min and max size of the cross section */
data workable2; set &input;
if &n1<=n<&n2;


/* sort by var1 into tercile/quintile/decile */
proc sort; by &neutral &timevar;
proc rank data=workable2 out=var1 groups=&Ngrp1;
var &rankvar1;
by &neutral &timevar;
ranks rank_var1;
proc sort; by code &neutral &timevar;
run;
data var1; set var1;
if rank_var1=. then delete;
run;

/* sort by var2 into tercile/quintile/decile */
proc rank data=workable2 out=var2 groups=&Ngrp2;
var &rankvar2;
by &neutral &timevar;
ranks rank_var2;
proc sort; by code &neutral &timevar;
run;
data var2; set var2;
if rank_var2=. then delete;
run;

/* combine two way sort  */
/* note this is the INTERSECTION not by a particular order */
data intx; merge var1(in=a) var2(in=b);
by code &neutral &timevar;
if a and b;
proc sort;
by code &neutral &timevar rank_var1 rank_var2;
run;
data intx2; set intx;
equal = 1;
portnum2 = (rank_var1+1)*10 + rank_var2;
proc sort; by &neutral &timevar portnum2;
run;

option nonotes;
proc means data=intx2 noprint;
var &ret;
by &neutral &timevar portnum2 rank_var1 rank_var2;
weight &weighting;
output out=port mean=retbar n=num;
run;

option notes;
data port2; set port;
/* if portnum2 ~=.; */
run;
proc sort data=port2;
by rank_var1 rank_var2 &neutral &timevar;
run;
proc transpose data=port2 out=port3;
by rank_var1 rank_var2 &neutral &timevar; var retbar;
run;
proc sort data=port3;
by _name_ rank_var1 rank_var2 &neutral &timevar;
run;

/*Find H-L difference for rank variable 2; */
proc sort data=port2 out=sum;
by rank_var1 &neutral &timevar rank_var2;
run;
data sum_diff; set sum(where=(rank_var2>-1));
by rank_var1 &neutral &timevar rank_var2;
if first.&timevar or last.&timevar; if first.&timevar then rank_var2=1;
if last.&timevar then rank_var2=2; run;
proc transpose data=sum_diff out=sum_diff2; by rank_var1 &neutral &timevar;
var retbar; id rank_var2; run;
data sum_diff2; set sum_diff2; rank_var2=99; col1 = _2 - _1; drop _2 _1; run;
data sum_diff2; set port3 sum_diff2; run;

/*Find H-L difference for rank variable 1; */
proc sort data=sum_diff2;
by _name_ rank_var2 &neutral &timevar rank_var1;
run;
data sum_diff3; set sum_diff2(where=(rank_var1>-1));
by _name_ rank_var2 &neutral &timevar rank_var1;
if first.&timevar or last.&timevar;if first.&timevar then rank_var1=1;
if last.&timevar then rank_var1=2; run;
proc transpose data=sum_diff3 out=sum_diff3;
by _name_ rank_var2 &neutral &timevar; var col1; id rank_var1; run;

data sum_diff3; set sum_diff3; rank_var1=100; col1 = _2 - _1; drop _2 _1; run;
data sum_diff3; set sum_diff3 sum_diff2;run;
proc sort data=sum_diff3;
by _name_ rank_var1 rank_var2 &neutral &timevar; run;
data sum_diff3; set sum_diff3;
if rank_var1=100 or rank_var2=99  then exret=col1; run;

/* average return --- aggregate by agg
can be different levels: country, region or global?
also do the NW adjustment for everything */

data sum_diff3; set sum_diff3;
world = 'world';
options nonotes;
proc sort data=sum_diff3;
by _name_ &agg;
proc model data=sum_diff3;
by _name_ &agg rank_var1 rank_var2;
parms a; exogenous col1 ;
instruments / intonly;
col1=a;
fit col1 / gmm kernel=(bart, %eval(1), 0);
ods output parameterestimates=param;
quit;
data param0; set param; type='Average ret';run;
data param0; set param0;
if probt<0.1 then p='*  ';
if probt<0.05 then p='** ';
if probt<0.01 then p='***';
tvalue=put(tvalue,7.3);
est=put(estimate, 12.9);
param=est;
if rank_var1=100 or rank_var2=99 then param=compress(est||p);
/* T=compress('('||tvalue||')'); */
T = tvalue;
keep &agg rank_var1 rank_var2 type _name_ param T;
rename _name_=name;
run;
proc sort data=param0;
by name type &agg rank_var1 rank_var2;
run;
proc transpose data=param0 out=&output;
by &agg rank_var1; var param T; id rank_var2; run;
data &output; set &output;
drop _name_;
run;
%mend;



%macro two_way_test(rhs,nobs,temps);
%let rhs = rdc3;
%let nobs= 15;
%let temps = 20181108;
x md "C:\TEMP\displace\&temps\&rhs";
x cd "C:\TEMP\displace\&temps\&rhs";
%makerhs(&rhs, 0, 10000000, 10000000);
/* scale within the globe */
proc sort data=agret1;
by mthyr;
run;
proc means data=agret1 noprint; by mthyr;
var lagmv_us; output out=meanmv mean=mvbar sum=mvsum n=n;
run;
data agret; merge agret1(in=a) meanmv(in=b);
by mthyr;
if a and b;
world = 'world';
ew = 1;
/* mvport = lagmv_us/mvsum; */
mvport = mvsum/lagmv_us;
if rhs~=.;
if rhs>0;
portyear_old = portyear;
portyear = mthyr;
/* if portyear_old>1985; */
if ret_us~=.;
drop _type_ _freq_ ret;
run;
%twowaysprd(agret, &nobs, 10000000, 5, 5, rhs, mv_us, ret_us, equal, world, world, portyear, summary521);
data sum_diff3_ew; set sum_diff3;
if rank_var1=100 & rank_var2~=99;
proc means; var col1;
output out=avg100_ew mean=ew_bar std=ew_sigma;
run;
data avg100_ew; set avg100_ew;
tvalue = ew_bar/ew_sigma*sqrt(_freq_/5);
run;
%twowaysprd(agret, &nobs, 10000000, 5, 5, rhs, mv_us, ret_us, mv_us, world, world, portyear, summary522);
data sum_diff3_vw; set sum_diff3;
if rank_var1=100 & rank_var2~=99;
proc means; var col1;
output out=avg100_vw mean=vw_bar std=vw_sigma;
run;
data avg100_vw; set avg100_vw;
tvalue = vw_bar/vw_sigma*sqrt(_freq_/5);
run;
ods tagsets.tablesonlylatex file="summary521.tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=summary521; run; quit;
ods tagsets.tablesonlylatex file="avg100_ew.tex"   (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=avg100_ew; run; quit;
ods tagsets.tablesonlylatex file="summary522.tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=summary522; run; quit;
ods tagsets.tablesonlylatex file="avg100_vw.tex"   (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=avg100_vw; run; quit;
ods tagsets.tablesonlylatex close;
%mend;

*%two_way_test(rdc3,15,20181108);

