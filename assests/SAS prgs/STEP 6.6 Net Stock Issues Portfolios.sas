***************************************************************************************************
* Net Stock Issues (Fama and French, 2008, Pontiff and Woodgate, 2008)
***************************************************************************************************
* Chen Xue / A Comparison of New Factor Models / 2014-06-16
***************************************************************************************************;

*** Specify data libraries;
%let root=G:\Project -- Factor Model Comparison\2014-06-16;
libname raw "&root\Data Raw";
libname cln "&root\Data Clean";
libname tst "&root\Data Test (Group 3)";

*** Specify the macros;
filename mac "&root\Macros";
%include mac("*");

*** Clear the work folder;
proc delete data=work._all_; run;


*** Net Stock Issues;
proc sql;
 
   create table Shares as
   select permno, datadate, CSHO*AJEX as Shares
     from raw.acc6113;

   create table NSI as
   select a.permno, a.datadate, year(a.datadate)+1 as myear,
          case when a.Shares>0 and b.Shares>0 then log(a.Shares/b.Shares) else . end as NSI
	 from Shares as a, Shares as b
	where a.permno=b.permno and intck('month',b.datadate,a.datadate)=12;

   create table tst.NSI as
   select *
     from NSI
	where abs(NSI)>0         /** Exclude firms with no activities **/
      and 1966<=myear<=2013; /** N=171,273 from myear 1966 to 2013 **/

quit;


*** June-end NSI;
proc sql;
   create table Jun_NSI as
   select a.permno, a.exchcd, b.myear, b.NSI
     from cln.returns_all (where=(month(date)=6)) as a, tst.NSI as b
	where a.permno=b.permno and year(a.date)=b.myear
	  and a.ABM in (0,1) /** use ABM=1 to exclude micro stocks **/
    order by myear;
quit;

*** Rank on June-end NSI using NYSE breakpoints;
proc univariate data=Jun_NSI noprint;
   var NSI;
   by myear;
   where exchcd=1; *** Exclude this line for ALL breakpoints;
   output out=BP_NSI
          n=nfirms
          pctlpts=10 to 90 by 10
          pctlpre=P;
run;

proc sql;

   create table tst.Jun_NSI as
   select a.*, case when        a.NSI<b.P10 then 1
                    when b.P10<=a.NSI<b.P20 then 2
                    when b.P20<=a.NSI<b.P30 then 3
                    when b.P30<=a.NSI<b.P40 then 4
                    when b.P40<=a.NSI<b.P50 then 5
                    when b.P50<=a.NSI<b.P60 then 6
                    when b.P60<=a.NSI<b.P70 then 7
                    when b.P70<=a.NSI<b.P80 then 8
                    when b.P80<=a.NSI<b.P90 then 9
                    else 10 end as rank_NSI 
     from Jun_NSI as a, BP_NSI as b
	where a.myear=b.myear; /** N=132,170 or 60,598 for ABM **/

   *** Append ranking to July t to June t+1;
   create table tst.ret_NSI as
   select a.*, b.rank_NSI
     from cln.returns as a, tst.Jun_NSI as b
	where a.permno=b.permno and a.myear=b.myear and year(a.date)>=1967; /** N=1,502,058 or 697,506 for ABM **/

   *** Portfolio returns;
   create table tst.pret_NSI as
   select rank_NSI, year(date) as year, month(date) as month, count(*) as nfirms, 
          sum(ret*ME_beg)/sum(ME_beg)*100 as ret_VW, mean(ret)*100 as ret_EW,

		  /** Characteristics of VW portfolios (FF aggregation) **/
		  sum(ME*ME_beg)/sum(IFN(missing(ME),0,1)*ME_beg)/1000 as ME_VW, 
          sum(AT-AT_lag)/sum(AT_lag)*100 as I2A_VW, 
          sum(IBQ)/sum(BEQ_lag)*100      as ROE_VW,

		  /** Characteristics of EW portfolios (1/ME aggregation) **/
		  mean(ME)/1000 as ME_EW, 
		  sum((AT-AT_lag)*(1/ME_beg))/sum(AT_lag*(1/ME_beg))*100 as I2A_EW, 
          sum(IBQ*(1/ME_beg))/sum(BEQ_lag*(1/ME_beg))*100        as ROE_EW

	 from tst.ret_NSI
	group by rank_NSI, date;

   *** Quick check;
   create table Mean_NSI as
   select rank_NSI, mean(nfirms) as nfirms, min(nfirms) as min_nfirms, 
          mean(ret_VW) as ret_VW, mean(ret_EW) as ret_EW, count(*) as nobs
     from tst.pret_NSI
	group by rank_NSI;

   create table HL_NSI as
   select 11 as rank_NSI, mean(a.nfirms,b.nfirms) as nfirms, mean(a.min_nfirms,b.min_nfirms) as min_nfirms,
          a.ret_VW-b.ret_VW as ret_VW, a.ret_EW-b.ret_EW as ret_EW, min(a.nobs,b.nobs) as nobs
     from Mean_NSI as a, Mean_NSI as b
	where a.rank_NSI=10 and b.rank_NSI=1;

   create table Mean_NSI as
   select * from Mean_NSI
          union
   select * from HL_NSI;

quit;
