
%let input=tem;
%let neutral=country;
%let timevar=portyear;
%let signal1 = signal1;
%let signal2 = signal2;
%let signal3 = signal3;


proc sort data=&input;
by &neutral &timevar;
run;

proc rank data=&input out=rank;
var &signal1 &signal2 &signal3;
by &neutral &timevar;
ranks r1 r2 r3;

run;

proc means data=rank noprint;
options nolabel; 
by &neutral &timevar;
var r1 r2 r3;
output out=rankmean mean=mu1 mu2 mu3 std=sigma1 sigma2 sigma3 n=n;
run;
data rankmean; set rankmean;
drop _type_ _freq_;
run;

data zscore; merge rank rankmean;
by &neutral &timevar;
z1=(r1-mu1)/sigma1;
z2=(r2-mu2)/sigma2;
z3=(r3-mu3)/sigma3;
z=mean(z1, z2, z3);
zcoal=coalesce(mean(z1, z2, z3), mean(z1,z3), z1);
*drop r1 r2 r3 mu1 mu2 mu3 sigma1 sigma3 sigma2 z1 z2 z3;
if z~=.;
run;

proc sql;
create table diff as 
select code, z, zcoal from zscore
where z <> zcoal
;
quit;


data missing; set tem;
if signal1=. and signal3~=.;
run;
