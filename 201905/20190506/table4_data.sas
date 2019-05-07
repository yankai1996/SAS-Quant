
libname db "V:\data_for_kai";
libname nnnDS "V:\data_for_kai\WSDS20190215";
libname pwd "C:\TEMP\displace\20190506";


data agret0; set nnnDS.agret0;
by code mthyr;
lagret_us=lag(ret_us);
if first.code then lagret_us=.;
if (lagret_us > 3 or ret_us>3) and (1+lagret_us)*(1+ret_us)<1.5 then do;
	ret_us=.;
	lagret_us=.;
end;
keep code country portyear mthyr ret_us CFO MC;
proc sort; by country mthyr;
run;

proc univariate data=agret0 noprint;
by country mthyr;
var ret_us;
output out=outliers pctlpts=0.1 99.9 pctlpre=ret;
run;

data agret1; merge agret0 outliers;
by country mthyr;
if ret_us<ret0_1 or ret_us>ret99_9 then ret_us=.;
proc sort; by code mthyr;
run;


data price; set nnnDS.retm;
code=dscd;
mthyr=year(date)*100+month(date);
keep code mthyr p mcus;
proc sort; by code mthyr;
run;
data price; set price;
by code mthyr;
lagP=lag(p);
lagmv_us=lag(MCUS);
if first.code then do;
lagP=.;
lagmv_us=.;
end;
run;


data agret1; merge agret1(in=a) price;
by code mthyr;
if a;
if lagP<1 then ret_us=.;
run;



/************** F_MOM ********************/

data momenret; set agret1;
rhs=log(ret_us+1);
keep code country portyear mthyr ret_us rhs lagmv_us;
run;

%macro fairelag(rhs, n);
%do i = 0 %to &n;
%let j=%eval(&i+1);
data momenret; set momenret;
by code mthyr;
lag0&rhs = &rhs;
lag&j&rhs = lag(lag&i&rhs);
if first.code then lag&j&rhs = .;
*lagret = lagret + lag&j&rhs;
run;
%end;
%mend;

%fairelag(rhs, 11);


data momen; set momenret;
mom1=lag2rhs+lag3rhs+lag4rhs+lag5rhs+ lag6rhs;
mom2=lag3rhs+lag4rhs+lag5rhs+lag6rhs+ lag7rhs;
mom3=lag4rhs+lag5rhs+lag6rhs+lag7rhs+ lag8rhs;
mom4=lag5rhs+lag6rhs+lag7rhs+lag8rhs+ lag9rhs;
mom5=lag6rhs+lag7rhs+lag8rhs+lag9rhs+ lag10rhs;
mom6=lag7rhs+lag8rhs+lag9rhs+lag10rhs+lag11rhs;
run;

data test; set momen;
mom1=exp(mom1)-1;
mom2=exp(mom2)-1;
mom3=exp(mom3)-1;
mom4=exp(mom4)-1;
mom5=exp(mom5)-1;
mom6=exp(mom6)-1;
keep code mthyr ret_us lagmv_us mom:;
proc sort; by mthyr;
run;


%macro momsprd(rhs);

proc rank data=test group=5 out=rank;
var &rhs; by mthyr; ranks r;
run;
data rank; set rank; r=r+1;
proc sort; by mthyr r;
run;

proc means data=rank noprint; by mthyr r;
var ret_us; weight lagmv_us;
output out=rhs1 mean=ret;
run;

data bot; set rhs1; if r=1; bot=ret; keep mthyr bot; run;
data top; set rhs1; if r=5; top=ret; keep mthyr top; run;

data sprd&rhs; merge bot top;
by mthyr;
&rhs = top-bot;
keep mthyr &rhs;
run;
%mend;


%momsprd(mom1);
%momsprd(mom2);
%momsprd(mom3);
%momsprd(mom4);
%momsprd(mom5);
%momsprd(mom6);

data fmom; merge sprdmom:;
by mthyr;
F_MOM=(mom1+mom2+mom3+mom4+mom5+mom6)/6*100;
keep mthyr F_MOM;
run;



/************** F_C/P ********************/

data test; set agret1;
if CFO>0 and MC>0;
CP=CFO/MC;
keep code mthyr ret_us lagmv_us CP;
proc sort; by mthyr;
run;

%momsprd(CP);

data Fcp; set sprdcp;
F_CP=cp*100;
keep mthyr F_CP;
run;



/************** Rm_Rf ********************/

proc import datafile="C:\TEMP\displace\20190506\RF.CSV"
out=rf dbms=csv replace; 
getnames=yes; 
run;


data RM; set agret1;
keep code mthyr ret_us MCUS;
proc sort; by mthyr;
proc means noprint; by mthyr;
var ret_us; weight MCUS;
output out=rm mean=rm;
run; 

data rm_rf; merge rm rf;
by mthyr;
rm=rm*100;
RM_RF=rm-rf;
if mthyr<=201812;
keep mthyr RM_RF RF;
run;



/************* Merge all ***************/

data hkk_new; merge fmom fcp rm_rf;
by mthyr;
run;
data pwd.hkk_new; set hkk_new; run;



proc import out=hkk_old
	file="V:\data_for_kai\hkk_factors_2010.xls"
	dbms=excel replace;
getnames=yes;
run;

data hkk_old; set hkk_old;
if CALMONTH=. then delete;
mthyr=CALMONTH;
F_mom_old=F_sret;
F_CP_old=F_C_P;
RM_RF_old=RM_RF;
keep mthyr F_mom_old F_CP_old RM_RF_old;
proc sort; by mthyr;
run;

data hkk; merge hkk_old hkk_new;
by mthyr;
run;

data pwd.hkk; set hkk; run;


data junk4; set hkk;
if mthyr<=201012;
proc corr; var F_CP:; run;
proc corr; var RM_RF:; run;
