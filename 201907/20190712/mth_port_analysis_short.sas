

%macro mth_port_analysis_short();

/* 2.1.1 world average */
%rhseffect(tem, ret_us, country, ew, ew, effect_us, 0, out_us_ew);
data pwd.cn_ew_sprd; set effect_us; run;
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




/* 2.1.3 throw out US, do world average again */
data tem_xus; set tem;
if country~='US';
%rhseffect(tem_xus, ret_us, country, ew, ew, effect_us, 1, out_us_ew);
data pwd.cn_xUS_ew_sprd; set effect_us; run;
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
data pwd.cn_vw_sprd; set effect_us; run;
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



/* 2.1.3 throw out US, do world average again */
data tem_xus; set tem;
if country~='US';
%rhseffect(tem_xus, ret_us, country, lagmv_us, mvport, effect_us, 1, out_us_vw);
data pwd.cn_xUS_vw_sprd; set effect_us; run;
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
data final; set final211 final213 final221 final223;
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
if n>15;
run;
proc sort; by portyear;
run;

/* 5.1 Equally weighted */
%rhseffect(agret_us, ret_us, globe, ew, ew, effect_us_ew_g, 0, out_us_ew_reg);
data pwd.g_ew_sprd; set effect_us_ew_g; run;
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
data pwd.g_vw_sprd; set effect_us_vw_g; run;
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


%mend;
