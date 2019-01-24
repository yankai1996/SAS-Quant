data practice;
set sashelp.cars;
keep make model type msrp horsepower length;
run;

proc sort; by type length;

proc rank data=practice group=2 out=practice;
var msrp; by type length; ranks r;
run;

data practice; set practice; r=r+1; weight=1;
proc sort; by length type r;
run;

proc means data=practice noprint; 
by length type r;
var msrp horsepower; weight weight;
output out=msrp1 mean=msrp horsepower;
run;

data low; set msrp1; if r in (1);
lowPrice=msrp; lowHorsepower=horsepower;
keep type length lowPrice lowHorsepower;
proc sort; by type length;

data high; set msrp1; if r in (2);
highPrice=msrp; highHorsepower=horsepower;
keep type length highPrice highHorsepower;
proc sort; by type length;
run;

data cars3; merge low high;
by type length;
dprice = highPrice - lowPrice;
dHorsepower = highHorsepower - lowHorsePower;
ratio = (dHorsepower / lowHorsepower) / (dprice / lowPrice);
if (ratio~=.);
keep type length dprice dHorsepower ratio;
format dprice dollar8.;
run;
