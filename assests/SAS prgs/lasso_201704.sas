option NOERRORABEND;
options noxwait;
x 'o:\projects';

x 'cd o:\projects\ipp';
%include 'winsor.sas';

x 'cd o:\projects\google';

%include 'ind_ff48.sas';
%include 'ind_ff38.sas';
%include 'ind_ff12.sas';


libname prospect "o:\projects\prospect";

libname crsp "O:\projects\IPP\data_to_yan_20140919";

x 'cd o:\projects\seasonality';

libname prospect "o:\projects\prospect";

libname season "o:\projects\seasonality";

libname lasso "o:\projects\lasso";

data retmonthly; set season.retmonthly;
mthyr = year(date)*100+month(date);
mth = month(date);
retnew = coalesce(ret,dlret,ret+dlret);
if shrcd~=10 & shrcd~=11 then delete;
me = abs(prc)*shrout;
portyear = year(date);
if month<=6 then portyear = year(date)-1;
if year(date) >= 1965;
keep me mthyr ret permno retnew date prc mth portyear exchcd shrout;
run;

/* what to filter here?
create lagret as cum return 12-->1 */
proc sort data=retmonthly; by permno mthyr;
data retmonthly; set retmonthly;
by permno mthyr;
lagme = lag(me);
lagret = 0;
lag1retnew = lag(retnew);
lagprc = lag(prc);
if first.permno then do
	lagme=.;
	lag1retnew = .;
end;
run;


/* NYSE size 20% above */
option notes;
data me_breakpoints; set season.me_breakpoints;
count + 1;
by calyear;
run;
proc sort; by count;
data me_breakpoints; set me_breakpoints;
by count;
mthyr = lag(calyear);
run;

proc sql;
  	create table retmonthly as
   	select a.*, b.dec20
   	from retmonthly as a
	left join me_breakpoints as b on a.mthyr=b.mthyr;
	/*where a.lagme/1000 >= b.dec20;*/
quit;


option notes;


proc sql;
   create table R11 as
   select distinct a.permno, a.date, a.me, a.mthyr, a.retnew, a.lagprc, a.portyear, a.lagme, a.dec20, a.mth, a.lag1retnew, exp(sum(log(1+b.retnew)))-1 as lagret, count(a.retnew) as count1, count(b.retnew) as count2
     from retmonthly (where=(year(date)>=1966)) as a,
          retmonthly (where=(year(date)>=1965)) as b
	where a.permno=b.permno and 2<=intck('month',b.date,a.date)<=12
	group by a.permno, a.date
   having count(b.retnew)=11;
quit;




*** Composite Equity Issuance;
proc sql;

  *** Changes in log ME;
  create table logME_Jun as
  select permno, year(date) as myear, exchcd, prc, log(prc*shrout) as logME
    from retmonthly
   where prc*shrout>0 and month(date)=6;

  create table logME_chg as
  select a.permno, a.myear, a.exchcd, a.prc, a.logME-b.logME as logME_chg
    from logME_Jun as a, logME_Jun as b
   where a.permno=b.permno and a.myear-b.myear=5;

  *** 5-year cumulative log return;
  create table ret as
  select permno, date, year(intnx('month',date,+6)) as myear, retnew
    from retmonthly
   where ^missing(ret);

  create table logret as
  select permno, myear, sum(log(1+retnew)) as logret
    from ret
   group by permno, myear
  having count(retnew)=12;

  create table logret_5yr as
  select a.permno, a.myear, sum(b.logret) as logret_5yr
    from logret as a, logret as b
   where a.permno=b.permno and 0<=a.myear-b.myear<=4
   group by a.permno, a.myear
  having count(b.logret)=5;

  *** Composite Equity Issuance;
  create table CEI as
  select a.*, b.logret_5yr
    from logME_chg as a, logret_5yr as b
   where a.permno=b.permno and a.myear=b.myear;

  create table CEI as
  select *, logME_chg-logret_5yr as CEI, myear as portyear
    from CEI
   where 1966<=myear<=2015; /** N=141,480 from myear 1966 to 2013 **/

quit;
proc sort; by permno portyear; run;

data temp; set cei;
keep portyear;
proc sort nodup; by portyear; run;


proc sql;
  create table ag as
/*  select a.*, b.roe1, b.CEQ, coalesce(b.AT,a.AT) as AT, c.PPEGT, c.XRD, c.INVT as INVT, c.SALE, c.CAPX, d.DLTT, d.DVC, d.PSTK, e.AJEX, e.LT, e.PI, e.CSHO*/
  select a.*, b.*, c.*, d.*, e.*
          from prospect.accrual_size_bm as a
		  left join prospect.op_bm as b on a.gvkey=b.gvkey and a.fyear=b.fyear
		left join prospect.yan_20150630 as c on a.gvkey=c.gvkey and a.fyear=c.fyear
		  left join prospect.yan_20150816 as d on a.gvkey=d.gvkey and a.fyear=d.fyear
		left join prospect.yan_20160424 as e on a.gvkey=e.gvkey and a.fyear=e.fyear;	
quit;

/*
data temp1; set ag;
if gvkey=019049;
if fyear=1994;
run;
*/

