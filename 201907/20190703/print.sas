
*libname pwd "C:\TEMP\displace\201906\20190626";


data junk; set pwd.table15;
if lhs="ew_sprd" then id1=1;
else if lhs="vw_sprd" then id1=2;
else if lhs="ew_slop" then id1=3;
else id1=4;
estimates=round(estimates,.001);
tstat=round(tstat,.001);
_RSQ_=round(_RSQ_,.001);
drop stderr;
proc sort; by id1 id;
proc print;
run;






%macro ewvw(input, lhs);

data &input; set &input;
&input=&lhs;
keep country portyear &input;
run;

%mend ewvw;

%ewvw(ew_slope, slope);
%ewvw(ew_sprd, retsprd);
%ewvw(vw_slope, slope);
%ewvw(vw_sprd, retsprd);

data lhs; merge ew_: vw_:;
by country portyear;
proc means noprint; by country;
output out=lhs_stat;
run;

data lhs_stat; set lhs_stat;
retain country ew_sprd vw_sprd ew_slope vw_slope;
if _stat_="MEAN";/*
ew_sprd=round(ew_sprd*100, 0.001);
vw_sprd=round(vw_sprd*100, 0.001);
ew_slope=round(ew_slope*100, 0.001);
vw_slope=round(vw_slope*100, 0.001);*/
keep country ew_sprd vw_sprd ew_slope vw_slope;
proc print;
run;


data rhsdata; merge rhsdata1 rhsdata;
by country portyear;
proc means noprint; by country;
output out=rhs_stat;
run;
data rhs_stat; set rhs_stat;
if _stat_="MEAN";
drop portyear _freq_ _type_ _stat_;
run;

data stat; merge lhs_stat(in=a) rhs_stat;
by country;
if a;
run;



data lhs; set lhs;
mthyr=portyear;
portyear=floor(mthyr/100);
if mthyr-portyear*100<7 then portyear=portyear-1;
run;


data corr; merge lhs(in=a) rhsdata;
by country portyear;
if a;
drop country portyear mthyr;
ods exclude all;
proc corr;
ods output PearsonCorr=P;
run;
ods exclude none;
