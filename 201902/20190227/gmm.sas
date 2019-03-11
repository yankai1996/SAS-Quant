
libname sprd "C:\TEMP\sprd";


%macro bm_cog_reg(country);

data lhs_sprd; set sprd.bm_&country;
lhs = retsprd;
keep portyear lhs;
run;
data rhs_sprd; set sprd.lagcog_us_&country;
rhs = retsprd;
keep portyear rhs;
run;

data lhs_rhs_sprd; merge lhs_sprd(in=a) rhs_sprd(in=b);
by portyear;
if a and b;
run;

proc model data=lhs_rhs_sprd;
exogenous rhs;
parms a b;
lhs=a + b*rhs;
fit lhs / gmm kernel=(bart, %eval(1), 0);
instruments rhs;
ods output parameterestimates=param;
quit;

/*
proc reg data=lhs_rhs_sprd;
model lhs = rhs;
run;
*/

data out&country; set param;
if probt<0.1 then p='*  ';
if probt<0.05 then p='** ';
if probt<0.01 then p='***';
tvalue=put(tvalue,7.3);
est=put(estimate, 12.3);
prob=put(probt,7.3);
stder=put(stderr, 7.3);
T=compress('('||tvalue||')');
drop EstType est StdErr probt DF T _type_;  /*may keep these information */
run;

%mend bm_cog_reg;

%bm_cog_reg(g7);
