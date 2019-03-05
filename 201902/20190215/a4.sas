
libname db "V:\data_for_kai";

data allnames; set agret0; 
keep code;
proc sort nodup; by code;
run;

