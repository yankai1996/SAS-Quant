
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

proc reg data=testdata4 noprint tableout outest=est;
by mthyr;
model slope=pe / noint;
quit;

proc transpose out=est1; by mthyr;
var pe;
id _type_;
run;



%macro mthreg(lhsdata, lhs, rhs, wstype, wsby, output);

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


data testdata4; set testdata2;
if portyear>=1981;
proc sort; by mthyr;
run;

proc reg data=testdata4 noprint tableout outest=est;
by mthyr;
model &lhs=&rhs / noint;
quit;

proc transpose out=&output; by mthyr;
var &rhs;
id _type_;
run;

data pwd.&output; set &output;
lhs="&lhsdata";
type="&wstype";
by="&wsby";
run;

%mend mthreg;


%macro mthtest(rhs, wstype, wsby, ijkl);

%mthreg(ew_sprd, retsprd, &rhs, &wstype, &wsby, out&ijkl.1);
%mthreg(vw_sprd, retsprd, &rhs, &wstype, &wsby, out&ijkl.2);
%mthreg(ew_slope, slope, &rhs, &wstype, &wsby, out&ijkl.3);
%mthreg(vw_slope, slope, &rhs, &wstype, &wsby, out&ijkl.4);

%mend rhstest;


data junk; set bk.new_pe_bk;
sprd90=dec90-dec10;
sprd80=dec80-dec20;
sprd75=dec75-dec25;
keep sprd:;
proc univariate; run;

data junk2; set bk.new_pe2_bk;
sprd90=dec90-dec10;
sprd80=dec80-dec20;
sprd75=dec75-dec25;
keep sprd:;
proc univariate; run;
