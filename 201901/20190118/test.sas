
libname export "C:\TEMP\export\";
libname import "C:\TEMP\import\";
libname disp "C:\TEMP\displace\";

proc sql;
create table oldnames as 
select distinct code, country from disp.agret0;
quit;


proc sql;
create table us as
select a.*, b.* from tmp1.mthret as a, tmp1.ret2018_us as b
where a.dscd = b.dscd and a.mthyr = b.year
;
quit;



data mthret_xus; set import.mthret;
keep dscd mthyr ri price mthret;
proc sort; by dscd mthyr;
run;


data mthret_us; set import.ret2018_us;
mthyr=year;
proc sort; by dscd mthyr;
run;
data mthret_us; set mthret_us;
by dscd mthyr;
if first.mthyr;
run;
data mthret_us; set mthret_us;
by dscd;
mthret = ri/lag(ri)-1;
price=pi;
if first.dscd then mthret=.;
keep dscd mthyr ri price mthret;
run;
data mthret_us; merge mthret_us(in=a) mthret_xus(in=b);
by dscd mthyr;
if a & ~b;
run;


data mthret_set; set mthret_us mthret_xus;
annee = floor(mthyr/100);
mois = floor(mthyr-annee*100);
proc sort; by dscd mthyr;
run;




data mthret; set mthret_set;
by dscd mthyr; 
portyear = annee;
if mois<=6 then portyear = annee-1;
code = dscd;
ret=mthret;
if ret=0 & lag(ret)=0 then delete;
if (1+ret)*(1+lag(ret))<1.5 and ret>3 or lag(ret)>3 then delete; 
ret_us = ret;
keep code ret ret_us portyear mthyr;
run;
data mthret; retain code mthyr portyear ret ret_us;
set mthret; 
run;

proc sql;
create table mthret2 as
   select a.*, b.country
          from mthret as a, oldnames as b
		  where a.code=b.code;
quit;

data mthret2_us; set mthret2;
if country="US" and mthyr>201306;
run;
data mthret2_xus; set mthret2;
if country~="US" and mthyr>201206;
run;

data export.mthret_us; set mthret2_us; run;
data export.mthret_xus; set mthret2_xus; run;






data annprice; set mthret_set;
if mois=6;
portyear=annee;
code=dscd;
p_us_updated = price;
keep code portyear p_us_updated;
run;
proc sql;
  create table annprice as
   select a.*, b.country
          from annprice as a, oldnames as b
		  where a.code=b.code;
quit;

proc sort data=annprice; by portyear country;
run;
proc univariate data=annprice noprint;
by portyear country;
var p_us_updated;
output out=price p10=p_us_10;
run;

data annprice2; merge annprice price;
by portyear country;
run;

data annprice2; retain code; set annprice2;
proc sort; by code portyear;
run;

data annprice_us; set annprice2;
if country="US" and 2013<=portyear<2018;
run;
data annprice_xus; set annprice2;
if country~="US" and 2012<=portyear<2018;
run;

data export.annprice_us; set annprice_us; run;
data export.annprice_xus; set annprice_xus; run;




data acct_us; set tmp1.annual2018_us;
portyear=year+1;
code = dscd;
drop dscd;
if 2012<=portyear<2018;
run;
proc sql;
create table acct_us as 
select a.*, b.country
 from acct_us as a, oldnames as b
 where a.code=b.code;
quit;
data acct_us; retain code portyear year country;
set acct_us;
run;


proc sql; 
create table acct_xus as
select a.*, b.country
 from tmp1.wsacct2018 as a, oldnames as b
 where a.dscd=b.code and b.country~="US";
quit; 
data acct_xus; retain code portyear year country;
set acct_xus;
portyear=year+1;
code = dscd;
drop dscd;
if 2012<=portyear<2018;
mc=mvus/cequs*ceq;
run;



data mvdec_us2018; set acct_us;
mv=mc;
mv_us=mv;
keep code country year mv mv_us portyear;
run;

data mvdec_xus2018; set acct_xus;
mv=mc;
mv_us=mvus;
keep code country year mv mv_us portyear;
run;

data mvbar; set tmp4.agret0;
proc sort; by country;
proc means data=mvbar;
var mc;
by country;
output out=mcbar_agret0;
run;
data mcbar_agret0; set mcbar_agret0;
mc_agret0 = mc;
drop mc _type_ _freq_;
proc sort data=mcbar_agret0; by country _stat_;
run;

%macro distribute(input, variable, output);

