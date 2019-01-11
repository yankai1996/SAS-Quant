

%macro mth_port_analysis_short(rhs,nobs);

option notes;
/* ----------------------------------- */
/* 2. Country Neutral first    */
/* ----------------------------------- */

%makerhs(&rhs, 0, 1000000, &nobs);
/**************this is new  ******************************************/
data agret1; set agret1;
if mthyr<=201206;
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
mvport = mvbar/lagmv_us;
if rhs~=.;
if rhs>0;
portyear_old = portyear;
portyear = mthyr;
/* if myroe>-10 and myroe<10;  */
/* if portyear_old>1985; */
if ret_us~=.;
drop _type_ _freq_;
run;

data tem; set agret;
if n>&nobs;
run;

/* 2.1.1 world average */
%rhseffect(tem, ret_us, country, ew, ew, effect_us, 0, out_us_ew);
data effect_us; set effect_us; if retsprd>-1;
proc sort data=effect_us;
by portyear;
proc means data=effect_us noprint;
by portyear;
var rhssprd retsprd slope;
output out=avg211 mean=rhssprd retsprd slope;
run;
%NWavg(avg211, _type_, 0, avg211avg);
data avg211avg; set avg211avg;
r = 6;
run;

proc sort data=rhs1; by portyear r;
proc means data=rhs1 noprint; by portyear r;
var ret;
output out=vecout mean=retsprd;
run;
proc sort data=vecout; by r;
proc model data=vecout;
by r;
parms a; exogenous retsprd;
instruments / intonly;
retsprd=a;
fit retsprd / gmm kernel=(bart, %eval(1), 0);
ods output parameterestimates=param100;
quit;
data param100; set param100;
keep r estimate tValue;
data avg211avg; set avg211avg;
keep r estimate tValue;
data final211; set param100 avg211avg;
rename r=rank;
run;



/* 2.1.2 keep US, do world average again */
data tem_us; set tem;
if country='US';
%rhseffect(tem_us, ret_us, country, ew, ew, effect_us, 1, out_us_ew);
data effect_us; set effect_us; if retsprd>-1;
data effect_us_us; set effect_us;
proc sort data=effect_us_us;
by portyear;
proc means data=effect_us_us noprint;
by portyear;
var rhssprd retsprd slope;
output out=avg212 mean=rhssprd retsprd slope;
run;
%NWavg(avg212, _type_, 0, avg212avg);

data avg212avg; set avg212avg;
r = 6;
run;
proc sort data=rhs1; by portyear r;
proc means data=rhs1 noprint; by portyear r;
var ret;
output out=vecout mean=retsprd;
run;
proc sort data=vecout; by r;
proc model data=vecout;
by r;
parms a; exogenous retsprd;
instruments / intonly;
retsprd=a;
fit retsprd / gmm kernel=(bart, %eval(1), 0);
ods output parameterestimates=param100;
quit;
data param100; set param100;
keep r estimate tValue;
data avg212avg; set avg212avg;
keep r estimate tValue;
data final212; set param100 avg212avg;
rename r=rank;
run;


/* 2.1.3 throw out US, do world average again */
data tem_xus; set tem;
if country~='US';
%rhseffect(tem_xus, ret_us, country, ew, ew, effect_us, 1, out_us_ew);
data effect_us; set effect_us; if retsprd>-1;
data effect_us_xus; set effect_us;
proc sort data=effect_us_xus;
by portyear;
proc means data=effect_us_xus noprint;
by portyear;
var rhssprd retsprd slope;
output out=avg213 mean=rhssprd retsprd slope;
run;
%NWavg(avg213, _type_, 0, avg213avg);
data avg213avg; set avg213avg;
r = 6;
run;

proc sort data=rhs1; by portyear r;
proc means data=rhs1 noprint; by portyear r;
var ret;
output out=vecout mean=retsprd;
run;
proc sort data=vecout; by r;
proc model data=vecout;
by r;
parms a; exogenous retsprd;
instruments / intonly;
retsprd=a;
fit retsprd / gmm kernel=(bart, %eval(1), 0);
ods output parameterestimates=param100;
quit;
data param100; set param100;
keep r estimate tValue;
data avg213avg; set avg213avg;
keep r estimate tValue;
data final213; set param100 avg213avg;
rename r=rank;
run;

