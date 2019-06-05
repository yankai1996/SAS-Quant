/* use monthly return to generate annual return;
then require each firm to have at least 6 months non missing for a portyear */

proc sql;
	create table retmonthly5 as
	select a.*, b.country
	from retmonthly5 as a
	left join oldnames as b on a.code=b.code;
quit;

/* log transformation */
data logret; set retmonthly5;
by code mno;
ret = log(1+ret);
ret_us = log(1+ret_us);
if ret>-1 and ret<=10; 		/* throw away extreme returns */
/*if portyear le 2009; /* this is to exclude 2009 requiring returns between 1/2011-6/2011 (not available)*/
keep code date mthyr country ret ret_us portyear;
run;

proc sort data=logret;
by portyear code country;
/* find annual returns, and screen if half a year is missing */
proc means data=logret noprint; var ret ret_us;
by portyear code country;
output out=aret sum=ret ret_us n=n1 n2;
run;
data retannual; set aret;
ret1y=exp(ret)-1;
ret1y_us=exp(ret_us)-1;
if n1 ge 6;
/*if portyear le 2009; /* this is to exclude 2009 requiring returns between 1/2011-6/2011 (not available)*/
keep code country portyear ret1y ret1y_us n1 n2;
proc sort; by code portyear;
run;


/*  now need to add all control variables here */









proc sort data=ag; by code portyear;
/* data agret0; merge ipp.retannual(in=a) ag(in=b) ipp.momret(in=c) ipp.juneret(in=d); */
data agret0; merge retannual(in=a) ag(in=b) ipp.momret(in=c) ipp.juneret(in=d);
by code portyear;
if country='US' then ret1y_us=ret1y;
if a and b;
/*keep code country ctyid portyear ta rhs rdme rdme2 rdme3 rdta rdta2 rdta3 rdbe11 rdbe12 rdbe13 rdbe14 rdbe21 rdbe22 rdbe23 rdbe24 rdbe31 rdbe32 rdbe33 rdbe34 cm mc sl ag rd rdc ia ia2 slaga roe roa dte maba tobinq capex lev cfa mpk pvgo1 pvgo2 pvgo3 pvgo4 pvgo5 calret1y calret1y_us opm myroa myroe sg sa empg momen sigma sigma_us ret1y ret1y_us ret2y ret2y_us ret3y ret3y_us ret1m ret1m_us ret1to2y ret1to2y_us ret2to3y ret2to3y_us mv mv_us mvport indcode indbin1-indbin48 ftag3-ftag5; */
keep code country ctyid portyear ta rd: cm mc sl ag rd rdc ia ia2 slaga roe roa lev cfa mpk calret1y calret1y_us opm myroa myroe myroe2 sg sa empg momen sigma sigma_us ret1y ret1y_us ret2y ret2y_us ret3y ret3y_us ret1m ret1m_us ret1to2y ret1to2y_us ret2to3y ret2to3y_us mv mv_us mvport indcode indbin1-indbin48 ftag3-ftag5 pf1 pf2 be:;
proc sort; by code portyear;
run;




data agret1; merge agret0(in=a) mois.mvjune(in=b);
by code portyear;
if a and b;
if mv ne .;
run;
/* scale within a country */
proc sort data=agret1;
by country portyear;
run;
proc means data=agret1 noprint; by country portyear;
var mv; output out=meanmv mean=mvbar sum=mvsum n=n;
run;




option notes;


data agret; merge agret1(in=a) meanmv(in=b);
by country portyear;
if a and b;
ew = 1;
mvport = mv/mvbar;
/* mvport = mv/mvsum; */
drop _type_ _freq_;
run;

proc sort; by code;
run;


data table3aug; merge db.siccode(in=a) db.indcode(in=b) agret(in=c);
by code;
if c;
/* keep code country ctyid portyear ta rhs rdme rdme2 rdme3 rdta rdta2 rdta3 rdbe11 rdbe12 rdbe13 rdbe21 rdbe22 rdbe23 rdbe31 rdbe32 rdbe33 cm mc sl ag rd rdc ia ia2 slaga roe roa dte maba tobinq capex lev cfa mpk pvgo1 pvgo2 pvgo3 pvgo4 pvgo5 calret1y calret1y_us opm myroa myroe sg sa empg momen sigma sigma_us ret1y ret1y_us ret2y ret2y_us ret3y ret3y_us ret1m ret1m_us ret1to2y ret1to2y_us ret2to3y ret2to3y_us mv mv_us mvport indcode indbin1-indbin48 ftag3-ftag5; */
keep code country ctyid portyear ta rd: cm mc sl ag rd rdc ia ia2 slaga roe roa lev cfa mpk calret1y calret1y_us opm myroa myroe myroe2 sg sa empg momen sigma sigma_us ret1y ret1y_us ret2y ret2y_us ret3y ret3y_us ret1m ret1m_us ret1to2y ret1to2y_us ret2to3y ret2to3y_us mv mv_us mvport indcode indbin1-indbin48 ftag3-ftag5 pf1 pf2 be:;
run;

