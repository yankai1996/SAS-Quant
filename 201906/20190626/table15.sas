
libname bk "V:\data_for_kai\pvgo_pe_bk";

*%macro pvgo_pe(high1, low1, high2, low2);
%macro rhsdata();

data pe_old; set bk.old_pe_bk;
pe_old=dec75-dec25;
keep country portyear pe_old;
run;

data pe_new; set bk.new_pe_bk;
pe_new=dec75-dec25;
keep country portyear pe_new;
proc sort; by country portyear;
run;

data pe; merge pe_old pe_new;
by country portyear;
pe=coalesce(pe_old, pe_new);
run;

data rhsdata; merge pe daily.short daily.irisk daily.dvol daily.snipo daily.pbsprd;
by country portyear;
dvol=log(coalesce(dvol_old, dvol_sum)/1000);
irisk=irisk*100;
snipo=snipo*100;
keep country portyear pe short irisk dvol snipo pbsprd;
run;

%mend pvgo_pe;



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

%winsor(dsetin=testdata, dsetout=testdata2, byvar=portyear, vars=&lhs, type=delete, pctl=10 90);
data testdata2; set testdata2;
keep mthyr portyear country &lhs;
proc sort; by mthyr country;
run;
proc sort data=testdata; by country; run;
%winsor(dsetin=testdata, dsetout=testdata3, byvar=country, vars=pe, type=winsor, pctl=10 90);
data testdata3; set testdata3;
keep mthyr country pe;
proc sort; by mthyr country;
run;
%winsor(dsetin=testdata, dsetout=testdata4, byvar=globe, vars=short irisk dvol snipo pbsprd, type=delete, pctl=1 99);
data testdata4; set testdata4;
keep mthyr country short irisk dvol snipo pbsprd;
proc sort; by mthyr country;
run;

data testdata5; merge testdata2(in=a) testdata3 testdata4;
by mthyr country;
if a;
globe=1;
run;

proc means data=testdata5 noprint;
var &lhs pe short irisk dvol snipo pbsprd;
output out=stat&output;
run;
proc transpose data=stat&output out=stat&output;
var &lhs pe short irisk dvol snipo pbsprd;
id _stat_;
run;
data stat&output; set stat&output;
lhs="&lhsdata";
drop _LABEL_;
run;

proc sql;
create table testdata6 as
select country, mthyr, globe, &lhs-avg(&lhs) as &lhs, 
	pe-avg(pe) as pe, short-avg(short) as short, 
	irisk-avg(irisk) as irisk, dvol-avg(dvol) as dvol, 
	snipo-avg(snipo) as snipo, pbsprd-avg(pbsprd) as pbsprd 
from testdata5
group by mthyr
;
quit;


%MYREG2DSE(&lhs, pe short, country, mthyr, 0, testdata6, myreg1);
%MYREG2DSE(&lhs, pe irisk, country, mthyr, 0, testdata6, myreg2);
%MYREG2DSE(&lhs, pe dvol, country, mthyr, 0, testdata6, myreg3);
%MYREG2DSE(&lhs, pe snipo, country, mthyr, 0, testdata6, myreg4);
%MYREG2DSE(&lhs, pe pbsprd, country, mthyr, 0, testdata6, myreg5);
%MYREG2DSE(&lhs, pe short irisk dvol snipo pbsprd, country, mthyr, 0, testdata6, myreg6);


data testdata5; set testdata5;
%do year=1981 %to 2018;
year&year=0;
if portyear=&year then year&year=1;
%end;
run;

proc reg data=testdata5 noprint rsquare outest=rsquare;
model &lhs=pe short year:;
model &lhs=pe irisk year:;
model &lhs=pe dvol year:;
model &lhs=pe snipo year:;
model &lhs=pe pbsprd year:;
model &lhs=pe short irisk dvol snipo pbsprd year:;
quit;

data rsquare; set rsquare;
%do i=1 %to 6;
if _model_="MODEL&i" then id=&i;
%end;
keep id _RSQ_;
run;

%do i=1 %to 6;
data myreg&i; set myreg&i; id=&i; run;
%end;

data &output; set myreg:;
lhs="&lhsdata";
if parameter="R-Square" then delete;
run;
data &output; merge &output rsquare;
by id;
run;

%mend twoDtest;


/*
libname pwd "C:\TEMP\displace\20190626";
%onewaytest(country portyear, winsor);*/
%rhsdata();
%twoDtest(ew_sprd, retsprd, output1);
%twoDtest(vw_sprd, retsprd, output2);
%twoDtest(ew_slope, slope, output3);
%twoDtest(vw_slope, slope, output4);


data pwd.table15;
retain id lhs; set output:;
proc sort; by id lhs;
run;

data pwd.stat15; 
retain lhs; set statoutput:;
run;

/*
x cd "C:\TEMP\displace\20190626";
%let j=12;
ods tagsets.tablesonlylatex file="table&j..tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=pwd.table&j; run; quit;
ods tagsets.tablesonlylatex close;
ods tagsets.tablesonlylatex file="stat&j..tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=pwd.stat&j; run; quit;
ods tagsets.tablesonlylatex close;
*/

