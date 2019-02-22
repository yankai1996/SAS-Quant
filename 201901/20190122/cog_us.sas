
libname export "C:\TEMP\export\";
libname import "C:\TEMP\import\";
libname disp "C:\TEMP\displace\";


data agret0_us; set disp.agret0;
if country="US" and mthyr<=201306;
cog_us = cog;
keep code ret ret_us mthyr year portyear country RD MC EMP COG SGA p_us_updated p_us_10;
run;

data agret0_xus; set disp.agret0;
if country~="US" and mthyr<=201206;
keep code ret ret_us mthyr year portyear country RD MC MC_us EMP COG SGA p_us_updated p_us_10;
run;

data agret1_us; set export.agret1_us;
if mthyr>201306;
keep code ret ret_us mthyr year portyear country RD MC EMP COG SGA p_us_updated p_us_10;
run;

data agret1_xus; set export.agret1_xus;
if mthyr>201206;
keep code ret ret_us mthyr year portyear country RD MC EMP COG SGA p_us_updated p_us_10;
run;


data agret0; set agret0_us agret0_xus agret1_us agret1_xus;
run;

data mvdec; set disp.mvdec export.mvdec_new;
proc sort nodup; by code portyear;
run;

data region; set disp.region; run;



/*
data junk; set disp.agret0;
if country~="US" and mthyr<=201206;
if cog~=. and rd~=.;
rate = mc_us/mc;
if rate=. or rate=0 then rate=rd_us/rd;
if rate=. or rate=0 then rate=ta_us/ta;
if rate=. or rate=0 then rate=ta_us_updated/ta_updated;
if rate=. or rate=0 then rate=sl_us/sl;
if rate=0 then rate=.;
if rate=.;
run;
*/

data rate; set disp.agret0;
if country~="US" and mthyr<=201206;
if cog~=. and rd~=.;
rate = mc_us/mc;
if rate=. or rate=0 then rate=rd_us/rd;
if rate=. or rate=0 then rate=ta_us/ta;
if rate=. or rate=0 then rate=ta_us_updated/ta_updated;
if rate=. or rate=0 then rate=sl_us/sl;
if rate=0 then rate=.;
if rate~=.;
keep code mthyr country rate;
proc sort nodup; by mthyr country rate;
run;



%macro zrate(input, neutral, timevar, signal);

%let output=zrate;

data &output; set &input;
proc sort data=&output;
by &neutral &timevar;
run;

proc rank data=&output out=rank;
var &signal;
by &neutral &timevar;
ranks r;
run;

proc means data=rank noprint;
by &neutral &timevar;
var r;
output out=rankmean mean=mu std=sigma n=n;
run;
data rankmean; set rankmean;
drop _type_ _freq_;
run;

data &output; merge rank rankmean;
by &neutral &timevar;
z = (r-mu)/sigma;
drop r mu sigma;
run;

%mend zrate;


%macro ratebar(input, neutral, sort, rate);

%zrate(&input, &neutral, &sort, &rate);

data zrate; set zrate;
zrate=rate;
if abs(z)>=1.5 then zrate=.;
run;

proc means data=zrate noprint;
by &neutral &sort;
var zrate;
output out=ratemean mean=ratebar n=n;
run;
data ratemean; set ratemean;
drop _type_ _freq_;
run;

data ratebar; merge zrate ratemean;
by &neutral &sort;
keep mthyr country ratebar;
proc sort nodup; by mthyr country;
run;

%mend ratebar;

%ratebar(rate, mthyr, country, rate);

data export.rate2010; set ratebar; run;


data agret0; set disp.agret0;
proc sort; by mthyr country;
run;

data agret0; merge agret0 ratebar;
by mthyr country;
COG_US = round(COG*ratebar, 1);
if country="US" then COG_US=COG;
proc sort; by code mthyr;
run;


data disp.agret0; set agret0;
by code mthyr;
if not (first.mthyr & last.mthyr) then do;
	if rd=. or rd=0 then delete;
end;
run;

data disp.agret0; set disp.agret0;
by code mthyr;
if not (first.mthyr & last.mthyr) then do;
	if (iss=. or iss=0) & (lag(iss~=.) & lag(iss)~=0) then delete;
end;
run;

data junk; set disp.agret0;
by code mthyr;
if not (first.mthyr & last.mthyr);
run;

data agret1; set disp.agret0;
proc sort nodup; by code mthyr;
run;



data export.agret1_us; set export.agret1_us;
cog_us = cog;
proc sort; by code mthyr;
run;


data ceq; retain code; set import.wsacct2018;
code = dscd;
keep code year ceq cequs;
proc sort; by code year;
run;

proc sql;
create table ceq as
   select a.*, b.country
          from ceq as a, oldnames as b
		  where a.code=b.code;
quit;

data rate; merge ceq(in=a) export.agret1_xus(in=b);
by code year;
if b;
rate=cequs/ceq;
keep code year country rate;
proc sort nodup; by year country rate;
run;

%ratebar(rate, year, country, rate);


proc sort data=ratebar; by code year;
run;
data agret1_xus; merge export.agret1_xus ratebar;
by code year;
drop rate n z zrate;
COG_US = round(COG*ratebar, 1);
proc sort; by code mthyr;
run;

data export.agret1_xus; set agret1_xus;
drop ratebar;
run;
