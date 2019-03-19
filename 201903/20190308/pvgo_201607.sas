




data ag21; set ag20;
if pvgo2<100;
if pvgo2>-5;
keep country portyear pvgo1 pvgo2 pvgo3 pvgo4 pvgo5;
run;

proc sort; by country portyear;


proc univariate data=ag21 noprint;
by country portyear;
var pvgo2;
output out=breakpoint2 pctlpre=dec pctlpts=0 to 100 by 5;
run;

data tem; set breakpoint2;
pvgobar2 = dec75 - dec25;
keep country portyear pvgobar2;
run;

data gobar21; set tem;
if country="" then delete;
run;
/* proc sort; by country portyear; */
proc export data= work.gobar21
            outfile= "o:\projects\ipp\ctychar_20160518.dta"
            dbms=dta replace;
run;







/************************************/
/* get next June MV */
/* to generate PB */
proc sql;
  create table ag19 as
   select a.*, b.p_updated, b.month, b.p_us_updated
          from ag00 as a
		  left join mois.prmonthly as b on a.code=b.code and a.year=b.year-1 and b.month=6;
quit;
proc sort data=ag19; by code year;
data ag20; set ag19;
by code year;
if pf=. then pf=0;
if dit=. then dit=0;
mc2=p_updated*csh;
if country="UK" then mc2=p_updated*csh/100;
be1 = eq-pf+dit; 
be2 = cm+dit;
be3 = ta-tl-pf+dit;
be4 = be1;
if be1=. then be4=be2;
if be1=. & be2=. then be4=be3;
ndltl = ta - cl - dvp;
goroe = ocf/lag(ndltl);
l1goroe = lag(goroe);
l2goroe = lag(l1goroe);
l3goroe = lag(l2goroe);
l4goroe = lag(l3goroe);
if first.code then do
	goroe=.; l1goroe=.; l2goroe=.; l3goroe=.; l4goroe=.; end;
if year ~= lag(year) + 1 then do
	goroe=.; l1goroe=.; l2goroe=.; l3goroe=.; l4goroe=.;	end;
n_maba =  coalesce(ta - cm + mc2, ta-cm);
n_q = mc2 + pf + cl - ca + dl;
tobinq = (n_q) / ta;
n_dte = (dc + dl + pf); 
dte =  n_dte / mc2;
capex = ce / k;
lev = (dc + dl) / (dl + mc2); 
diff = mc2/mc;
if diff>100 then do
n_maba=.;
n_q=.;
end;
maba = (n_maba) / ta ;
if maba>100 then maba=.;
mc3 = mc2; 
/*if mc3/cm>150 then do
mc3 = .;
end;
if cm<0 then do
mc3 = .;
end;
*/
mebe1 = mc3/be1;
mebe2 = mc3/be2;
mebe3 = mc3/be3;
mebe4 = mc3/be4;
portyear=year+1;
mc_us = mc;
pe = pb / roe *(eq + lag(eq))/2/eq*100;
earn = roe *(be4 + lag(be4))/2/100;
pe = mc3/earn;
if first.code then pe=.; 
if first.code then earn=.; 
/* if roe<0 then pe=.; */
if ndltl<0 then ndltl=.;
/*eroe = 0.4*l1goroe + 0.3*l2goroe + 0.2*l3goroe + 0.1*l4goroe;
 */
eroe = coalesce(0.4*l1goroe + 0.3*l2goroe + 0.2*l3goroe + 0.1*l4goroe,(0.4*l1goroe + 0.3*l2goroe + 0.2*l3goroe)/.9,(0.4*l1goroe + 0.3*l2goroe)/.7,l1goroe);
if eroe<0 || eroe>1 then eroe=.;
proje = eroe*ndltl; 
if proje<-1 then proje=.; 
if proje<0 then proje=.;
ear = eps*csh;
run; 
proc sort data=ag20; by country portyear;
proc means data=ag20 noprint; var mc mc_us mc2 mv_us;
by country portyear;
output out=gobar22 sum= mcsum mcussum mc2sum mvussum;
run;
proc sort data=gobar22; by country portyear;
/*
proc means data=ag20; var ndltl pe;
run;


proc sort data=ag20; by country portyear;
proc univariate data=ag20 noprint;
by country portyear;
var mebe1;
output out=breakpoint pctlpre=dec pctlpts=0 to 100 by 5;
run;
*/


proc sort data=ag20; by country year;
proc sort data=meanretew; by country year;
proc sort data=meanretvw; by country year;
proc sort data=medianret; by country year;

data ag20; merge ag20(in=a) meanretew(in=b) meanretvw(in=c) medianret(in=d);
by country year;
if a;
run;
proc sort data=ag20; by code year;
proc sort data=retannum; by code year;
data ag20; merge ag20(in=a) annret retannum;
by code year;
if a;
run;

