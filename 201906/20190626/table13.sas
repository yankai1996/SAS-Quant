
libname daily "V:\data_for_kai\Daily data";

%macro rhsdata();

data rhsdata; merge daily.snipo daily.pbsprd;
by country portyear;
snipo=snipo*100;
keep country portyear snipo pbsprd;
run;

%mend;

/*********** MACRO twoDtest ************/
%macro twoDtest(lhsdata, lhs, output);

data testdata; set &lhsdata;
mthyr=portyear;
portyear=floor(mthyr/100);
if mthyr-portyear*100<7 then portyear=portyear-1;
keep country mthyr portyear &lhs;
proc sort; by country portyear;
run;

data testdata; merge testdata(in=a) rhsdata(in=b);
by country portyear;
if a and b;
*if 1989<=portyear;
globe=1;
&lhs=&lhs*100;
proc sort; by mthyr;
run;

%winsor(dsetin=testdata, dsetout=testdata2, byvar=globe, vars=&lhs snipo pbsprd, type=delete, pctl=1 99);


proc means data=testdata2 noprint;
var &lhs snipo pbsprd;
output out=stat&output;
run;
proc transpose data=stat&output out=stat&output;
var &lhs snipo pbsprd;
id _stat_;
run;
data stat&output; set stat&output;
lhs="&lhsdata";
drop _LABEL_;
run;

proc sql;
create table testdata3 as
select country, mthyr, globe, &lhs-avg(&lhs) as &lhs, 
	snipo-avg(snipo) as snipo, pbsprd-avg(pbsprd) as pbsprd
from testdata2
group by mthyr
;
quit;


%MYREG2DSE(&lhs, snipo, country, mthyr, 0, testdata3, myreg1);
%MYREG2DSE(&lhs, pbsprd, country, mthyr, 0, testdata3, myreg2);
%MYREG2DSE(&lhs, snipo pbsprd, country, mthyr, 0, testdata3, myreg3);


data testdata2; set testdata2;
%do year=1981 %to 2018;
year&year=0;
if portyear=&year then year&year=1;
%end;
run;

proc reg data=testdata2 noprint rsquare outest=rsquare;
model &lhs=snipo year:;
model &lhs=pbsprd year:;
model &lhs=snipo pbsprd year:;
quit;

data rsquare; set rsquare;
if _model_="MODEL1" then id=1;
if _model_="MODEL2" then id=2;
if _model_="MODEL3" then id=3;
keep id _RSQ_;
run;


data myreg1; set myreg1; id=1; run;
data myreg2; set myreg2; id=2; run;
data myreg3; set myreg3; id=3; run;

data &output; set myreg:;
lhs="&lhsdata";
if parameter="R-Square" then delete;
run;
data &output; merge &output rsquare;
by id;
run;

%mend twoDtest;


/*
libname pwd "C:\TEMP\displace\20190625";
%onewaytest(country portyear, winsor);*/
%rhsdata();
%twoDtest(ew_sprd, retsprd, output1);
%twoDtest(vw_sprd, retsprd, output2);
%twoDtest(ew_slope, slope, output3);
%twoDtest(vw_slope, slope, output4);


data pwd.table13;
retain id lhs; set output:;
proc sort; by id lhs;
run;

data pwd.stat13; 
retain lhs; set statoutput:;
run;

/*
x cd "C:\TEMP\displace\20190624";
ods tagsets.tablesonlylatex file="finalR.tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=pwd.final4; run; quit;
ods tagsets.tablesonlylatex close;
ods tagsets.tablesonlylatex file="stat.tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=pwd.stat4; run; quit;
ods tagsets.tablesonlylatex close;
*/

