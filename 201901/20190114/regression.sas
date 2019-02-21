libname import "C:\TEMP\import\";

data bm_world_vw_sprd; set import.bm_world_vw_sprd;
run;
data combo_world_vw_sprd; set import.combo_world_vw_sprd;
run;




%let input1 = bm_world_vw_sprd;
%let input2 = combo_world_vw_sprd;
%let lhs = bm;
%let rhs = combo;

data &input1._temp(rename=(retsprd=&lhs)); set &input1;
keep world portyear retsprd;
proc sort; by portyear; 
run;
data &input2._temp(rename=(retsprd=&rhs)); set &input2;
keep world portyear retsprd;
proc sort; by portyear; 
run;

data &lhs._&rhs; merge &input1._temp &input2._temp;
by portyear;
run;

proc reg data=&lhs._&rhs noprint outest=coef edf;
model &lhs=&rhs;
by world;
run;
data coef; set coef;
slope=&rhs;
keep slope portyear world;
run;

%NWavg(coef, world, 1, &lhs._&rhs._reg);
