
*%macro sprd(input, n1, n2, ret, sort, weighting1, ngroup);
*%sprd(&input, 4, 50, &ret, &sort, &weighting1, 3);
%let input = exp2;
%let n1 = 51;
%let n2 = 100000;
%let ret = ret_us;
%let sort = country;
%let weighting1 = ew;
%let weighting2 = ew;
%let ngroup = 5;

*%macro sprd(input, n1, n2, ret, sort, weighting1, ngroup);
*%sprd(&input, 51, 100000, &ret, &sort, &weighting1, 5);
/*
%let input = tem;
%let n1 = 4;
%let n2 = 50;
%let ret = ret_us;
%let sort = country;
%let weighting1 = lagmv_us;
%let weighting2 = mvport;
%let ngroup = 3;
*/

data sub; set &input;
n=1000;
weighting1=1;
if &n1<=n<&n2;
run;

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
