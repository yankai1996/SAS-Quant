***************************************************************************************************
* ROA Portfolios (Balakrishnan, Bartov, and Faurel, 2010)
***************************************************************************************************
* Chen Xue / A Comparison of New Factor Models / 2014-06-16
***************************************************************************************************;

*** Specify data libraries;
%let root=G:\Project -- Factor Model Comparison\2014-06-16;
libname raw "&root\Data Raw";
libname cln "&root\Data Clean";
libname tst "&root\Data Test (Group 4)";

*** Specify the macros;
filename mac "&root\Macros";
%include mac("*");

*** Clear the work folder;
proc delete data=work._all_; run;


*** ROA;
proc sql;

   create table ROA as
   select a.permno, a.datadate, a.rdq, a.IBQ, b.ATQ, a.IBQ/b.ATQ as ROA
     from raw.qacc6113 as a, raw.qacc6113 as b
	where a.permno=b.permno and intck('month',b.datadate,a.datadate)=3 and b.ATQ>0;

   create table tst.ROA as
   select *
     from ROA
	where ROA^=.
      and year(datadate)>=1971
      and datadate<rdq; /** announcement date should be after fiscal quarter end **/

quit; /** N=654,516 from 1971 to 2013 **/


*** Announced ROA by month-end;
proc sql;
   create table mon_ROA as
   select a.*, b.ROA, b.datadate, b.rdq
     from cln.returns_all as a, tst.ROA as b
	where a.permno=b.permno
      and mdy(12,1,1971)<=a.date<=mdy(11,30,2013) 
	  and a.ABM in (0,1) /** use ABM=1 to exclude micro stocks **/
      and 0<=intck('month',b.rdq,a.date) /** annouced by month-end (formation date) **/
      and 1<=intck('month',b.datadate,a.date)<=6; /** avoid stale data: fiscal qtr at most 6 month old **/
quit;

*** Keep the lastest available ROA;
proc sort data=mon_ROA; by date permno descending datadate; run;
proc sort data=mon_ROA nodupkey; by date permno; run;

*** Rank on ROA at the end of month t-1 (or equivalently the beginning of t);
proc univariate data=mon_ROA noprint;
   var ROA;
   by date;
   where exchcd=1; *** Exclude this line for ALL breakpoints;
   output out=BP_ROA
          n=nfirms
          pctlpts=10 to 90 by 10
          pctlpre=P;
run;

proc sql;
   create table tst.mon_ROA as
   select a.*, case when        a.ROA<b.P10 then 1
                    when b.P10<=a.ROA<b.P20 then 2
                    when b.P20<=a.ROA<b.P30 then 3
                    when b.P30<=a.ROA<b.P40 then 4
                    when b.P40<=a.ROA<b.P50 then 5
                    when b.P50<=a.ROA<b.P60 then 6
                    when b.P60<=a.ROA<b.P70 then 7
                    when b.P70<=a.ROA<b.P80 then 8
                    when b.P80<=a.ROA<b.P90 then 9
                    else 10 end as rank_ROA 
     from mon_ROA as a, BP_ROA as b
	where a.date=b.date;
quit; /** N=1,598,869 or 710,984 for ABM from 12/1971 to 11/2013 **/


*** Hold the portfolios from t to t+J-1;
%let J=;

proc sql;

   create table tst.ret_ROA_&J as
   select distinct a.permno, a.date, a.ret, a.ME_beg, a.ME, a.AT, a.AT_lag, a.IBQ, a.BEQ_lag,
          b.rank_ROA as rank_ROA_&J, b.date as form_date label='formation date'
     from cln.returns as a, tst.mon_ROA as b
	where a.permno=b.permno and 1<=intck('month',b.date,a.date)<=&J;	
   /** J=1: N=1,588,529 or 707,833 for ABM **/

   *** Portfolio returns;
   create table pret_ROA_&J as
   select rank_ROA_&J, date, form_date, count(*) as nfirms, 
          sum(ret*ME_beg)/sum(ME_beg)*100 as ret_VW, mean(ret)*100 as ret_EW,

		  /** Characteristics of VW portfolios (FF aggregation) **/
		  sum(ME*ME_beg)/sum(IFN(missing(ME),0,1)*ME_beg)/1000 as ME_VW, 
          sum(AT-AT_lag)/sum(AT_lag)*100 as I2A_VW, 
          sum(IBQ)/sum(BEQ_lag)*100      as ROE_VW,

		  /** Characteristics of EW portfolios (1/ME aggregation) **/
		  mean(ME)/1000 as ME_EW, 
		  sum((AT-AT_lag)*(1/ME_beg))/sum(AT_lag*(1/ME_beg))*100 as I2A_EW, 
          sum(IBQ*(1/ME_beg))/sum(BEQ_lag*(1/ME_beg))*100        as ROE_EW

	 from tst.ret_ROA_&J
	group by rank_ROA_&J, date, form_date;

   *** Average over formation dates;
   create table tst.pret_ROA_&J as
   select rank_ROA_&J, year(date) as year, month(date) as month, mean(nfirms) as nfirms, 
          mean(ret_VW) as ret_VW, mean(ret_EW) as ret_EW, count(*) as nobs,
		  mean(ME_VW)  as ME_VW,  mean(I2A_VW) as I2A_VW, mean(ROE_VW)  as ROE_VW,
          mean(ME_EW)  as ME_EW,  mean(I2A_EW) as I2A_EW, mean(ROE_EW)  as ROE_EW
	 from pret_ROA_&J
	group by rank_ROA_&J, date;

   *** Quick check;
   create table Mean_ROA_&J as
   select rank_ROA_&J, mean(nfirms) as nfirms, min(nfirms) as min_nfirms, 
          mean(ret_VW) as ret_VW, mean(ret_EW) as ret_EW, count(*) as nobs
     from tst.pret_ROA_&J
	group by rank_ROA_&J;

   create table HL_ROA_&J as
   select 11 as rank_ROA_&J, mean(a.nfirms,b.nfirms) as nfirms, mean(a.min_nfirms,b.min_nfirms) as min_nfirms,
          a.ret_VW-b.ret_VW as ret_VW, a.ret_EW-b.ret_EW as ret_EW, min(a.nobs,b.nobs) as nobs
     from Mean_ROA_&J as a, Mean_ROA_&J as b
	where a.rank_ROA_&J=10 and b.rank_ROA_&J=1;

   create table Mean_ROA_&J as
   select * from Mean_ROA_&J
          union
   select * from HL_ROA_&J;

quit;