/* -------------------- */
/* 2.2 Value weighted
/* -------------------- */

/* 2.2.1 world average */
%rhseffect(tem, ret_us, country, lagmv_us, mvport, effect_us, 1, out_us_vw);
data effect_us; set effect_us; if retsprd>-1;

proc sort data=effect_us;
by portyear;
proc means data=effect_us noprint;
by portyear;
var rhssprd retsprd slope;
output out=avg221 mean=rhssprd retsprd slope;
run;
%NWavg(avg221, _type_, 0, avg221avg);
data avg221avg; set avg221avg;
r = 6;
run;

proc sort data=rhs1; by portyear r;
proc means data=rhs1 noprint; by portyear r;
var ret;
output out=vecout mean=retsprd;
run;
proc sort data=vecout; by r;
proc model data=vecout;
by r;
parms a; exogenous retsprd;
instruments / intonly;
retsprd=a;
fit retsprd / gmm kernel=(bart, %eval(1), 0);
ods output parameterestimates=param100;
quit;
data param100; set param100;
keep r estimate tValue;
data avg221avg; set avg221avg;
keep r estimate tValue;
data final221; set param100 avg221avg;
rename r=rank;
run;



/* 2.1.2 keep US, do world average again */
data tem_us; set tem;
if country='US';
%rhseffect(tem_us, ret_us, country, lagmv_us, mvport, effect_us, 1, out_us_vw);
data effect_us; set effect_us; if retsprd>-1;
data effect_us_us; set effect_us;
proc sort data=effect_us_us;
by portyear;
proc means data=effect_us_us noprint;
by portyear;
var rhssprd retsprd slope;
output out=avg222 mean=rhssprd retsprd slope;
run;
%NWavg(avg222, _type_, 0, avg222avg);
data avg222avg; set avg222avg;
r = 6;
run;

proc sort data=rhs1; by portyear r;
proc means data=rhs1 noprint; by portyear r;
var ret;
output out=vecout mean=retsprd;
run;
proc sort data=vecout; by r;
proc model data=vecout;
by r;
parms a; exogenous retsprd;
instruments / intonly;
retsprd=a;
fit retsprd / gmm kernel=(bart, %eval(1), 0);
ods output parameterestimates=param100;
quit;
data param100; set param100;
keep r estimate tValue;
data avg222avg; set avg222avg;
keep r estimate tValue;
data final222; set param100 avg222avg;
rename r=rank;
run;


/* 2.1.3 throw out US, do world average again */
data tem_xus; set tem;
if country~='US';
%rhseffect(tem_xus, ret_us, country, lagmv_us, mvport, effect_us, 1, out_us_vw);
data effect_us; set effect_us; if retsprd>-1;
data effect_us_xus; set effect_us;
proc sort data=effect_us_xus;
by portyear;
proc means data=effect_us_xus noprint;
by portyear;
var rhssprd retsprd slope;
output out=avg223 mean=rhssprd retsprd slope;
run;
%NWavg(avg223, _type_, 0, avg223avg);
data avg223avg; set avg223avg;
r = 6;
run;

proc sort data=rhs1; by portyear r;
proc means data=rhs1 noprint; by portyear r;
var ret;
output out=vecout mean=retsprd;
run;
proc sort data=vecout; by r;
proc model data=vecout;
by r;
parms a; exogenous retsprd;
instruments / intonly;
retsprd=a;
fit retsprd / gmm kernel=(bart, %eval(1), 0);
ods output parameterestimates=param100;
quit;
data param100; set param100;
keep r estimate tValue;
data avg223avg; set avg223avg;
keep r estimate tValue;
data final223; set param100 avg223avg;
rename r=rank;
run;
data final; set final211 final212 final213 final221 final222 final223;
run;


/* ------------------------ */
/*  Global portfolio with US*/
/* ------------------------ */

data agret_us; set agret;
drop n mvsum mvbar mvport;
run;

