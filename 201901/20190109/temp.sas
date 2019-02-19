proc means data=agret0;
var mthyr;
run;

data agret1; set agret0;
bm4 = be4/mc;
if bm4~=.;
run;
proc means data=agret1;
var mthyr;
run;

data agret2; set agret0;
if mthyr > 201006;
keep code country mthyr rd be4 mc;
run;
