
%macro twoDtest(lhsdata, lhs, rhs, wstype, wsby, output);

data testdata; set &lhsdata;
mthyr=portyear;
*if mthyr<201707;
portyear=floor(mthyr/100);
if mthyr-portyear*100<7 then portyear=portyear-1;
keep country mthyr portyear &lhs;
proc sort; by country portyear;
run;

data testdata; merge testdata(in=a) pvgo_pe(in=b);
by country portyear;
if a and b;
globe=1;
*pe=pe/100;
*if -3<&lhs<3;
proc sort; by mthyr;
run;

%winsor(dsetin=testdata, dsetout=testdata2, byvar=&wsby, vars=&lhs &rhs, type=&wstype, pctl=1 99);

proc sql;
create table testdata3 as
select country, mthyr, globe, &lhs-avg(&lhs) as &lhs, 
	pvgo2-avg(pvgo2) as pvgo2, pe-avg(pe) as pe 
from testdata2
group by mthyr
;
quit;


%MYREG2DSE(&lhs, &rhs, country, mthyr, 0, testdata3, &output);

data &output; set &output;
lhs="&lhsdata";
run;

%mend twoDtest;




data testdata4; set testdata2;
if portyear>=1981;
proc sort; by mthyr;
run;

proc reg data=testdata4 noprint; by mthyr;
model slope=pe;
output parameterestimates=junk1;
run;
