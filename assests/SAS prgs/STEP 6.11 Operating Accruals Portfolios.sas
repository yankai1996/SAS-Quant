  ***************************************************************************************************
* Operating Accruals Portfolios (Sloan, 1996, Kraft et al., 2006, Hafzalla et al., 2011)
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


*** Operating Accruals;
proc sql;

   *** Use Balance Sheet before 1988 (Sloan, 1996);
   *** Treat missing values to zero for minor iterms (short-term debt, tax payable, depreciation);
   create table OABS as
   select a.permno, a.datadate, year(a.datadate)+1 as myear, 
          (   ((a.ACT-b.ACT)-(a.CHE-b.CHE)) 
            - ((a.LCT-b.LCT)-(coalesce(a.DLC,0)-coalesce(b.DLC,0))-(coalesce(a.TXP,0)-coalesce(b.TXP,0)))
			- coalesce(a.DP,0) ) / b.AT as OABS
     from raw.acc6113 as a, raw.acc6113 as b
	where a.permno=b.permno and intck('month',b.datadate,a.datadate)=12 and b.AT>0;

   *** Use Cash Flow after 1988 (Kraft et al., 2006);
   create table OACF as
   select a.permno, a.datadate, year(a.datadate)+1 as myear, 
          (a.NI-a.OANCF)/b.AT as OACF
     from raw.acc6113 as a, raw.acc6113 as b
	where a.permno=b.permno and intck('month',b.datadate,a.datadate)=12 and b.AT>0;

   create table tst.OA as
   select permno, datadate, myear, OABS as OA from OABS where OABS^=. and 1966<=myear<=1988
          union
   select permno, datadate, myear, OACF as OA from OACF where OACF^=. and 1989<=myear<=2013; 
   /** N=180,112 from myear 1966 to 2013 **/

quit;


*** June-end OA;
proc sql;
   create table Jun_OA as
   select a.permno, a.exchcd, b.myear, b.OA
     from cln.returns_all (where=(month(date)=6)) as a, tst.OA as b
	where a.permno=b.permno and year(a.date)=b.myear
	  and a.ABM in (0,1) /** use ABM=1 to exclude micro stocks **/
    order by myear;
quit;

*** Rank on June-end OA using NYSE breakpoints;
proc univariate data=Jun_OA noprint;
   var OA;
   by myear;
   where exchcd=1; *** Exclude this line for ALL breakpoints;
   output out=BP_OA
          n=nfirms
          pctlpts=10 to 90 by 10
          pctlpre=P;
run;

proc sql;

   create table tst.Jun_OA as
   select a.*, case when        a.OA<b.P10 then 1
                    when b.P10<=a.OA<b.P20 then 2
                    when b.P20<=a.OA<b.P30 then 3
                    when b.P30<=a.OA<b.P40 then 4
                    when b.P40<=a.OA<b.P50 then 5
                    when b.P50<=a.OA<b.P60 then 6
                    when b.P60<=a.OA<b.P70 then 7
                    when b.P70<=a.OA<b.P80 then 8
                    when b.P80<=a.OA<b.P90 then 9
                    else 10 end as rank_OA 
     from Jun_OA as a, BP_OA as b
	where a.myear=b.myear; /** N=149,742 or 63,014 for ABM **/

   *** Append ranking to July t to June t+1;
   create table tst.ret_OA as
   select a.*, b.rank_OA
     from cln.returns as a, tst.Jun_OA as b
	where a.permno=b.permno and a.myear=b.myear and year(a.date)>=1967; /** N=1,700,075 or 725,385 for ABM **/

   *** Portfolio returns;
   create table tst.pret_OA as
   select rank_OA, year(date) as year, month(date) as month, count(*) as nfirms, 
          sum(ret*ME_beg)/sum(ME_beg)*100 as ret_VW, mean(ret)*100 as ret_EW,

		  /** Characteristics of VW portfolios (FF aggregation) **/
		  sum(ME*ME_beg)/sum(IFN(missing(ME),0,1)*ME_beg)/1000 as ME_VW, 
          sum(AT-AT_lag)/sum(AT_lag)*100 as I2A_VW, 
          sum(IBQ)/sum(BEQ_lag)*100      as ROE_VW,

		  /** Characteristics of EW portfolios (1/ME aggregation) **/
		  mean(ME)/1000 as ME_EW, 
		  sum((AT-AT_lag)*(1/ME_beg))/sum(AT_lag*(1/ME_beg))*100 as I2A_EW, 
          sum(IBQ*(1/ME_beg))/sum(BEQ_lag*(1/ME_beg))*100        as ROE_EW

	 from tst.ret_OA
	group by rank_OA, date;

   *** Quick check;
   create table Mean_OA as
   select rank_OA, mean(nfirms) as nfirms, min(nfirms) as min_nfirms, 
          mean(ret_VW) as ret_VW, mean(ret_EW) as ret_EW, count(*) as nobs
     from tst.pret_OA
	group by rank_OA;

   create table HL_OA as
   select 11 as rank_OA, mean(a.nfirms,b.nfirms) as nfirms, mean(a.min_nfirms,b.min_nfirms) as min_nfirms,
          a.ret_VW-b.ret_VW as ret_VW, a.ret_EW-b.ret_EW as ret_EW, min(a.nobs,b.nobs) as nobs
     from Mean_OA as a, Mean_OA as b
	where a.rank_OA=10 and b.rank_OA=1;

   create table Mean_OA as
   select * from Mean_OA
          union
   select * from HL_OA;

quit;
