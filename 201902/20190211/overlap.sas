
libname export "C:\TEMP\export";
libname disp "C:\TEMP\displace";
libname dsws "C:\TEMP\new DSWS";

%macro overlap(input1, input2, byvars, output);

data &input1; set &input1;
keep &byvars old;
old=1;
proc sort; by &byvars;
run;
data &input2; set &input2;
keep &byvars new;
new=1;
proc sort; by &byvars;
run;

data &output; merge &input1 &input2;
by &byvars;
run;

%mend overlap;


data old; set disp.agret0 export.agret1_us export.agret1_xus;
keep code mthyr country;
run;

data new; set dsws.agret0;
keep code mthyr country;
run;



data AB_names; set old;
if mthyr <= 201206;
keep code;
proc sort nodup; by code;
run;

data BC_names; set new;
if mthyr <= 201206;
keep code;
proc sort nodup; by code;
run;

%overlap(AB_names, BC_names, code, ABC_names);
data ABC_names; set ABC_names;
AB = old;
BC = new;
if AB & BC then B = 1;
drop old new;
proc means; output out=ABC_names_stat;
run;

data ABC_names_stat; set ABC_names_stat;
A = AB-B;
C = BC-B;
drop _freq_ _type_ AB BC;
if _stat_ = "N";
run;



data DE_names; set old;
if mthyr > 201206;
keep code;
proc sort nodup; by code;
run;

data EF_names; set new;
if mthyr > 201206;
keep code;
proc sort nodup; by code;
run;

%overlap(DE_names, EF_names, code, DEF_names);
data DEF_names; set DEF_names;
DE = old;
EF = new;
if DE & EF then E = 1;
drop old new;
proc means; output out=DEF_names_stat;
run;

data DEF_names_stat; set DEF_names_stat;
D = DE-E;
F = EF-E;
drop _freq_ _type_ DE EF;
if _stat_ = "N";
run;

data names_stat; retain _stat_ A B C D E ;
merge ABC_names_stat DEF_names_stat;
by _stat_;
_stat_ = "names";
run;


data AB_obs; set old;
if mthyr <= 201206;
proc sort nodup; by code mthyr;
run;

data BC_obs; set new;
if mthyr <= 201206;
proc sort nodup; by code mthyr;
run;

%overlap(AB_obs, BC_obs, code mthyr, ABC_obs);
data ABC_obs; set ABC_obs;
AB = old;
BC = new;
if AB & BC then B = 1;
drop old new;
proc means; output out=ABC_obs_stat;
run;

data ABC_obs_stat; set ABC_obs_stat;
A = AB-B;
C = BC-B;
drop _freq_ _type_ AB BC;
if _stat_ = "N";
run;




data DE_obs; set old;
if mthyr > 201206;
proc sort nodup; by code mthyr;
run;

data EF_obs; set new;
if mthyr > 201206;
proc sort nodup; by code mthyr;
run;

%overlap(DE_obs, EF_obs, code mthyr, DEF_obs);
data DEF_obs; set DEF_obs;
DE = old;
EF = new;
if DE & EF then E = 1;
drop old new;
proc means; output out=DEF_obs_stat;
run;

data DEF_obs_stat; set DEF_obs_stat;
D = DE-E;
F = EF-E;
drop _freq_ _type_ DE EF;
if _stat_ = "N";
run;

data obs_stat; retain _stat_ A B C D E ;
merge ABC_obs_stat DEF_obs_stat;
by _stat_;
drop mthyr;
_stat_ = "obs";
run;


data disp.stat; set names_stat obs_stat;
run;

x cd "C:\TEMP";
ods tagsets.tablesonlylatex file="stat.tex"   (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=disp.STAT; run; quit;
ods tagsets.tablesonlylatex close;
