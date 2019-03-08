

dm 'log;clear;';
%let pwd = "C:\TEMP\displace\20190225\xUS-lagcog_us-g10-sum";
x md &pwd;
x cd &pwd;
libname pwd &pwd;

data test; set tem;
world = "world";
signal1=RD1/MC;
signal2=RD2/MC;
signal3=RD3/MC;
*if signal1~=. and EMP2~=.;
*if signal1~=.;
*if EMP2~=.;
run;

%zRD(test, world, portyear, signal1, signal2, signal3, RD);
%zEMP(zscore, world, portyear, EMP2, 1);


data agret6; set zscore;
rhs1 = z1;
rhs2 = z2;
rhs3 = z3;
rhs4 = mean(z1,z2,z3);
rhs5 = z1 + zEMP;
rhs6 = z2 + zEMP;
rhs7 = z3 + zEMP;
rhs8 = rhs4 + zEMP;
n = 100;
run;

%macro tests(i);
%do i = 1 %to 8;
data testdata; set agret6;
rhs = rhs&i;
if lagmv_us~=.;
run;
%sprd(testdata, 51, 100000, ret_us, world, lagmv_us, 10);
proc sql;
	create table mysum_&i as
	select mean(retsprd) as bar, std(retsprd) as sigma, mean(retsprd)/std(retsprd)*sqrt(12) as sharpe
	from sprd10;
quit;
%end;
data outp; set mysum:; run;

ods tagsets.tablesonlylatex file="outp.tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=outp; run; quit;
ods tagsets.tablesonlylatex close;

%mend;
%tests(i);



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

%macro NWtest(output, lags, outstat);
proc model data=&output;
parms retsprdbar; exogenous retsprd;
instruments / intonly;
retsprd = retsprdbar;
fit retsprd / gmm kernel=(bart, %eval(1+&lags), 0);
ods output parameterestimates=&outstat;
quit;
%mend;
