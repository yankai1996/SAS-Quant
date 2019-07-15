***************************************************************************************************
* B/M Portfolios (Rosenberg, Reid, and Lanstein, 1985)
***************************************************************************************************
* Chen Xue / A Comparison of New Factor Models / 2014-06-16
***************************************************************************************************;

*** Specify data libraries;
%let root=G:\Project -- Factor Model Comparison\2014-06-16;
libname raw "&root\Data Raw";
libname cln "&root\Data Clean";
libname tst "&root\Data Test (Group 2)";

*** Specify the macros;
filename mac "&root\Macros";
%include mac("*");

*** Clear the work folder;
proc delete data=work._all_; run;


*** B/M;
proc sql;

   *** BE for fiscal year ending in t-1;
   *** ME at the end of December t-1 from Compustat or CRSP;
   create table BM as
   select a.permno, a.datadate, year(a.datadate)+1 as myear,
          coalesce(a.SEQ,a.CEQ+a.PSTK,a.AT-a.LT)+coalesce(a.TXDITC,0)-coalesce(a.PSTKRV,a.PSTKL,a.PSTK) as BE, 
          case when month(a.datadate)=12 and a.PRCC_F*a.CSHO>0 then coalesce(a.PRCC_F*a.CSHO,b.prc*b.shrout) 
               else b.prc*b.shrout end as ME_Dec
     from raw.acc6113 as a
          left join
          raw.msf6113 (where=(month(date)=12)) as b
	   on a.permno=b.permno and year(a.datadate)=year(b.date);

   *** For duplicates due to FYE changes, keep the latest info;
   *** Following FF, keep only firms with positive BE;
   create table tst.BM as
   select *, BE/ME_Dec as BM
     from BM
    where BE>0 and ME_Dec>0 and 1966<=myear<=2013
	group by permno, myear
   having datadate=max(datadate);

quit; /** N=204,586 from myear 1966 to 2013 **/


*** June-end BM;
proc sql;
   create table Jun_BM as
   select a.permno, a.exchcd, b.myear, b.BM
     from cln.returns_all (where=(month(date)=6)) as a, tst.BM as b
	where a.permno=b.permno and year(a.date)=b.myear
	  and a.ABM in (0,1) /** use ABM=1 to exclude micro stocks **/
    order by myear;
quit;

*** Rank on June-end BM using NYSE breakpoints;
proc univariate data=Jun_BM noprint;
   var BM;
   by myear;
   where exchcd=1; *** Exclude this line for ALL breakpoints;
   output out=BP_BM
          n=nfirms
          pctlpts=10 to 90 by 10
          pctlpre=P;
run;

proc sql;

   create table tst.Jun_BM as
   select a.*, case when        a.BM<b.P10 then 1
                    when b.P10<=a.BM<b.P20 then 2
                    when b.P20<=a.BM<b.P30 then 3
                    when b.P30<=a.BM<b.P40 then 4
                    when b.P40<=a.BM<b.P50 then 5
                    when b.P50<=a.BM<b.P60 then 6
                    when b.P60<=a.BM<b.P70 then 7
                    when b.P70<=a.BM<b.P80 then 8
                    when b.P80<=a.BM<b.P90 then 9
                    else 10 end as rank_BM 
     from Jun_BM as a, BP_BM as b
	where a.myear=b.myear; /** N=167,882 or 68,630 for ABM **/

   *** Append ranking to July t to June t+1;
   create table tst.ret_BM as
   select a.*, b.rank_BM
     from cln.returns as a, tst.Jun_BM as b
	where a.permno=b.permno and a.myear=b.myear and year(a.date)>=1967; /** N=1,905,816 or 789,963 for ABM **/

   *** Portfolio returns;
   create table tst.pret_BM as
   select rank_BM, year(date) as year, month(date) as month, count(*) as nfirms, 
          sum(ret*ME_beg)/sum(ME_beg)*100 as ret_VW, mean(ret)*100 as ret_EW,

		  /** Characteristics of VW portfolios (FF aggregation) **/
		  sum(ME*ME_beg)/sum(IFN(missing(ME),0,1)*ME_beg)/1000 as ME_VW, 
          sum(AT-AT_lag)/sum(AT_lag)*100 as I2A_VW, 
          sum(IBQ)/sum(BEQ_lag)*100      as ROE_VW,

		  /** Characteristics of EW portfolios (1/ME aggregation) **/
		  mean(ME)/1000 as ME_EW, 
		  sum((AT-AT_lag)*(1/ME_beg))/sum(AT_lag*(1/ME_beg))*100 as I2A_EW, 
          sum(IBQ*(1/ME_beg))/sum(BEQ_lag*(1/ME_beg))*100        as ROE_EW

	 from tst.ret_BM
	group by rank_BM, date;

   *** Quick check;
   create table Mean_BM as
   select rank_BM, mean(nfirms) as nfirms, min(nfirms) as min_nfirms, 
          mean(ret_VW) as ret_VW, mean(ret_EW) as ret_EW, count(*) as nobs
     from tst.pret_BM
	group by rank_BM;

   create table HL_BM as
   select 11 as rank_BM, mean(a.nfirms,b.nfirms) as nfirms, mean(a.min_nfirms,b.min_nfirms) as min_nfirms,
          a.ret_VW-b.ret_VW as ret_VW, a.ret_EW-b.ret_EW as ret_EW, mean(a.nobs,b.nobs) as nobs
     from Mean_BM as a, Mean_BM as b
	where a.rank_BM=10 and b.rank_BM=1;

   create table Mean_BM as
   select * from Mean_BM
          union
   select * from HL_BM;

quit;
