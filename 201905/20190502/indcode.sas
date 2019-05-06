
proc sort data=agret1; by code; run;

data indcode; set db.indcode;
keep code indc:;
proc sort; by code;
run;

data siccode; set db.siccode;
keep code ic:;
proc sort; by code;
run;

data junk1; merge agret1(in=a) indcode(in=b);
by code;
if a & b;
run;

data junk2; merge junk1(in=a) siccode(in=b);
by code;
if a & b;
run;
