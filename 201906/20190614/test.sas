
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
&lhs=&lhs*100;
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



%macro tstat(tmp, pre);

%do i=1 %to 2;
	%do j=1 %to 3;
		%do k=2 %to 2;
			%do l=1 %to 4;
				%let id=&pre&i&j&k&l;
				data out&i&j&k&l; set &tmp..out&id;
				if mthyr>=198907;
				id=&id;
				run;
			%end;
		%end;
	%end;
%end;

data out0; set out1: out2:; 
proc sort; by id _name_;
run;

proc model data=out0;
by id _name_;
parms parmsbar; exogenous parms;
instruments / intonly;
parms = parmsbar;
/* fit rhssprd retsprd stdsprd slope / gmm kernel=(bart, %eval(2), 0); */
fit parms / gmm kernel=(bart, %eval(13), 0);
ods output parameterestimates=tout&pre;
quit;

%mend;

%tstat(tmp1, 1);
%tstat(tmp1, 2);
%tstat(tmp1, 3);

data pwd.bivar1989_12; set tout:;
if id-floor(id/10)*10=1 then lhs="ew_sprd";
else if id-floor(id/10)*10=2 then lhs="vw_sprd";
else if id-floor(id/10)*10=3 then lhs="ew_slope";
else if id-floor(id/10)*10=4 then lhs="vw_slope";
proc sort; by id; 
run;
