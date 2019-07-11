
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

data pwd.EPS; merge permno(in=a) pwd.quarter(in=b);
by gvkey;
if a and b;
proc sort; by permno;
run;


data earnings; set earnings;
if datadate~=.;
keep permno gvkey iid datadate FYEARQ FQTR EPSPIQ EPSPXQ;
proc sort nodup; by FYEARQ FQTR permno;
run;



proc sql;
create table junk as
select distinct permno from earnings;
quit;
