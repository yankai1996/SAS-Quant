
proc import out=old
	file="V:\data_for_kai\old_pepvgo.csv" 
	dbms=csv replace;
getnames=yes;
run;

data old; set old;
drop mthyr;
proc sort nodup; by country portyear;
run;

data old_new; merge old pvgosprd;
by country portyear;
run;

data junk; set old_new;
if pvgobar2~=. and pvgo2~=.;
proc corr; by country; var pvgobar2 pvgo2;
run;


data junk2; set old_new;
if pebar~=. and pe~=.;
proc corr; by country; var pebar pe;
run;



data pvgosprd; set old_new;
penew=pe;
pe=coalesce(pebar,pe);
pvgo2new=pvgo2;
pvgo2=coalesce(pvgobar2, pvgo2);
run;
