
/* -------------------  Multi Signals Sprd------------------------------------ */

%macro multisignals(input, n1, n2, ret, neutral, weighting, Ngrp);

/* decide tercile/quintile/decile based on the min and max size of the cross section */
data workable2; set &input;
if &n1<=n<&n2;
run;

%let rankvar1 = bm;
%let rankvar2 = bm2;
%let rankvar3 = bm3;
%let rankvar4 = bm4;
%let timevar = portyear;

/* rank by var1, var2, var3, var4 into tercile/quintile/decile */
proc sort; by &neutral &timevar;
proc rank data=workable2 out=rank groups=&Ngrp;
var &rankvar1 &rankvar2 &rankvar3 &rankvar4;
by &neutral &timevar;
ranks rank_var1 rank_var2 rank_var3 rank_var4;
run;
data rank; set rank;
if rank_var1=. then delete;
if rank_var2=. then delete;
if rank_var3=. then delete;
if rank_var4=. then delete;
equal=1;
rank_var1 = rank_var1 + 1;
rank_var2 = rank_var2 + 1;
rank_var3 = rank_var3 + 1;
rank_var4 = rank_var4 + 1;
run;
proc sort data=rank; 
by &neutral &timevar rank_var1 rank_var2 rank_var3 rank_var4; 
run;

option nonotes;
proc means data=rank noprint;
var &ret;
by &neutral &timevar rank_var1 rank_var2 rank_var3 rank_var4;
weight &weighting;
output out=port mean=retbar n=num;
run;

option notes;
proc sort data=port out=port;
by rank_var1 rank_var2 rank_var3 rank_var4 &neutral &timevar;
run;
proc transpose data=port out=port2;
by rank_var1 rank_var2 rank_var3 rank_var4 &neutral &timevar; var retbar;
run;
proc sort data=port2;
by _name_ rank_var1 rank_var2 rank_var3 rank_var4 &neutral &timevar;
run;


data bot; set port2;
if rank_var1=1 and rank_var2=1 and rank_var3=1 and rank_var4=1;
bot1=col1;
keep &neutral &timevar bot1;
run;
data top; set port2;
if rank_var1=&Ngrp and rank_var2=&Ngrp and rank_var3=&Ngrp and rank_var4=&Ngrp;
top1=col1;
keep &neutral &timevar top1;
run;


data sprd&Ngrp; merge bot top;
by &neutral &timevar;
col1 = top1 - bot1;
keep &neutral &timevar col1;
run;


%mend multisignals;



%macro bmeffect(input, ret, sort, weighting, output);

%multisignals(&input, 4, 50, &ret, &sort, &weighting, 3);
%multisignals(&input, 51, 100000, &ret, &sort, &weighting, 5);

data sprd; set sprd3 sprd5;
proc sort; by &sort portyear;
run;

proc model data=sprd;
by &sort;
parms a; exogenous col1 ;
instruments / intonly;
col1=a;
fit col1 / gmm kernel=(bart, %eval(1), 0);
ods output parameterestimates=param;
quit;


data &output; set param;
if probt<0.1 then p='*  ';
if probt<0.05 then p='** ';
if probt<0.01 then p='***';
tvalue=put(tvalue,7.3);
est=put(estimate, 12.9);
param=est;
T = tvalue;
keep &sort param T p;
run;
data &output; retain &sort param T; set &output; run;

ods tagsets.tablesonlylatex file="&output..tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=&output; run; quit;
ods tagsets.tablesonlylatex close;

%mend bmeffect;
