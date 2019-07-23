***************************************************************************************************
* ROE Portfolios (Haugen and Baker, 1996)
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


*** ROE;
*** For portfolio formation before 1972;
proc sql;

   *** Quarterly earnings and lagged BEQ;
   create table ROE_pre72 as
   select a.permno, a.datadate, a.IBQ label='IBQ', b.BEQ as BEQ_lag
     from raw.qacc6113 as a, tst.BEQ_imp as b
	where a.permno=b.permno and intck('month',b.datadate,a.datadate)=3
      and 1966<=year(a.datadate)<=1971;

   create table tst.ROE_pre72 as
   select *, IBQ/BEQ_lag as ROE
     from ROE_pre72
	where IBQ^=. and BEQ_lag>0;

quit; /** N=34,762 from 1966 to 1971 **/

*** For portfolio formation after 1972;
proc sql;

   create table ROE_post72 as
   select a.permno, a.datadate, a.rdq, a.IBQ label='IBQ',
		  coalesce(b.SEQQ,b.CEQQ+b.PSTKQ,b.ATQ-b.LTQ)+coalesce(b.TXDITCQ,0)-coalesce(b.PSTKRQ,b.PSTKQ) as BEQ_lag
     from raw.qacc6113 as a, raw.qacc6113 as b
	where a.permno=b.permno and intck('month',b.datadate,a.datadate)=3
      and 1971<=year(a.datadate);

   create table tst.ROE_post72 as
   select *, IBQ/BEQ_lag as ROE
     from ROE_post72
	where IBQ^=. and BEQ_lag>0
      and datadate<rdq; /** Announcement should be after FQE **/

quit; /** N=659,760 from 1971 to 2013 **/


*** Announced ROE by month-end;
proc sql;

   *** For portfolio formation at month-end of 12/1966 to 11/1971: Lag ROE by 4 months;
   create table mon_ROE_pre72 as
   select a.permno, a.date, a.exchcd, b.ROE, b.datadate
     from cln.returns_all as a, tst.ROE_pre72 as b
	where a.permno=b.permno
	  and mdy(12,1,1966)<=a.date<=mdy(11,30,1971)
      and a.ABM in (0,1)                          /** use ABM=1 to exclude micro stocks **/
      and 4<=intck('month',b.datadate,a.date)<=6; /** Lag ROE by 4 months after FQE **/

   *** For portfolio formation at month-end of 12/1971 to 11/2013: Use announcement date;
   create table mon_ROE_post72 as
   select a.permno, a.date, a.exchcd, b.ROE, b.datadate
     from cln.returns_all as a, tst.ROE_post72 as b
	where a.permno=b.permno
      and mdy(12,1,1971)<=a.date<=mdy(11,30,2013)
	  and a.ABM in (0,1)                          /** use ABM=1 to exclude micro stocks **/
      and 0<=intck('month',b.rdq,a.date)          /** Annouced by formation **/
      and 1<=intck('month',b.datadate,a.date)<=6; /** FQE at most 6 month old at formation **/

   *** Merge;
   create table mon_ROE as
   select permno, date, exchcd, ROE, datadate from mon_ROE_pre72
          union
   select permno, date, exchcd, ROE, datadate from mon_ROE_post72;

quit;

*** Keep the lastest announced ROE;
proc sort data=mon_ROE; by date permno descending datadate; run;
proc sort data=mon_ROE nodupkey; by date permno; run;

*** Rank on ROE at the end of month t-1 (or equivalently the beginning of t);
proc univariate data=mon_ROE noprint;
   var ROE;
   by date;
   where exchcd=1; *** Exclude this line for ALL breakpoints;
   output out=BP_ROE
          n=nfirms
          pctlpts=10 to 90 by 10
          pctlpre=P;
run;

