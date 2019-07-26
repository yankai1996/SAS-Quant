
data agret1; set us.agret1;
proc sort; by gvkey fyearQ FQTR; 
run;

libname pwd "C:\TEMP\displace\20190722";

data rdq; set pwd.rdq;
keep gvkey fyearQ FQTR RDQ;
proc sort; by gvkey fyearQ FQTR;
run;

data agret1; merge agret1(in=a) rdq;
by gvkey fyearQ FQTR;
if a;
proc sort; by code mthyr;
run;

