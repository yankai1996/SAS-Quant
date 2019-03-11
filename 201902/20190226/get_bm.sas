
dm 'log;clear;';
%let pwd = "C:\TEMP\displace\20190226\bm-developed";
x md &pwd;
x cd &pwd;
libname pwd &pwd;


%zBM(tem, world, portyear, bm4, 0);
%onewayeffect(zscore, ret_us, world, ew, world_ew, z);
data pwd.world_ew_sprd; set sprd; run;
%onewayeffect(zscore, ret_us, world, lagmv_us, world_vw, z);
data pwd.world_vw_sprd; set sprd; run;
%firmcty(rank, long, 10);
%firmcty(rank, short, 1);


libname DB 'V:\data_for_kai';
libname nDS 'V:\data_for_kai\new DSWS\merged';
libname nnDS 'V:\data_for_kai\newnew_DSWS\merged';
libname export 'V:\data_for_kai\new data';
libname nnnDS 'V:\data_for_kai\WSDS20190215';


data agret0; set db.agret0;
keep code country mthyr portyear ret ret_us mc dit eq pf cm ta tl p_us_updated;
if (country="US" and mthyr<201307) or (country~="US" and mthyr<201207);
run;

data agret1_us; set export.agret1_us; 
keep code country mthyr portyear ret ret_us mc dit eq pf cm ta tl p_us_updated;
run;
data agret1_xus; set export.agret1_xus; 
keep code country mthyr portyear ret ret_us mc dit eq pf cm ta tl p_us_updated;
run;


data old; set agret0 agret1_us agret1_xus; 
proc sort; by code mthyr;
data old; set old;
by code mthyr;
if code=lag(code) & mthyr=lag(mthyr) then delete;
run;



data new; set nds.agret0_new_dsws;
eq=se;
pf=pref;
dit=tax;
cm=ce;
keep code country mthyr portyear ret ret_us mc dit eq pf cm ta tl p_us_updated;
run;


/* yet another way to expand ``old'' then combine in one step */
proc sql;
create table A5 as
select coalesce(a.code,b.code) as code,
	coalesce(a.country,b.country) as country,
	coalesce(a.mthyr,b.mthyr) as mthyr,
	coalesce(a.portyear,b.portyear) as portyear,
	coalesce(a.ret,b.ret) as ret,
	coalesce(a.ret_us,b.ret_us) as ret_us,
	coalesce(a.mc,b.mc) as mc,
	coalesce(a.dit,b.dit) as dit,
	coalesce(a.eq,b.eq) as eq,
	coalesce(a.pf,b.pf) as pf,
	coalesce(a.cm,b.cm) as cm,
	coalesce(a.ta,b.ta) as ta,
	coalesce(a.tl,b.tl) as tl,
	coalesce(a.p_us_updated,b.p_us_updated) as p_us_updated
from old as a
full join new as b on a.code=b.code and a.mthyr=b.mthyr
;
create table A5 as
select a.code, a.country, a.mthyr, a.portyear, a.ret, a.ret_us,
	a.mc, a.cm, a.ta, a.tl, 
	coalesce(a.eq,b.se) as eq, 
	coalesce(a.pf,b.pref) as pf, 
	coalesce(a.dit,b.tax) as dit,
	a.p_us_updated
from A5 as a
left join nnnDS.acct as b on a.code=b.dscd and a.portyear=b.year+1;
quit;


data A5; set A5;
if dit=. then dit=0;
be1 = eq-pf+dit;
be2 = cm+dit;
be3 = ta-tl-pf+dit;
be4 = coalesce(be1,be2,be3);
bm4 = be4/mc;
proc sort; by code portyear;
run;

data db.A5; set A5; run;
