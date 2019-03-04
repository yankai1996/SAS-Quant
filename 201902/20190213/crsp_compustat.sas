
libname wrds "C:\TEMP\WRDS";

proc sql;
	create table CUSIP_LINK as 
	select distinct a.permno, gvkey, iid, date, prc, vol, ret
	from
		wrds.msf as a, 					/*CRSP Monthly stock file*/
		wrds.msenames 
		(
			where=(not missing(ncusip)	/*Historical CUSIP is not missing*/
			and shrcd in (10 11))		/*Common stocks of U.S. Companies*/
		) as b, 
		wrds.security
		(
			where=(not missing(cusip)	/*Current CUSIP is not missing*/
			and excntry='USA')			/*Stocks listed in U.S. Exchanges*/
		) as c
	where
		a.permno=b.permno
		and NAMEDT<=a.date<=NAMEENDT	/*Date range conditions*/
		and b.ncusip=substr(c.cusip,1,8);	/*Linking on the first 8 alpha-numerics of CUSIP*/
quit;

data wrds.CUSIP_LINK; set CUSIP_LINK; run;



data junk; set CUSIP_LINK;
mthyr=year(date)*100+month(date);
proc sort; by PERMNO mthyr;
run;

proc means data=junk;
var mthyr;
run;

data junk2; set junk;
keep PERMNO;
proc sort nodup; by PERMNO;
run;

