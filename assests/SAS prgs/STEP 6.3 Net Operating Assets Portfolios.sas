***************************************************************************************************
* Net Operating Assets Portfolios (Hirshleifer, Hou, Teoh, and Zhang, 2004)
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


*** Net Operating Assets;
proc sql;

   *** Set missing values to zero for minor items (see paragraph 4, page 307);
   create table NOA as
   select a.permno, a.datadate, year(a.datadate)+1 as myear, 
          ((a.AT-a.CHE)-(a.AT-coalesce(a.DLC,0)-coalesce(a.DLTT,0)-coalesce(a.MIB,0)-coalesce(a.PSTK,0)-a.CEQ))/b.AT as NOA
	 from raw.acc6113 as a, raw.acc6113 as b
    where a.permno=b.permno and intck('month',b.datadate,a.datadate)=12 and b.AT>0;

   create table tst.NOA as
   select *
     from NOA
	where NOA^=. and 1966<=myear<=2013; /** N=193,683 from myear 1966 to 2013 **/

quit;


*** June-end NOA;
proc sql;
   create table Jun_NOA as
   select a.permno, a.exchcd, b.myear, b.NOA
     from cln.returns_all (where=(month(date)=6)) as a, tst.NOA as b
	where a.permno=b.permno and year(a.date)=b.myear
	  and a.ABM in (0,1) /** use ABM=1 to exclude micro stocks **/
    order by myear;
quit;

*** Rank on June-end NOA using NYSE breakpoints;
proc univariate data=Jun_NOA noprint;
   var NOA;
   by myear;
   where exchcd=1; *** Exclude this line for ALL breakpoints;
   output out=BP_NOA
          n=nfirms
          pctlpts=10 to 90 by 10
          pctlpre=P;
run;

proc sql;

   create table tst.Jun_NOA as
   select a.*, case when        a.NOA<b.P10 then 1
                    when b.P10<=a.NOA<b.P20 then 2
                    when b.P20<=a.NOA<b.P30 then 3
                    when b.P30<=a.NOA<b.P40 then 4
                    when b.P40<=a.NOA<b.P50 then 5
                    when b.P50<=a.NOA<b.P60 then 6
                    when b.P60<=a.NOA<b.P70 then 7
                    when b.P70<=a.NOA<b.P80 then 8
                    when b.P80<=a.NOA<b.P90 then 9
                    else 10 end as rank_NOA 
     from Jun_NOA as a, BP_NOA as b
	where a.myear=b.myear; /** N=150,741 or 63,372 for ABM **/

   *** Append ranking to July t to June t+1;
   create table tst.ret_NOA as
   select a.*, b.rank_NOA
     from cln.returns as a, tst.Jun_NOA as b
	where a.permno=b.permno and a.myear=b.myear and year(a.date)>=1967; /** N=1,713,656 or 730,964 for ABM **/

   *** Portfolio returns;
   create table tst.pret_NOA as
   select rank_NOA, year(date) as year, month(date) as month, count(*) as nfirms, 
          sum(ret*ME_beg)/sum(ME_beg)*100 as ret_VW, mean(ret)*100 as ret_EW,

		  /** Characteristics of VW portfolios (FF aggregation) **/
		  sum(ME*ME_beg)/sum(IFN(missing(ME),0,1)*ME_beg)/1000 as ME_VW, 
          sum(AT-AT_lag)/sum(AT_lag)*100 as I2A_VW, 
          sum(IBQ)/sum(BEQ_lag)*100      as ROE_VW,

		  /** Characteristics of EW portfolios (1/ME aggregation) **/
		  mean(ME)/1000 as ME_EW, 
		  sum((AT-AT_lag)*(1/ME_beg))/sum(AT_lag*(1/ME_beg))*100 as I2A_EW, 
          sum(IBQ*(1/ME_beg))/sum(BEQ_lag*(1/ME_beg))*100        as ROE_EW

	 from tst.ret_NOA
	group by rank_NOA, date;

   *** Quick check;
   create table Mean_NOA as
   select rank_NOA, mean(nfirms) as nfirms, min(nfirms) as min_nfirms, 
          mean(ret_VW) as ret_VW, mean(ret_EW) as ret_EW, count(*) as nobs
     from tst.pret_NOA
	group by rank_NOA;

   create table HL_NOA as
   select 11 as rank_NOA, mean(a.nfirms,b.nfirms) as nfirms, mean(a.min_nfirms,b.min_nfirms) as min_nfirms,
          a.ret_VW-b.ret_VW as ret_VW, a.ret_EW-b.ret_EW as ret_EW, min(a.nobs,b.nobs) as nobs
     from Mean_NOA as a, Mean_NOA as b
	where a.rank_NOA=10 and b.rank_NOA=1;

   create table Mean_NOA as
   select * from Mean_NOA
          union
   select * from HL_NOA;

quit;
