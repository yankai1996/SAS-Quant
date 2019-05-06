
proc import out=hkk
	file="V:\data_for_kai\hkk_factors_2010.xls"
	dbms=excel replace;
getnames=yes;
run;

data hkk; retain portyear; set hkk;
if CALMONTH=. then delete;
portyear=CALMONTH;
drop CALMONTH RF;
proc sort; by portyear;
run;


libname sprd "C:\TEMP\displace\20190430";


%macro hkkreg(input, output);

data retsprd; set &input;
keep portyear retsprd country globe;
proc sort; by portyear;
run;

data test; merge retsprd(in=a) hkk(in=b);
by portyear;
if a & b;
run;

proc model data=test;
parms b1 b2 b3; 
exogenous RM_RF F_SRET F_C_P;
*instruments / intonly;
retsprd = alpha + b1*RM_RF + b2*F_SRET + b3*F_C_P;
fit retsprd / gmm kernel=(bart, 7, 0);
ods output parameterestimates=param0;
quit;
data &output; set param0;
if Probt<0.1 then p='*  ';
if Probt<0.05 then p='** ';
if Probt<0.01 then p='***';
Estimate=round(Estimate*100, 0.001);
Estimate=put(Estimate, 12.9);
est=compress(Estimate||p);
keep parameter tValue est;
proc sort; by parameter;
proc transpose out=&output;
by parameter;
var est tValue;
run;

data &output; set &output;
&output=col1;
keep parameter _name_ &output;
proc sort; by parameter _name_;
run;


%mend hkkreg;


%hkkreg(sprd.g_ew_sprd, g_ew);
%hkkreg(sprd.g_vw_sprd, g_vw);
%hkkreg(sprd.cn_ew_sprd, cn_ew);
%hkkreg(sprd.cn_vw_sprd, cn_vw);
%hkkreg(sprd.cn_xus_ew_sprd, cn_xus_ew);
%hkkreg(sprd.cn_xus_vw_sprd, cn_xus_vw);

data table4; merge g_: cn_:;
by parameter _name_;
run;


data pwd.table4; set table4; run;

proc export data=table4
	outfile= "C:\TEMP\displace\20190430\table4.csv"
    dbms=csv replace;
run;
