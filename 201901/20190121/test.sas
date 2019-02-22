
data numfirms; set zscore;
keep portyear country n;
run;
proc sort nodup;
by portyear country;
run;

proc transpose data=numfirms out=numtrans;
by portyear;
var n;
id country;
run;

data numtrans; 
retain portyear _name_
AR AU
BD BG BN BR
CB CH CL CN CP CY CZ
DK
ES EY
FN FR
GR
HK HN
ID IN IR IS
JP
KN KO
LX
MO MX MY
NL NW NZ
OE 
PE PH PK PO PT
RH RS 
SA SD SW 
TA TH TK
UK US
VE
;
set numtrans;
run;

data export.numbers; set numtrans; run;
