

%macro mth_port_analysis_short(rhs,nobs);


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

%mth_port_analysis_short(z,15);
