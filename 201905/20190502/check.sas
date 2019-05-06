
data junk; set nnnDS.acct; 
mthyr=year(fye)*100+month(fye);
keep dscd geogn year FYE mthyr;
run;
proc means; run;

data junk2; set nnnDS.acct;
if year=1980;
if MC~=.;
run;

data junk3; set junk2;
mthyr=year(fye)*100+month(fye);
if mthyr=198012;
run;
proc sql;
	create table junk3 as
	select b.country as country, a.*
	from junk3 as a
	left join db.ctycode as b on a.geogn=b.cty;
quit;
data junk3; set junk3;
if country in ("AU", "BD", "CH", "CN", "FN", "FR", "GR", "HK", "IN", "IS", 
"IT", "JP", "KO", "MY","SD", "SG", "SW", "TA", "TK", "UK", "US");
run;

data mvdec1980; set junk3;
code=dscd;
mv=round(MC/1000, .01);
mv_us=round(MCUS/1000, .01);
portyear=1981;
keep code year portyear mv mv_us;
run;

data mvdec; set nnnDS.mvdec mvdec1980;
proc sort; by code portyear;
run;


data junk4; set mvdec;
if year in (1980, 1981);
run;
proc sql;
create table junk4 as
select * from junk4
group by code
having count(year)=2;
quit;
proc sort data=junk4; by code year; run;


data nnnDS.mvdec; set mvdec; run;
