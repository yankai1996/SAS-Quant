
%pvgosprd(ag21, pvgosprd, 25);

data pvgosprd; set pvgosprd;
if 5<pe<40;
run;

%rhstest(pe, delete, country, 0003);
%rhstest(pvgo2, delete, country, 0004);


libname sprd "C:\TEMP\displace\201904\20190408\4k-obs\winsor1-portyear";
libname sprd "C:\TEMP\displace\20190527\4k-obs\winsor1-portyear";


/*********** MACRO twoDtest ************/
%macro twoDtest(lhsdata, lhs, rhs, wstype, wsby, output);

data testdata; set sprd.country_&lhsdata;
mthyr=portyear;
*if mthyr<201707;
portyear=floor(mthyr/100);
if mthyr-portyear*100<7 then portyear=portyear-1;
keep country mthyr portyear &lhs;
proc sort; by country portyear;
run;

data testdata; merge testdata(in=a) pvgosprd(in=b);
by country portyear;
if a and b;
globe=1;
pe=pe/100;
*if -1<&lhs<1;
proc sort; by mthyr;
run;

%winsor(dsetin=testdata, dsetout=testdata2, byvar=&wsby, vars=&lhs &rhs, type=&wstype, pctl=1 99);

proc sql;
create table testdata3 as
select country, mthyr, globe, &lhs-avg(&lhs) as &lhs, pvgo1-avg(pvgo1) as pvgo1, 
	pvgo2-avg(pvgo2) as pvgo2, pvgo3-avg(pvgo3) as pvgo3, pe-avg(pe) as pe 
from testdata2
group by mthyr
;
quit;


%MYREG2DSE(&lhs, &rhs, country, mthyr, 0, testdata3, &output);

data &output; set &output;
lhs="&lhsdata";
run;

%mend twoDtest;


%macro rhstest(rhs, wstype, wsby, ijkl);

%twoDtest(ew_sprd, retsprd, &rhs, &wstype, &wsby, tout1);
%twoDtest(vw_sprd, retsprd, &rhs, &wstype, &wsby, tout2);
%twoDtest(ew_slope, slope, &rhs, &wstype, &wsby, tout3);
%twoDtest(vw_slope, slope, &rhs, &wstype, &wsby, tout4);

data output&ijkl; set tout:;
id=&ijkl;
range=25;
type="&wstype";
by="&wsby";
run;

%mend rhstest;


dm "log;clear;";
%rhstest(pe, delete, country, 0000);


proc univariate data=testdata3; var pe; run;



data out2; set output0002;
drop id range type by;
run;


x cd "C:\TEMP\displace\20190528";
ods tagsets.tablesonlylatex file="out2.tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=out2; run; quit;
ods tagsets.tablesonlylatex close;