proc sql;
   create table tst.mon_ROE as
   select a.*, case when        a.ROE<b.P10 then 1
                    when b.P10<=a.ROE<b.P20 then 2
                    when b.P20<=a.ROE<b.P30 then 3
                    when b.P30<=a.ROE<b.P40 then 4
                    when b.P40<=a.ROE<b.P50 then 5
                    when b.P50<=a.ROE<b.P60 then 6
                    when b.P60<=a.ROE<b.P70 then 7
                    when b.P70<=a.ROE<b.P80 then 8
                    when b.P80<=a.ROE<b.P90 then 9
                    else 10 end as rank_ROE 
     from mon_ROE as a, BP_ROE as b
	where a.date=b.date;
quit; /** N=1,718,611 or 778,298 for ABM from 12/1966 to 11/2013 **/


*** Hold the portfolios from t to t+J-1;
%let J=;

proc sql;

   create table tst.ret_ROE_&J as
   select distinct a.permno, a.date, a.ret, a.ME_beg, a.ME, a.AT, a.AT_lag, a.IBQ, a.BEQ_lag,
          b.rank_ROE as rank_ROE_&J, b.date as form_date label='formation date'
     from cln.returns as a, tst.mon_ROE as b
	where a.permno=b.permno and 1<=intck('month',b.date,a.date)<=&J;	
   /** J=1: N=1,708,159 or 775,067 for ABM **/

   *** Portfolio returns;
   create table pret_ROE_&J as
   select rank_ROE_&J, date, form_date, count(*) as nfirms, 
          sum(ret*ME_beg)/sum(ME_beg)*100 as ret_VW, mean(ret)*100 as ret_EW,

		  /** Characteristics of VW portfolios (FF aggregation) **/
		  sum(ME*ME_beg)/sum(IFN(missing(ME),0,1)*ME_beg)/1000 as ME_VW, 
          sum(AT-AT_lag)/sum(AT_lag)*100 as I2A_VW, 
          sum(IBQ)/sum(BEQ_lag)*100      as ROE_VW,

		  /** Characteristics of EW portfolios (1/ME aggregation) **/
		  mean(ME)/1000 as ME_EW, 
		  sum((AT-AT_lag)*(1/ME_beg))/sum(AT_lag*(1/ME_beg))*100 as I2A_EW, 
          sum(IBQ*(1/ME_beg))/sum(BEQ_lag*(1/ME_beg))*100        as ROE_EW

	 from tst.ret_ROE_&J
	group by rank_ROE_&J, date, form_date;

   *** Average over formation dates;
   create table tst.pret_ROE_&J as
   select rank_ROE_&J, year(date) as year, month(date) as month, mean(nfirms) as nfirms, 
          mean(ret_VW) as ret_VW, mean(ret_EW) as ret_EW, count(*) as nobs,
		  mean(ME_VW)  as ME_VW,  mean(I2A_VW) as I2A_VW, mean(ROE_VW)  as ROE_VW,
          mean(ME_EW)  as ME_EW,  mean(I2A_EW) as I2A_EW, mean(ROE_EW)  as ROE_EW
	 from pret_ROE_&J
	group by rank_ROE_&J, date;

   *** Quick check;
   create table Mean_ROE_&J as
   select rank_ROE_&J, mean(nfirms) as nfirms, min(nfirms) as min_nfirms, 
          mean(ret_VW) as ret_VW, mean(ret_EW) as ret_EW, count(*) as nobs
     from tst.pret_ROE_&J
	group by rank_ROE_&J;

   create table HL_ROE_&J as
   select 11 as rank_ROE_&J, mean(a.nfirms,b.nfirms) as nfirms, mean(a.min_nfirms,b.min_nfirms) as min_nfirms,
          a.ret_VW-b.ret_VW as ret_VW, a.ret_EW-b.ret_EW as ret_EW, min(a.nobs,b.nobs) as nobs
     from Mean_ROE_&J as a, Mean_ROE_&J as b
	where a.rank_ROE_&J=10 and b.rank_ROE_&J=1;

   create table Mean_ROE_&J as
   select * from Mean_ROE_&J
          union
   select * from HL_ROE_&J;

quit;
