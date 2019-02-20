
/* -------------------  Z Score ------------------------------------ */

%macro zRD(input, neutral, timevar, signal1, signal2, signal3, label);

proc sort data=&input;
by &neutral &timevar;
run;

proc rank data=&input out=rank;
var &signal1 &signal2 &signal3;
by &neutral &timevar;
ranks r1 r2 r3;
run;

proc means data=rank noprint;
options nolabel; 
by &neutral &timevar;
var r1 r2 r3;
output out=rankmean mean=mu1 mu2 mu3 std=sigma1 sigma2 sigma3 n=n;
run;
data rankmean; set rankmean;
drop _type_ _freq_;
run;

data zscore; merge rank rankmean;
by &neutral &timevar;
z1=(r1-mu1)/sigma1;
z2=(r2-mu2)/sigma2;
z3=(r3-mu3)/sigma3;
z&label=mean(z1, z2, z3);
drop r1 r2 r3 mu1 mu2 mu3 sigma1 sigma2 sigma3;
run;
option label;

%mend zRD;


%macro zEMP(input, neutral, timevar, signal, abs);

data zscore; set &input;
%if &abs>0 %then %do;
&signal = abs(&signal);
%end;
proc sort data=zscore;
by &neutral &timevar;
run;

proc rank data=zscore out=rank;
var &signal;
by &neutral &timevar;
ranks r;
run;

proc means data=rank noprint;
options nolabel; 
by &neutral &timevar;
var r;
output out=rankmean mean=mu std=sigma n=n;
run;
data rankmean; set rankmean;
drop _type_ _freq_;
run;

data zscore; merge rank rankmean;
by &neutral &timevar;
zEMP = (r-mu)/sigma;
drop r mu sigma;
run;

%mend zEMP;



%macro zcombine(input, neutral, timevar, sign);

data &input; set &input;
%if &sign > 0 %then %do;
z = mean(zRD, zEMP);
%end; %else %do;
z = mean(zRD, -zEMP);
%end;
drop n;
run;

proc means data=&input noprint;
by &neutral &timevar;
var z;
output out=zn n=n;
run;
data &input; merge &input zn;
by &neutral &timevar;
drop _type_ _freq_;
if z~=.;
run;

%mend;


%macro zn(input, neutral, timevar);

data &input; set &input;
z = zRD+zEMP;
drop n;
run;

proc means data=&input noprint;
by &neutral &timevar;
var z;
output out=zn n=n;
run;
data &input; merge &input zn;
by &neutral &timevar;
drop _type_ _freq_;
if z~=.;
run;

%mend zn;


/*************** Start from here *************************/

%let rhs=rdc3;
%let lb=0;
%let ub=1000000;
%let nobs=15;

%makerhs(&rhs, &lb, &ub, &nobs);

%mergeRegion(agret1, agret1);

%makeRD(agret1, agret1);

%makeEMP(agret1, agret1);

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
drop n;
if portyear=199505 and ret_us > 5 then delete;
if country='RH' then delete;
run;

*%winsor(dsetin=tem, dsetout=tem, byvar=portyear country, vars=EMP1 EMP2 EMP3, type=winsor, pctl=1 99);



%macro absEMPtest(EMPi);

dm 'log;clear;';
%let pwd = "C:\TEMP\displace\20190110\abs&EMPi";
x md &pwd;
x cd &pwd;
libname pwd &pwd;

%zEMP(tem, country, portyear, &EMPi, 1);
%onewayeffect(zscore, ret_us, country, ew, country_ew, zEMP);
%onewayeffect(zscore, ret_us, country, lagmv_us, country_vw, zEMP);

%zEMP(tem, region, portyear, &EMPi, 1);
%onewayeffect(zscore, ret_us, region, ew, region_ew, zEMP);
%onewayeffect(zscore, ret_us, region, lagmv_us, region_vw, zEMP);

%zEMP(tem, world, portyear, &EMPi, 1);
%onewayeffect(zscore, ret_us, world, ew, world_ew, zEMP);
data pwd.world_ew_sprd; set sprd; run;
%onewayeffect(zscore, ret_us, world, lagmv_us, world_vw, zEMP);
data pwd.world_vw_sprd; set sprd; run;

%mend absEMPtest;


%absEMPtest(EMP2);


%macro RDtest(denominator);

dm 'log;clear;';
%let pwd = "C:\TEMP\displace\20190109\&denominator";
x md &pwd;
x cd &pwd;
libname pwd &pwd;

data zscore; set tem;
signal1=RD1/&denominator;
signal2=RD2/&denominator;
signal3=RD3/&denominator;
run;

%winsor(dsetin=zscore, dsetout=zscore, byvar=portyear country, vars=signal1 signal2 signal3, type=winsor, pctl=1 99);

%zRD(zscore, country, portyear, signal1, signal2, signal3, RD);
%zeffect(zscore, ret_us, country, ew, country_ew, zRD);
%zeffect(zscore, ret_us, country, lagmv_us, country_vw, zRD);

