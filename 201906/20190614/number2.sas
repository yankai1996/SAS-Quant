
data agret2; set agret1;
n=1;
if country in ("AU", "BD", "CH", "CN", "FN", "FR", "GR", "HK", "IN", "IS", 
"IT", "JP", "KO", "MY","SD", "SG", "SW", "TA", "TK", "UK", "US");
keep country mthyr code n;
proc sort; by mthyr country;
proc means noprint; by mthyr country;
output out=number n=n;
run;

proc transpose data=number out=number;
by mthyr;
var n;
id country;
run;

data pwd.agret1number; set number; run;
