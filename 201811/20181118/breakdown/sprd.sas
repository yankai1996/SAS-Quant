
%macro sprd(input, n1, n2, ret, sort, weighting1, ngroup);

/*
%let input=tem;
%let n1=4;
%let n2=50;
%let ret=ret_us;
%let sort=country;
%let weighting1=ew;
%let ngroup=3;
*/

data sub; set &input;
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

%mend sprd;

data test; set disp.agret0;
keep code country region;
run;
