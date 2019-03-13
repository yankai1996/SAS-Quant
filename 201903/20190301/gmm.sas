
libname sprd "C:\TEMP\sprd";

%macro bm_cog_reg(data1, data2, neutral, out);

data lhs_sprd; set sprd.&data1;
lhs = retsprd;
keep &neutral portyear lhs;
proc sort; by &neutral portyear;
run;

data rhs_sprd; set sprd.&data2;
rhs = retsprd;
keep &neutral portyear rhs;
proc sort; by &neutral portyear;
run;

data lhs_rhs_sprd; merge lhs_sprd(in=a) rhs_sprd(in=b);
by &neutral portyear;
if a and b;
run;

proc model data=lhs_rhs_sprd;
by &neutral;
exogenous rhs;
parms a b;
lhs=a + b*rhs;
fit lhs / gmm kernel=(bart, %eval(1), 0);
instruments rhs;
ods output parameterestimates=param;
quit;

data &out; set param;
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

ods tagsets.tablesonlylatex file="&out..tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=&out; run; quit;
ods tagsets.tablesonlylatex close;

%mend bm_cog_reg;



dm 'log;clear;';
%let pwd = "C:\TEMP\displace\20190301\regression";
x md &pwd;
x cd &pwd;
libname pwd &pwd;

%bm_cog_reg(bm_world, top33_rhs4_world, world, bm_top33_rhs4_world);
%bm_cog_reg(top33_rhs4_world, bm_world, world, top33_rhs4_bm_world);
%bm_cog_reg(bm_world, benchmark_rhs4_world, world, bm_benchmark_rhs4_world);
%bm_cog_reg(benchmark_rhs4_world, bm_world, world, benchmark_rhs4_bm_world);
/*
%bm_cog_reg(bm_world_vw, combo_world_vw, world, bm_combo_world);
%bm_cog_reg(combo_world_vw, bm_world_vw, world, combo_bm_world);
*/

%bm_cog_reg(bm_country, top33_rhs4_country, country, bm_top33_rhs4_country);
%bm_cog_reg(top33_rhs4_country, bm_country, country, top33_rhs4_bm_country);
%bm_cog_reg(bm_country, benchmark_rhs4_country, country, bm_benchmark_rhs4_country);
%bm_cog_reg(benchmark_rhs4_country, bm_country, country, benchmark_rhs4_bm_country);
