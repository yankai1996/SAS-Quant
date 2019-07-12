
libname link "V:\data_for_kai\Compustat&CRSP merged\20190215";


**(3) merge CRSP and Compustat **;

data crsp; set link.crsp;

	if shrcd in (10,11) and HEXCD in (1,2,3) and (HSICCD<6000 or HSICCD>6999); /* common shares listed on NYSE, AMEX and NASDAQ, non-financial firms */

	if dlret ^= . and dlret ^= .A then do;
		if ret = . then ret = dlret;
		else ret = (1 + ret) * (1 + dlret) - 1;
	end;  /*dealing the delisting return*/
run;

proc sql;
	create table date as
	select unique date, year(date) as year, month(date) as mth
	from crsp;
quit;

data date; set date; reldate=_n_;run;
data portyr; set date; if mth=6;run;

proc sql;
	create table port as
	select unique a.year as portyear, a.date as portdate, b.date as mthyr format yymmd.
	from portyr a left join date b
	on a.reldate<b.reldate<=a.reldate+12;

	create table port as
	select unique a.*, b.HSICCD as sic, b.permno, b.ret, abs(b.prc)*b.shrout/1000 as mc_mth
	from port a left join crsp b
	on a.mthyr=b.date;

	create table port as 
	select distinct a.*, b.gvkey, b.liid as iid, b.lpermno as lpermno
	from port a, link.Ccmxpf_linktable2018 b
	where a.permno=b.lpermno and
	      b.linkdt<=a.portdate<=coalesce(b.linkenddt, today())	/*LinkTable Date range conditions*/ and
          b.linktype in ('LU' 'LC') and /*KEEP reliable LINKS only*/
          b.LINKPRIM in ('P' 'C') and   /*KEEP primary Links*/
	      b.USEDFLAG=1                /*Legacy condition, no longer necessary*/ 
	order by a.portyear, a.permno, a.mthyr;

	create table earnings(drop=portdate) as
	select unique a.*, b.datadate, b.FYEARQ, b.FQTR, b.EPSPIQ, b.EPSPXQ
	from port a left join pwd.quarter b
	on a.gvkey=b.gvkey and
	   /*a.iid=b.iid and*/
	   a.portdate-380<=b.datadate<=a.portdate
	group by a.gvkey, /*a.iid,*/ a.portdate
	having b.datadate=max(b.datadate);
quit;

/*
data permno; set port;
keep permno gvkey iid lpermno;
proc sort nodup; by permno gvkey iid;
run;

data junk; set permno;
if lpermno=lag(lpermno) and permno~=lag(permno);
run;
*/

data permno; set port;
keep permno gvkey;
proc sort nodup; by gvkey;
run;



data comp_ann; merge permno(in=a) us.comp_ann(in=b);
by gvkey;
if a and b;
keep permno gvkey fyear PRCC_F PPEGT INVT TXP NI REVT COGS PI;
proc sort; by permno fyear;
run;






data comp_ann; set us.comp_ann;
if INDFMT="FS" then delete;
if fyear=. then delete;
keep gvkey fyear PRCC_F PPEGT INVT TXP NI REVT COGS PI;
proc sort; by gvkey fyear;
run;


data agret0; set us.agret0;
proc sort; by gvkey fyear;
run;


data agret1; merge agret0(in=a) comp_ann;
by gvkey fyear;
if a;
run;



proc sort data=us.comp_qua out=comp_qua; by gvkey fyearQ FQTR;
data comp_qua; set comp_qua;
by gvkey fyearQ FQTR;
if last.FQTR;
DateQ=datadate;
format DateQ YYMMDDn8.;
keep gvkey fyearQ FQTR DateQ IBQ SEQQ CEQQ PSTKQ ATQ LTQ TXDITCQ PSTKRQ NIQ CHEQ;
run;



data date; set us.crsp_20190314;
mthyr=year(date)*100+month(date);
keep permno date mthyr;
proc sort nodup; by permno mthyr;
run;

proc sort data=agret1; by permno mthyr; run;
data agret1; retain code date mthyr; merge agret1(in=a) date;
by permno mthyr;
if a;
proc sort; by gvkey date;
run;


proc sql;
create table agret2 as
select a.*, b.* 
from agret1 as a left join comp_qua as b
on a.gvkey=b.gvkey
where a.date>b.DateQ and a.fyear-b.FYEARQ<=1
group by a.gvkey, a.date
having a.date-b.DateQ=min(a.date-b.DateQ);
quit;

data agret2; set agret2;
by gvkey date;
if first.date;
run;


data agret3; merge agret1(in=a) agret2(in=b);
by gvkey date;
proc sort; by code date;
run;


data junk5; set comp_qua;
if gvkey="003785";
run;


data us.agret1; set agret3; run;
