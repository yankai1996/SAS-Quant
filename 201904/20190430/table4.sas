
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


%macro hkkreg(input, output, firm);

data retsprd; set &input;
keep portyear retsprd country globe;
proc sort; by portyear;
run;

data test; merge retsprd(in=a) hkk(in=b);
by portyear;
if a & b;
run;

proc reg data=test outest=regout tableout noprint;
model retsprd=RM_RF F_SRET F_C_P;
quit;

data regout; set regout;
if _TYPE_ in ("PARMS", "T", "PVALUE");
keep _TYPE_ intercept RM_RF F_SRET F_C_P;
run;

proc transpose data=regout out=&output; 
var intercept RM_RF F_SRET F_C_P;
id _TYPE_;
run;

data &output; set &output;
if PVALUE<0.1 then p='*  ';
if PVALUE<0.05 then p='** ';
if PVALUE<0.01 then p='***';
PARMS=round(PARMS*100, 0.001);
PARMS=put(PARMS, 12.9);
est=compress(PARMS||p);
factor=_name_;
keep factor t est;
proc sort; by factor;
proc transpose out=&output;
by factor;
var est t;
run;

data &output; set &output;
&output=col1;
drop col1;
proc sort; by factor _name_;
run;

%mend hkkreg;


%hkkreg(sprd.g_ew_sprd, g_ew, globe);
%hkkreg(sprd.g_vw_sprd, g_vw, globe);
%hkkreg(sprd.cn_ew_sprd, cn_ew, country);
%hkkreg(sprd.cn_vw_sprd, cn_vw, country);
%hkkreg(sprd.cn_xus_ew_sprd, cn_xus_ew, country);
%hkkreg(sprd.cn_xus_vw_sprd, cn_xus_vw, country);

data table4; merge g_: cn_:;
by factor _name_;
proc sort; by factor descending _name_;
run;


data pwd.table4; set table4; run;

proc export data=table4
	outfile= "C:\TEMP\displace\20190430\table4.csv"
    dbms=csv replace;
run;
