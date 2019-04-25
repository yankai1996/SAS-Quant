
data junk; set all_lc;
if country="US" & portyear=1992;
run;

data junk2; set all_lc;
keep dscd country portyear;
proc sort nodup; by country portyear;
run;

data junk3; set junk2;
if country="US";
proc means; by portyear;
run;


data junk4; set test;
if country="US";
run;

data junkus; set daily.all_lc;
if country="US";
run;


data test1; set all_lc;
code=dscd;
country1=country;
keep code portyear date ret;
if ret~=.;
proc sort; by code portyear;
run;

data test1; merge test1(in=a) mvdec(in=b);
by code portyear;
if a & b;
if mv~=.;
run;

data junk5; set test1;
if country="US";
run;

data junk6; set all_lc;
if dscd=130610;
run;

data junk7; set nnnDS.acct;
if dscd=130610;
run;

data junk8; set daily.sg_tdvol_usd;
if dscd=130610;
run;