%zRD(zscore, region, portyear, signal1, signal2, signal3, RD);
%zeffect(zscore, ret_us, region, ew, region_ew, zRD);
%zeffect(zscore, ret_us, region, lagmv_us, region_vw, zRD);

%zRD(zscore, world, portyear, signal1, signal2, signal3, RD);
%zeffect(zscore, ret_us, world, ew, world_ew, zRD);
data pwd.world_ew_sprd; set sprd; run;
%zeffect(zscore, ret_us, world, lagmv_us, world_vw, zRD);
data pwd.world_vw_sprd; set sprd; run;

%mend RDtest;


%RDtest(MC);
%RDtest(TA);
%RDtest(be4);
%RDtest(SL);


%macro EMPmeantest();

%let pwd = "C:\TEMP\displace\20190109\EMPmean";
x md &pwd;
x cd &pwd;
libname pwd &pwd;

%zRD(tem, country, portyear, EMP1, EMP2, EMP3, EMP);
%zeffect(zscore, ret_us, country, ew, country_ew, zEMP);
%zeffect(zscore, ret_us, country, lagmv_us, country_vw, zEMP);

%zRD(tem, region, portyear, EMP1, EMP2, EMP3, EMP);
%zeffect(zscore, ret_us, region, ew, region_ew, zEMP);
%zeffect(zscore, ret_us, region, lagmv_us, region_vw, zEMP);

%zRD(tem, world, portyear, EMP1, EMP2, EMP3, EMP);
%zeffect(zscore, ret_us, world, ew, world_ew, zEMP);
%zeffect(zscore, ret_us, world, lagmv_us, world_vw, zEMP);
data pwd.world_vw_sprd; set sprd; run;

%mend EMPmeantest;

%EMPmeantest();


%macro onewaytest();

dm 'log;clear;';
%let pwd = "C:\TEMP\displace\20190111\xUS-one-way-quintile";
x md &pwd;
x cd &pwd;
libname pwd &pwd;

data test; set tem;
if country='US' then delete;
run;

%zRD(test, country, portyear, signal1, signal2, signal3, RD);
%zEMP(zscore, country, portyear, EMP2, 1);
%zn(zscore, country, portyear);
%onewayeffect(zscore, ret_us, country, ew, country_ew, z);
%onewayeffect(zscore, ret_us, country, lagmv_us, country_vw, z);

%zRD(test, region, portyear, signal1, signal2, signal3, RD);
%zEMP(zscore, region, portyear, EMP2, 1);
%zn(zscore, region, portyear);
%onewayeffect(zscore, ret_us, region, ew, region_ew, z);
%onewayeffect(zscore, ret_us, region, lagmv_us, region_vw, z);

%zRD(test, world, portyear, signal1, signal2, signal3, RD);
%zEMP(zscore, world, portyear, EMP2, 1);
%zn(zscore, world, portyear);
%onewayeffect(zscore, ret_us, world, ew, world_ew, z);
data pwd.world_ew_sprd; set sprd; run;
%onewayeffect(zscore, ret_us, world, lagmv_us, world_vw, z);
data pwd.world_vw_sprd; set sprd; run;

%mend combotest;


%macro saveTS(name);

data port2trans; set port2;
rank_var = portnum2 + 1;
drop portnum2 rank_var1 rank_var2 _type_ _freq_;
proc sort; by portyear;
run;

proc transpose data=port2trans out=port2trans;
by world portyear; var rank_var retbar num;
run;

data pwd.&name; set port2trans;
%do i=1 %to 5;
	%do j=1 %to 5;
		rank&i&j = col%eval((&i-1)*5 + &j);
	%end;
%end;
drop col:;
if _name_ = "rank_var" then delete;
run;

%mend;


%macro twowaytest(EMPi);

dm 'log;clear;';
%let pwd = "C:\TEMP\displace\20190112\two-way\xUS-two-way";
x md &pwd;
x cd &pwd;
libname pwd &pwd;

%zRD(test, world, portyear, signal1, signal2, signal3, RD);
%zEMP(zscore, world, portyear, &EMPi, 1);
%zn(zscore, world, portyear);
%twowaysprd(zscore, 51, 10000000, 5, 5, zEMP, zRD, ret_us, equal, world, world, portyear, world_ew);
%saveTS(world_ew);
%twowaysprd(zscore, 51, 10000000, 5, 5, zEMP, zRD, ret_us, lagmv_us, world, world, portyear, world_vw);
%saveTS(world_vw);
ods tagsets.tablesonlylatex file="world_ew.tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=world_ew; run; quit;
ods tagsets.tablesonlylatex file="world_vw.tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=world_vw; run; quit;
ods tagsets.tablesonlylatex close;

%mend twowaytest;

%twowaytest(EMP2);


proc means data=tem;
var COG;
run;

data COG; set zscore;
if COG~=. and COG <0;
keep code portyear country region COG ret_us lagmv_us;
run;

proc sort data=zscore;
by country;
proc means data=zscore noprint;
var zEMP ret_us;
by country;
output out=distribution;
run;

