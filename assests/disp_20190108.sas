;

/* start from here */


options noxwait;
x 'O:\projects';
libname roadeco "O:\projects\roadeco";

libname deco "O:\projects\retdeco";
x 'cd O:\projects\AG';
libname intag '201111';
libname mois '201111\monthly\02_exfin';
libname annee '201111\yearly\02_exfin';
libname ipp 'O:\projects\ipp';
libname jour 'O:\projects\AG\af79\200909\02_exfin';

libname innopoli "O:\projects\innopoli";


x 'cd O:\projects\ipp';
%include 'winsor.sas';




option notes;


data oldnames; set annee.allannual;
keep code country;
proc sort nodup; by code;
run;

/* directly use USD returns downloaded Mar 2016 */
proc import out=retmonthly2016 datafile="O:\projects\ipp\ri_us.dta" replace; run; 
proc sql;
  create table retmonthly3 as
   select a.*, b.country
          from retmonthly2016 as a, oldnames as b
		  where a.dscd=b.code;
quit;

 
proc sort; by dscd mthyr;
data retmonthly4; set retmonthly3; 
by dscd mthyr;
ri_usd = ri;
annee = floor(mthyr/100);
mois = floor(mthyr-annee*100);
portyear = annee;
if mois<=6 then portyear = annee-1;
code = dscd;
ret = ri/lag(ri) - 1;
ret_us = ri_usd/lag(ri_usd) - 1; 
IF first.dscd THEN DO;
	ret = 0;
END;
if ret=0 & lag(ret)=0 then delete;
if mthyr>=201107;
if (1+ret)*(1+lag(ret))<1.5 and ret>3 or lag(ret)>3 then delete; 
keep code ret ret_us portyear mthyr;
run;



data retmonthly2; set ipp.retmonthly2;
if mthyr<=201106;
keep code ret ret_us portyear mthyr;
run;
data retmonthly5; set retmonthly2 retmonthly4;
run;

proc sql;
	create table retmonthly5 as
	select a.*, b.country
	from retmonthly5 as a
	left join oldnames as b on a.code=b.code;
quit;
proc sort; by code portyear mthyr;
run;




/* if use old data eq and pf */
proc sql;
  create table ag01 as
   select a.*, b.opm, b.dda, b.cog, b.dit, b.sga
          from annee.allannual as a
		  left join
          roadeco.annual2014 as b
		  on a.code=b.dscd and a.year=b.year
			where a.year<=2008;
quit;

proc sql;
  create table ag011 as
   select a.*, b.country, a.dscd as code
          from roadeco.annual2014 as a		
		  left join oldnames as b on a.dscd=b.code
		where a.year>=2009 and b.country~="";
quit;
proc sort; by code year;
run;


data ag; set ag01 ag011;
by code year;
/* if pf=. then pf=0;*/
if dit=. then dit=0;
be1 = eq-pf+dit;
be2 = cm+dit;
be3 = ta-tl-pf+dit;
be4 = be1;
if be1=. then be4=be2;
if be1=. & be2=. then be4=be3;
portyear = year + 1;
/*if country in ("AU", "BD", "CH", "CN", "FN", "FR", "GR", "HK", "IN", "IS", "IT", "JP", "KO", "MY","SD", "SG", "SW", "TA", "TK", "UK", "US"); */
run;



/* throw out 10% of size */


proc import out=ipp.prmonthly2016 datafile="O:\projects\ipp\p.dta";  run;  proc sort; by dscd mthyr; run;
data prmonthly2016; set ipp.prmonthly2016; 
by dscd mthyr;
annee = floor(mthyr/100);
mois = floor(mthyr-annee*100);
portyear = annee;
/* if mois<=6 then portyear = annee; */
code = dscd;
if mthyr>=201107;
if mois = 6;
p_us_updated = p;
keep code p_us_updated portyear;
run;
proc sql;
  create table prmonthly2 as
   select a.*, b.country
          from prmonthly2016 as a, oldnames as b
		  where a.code=b.code;
quit;



data prmonthly1; set mois.prmonthly;
if month=6;
portyear = year;
/*portyear = year;*/
keep code p_us_updated portyear country;
run;

data prmonthly; set prmonthly1 prmonthly2; 
run;

proc sort; by portyear country;
run;
proc univariate data=prmonthly noprint;
by portyear country;
var p_us_updated;
output out=price p10=p_us_10;
run;

proc sort data=prmonthly; by portyear country;
run;

data prmonthly; merge prmonthly price;
by portyear country;

proc sort; by code portyear;
run;


data retannual; set ipp.retannual;
if ret1y_us~=.;
run;

data mvmois_old; set mois.allmonthly;
mv = mv_updated;
mv_us = mv_us_updated;
if country = 'US' then mv_us = mv_updated;
mthyr = year(date)*100 + month(date);
keep code mv_us mthyr;

proc import out=ipp.mvmois2016 datafile="O:\projects\ipp\mv_us.dta";  run;  proc sort; by dscd mthyr; run;
data mvmois2016; set ipp.mvmois2016; 
by dscd mthyr;
code = dscd;
mv_us = mv;
if mthyr>=201110;
keep code mv_us mthyr;
run;

