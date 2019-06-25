

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
if portyear>=1987;
proc sort; by mthyr;
run;

proc reg data=testdata4 noprint tableout outest=est;
by mthyr;
model &lhs=&rhs;
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





%macro tstat(tmp, pre);

%do i=1 %to 2;
	%do j=1 %to 3;
		%do k=1 %to 1;
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
fit parms / gmm kernel=(bart, %eval(2), 0);
ods output parameterestimates=tout&pre;
quit;

%mend;

%tstat(pwd, 1);
%tstat(pwd, 2);
%tstat(pwd, 3);

data pwd.pe_1989_1; set tout:;
if id=. then delete;
if id-floor(id/10)*10=1 then lhs="ew_sprd";
else if id-floor(id/10)*10=2 then lhs="vw_sprd";
else if id-floor(id/10)*10=3 then lhs="ew_slope";
else if id-floor(id/10)*10=4 then lhs="vw_slope";
proc sort; by id; 
run;





data junk; set pvgo_pe;
if country in ("AU", "BD", "CH", "CN", "FN", "FR", "GR", "HK", "IN", "IS", 
"IT", "JP", "KO", "MY","SD", "SG", "SW", "TA", "TK", "UK", "US");
run;
proc univariate; var pe; run;
