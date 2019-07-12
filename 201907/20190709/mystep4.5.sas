
libname us "V:\data_for_kai\Compustat&CRSP merged";


proc means data=us.comp; run;


*** R11: Past 11-month cumulative return (t-12 to t-2) at the end of month t-1;
proc sql;
   create table R11 as
   select distinct a.permno, a.date, exp(sum(log(1+b.ret)))-1 as R11
     from us.crsp_20190314 (where=(year(date)>=1966)) as a, 
          us.crsp_20190314 (where=(year(date)>=1965)) as b
	where a.permno=b.permno and 1<=intck('month',b.date,a.date)<=11
	group by a.permno, a.date
   having count(b.ret)=11; /** N=2,565,262 from 1966 to 2013 **/
quit;



*** R11 at the end of month t-1;
*** Exclude stocks with price below $5 for FULL-ALL-EW portfolios;
proc sql;
   create table mon_R11 as
   select a.*, b.R11
     from us.crsp_20190314 as a, R11 as b
	where a.permno=b.permno and a.date=b.date
	  and mdy(12,1,1966)<=a.date<=mdy(11,30,2018)
	  and abs(a.prc)>=5
    order by a.date;
quit;


*** Rank on month-end R11 using NYSE/ALL breakpoints;
proc univariate data=mon_R11 noprint;
   var R11;
   by date;
   where HEXCD=1; *** Exclude this line for ALL breakpoints;
   output out=BP_R11
          n=nfirms
          pctlpts=10 to 90 by 10
          pctlpre=P;
run;

proc sql;
   create table mon_R11 as
   select a.*,
          case when        a.R11<b.P10 then 1
               when b.P10<=a.R11<b.P20 then 2
               when b.P20<=a.R11<b.P30 then 3
               when b.P30<=a.R11<b.P40 then 4
               when b.P40<=a.R11<b.P50 then 5
               when b.P50<=a.R11<b.P60 then 6
               when b.P60<=a.R11<b.P70 then 7
               when b.P70<=a.R11<b.P80 then 8
               when b.P80<=a.R11<b.P90 then 9
               else 10 end as rank_R11
	 from mon_R11 as a, BP_R11 as b
	where a.date=b.date;
quit;