data mvmois; set mvmois_old mvmois2016;
proc sort; by code mthyr;
run;

/*** use LAG !!! ***/
data mvmois; set mvmois;
by code mthyr;
lagmv_us = lag(mv_us);
if first.code then lagmv_us=.;
run;













data agret0; merge retmonthly5(in=a) ag(in=b) prmonthly ipp.juneret(in=d) ipp.momentum;
by code portyear;
if a and b;
if country='US' then ret_us=ret;
run;

libname db "D:\Dropbox\data_for_kai";
data db.agret0; set agret0;
data db.mvmois; set mvmois;
run;
data db.mvdec; set mois.mvdec;
portyear = year+1;
run;

data db.returndaily2018; set tmp6.AE_ret
tmp6.AR_ret
tmp6.AU_ret
tmp6.BD_ret
tmp6.BG_ret
tmp6.BL_ret
tmp6.BR_ret
tmp6.CB_ret
tmp6.CH_ret
tmp6.CL_ret
tmp6.CN_ret
tmp6.CP_ret
tmp6.CT_ret
tmp6.CY_ret
tmp6.CZ_ret
tmp6.DK_ret
tmp6.ES_ret
tmp6.EY_ret
tmp6.FN_ret
tmp6.FR_ret
tmp6.GR_ret
tmp6.HK_ret
tmp6.HN_ret
tmp6.ID_ret
tmp6.IN_ret
tmp6.IR_ret
tmp6.IS_ret
tmp6.IT_ret
tmp6.JM_ret
tmp6.JO_ret
tmp6.JP_ret
tmp6.KN_ret
tmp6.KO_ret
tmp6.KW_ret
tmp6.KZ_ret
tmp6.LN_ret
tmp6.LV_ret
tmp6.LX_ret
tmp6.MC_ret
tmp6.MX_ret
tmp6.MY_ret
tmp6.NG_ret
tmp6.NL_ret
tmp6.NW_ret
tmp6.NZ_ret
tmp6.OE_ret
tmp6.PE_ret
tmp6.PH_ret
tmp6.PK_ret
tmp6.PO_ret
tmp6.PT_ret
tmp6.QA_ret
tmp6.RM_ret
tmp6.RS_ret
tmp6.SA_ret
tmp6.SD_ret
tmp6.SG_ret
tmp6.SI_ret
tmp6.SJ_ret
tmp6.SW_ret
tmp6.SX_ret
tmp6.TA_ret
tmp6.TH_ret
tmp6.TK_ret
tmp6.TU_ret
tmp6.UA_ret
tmp6.UK_ret
tmp6.VE_ret
tmp6.VI_ret
tmp6.ZI_ret;
if ri~=.;
run;
data db.mvmonthly2018; set tmp13.AE_monthly
tmp13.AR_monthly
tmp13.AU_monthly
tmp13.BD_monthly
tmp13.BG_monthly
tmp13.BL_monthly
tmp13.BR_monthly
tmp13.CB_monthly
tmp13.CH_monthly
tmp13.CL_monthly
tmp13.CN_monthly
tmp13.CP_monthly
tmp13.CT_monthly
tmp13.CY_monthly
tmp13.CZ_monthly
tmp13.DK_monthly
tmp13.ES_monthly
tmp13.EY_monthly
tmp13.FN_monthly
tmp13.FR_monthly
tmp13.GR_monthly
tmp13.HK_monthly
tmp13.HN_monthly
tmp13.ID_monthly
tmp13.IN_monthly
tmp13.IR_monthly
tmp13.IS_monthly
tmp13.IT_monthly
tmp13.JM_monthly
tmp13.JO_monthly
tmp13.JP_monthly
tmp13.KN_monthly
tmp13.KO_monthly
tmp13.KW_monthly
tmp13.KZ_monthly
tmp13.LN_monthly
tmp13.LV_monthly
tmp13.LX_monthly
tmp13.MC_monthly
tmp13.MX_monthly
tmp13.MY_monthly
tmp13.NG_monthly
tmp13.NL_monthly
tmp13.NW_monthly
tmp13.NZ_monthly
tmp13.OE_monthly
tmp13.PE_monthly
tmp13.PH_monthly
tmp13.PK_monthly
tmp13.PO_monthly
tmp13.PT_monthly
tmp13.QA_monthly
tmp13.RM_monthly
tmp13.RS_monthly
tmp13.SA_monthly
tmp13.SD_monthly
tmp13.SG_monthly
tmp13.SI_monthly
tmp13.SJ_monthly
tmp13.SW_monthly
tmp13.SX_monthly
tmp13.TA_monthly
tmp13.TH_monthly
tmp13.TK_monthly
tmp13.TU_monthly
tmp13.UA_monthly
tmp13.UK_monthly
tmp13.VE_monthly
tmp13.VI_monthly
tmp13.ZI_monthly;
if mv~=.;
drop col2;
run;
