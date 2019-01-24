
*%macro mthtest(rhs, lb, ub, nobs, outp);

%let rhs = rdc3;
%let lb = 0;
%let ub = 1000000;
%let nobs = 15;

%makerhs(&rhs, &lb, &ub, &nobs);

/*********************************************************************/
/**************this is new  ******************************************/
data agret1; set agret1;
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
run;

%rhseffect(tem, ret_us, country, ew, ew, outpew, 0, out_us_ew);
/* data outpew; set outpew;
ew&rhs = retsprd;
drop retsprd expostyear;
run;
*/
%rhseffect(tem, ret_us, country, lagmv_us, mvport, outpvw, 0, out_us_vw);
/*data outpvw; set outpvw;
vw&rhs = retsprd;
drop retsprd expostyear;
run;
*/


*%mend;

*%mthtest(rdc3,0,1000000,15);