data ag20; set ag20;
aip1 = proje/ewmktret;
pvgo1 = (mc3 - aip1) / mc3;
aip2 = proje/vwmktret;
pvgo2 = (mc3 - aip2) / mc3;
aip3 = proje/mdmktret;
pvgo3 = (mc3 - aip3) / mc3;
aip4 = proje/estret1y;
pvgo4 = (mc3 - aip4) / mc3;
aip5 = proje/calmkt1y;
pvgo5 = (mc3 - aip5) / mc3;
/*if pvgo4>3 or pvgo4<0 then delete;
if pvgo2>1 or pvgo2<0 then delete;
if pvgo3>1 or pvgo3<0 then delete;
if pvgo4>1 or pvgo4<0 then delete;
if pvgo5>1 or pvgo5<0 then delete;*/
run;




options errors=0;

data ag21; set ag20;
pe = mc3/nib;
if roe=. then pe=.;
/*if earn=. then pe=.;*/
/*pe = mc3/ear; */
if pvgo2<100;
if pvgo2>-5;
if pvgo2<-1 then pvgo2=.;
/*if pvgo2>50 then pvgo2=.;
if RD<=0 then pvgo2=.;
if be1=. then pvgo2=.;
*/
if pe<=-250 then pe=.;
if pe>=250 then pe=.;
if RD<=0 then pe=.;
if be1=. then pe=.;
if mebe1>100 then mebe1=.;
if mebe1<0.01 then mebe1=.;
if RD<=0 then mebe1=.;
if be1=. then mebe1=.;
keep dscd country portyear pe pvgo2 mebe1;
run;


proc sort; by country portyear;

proc univariate data=ag21 noprint;
by country portyear;
var pvgo2;
output out=breakpoint pctlpre=dec pctlpts=0 to 100 by 5;
run;

data tem; set breakpoint;
pvgobar2 = dec75 - dec25;
keep country portyear pvgobar2;
run;


proc sort; by country portyear;

proc univariate data=ag21 noprint;
by country portyear;
var pe;
output out=breakpoint2 pctlpre=dec pctlpts=0 to 100 by 5;
run;

data tem2; set breakpoint2;
pebar = dec75 - dec25;
keep country portyear pebar;
run;

proc sort; by country portyear;

proc univariate data=ag21 noprint;
by country portyear;
var mebe1;
output out=breakpoint3 pctlpre=dec pctlpts=0 to 100 by 5;
run;

data tem3; set breakpoint3;
mebebar1 = dec75 - dec25;
keep country portyear mebebar1;
run;

proc sort; by country portyear;

data gobar21; merge tem tem2 tem3 gobar22;
by country portyear;
if country="" then delete;
run;
/* proc sort; by country portyear; */
proc export data= work.gobar21
            outfile= "o:\projects\ipp\ctychar_20160518.dta"
            dbms=dta replace;
run;

data tem2; set ag20;
keep country code portyear earn ebd ebi ni nib ear roe;
run;
proc means; run;
proc corr; var ni nib earn; run;












options errors=0;

data ag21; set ag20;
pe = mc3/nib;
if roe=. then pe=.;
/*if earn=. then pe=.;*/
/*pe = mc3/ear; */
if pvgo2<100;
if pvgo2>-5;
/*if RD<=0 then pvgo2=.;
if be1=. then pvgo2=.;
*/
if pe<=-250 then pe=.;
if pe>=250 then pe=.;
if RD<=0 then pe=.;
if be1=. then pe=.;
if mebe1>100 then mebe1=.;
if mebe1<0.01 then mebe1=.;
if RD<=0 then mebe1=.;
if be1=. then mebe1=.;
keep dscd country portyear pe pvgo2 mebe1;
run;


proc sort; by country portyear;

proc univariate data=ag21 noprint;
by country portyear;
var pvgo2;
output out=breakpoint pctlpre=dec pctlpts=0 to 100 by 5;
run;

data tem; set breakpoint;
pvgobar2 = dec80 - dec20;
keep country portyear pvgobar2;
run;


proc sort; by country portyear;

proc univariate data=ag21 noprint;
by country portyear;
var pe;
output out=breakpoint2 pctlpre=dec pctlpts=0 to 100 by 1;
run;

data tem2; set breakpoint2;
pebar = dec80 - dec20;
keep country portyear pebar;
run;

proc sort; by country portyear;

proc univariate data=ag21 noprint;
by country portyear;
var mebe1;
output out=breakpoint3 pctlpre=dec pctlpts=0 to 100 by 5;
run;

data tem3; set breakpoint3;
mebebar1 = dec80 - dec20;
keep country portyear mebebar1;
run;

proc sort; by country portyear;

proc sort; by country portyear;

data gobar21; merge tem tem2 tem3 gobar22;
by country portyear;
if country="" then delete;
run;
/* proc sort; by country portyear; */
proc export data= work.gobar21
            outfile= "o:\projects\ipp\ctychar_20160518.dta"
            dbms=dta replace;
run;




data junk3; set ag20;
if country="AR";
keep country code portyear earn ebd ebi ni nib;
if portyear=2003;
run;

data junk; set ag21;
if pe~=.;
run;
proc corr data=ag20;
var ni nib;
run;
