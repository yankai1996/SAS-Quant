

/*
data junk; set testdata3;
if slope*pe<0;
portyear=floor(mthyr/100);
if mthyr-portyear*100<7 then portyear=portyear-1;
proc sort; by portyear;
run;

proc means; by portyear; run;
*/


proc reg data=testdata3 noprint tableout outest=est;
by mthyr;
model slope=pe / noint;
quit;
proc transpose data=est out=est; by mthyr;
var pe;
id _type_;
run;

data junk2; set est;
if mthyr<199107;
proc means; run;


data testdata4; set testdata3; 
proc sort; by country;
run;
proc reg data=testdata4 tableout outest=est2;
by country;
model slope=pe / noint;
quit;
proc transpose data=est2 out=est2; by country;
var pe;
id _type_;
run;
