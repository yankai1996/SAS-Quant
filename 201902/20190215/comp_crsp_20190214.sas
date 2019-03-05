%let wrds=wrds-cloud.wharton.upenn.edu 4016;
options comamid=TCP remote=WRDS;
signon username=_prompt_;

rsubmit;
libname rd '/scratch/hkust/acwang';


**(1) compustat annual accounting variables **;

data comp; set compm.funda;

	if indfmt ='INDL' and datafmt = 'STD' and popsrc = 'D' and consol = 'C';

	keep gvkey iid datadate fyear sich EXCHG FIC
         EMP XRD
         CHE ACT PPENT AT DLC LCT DLTT TXDB LT MIB PSTK PSTKL PSTKRV  ITCB ITCI CEQ SEQ CSHO AJEX prcc_f mkvalt 
		 SALE COGS XSGA DP IB EPSPX CAPX OIADP OIBDP OANCF DVP;
run;

data sic; set compm.names; sic_=sic*1;run;

proc sql;
	create table comp as
	select unique a.*, b.sic_
	from comp a left join sic b
	on a.gvkey=b.gvkey;
quit;

data comp; set comp;

	sic=sich;  if sic=. then sic=sic_; drop sic_ sich;

run;

proc sql;
	create table rd.comp as
	select *
	from comp
	group by gvkey, iid, fyear
	having count(*)=1;
quit;



**(2) CRSP monthly return  ***;

proc sql;
	create table rd.crsp as
	select unique a.PERMNO, a.HEXCD, a.HSICCD, a.DATE, a.PRC, a.VOL, a.RET, a.shrout,
                  b.vwretd,  /*value-weigthed market index return */
	              c.dlret,   /*Delisting return*/
                  d.shrcd /*shrcd=10, 11, common shares */
	from crspa.msf a left join crspa.msi b
	on  a.date=b.date
	left join crspa.mse c 
	on a.permno=c.permno and 
       a.date=c.date
	left join crspa.msenames d
	on a.permno=d.permno and
	   d.NAMEDT<=a.date<=d.NAMEENDT;
quit;


**(3) merge CRSP and Compustat **;

libname ccm "C:\AResearch\RD_XY\COMP_CRSP";

data crsp; set ccm.crsp;

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
	select distinct a.*, b.gvkey, b.liid as iid 
	from port a, ccm.Ccmxpf_linktable2018 b
	where a.permno=b.lpermno and
	      b.linkdt<=a.portdate<=coalesce(b.linkenddt, today())	/*LinkTable Date range conditions*/ and
          b.linktype in ('LU' 'LC') and /*KEEP reliable LINKS only*/
          b.LINKPRIM in ('P' 'C') and   /*KEEP primary Links*/
	      b.USEDFLAG=1                /*Legacy condition, no longer necessary*/ 
	order by a.portyear, a.permno, a.mthyr;

	create table ccm.ccm(drop=portdate) as
	select unique a.*, b.datadate, b.xrd, b.emp, b.at
	from port a left join ccm.comp b
	on a.gvkey=b.gvkey and
	   a.iid=b.iid and
	   a.portdate-380<=b.datadate<=a.portdate
	group by a.gvkey, a.iid, a.portdate
	having b.datadate=max(b.datadate);
quit;

proc sort data=ccm.ccm; by portyear permno mthyr;run;



libname comp "C:\TEMP\Compustat&CRSP merged";


data ccm; set comp.ccm;
proc sort; by gvkey iid datadate;
run;

data comp; set comp.comp;
proc sort; by gvkey iid datadate;
run;

data ccm1; merge ccm(in=a) comp;
by gvkey iid datadate;
if a;
date=mthyr;
format date YYMMD7. mthyr BEST12.;
mthyr=year(date)*100+month(date);
proc sort; by permno mthyr;
run;


data crsp; set comp.crsp;
mthyr=year(date)*100+month(date);
keep permno mthyr shrcd dlret;
proc sort; by permno mthyr;
run;


data ccm2; merge ccm1(in=a) crsp(in=b);
by permno mthyr;
if a and b;
if shrcd~=10 & shrcd~=11 then delete;
retnew = coalesce(ret,dlret,ret+dlret);
run;



data junk1; set comp.crsp; 
proc sort; by permno date;
run;

data junk1; set junk1;
by permno date;
if not (first.date and last.date);
run;


data junk2; set comp.ccm; 
proc sort; by permno mthyr;
run;

data junk2; set junk2;
by permno mthyr;
if not (first.mthyr and last.mthyr);
run;


data junk3; set comp.comp; 
proc sort; by gvkey iid datadate;
run;

data junk3; set junk3;
by gvkey iid datadate;
if not (first.datadate and last.datadate);
run;


