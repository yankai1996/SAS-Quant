***************************************************************************************************
* 11-Month Momentum Portfolios (Fama and French, 1996)
***************************************************************************************************
* Chen Xue / A Comparison of New Factor Models / 2014-06-16
***************************************************************************************************;

*** Specify data libraries;
%let root=G:\Project -- Factor Model Comparison\2014-06-16;
libname raw "&root\Data Raw";
libname cln "&root\Data Clean";
libname tst "&root\Data Test (Group 1)";

*** Specify the macros;
filename mac "&root\Macros";
%include mac("*");

*** Clear the work folder;
proc delete data=work._all_; run;


*** R11: Past 11-month cumulative return (t-12 to t-2) at the end of month t-1;
proc sql;
   create table tst.R11 as
   select distinct a.permno, a.date, exp(sum(log(1+b.ret)))-1 as R11
     from raw.msf6113 (where=(year(date)>=1966)) as a, 
          raw.msf6113 (where=(year(date)>=1965)) as b
	where a.permno=b.permno and 1<=intck('month',b.date,a.date)<=11
	group by a.permno, a.date
   having count(b.ret)=11; /** N=2,565,262 from 1966 to 2013 **/
quit;


*** R11 at the end of month t-1;
*** Exclude stocks with price below $5 for FULL-ALL-EW portfolios;
proc sql;
   create table mon_R11 as
   select a.*, b.R11
     from cln.returns_all as a, tst.R11 as b
	where a.permno=b.permno and a.date=b.date
	  and mdy(12,1,1966)<=a.date<=mdy(11,30,2013)
	  and a.ABM in (0,1) /** Use ABM=1 to exclude micro stocks **/
    order by a.date;
quit;

*** Rank on month-end R11 using NYSE/ALL breakpoints;
proc univariate data=mon_R11 noprint;
   var R11;
   by date;
   where exchcd=1; *** Exclude this line for ALL breakpoints;
   output out=BP_R11
          n=nfirms
          pctlpts=10 to 90 by 10
          pctlpre=P;
run;

proc sql;
   create table tst.mon_R11 as
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
quit; /** N=2,014,674 or 815,930 for ABM from 12/1966 to 11/2013 **/


*** Hold the portfolios from t to t+J-1;
%let J=;

proc sql;

   create table tst.ret_R11_&J as
   select distinct a.permno, a.date, a.ret, a.ME_beg, a.ME, a.AT, a.AT_lag, a.IBQ, a.BEQ_lag,
          b.rank_R11 as rank_R11_&J, b.date as form_date label='formation date'
     from cln.returns as a, tst.mon_R11 as b
	where a.permno=b.permno and 1<=intck('month',b.date,a.date)<=&J;	
	/** J=1: N=1,999,216 or 812,221 for ABM **/

   *** Portfolio returns;
   create table Mret_R11_&J as
   select rank_R11_&J, date, form_date, count(*) as nfirms,
          sum(ret*ME_beg)/sum(ME_beg)*100 as ret_VW, mean(ret)*100 as ret_EW,

		  /** Characteristics of VW portfolios (FF aggregation) **/
		  sum(ME*ME_beg)/sum(IFN(missing(ME),0,1)*ME_beg)/1000 as ME_VW, 
          sum(AT-AT_lag)/sum(AT_lag)*100 as I2A_VW, 
          sum(IBQ)/sum(BEQ_lag)*100      as ROE_VW,

		  /** Characteristics of EW portfolios (1/ME aggregation) **/
		  mean(ME)/1000 as ME_EW, 
		  sum((AT-AT_lag)*(1/ME_beg))/sum(AT_lag*(1/ME_beg))*100 as I2A_EW, 
          sum(IBQ*(1/ME_beg))/sum(BEQ_lag*(1/ME_beg))*100        as ROE_EW

	 from tst.ret_R11_&J
	group by rank_R11_&J, date, form_date;

   *** Average over formation dates;
   create table tst.pret_R11_&J as
   select rank_R11_&J, year(date) as year, month(date) as month, mean(nfirms) as nfirms, 
          mean(ret_VW) as ret_VW, mean(ret_EW) as ret_EW, count(*) as nobs,
		  mean(ME_VW)  as ME_VW,  mean(I2A_VW) as I2A_VW, mean(ROE_VW)  as ROE_VW,
          mean(ME_EW)  as ME_EW,  mean(I2A_EW) as I2A_EW, mean(ROE_EW)  as ROE_EW
	 from Mret_R11_&J
	group by rank_R11_&J, date;

   *** Quick check;
   create table Mean_R11_&J as
   select rank_R11_&J, mean(nfirms) as nfirms, min(nfirms) as min_nfirms,
          mean(ret_VW) as ret_VW, mean(ret_EW) as ret_EW, count(*) as nobs
     from tst.pret_R11_&J
	group by rank_R11_&J;

   create table HL_R11_&J as
   select 11 as rank_R11_&J, mean(a.nfirms,b.nfirms) as nfirms, mean(a.min_nfirms,b.min_nfirms) as min_nfirms,
          a.ret_VW-b.ret_VW as ret_VW, a.ret_EW-b.ret_EW as ret_EW, min(a.nobs,b.nobs) as nobs
     from Mean_R11_&J as a, Mean_R11_&J as b
	where a.rank_R11_&J=10 and b.rank_R11_&J=1;

   create table Mean_R11_&J as
   select * from Mean_R11_&J
          union
   select * from HL_R11_&J;

quit;
