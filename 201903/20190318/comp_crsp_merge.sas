
*libname comp "C:\TEMP\Compustat&CRSP merged";
libname comp "V:\data_for_kai\Compustat&CRSP merged\20190314";

data ccm; set comp.ccm_20190314;
proc sort; by gvkey iid datadate;
run;

data comp; set comp.comp;
proc sort; by gvkey iid datadate;
run;

data ccm1; merge ccm(in=a) comp(in=b);
by gvkey iid datadate;
if a & b;
date=mthyr;
format date YYMMD7. mthyr BEST12.;
mthyr=year(date)*100+month(date);
proc sort; by permno mthyr;
run;


data crsp_p; set comp.crsp_20190314;
mthyr=year(date)*100+month(date);
p_us_updated = abs(PRC);
keep permno HEXCD mthyr shrcd p_us_updated;
proc sort nodup; by permno mthyr;
run;

data ccm2; merge ccm1(in=a) crsp_p(in=b);
by permno mthyr;
if a & b;
if shrcd=10 or shrcd=11;
datamthyr = year(datadate)*100+month(datadate);
proc sort; by permno datamthyr;
run;


data crsp_MC; set comp.crsp_20190314;
datamthyr=year(date)*100+month(date);
MC = abs(PRC)*SHROUT/1000;
keep permno datamthyr MC;
proc sort; by permno datamthyr;
run;

data ccm3; merge ccm2(in=a) crsp_MC(in=b);
by permno datamthyr;
if a;
MC = coalesce(mkvalt, MC);
proc sort; by portyear;
run;


proc univariate data=ccm3 noprint;
by portyear;
var p_us_updated;
output out=p_us_10 p10=p_us_10;
run;

data agret0; retain code mthyr country; 
merge ccm3 p_us_10;
by portyear;
label mthyr=' ';
code = permno;
country="US";
nyse=0;
if HEXCD = 1 then nyse=1;
drop datamthyr date portdate;
proc sort; by code portyear;
run;




data mvdec; set comp.crsp_20190314;
if month(date)=12;
code = permno;
year = year(date);
portyear = year+1;
mv = abs(PRC)*SHROUT/1000;
mv_us = mv;
if mv~=. and mv~=0;
keep code year portyear mv mv_us;
proc sort; by code portyear;
run;


data comp.agret0; set agret0; run;
data comp.mvdec; set mvdec; run;


