
libname nnnDS "V:\data_for_kai\WSDS20190215";


/* extract annual return to assign PVGO5 */
data logret3; set nnnDS.agret0;
year = round(mthyr,100)/100;
run;
proc sort; by code year;
proc means data=logret3 noprint; var drhat rm;
by code year;
output out=aret sum=drhat rm n=n1 n2;
run;
data annret; set aret;
estret1y=exp(drhat)-1;
calmkt1y=exp(rm)-1;
if year>=2010;
/*if n1 ge 11;
if year le 2010; /* this is to exclude 2009 requiring returns between 1/2011-6/2011 (not available)*/
keep code year estret1y calmkt1y;
proc sort; by code year;
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



data junk;
retain code year pf dit cl;
set nnnDS.agret0;
pf=pref;
dit=tax;
cm=ce;
keep code year pf dit cm cl;
run;



data ag20; set nnnDS.agret0;
by code year;
if pf=. then pf=0;
if dit=. then dit=0;
/* mc2=p_updated*sh; */
mc2 = p_updated*csh;
if country="UK" then mc2=p_updated*csh/100;
be1 = eq-pf+dit; 
be2 = cm+dit;
be3 = ta-tl-pf+dit;
be4 = be1;
if be1=. then be4=be2;
if be1=. & be2=. then be4=be3;
/*ndltl =  ltlps*sh - dl;
if ctyid=2 then ndltl = ltlps*sh*1000 - dl;
goroe = ocf/lag(dli - dl);
goroe = ocf/lag(ndltl);
if ndltl<0 then goroe=.; 
l1goroe = lag(goroe);
l2goroe = lag(l1goroe);
l3goroe = lag(l2goroe);
l4goroe = lag(l3goroe);
if first.code then do
	goroe=.; l1goroe=.; l2goroe=.; l3goroe=.; l4goroe=.; end;
if year ~= lag(year) + 1 then do
	goroe=.; l1goroe=.; l2goroe=.; l3goroe=.; l4goroe=.;	end;
eroe = 0.4*l1goroe + 0.3*l2goroe + 0.2*l3goroe + 0.1*l4goroe;
proje = eroe*ndltl;
myltl= ltlps*sh;
if ctyid=2 then ndltl = ltlps*sh*1000;
ndltl = be4; ; */
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
eroe = 0.4*l1goroe + 0.3*l2goroe + 0.2*l3goroe + 0.1*l4goroe;
/* proje = eroe*(dli-dl);*/
proje = eroe*ndltl; 
if proje<-1 then proje=.; 
n_maba =  coalesce(ta - cm + mc2, ta-cm);
maba = (n_maba) / ta ;
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
mc3 = mc2; 
if mc3/cm>150 then do
mc3 = .;
end;
if cm<0 then do
mc3 = .;
end;
mebe1 = mc3/be1;
mebe2 = mc3/be2;
mebe3 = mc3/be3;
mebe4 = mc3/be4;
portyear=year+1;
mc_us = mc;
run; 