proc sort data=agret_us; by portyear;
run;
/* figure out the size of cross section of region */
proc means data=agret_us noprint; by portyear;
var lagmv_us; output out=meanmv mean=mvbar n=n;
run;
data agret_us; merge agret_us(in=a) meanmv(in=b);
by portyear;
if a and b;
ew = 1;
globe = 1;
mvport = mvbar/lagmv_us;
drop _type_ _freq_;
if n>&nobs;
run;
proc sort; by portyear;
run;

/* 5.1 Equally weighted */
%rhseffect(agret_us, ret_us, globe, ew, ew, effect_us_ew_g, 0, out_us_ew_reg);
data final51; set out_us_ew_reg;
r=6;
keep r estimate tValue;
run;

proc sort data=rhs1; by portyear r;
proc means data=rhs1 noprint; by portyear r;
var ret;
output out=vecout mean=retsprd;
run;
proc sort data=vecout; by r;
proc model data=vecout;
by r;
parms a; exogenous retsprd;
instruments / intonly;
retsprd=a;
fit retsprd / gmm kernel=(bart, %eval(1), 0);
ods output parameterestimates=param100;
quit;
data param100; set param100;
keep r estimate tValue;
data final51; set param100 final51;
rename r=rank;
run;



/* 5.2 Value weighted */
%rhseffect(agret_us, ret_us, globe, lagmv_us, mvport, effect_us_vw_g, 0, out_us_vw_reg);
data final52; set out_us_vw_reg;
r=6;
keep r estimate tValue;
run;

proc sort data=rhs1; by portyear r;
proc means data=rhs1 noprint; by portyear r;
var ret;
output out=vecout mean=retsprd;
run;
proc sort data=vecout; by r;
proc model data=vecout;
by r;
parms a; exogenous retsprd;
instruments / intonly;
retsprd=a;
fit retsprd / gmm kernel=(bart, %eval(1), 0);
ods output parameterestimates=param200;
quit;
data param200; set param200;
keep r estimate tValue;
data final52; set param200 final52;
rename r=rank;
run;



/*  Global portfolio without US*/
data agret_xus; set agret_us;
drop n mvsum mvbar mvport;
if country~="US";
run;
proc sort data=agret_xus; by portyear;
run;
/* figure out the size of cross section of region */
proc means data=agret_xus noprint; by portyear;
var lagmv_us; output out=meanmv mean=mvbar n=n;
run;
data agret_xus; merge agret_xus(in=a) meanmv(in=b);
by portyear;
if a and b;
ew = 1;
globe = 1;
mvport = mvbar/lagmv_us;
drop _type_ _freq_;
if n>&nobs;
run;
proc sort; by portyear;
run;

/* 6.1 Equally weighted */
%rhseffect(agret_xus, ret_us, globe, ew, ew, effect_xus_ew_g, 0, out_xus_ew_reg);
data final61; set out_xus_ew_reg;
r=6;
keep r estimate tValue;
run;

proc sort data=rhs1; by portyear r;
proc means data=rhs1 noprint; by portyear r;
var ret;
output out=vecout mean=retsprd;
run;
proc sort data=vecout; by r;
proc model data=vecout;
by r;
parms a; exogenous retsprd;
instruments / intonly;
retsprd=a;
fit retsprd / gmm kernel=(bart, %eval(1), 0);
ods output parameterestimates=param300;
quit;
data param300; set param300;
keep r estimate tValue;
data final61; set param300 final61;
rename r=rank;
run;



/* 6.2 Value weighted */
%rhseffect(agret_xus, ret_us, globe, lagmv_us, mvport, effect_xus_vw_g, 0, out_xus_vw_reg);
data final62; set out_xus_vw_reg;
r=6;
keep r estimate tValue;
run;

proc sort data=rhs1; by portyear r;
proc means data=rhs1 noprint; by portyear r;
var ret;
output out=vecout mean=retsprd;
run;
proc sort data=vecout; by r;
proc model data=vecout;
by r;
parms a; exogenous retsprd;
instruments / intonly;
retsprd=a;
fit retsprd / gmm kernel=(bart, %eval(1), 0);
ods output parameterestimates=param400;
quit;
data param400; set param400;
keep r estimate tValue;
data final62; set param400 final62;
rename r=rank;
run;

%mend;