/* level return monthly return variance ipp.volout generated from mth_reg_gen */
/* log return monthly return variance are sigma and sigma_us already */

proc sort data=table3aug; by code portyear;
run;


data db.table3aug_20190501; merge table3aug(in=a) prmonthly db.volout_20190501;
by code portyear;
if a;
run;


proc export data= db.table3aug_20190501
                outfile= "d:\data_for_kai\table3aug_20190501.csv"
            dbms=csv replace;
     /*range="rhs2"; */
run;








option notes;



/* ==================================== */
/*--- TABLE 1: RD median and std dev ---*/
/* ==================================== */

/* annual summaries of No obs*/

proc sort data=agret1;
by code country;
run;
proc means data=agret1 noprint; by code country;
var ret1y; output out=tem1 sum=sig n=n1;
run;
proc sort; by country;
run;
proc means data=tem1 noprint; by country;
var n1; output out=tem2 sum=sig1 n=n2;
run;
proc sort; by country;
run;
data tem2; set tem2;
keep country sig1;
run;



/* annual summaries of No firms*/

proc sort data=agret1;
by portyear country;
run;
proc means noprint; by portyear country;
var ret1y; output out=tem3 sum=sig n=n1;
run;
proc sort; by country;
run;
proc means data=tem3 noprint; by country;
var n1; output out=tem4 mean=sig2 n=n2;
run;
proc sort; by country;
run;
data tem4; set tem4;
keep country sig2;
run;





/* annual (Dec) total market value in USD */
proc sort data=agret1; by portyear country;
run;
proc means data=agret1 noprint; by portyear country;
var mv_us; output out=tem6 sum=sig n=n1;
run;
proc sort; by country;
run;
proc means data=tem6 noprint; by country;
var sig; output out=tem7 mean=sig3 n=n2;
run;
proc sort; by country;
run;
data tem7; set tem7;
keep country sig3;
/*if country="BR" then sig3=sig3/1000;*/
run;



data agret2; set agret;
/*if portyear>=1985; 
if rdbe31>=0; */
if rdbe31>0;
if portyear<=2011; 
run;
%winsor(dsetin=agret2, dsetout=agret3, byvar=country, vars=rdbe31, type=winsor, pctl=1 99);
proc sort data=agret3; by country;
run;
proc means data=agret3 noprint; by country;
var rdbe31; output out=tem8 mean=moyen std=sigma n=n1;
run;
proc sort; by country;
run;
data tem8; set tem8;
keep country moyen sigma;
run;
data tem8; merge intag.countrylist_region tem8;
by country;
proc sort; by country_name;
run;
%winsor(dsetin=agret2, dsetout=agret4, byvar=portyear, vars=rdbe31, type=winsor, pctl=1 99);
proc means data=agret4 noprint;
var rdbe31; output out=tem81 mean=moyen std=sigma n=n1;
run;


data agret5; set agret4;
if country~="US";
proc means data=agret5 noprint;
var rdbe31; output out=tem82 mean=moyen std=sigma n=n1;
run;
data tem8; set tem8 tem81 tem82;





proc sort data=retmonthly5;
by country;
proc means noprint; by country;
var mthyr; output out=tem9 max=maxmth min=minmth n=n1;
run;
proc sort; by country;
run;
data tem9; set tem9;
keep country minmth;
run;

proc sort data=tem8;
by country;
data tem10; merge tem9 tem2 tem4 tem7 tem8;
by country;
run;
proc sort data=	intag.countrylist_region;
by country;
run;
data tem11; merge intag.countrylist_region tem10;
by country;
if country="RS" then country_name="Russia";
if country~="BN";
if country~="CP";
if country~="EY";
if country~="RH";
if moyen~=.;
drop region;
run;

proc means data=tem11 noprint;
var sig1 sig2 sig3; output out=tem12 sum=sum1 sum2 sum3;
run;
proc sql;
	create table tem13 as
	select a.*, a.sig1/b.sum1 as ratio1, a.sig2/b.sum2 as ratio2, a.sig3/b.sum3 as ratio3, b.*
	from tem11 as a, tem12 as b;
quit;





proc sort;
by country_name;
run;


proc export data= tem13
/*                outfile= "o:\projects\ipp\table1_20150714.csv"*/
                outfile= "o:\projects\ipp\table1_20160324.csv"
            dbms=csv replace;
     /*range="rhs2"; */
run;