proc sort; by permno calyear;
data ag; set ag;
by permno calyear;
logbm=log(bm);
logme=log(size);
portyear = calyear + 1;
ag = (at - lag(at))/lag(at);
noa = ((AT-CHE)-(AT-coalesce(DLC,0)-coalesce(DLTT,0)-coalesce(MIB,0)-coalesce(PSTK,0)-CEQ))/lag(AT);
dpi2a = (PPEGT-lag(PPEGT)+INVT-lag(INVT))/lag(AT);
shares = csho*ajex;
oabs2 = (((ACT-lag(ACT))-(CHE-lag(CHE))) - ((LCT-lag(LCT))-(coalesce(DLC,0)-coalesce(lag(DLC),0))-(coalesce(TXP,0)-coalesce(lag(TXP),0)))- coalesce(DP,0) ) / lag(AT);
oacf2 = (NI-OANCF)/lag(AT);
gp2a = (revt - cogs)/at;
TLTA = (DLC+DLTT)/AT;
WCTA = (ACT-LCT)/AT;
CLCA = LCT/ACT;
NITA = NI/AT;
FUTL = PI/LT;
OENEG = 0;
if LT-AT>0 then OENEG=1;
INTWO = 0;
if NI<0 and lag(NI)<0 then INTWO=1;
CHIN = (NI-lag(NI))/(abs(NI)+abs(lag(NI)));
oscore =    -1.32 -0.407*log(AT) +6.03*TLTA -1.43*WCTA +0.076*CLCA -1.72*OENEG
          -2.37*NITA -1.83*FUTL +0.285*INTWO -0.521*CHIN;
roa = ib/lag(at);
lagme = lag(logme);
if first.permno then lagme=.;
run;



proc means data=ag; run;





proc sort data=R11; by permno portyear;

/* merge Fama French three factors with R11 data*/
proc sql;
  create table R112 as
  select a.*, b.mktrf, b.rf, b.smb, b.hml
          from R11 as a
		  left join prospect.factors_monthly as b on a.mthyr=b.year*100+b.month;
quit;
/* use the excess return of each firm, regress on the market excess return, then obtain the regression RMSE.
Regression needs a history of data, so hold the beginning, then add one portyear at a time, roll ahead to do the regression */

data rollrmse;
options nonotes nosource nosource2 errors=0;
%macro fmb_rho(input, bucket);
%do i = 1967 %to 2015;
data tem; set &input;
if portyear<=&i & portyear>=1966;
if portyear~=.;
exret = retnew - rf;
run;
proc sort data=tem; by &bucket;
proc reg data=tem noprint outest=coef edf;
model retnew=mktrf;
 /*model ret=lagret; */
by &bucket;
run;
data coef; set coef;
rmse = _RMSE_;
portyear = &i;
if rmse~=.;
keep &bucket portyear rmse;
run;
data rollrmse; set rollrmse coef;
run;
%end;
%mend;
%fmb_rho(R112, permno);
proc sort; by permno portyear;
run;

options notes;
data agret0; merge R11(in=a) ag(in=b) cei(in=c) rollrmse(in=d);
by permno portyear;
if a and b;
keep permno portyear mthyr retnew logme logbm lagret roe1 ag gp2a roa noa dpi2a oscore cei lagme dec20 rmse;
/*keep permno portyear mthyr firm retnew logme logbm lagret roe ag gp2a roa noa dpi2a shares oscore oabs oacf cei oabs2 oacf2;
/*if logbm~=. & logme~=. & ag~=. & roe1~=. & lag1retnew~=.;*/
run;


data agret0; merge R11(in=a) ag(in=b) cei(in=c);
by permno portyear;
if a and b;
keep permno portyear mthyr retnew logme logbm lagret roe1 ag gp2a roa noa dpi2a oscore cei lagme dec20;
/*keep permno portyear mthyr firm retnew logme logbm lagret roe ag gp2a roa noa dpi2a shares oscore oabs oacf cei oabs2 oacf2;
/*if logbm~=. & logme~=. & ag~=. & roe1~=. & lag1retnew~=.;*/
run;
proc means data=agret0; run;

proc sort data=agret0;
by mthyr permno;
data agret0; set agret0;
by mthyr permno;
xsec = 0;
if first.mthyr then xsec=1;
run;
data agret0;
retain permno portyear mthyr retnew logme logbm lagret roe1 ag gp2a roa noa dpi2a oscore cei xsec lagme dec20 rmse;
set agret0;
run;

%winsor(dsetin=agret0, dsetout=agret1, byvar=mthyr, vars=logme logbm lagret roe1 ag gp2a roa noa dpi2a oscore cei, type=winsor, pctl=1 99);
proc means data=agret1; run;


proc sql;
  create table agret2 as
  select a.*, lagme/mean(lagme) as me2, rmse/mean(rmse) as rmse2
          from agret1 as a
		  group by mthyr;
quit;
proc sort; by mthyr permno;
proc export data= work.agret2
            /*outfile= "o:\projects\lasso\cslasso_20170426.csv"*/
			outfile= "o:\projects\lasso\cslasso_20170814.csv"
            dbms=csv replace;
run;


