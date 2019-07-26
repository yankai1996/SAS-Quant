
libname us "V:\data_for_kai\Compustat&CRSP merged\";

data agret1; set us.agret1;
keep code date mthyr ret mc_mth sic;
run;

%ind_ff49 (agret1, agret2, sic, bin_var, ind_code );

data agret2; set agret2;
if ind_code~=. & (ind_code<45 or ind_code>48);
drop bin_:;
proc sort; by mthyr ind_code;
run;

proc sql;
create table agret2 as 
select a.*, b.mc_mth as lagmc_mth 
from agret2 as a, agret2 as b
where a.code=b.code and intck("month", b.date, a.date)=1;
quit;

proc means data=agret2 noprint;
by mthyr ind_code;
var ret;
weight lagmc_mth;
output out=ind_ret mean=ind_ret;
run;


proc sql;
	create table Im as
	select distinct a.ind_code, a.mthyr, exp(sum(log(1+b.ind_ret)))-1 as Im
		from ind_ret as a, ind_ret as b
		where a.ind_code=b.ind_code and 1<=a.mthyr-b.mthyr<=6
		group by a.ind_code, a.mthyr
		having count(b.ind_ret)=6;
quit;