data mvtemp; set &input;
proc sort; by country;
proc means data=mvtemp;
var &variable;
by country;
output out=&output;
run;
data &output; set &output;
&output = &variable;
drop &variable _type_ _freq_;
proc sort data=&output; by country _stat_;
run;

%mend distribute;

%distribute(tmp4.agret0, mc, mc_agret0);
%distribute(mvdec_xus2018 mvdec_us2018, mv, mc_new);
%distribute(tmp4.mvdec, mv_us, mvus_old);
%distribute(mvdec_xus2018 mvdec_us2018, mv_us, mvus_new);


data distribution; merge mc_agret0 mc_new mvus_old mvus_new;
by country _stat_;
mvus_times = mvus_new/mvus_old;
*if 0.01 < mvustimes < 100 then mctimes=.;
if _stat_ ~= "MEAN" then mvus_times=.;
run;



data mvdec1; retain code; set import.mvmonthly2018;
if month(date) = 12;
year=year(date);
portyear=year+1;
code=dscd;
if 2011<=portyear<2018;
keep code year mv portyear;
run;
proc sql;
create table mvdec1 as 
select a.*, b.country
 from mvdec1 as a, oldnames as b
 where a.code=b.code;
quit;


data mvdec1_us; set mvdec1;
if country="US";
mv_us=mv;
run;

data mvdec1_xus; set mvdec1;
if country~="US";
proc sort; by code year;
run;

data exchange; set import.wsacct2018;
if 2011<year<2017;
code=dscd;
keep code year ceq cequs;
proc sort; by code year;
run;

data mvdec1_xus; merge mvdec1_xus(in=a) exchange(in=b);
by code year;
if a & b;
mv_us=cequs/ceq*mv;
drop cequs ceq;
run;

data mvdec_new; set mvdec1_us mvdec1_xus;
drop country;
proc sort; by code year;
run;
/*data mvdec_new; set mvdec_new;
by code year;
if first.year;
run;*/


data export.mvdec_new; set mvdec1; 
mv_us = mv;
drop country;
run;



proc sql;
create table us as
select * from import.annual2018
where dscd not in (select dscd from import.annual2018_us)
;
quit;


data acct_xus; retain code; set import.annual2018;
portyear=year+1;
code=dscd;
if 2012<=portyear<=2017;
drop dscd;
run;
proc sql;
create table acct_xus as 
select a.*, b.country
 from acct_xus as a, oldnames as b
 where a.code=b.code;
quit;

data us; set acct_xus;
if country="US" and portyear>=2013;
run;


data acct_us; retain code; set import.annual2018_us;
portyear=year+1;
code=dscd;
if 2013<=portyear<=2017;
drop dscd;
run;
proc sql;
create table acct_us as 
select a.*, b.country
 from acct_us as a, oldnames as b
 where a.code=b.code;
quit;


data us_check; set acct_us us;
proc sort; by code year;
run;
data us_check; set us_check;
by code year;
if first.year;
run;

data acct_us; set acct_us us;
proc sort; by code year;
run;
data acct_us; set us_check;
by code year;
if first.year;
run;

data acct_xus; set acct_xus;
if country~="US";
proc sort; by code year;
run;
data acct_xus; set acct_xus;
by code year;
if first.year;
run;


data export.acct_us; set acct_us; run;
data export.acct_xus; set acct_xus; run;


data export.agret1_us; merge 
export.mthret_us(in=a) 
export.acct_us(in=b) 
export.annprice_us(in=c);
by code portyear;
if a & b & c;
run;

data export.agret1_xus; merge 
export.mthret_xus(in=a) 
export.acct_xus(in=b) 
export.annprice_xus(in=c);
by code portyear;
if a & b & c;
run;


data wsacct2018; set import.wsacct2018;
code=dscd;
cog=cogs;
keep code year cog;
run;

data export.agret1_us; merge export.agret1_us(in=a) wsacct2018(in=b);
by code year;
if a;
run;

data uscog; set import.uscog;
code = dscd;
cog = uscog;
drop dscd uscog;
proc sort; by code year;
run;
data agret1_us; set export.agret1_us;
drop cog;
proc sort; by code year;
run;
data agret2_us; merge agret1_us(in=a) uscog(in=b);
by code year;
if a;
run;
data export.agret1_us; set agret2_us; run;


data export.agret1_xus; merge export.agret1_xus(in=a) wsacct2018(in=b);
by code year;
if a;
run;


data cogs; set export.agret1_us;
if cog=.;
drop cog;
run;

data cogs; merge cogs(in=a) wsacct2018(in=b);
by code year;
if a;
if cog~=.;
run;
