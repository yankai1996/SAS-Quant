
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
