***************************************************************************************************
* Size Portfolios (Banz, 1981)
***************************************************************************************************
* Chen Xue / A Comparison of New Factor Models / 2014-06-16
***************************************************************************************************;

*** Specify data libraries;
%let root=G:\Project -- Factor Model Comparison\2014-06-16;
libname raw "&root\Data Raw";
libname cln "&root\Data Clean";
libname tst "&root\Data Test (Group 6)";

*** Specify the macros;
filename mac "&root\Macros";
%include mac("*");

*** Clear the work folder;
proc delete data=work._all_; run;


*** ME;
proc sql;
   create table tst.ME as
   select permno, year(date) as myear, prc*shrout as ME
     from cln.returns_all
    where year(date)>=1966 and prc*shrout>0 and month(date)=6;
quit; /** N=187,889 from myear 1966 to 2013 **/


*** June-end ME;
proc sql;
   create table Jun_ME as
   select a.permno, a.exchcd, b.myear, b.ME
     from cln.returns_all (where=(month(date)=6)) as a, tst.ME as b
	where a.permno=b.permno and year(a.date)=b.myear
	  and a.ABM in (0,1) /** use ABM=1 to exclude micro stocks **/
    order by myear;
quit;

*** Rank on June-end ME using NYSE breakpoints;
proc univariate data=Jun_ME noprint;
   var ME;
   by myear;
   where exchcd=1; *** Exclude this line for ALL breakpoints;
   output out=BP_ME
          n=nfirms
          pctlpts=10 to 90 by 10
          pctlpre=P;
run;

proc sql;

   create table tst.Jun_ME as
   select a.*, case when        a.ME<b.P10 then 1
                    when b.P10<=a.ME<b.P20 then 2
                    when b.P20<=a.ME<b.P30 then 3
                    when b.P30<=a.ME<b.P40 then 4
                    when b.P40<=a.ME<b.P50 then 5
                    when b.P50<=a.ME<b.P60 then 6
                    when b.P60<=a.ME<b.P70 then 7
                    when b.P70<=a.ME<b.P80 then 8
                    when b.P80<=a.ME<b.P90 then 9
                    else 10 end as rank_ME 
     from Jun_ME as a, BP_ME as b
	where a.myear=b.myear; /** N=187,889 or 72,935 for ABM **/

   *** Append ranking to July t to June t+1;
   create table tst.ret_ME as
   select a.*, b.rank_ME
     from cln.returns as a, tst.Jun_ME as b
	where a.permno=b.permno and a.myear=b.myear and year(a.date)>=1967; /** N=2,121,883 or 937,121 for ABM **/

   *** Portfolio returns;
   create table tst.pret_ME as
   select rank_ME, year(date) as year, month(date) as month, count(*) as nfirms, 
          sum(ret*ME_beg)/sum(ME_beg)*100 as ret_VW, mean(ret)*100 as ret_EW,

		  /** Characteristics of VW portfolios (FF aggregation) **/
		  sum(ME*ME_beg)/sum(IFN(missing(ME),0,1)*ME_beg)/1000 as ME_VW, 
          sum(AT-AT_lag)/sum(AT_lag)*100 as I2A_VW, 
          sum(IBQ)/sum(BEQ_lag)*100      as ROE_VW,

		  /** Characteristics of EW portfolios (1/ME aggregation) **/
		  mean(ME)/1000 as ME_EW, 
		  sum((AT-AT_lag)*(1/ME_beg))/sum(AT_lag*(1/ME_beg))*100 as I2A_EW, 
          sum(IBQ*(1/ME_beg))/sum(BEQ_lag*(1/ME_beg))*100        as ROE_EW

	 from tst.ret_ME
	group by rank_ME, date;

   *** Quick check;
   create table Mean_ME as
   select rank_ME, mean(nfirms) as nfirms, min(nfirms) as min_nfirms, 
          mean(ret_VW) as ret_VW, mean(ret_EW) as ret_EW, count(*) as nobs
     from tst.pret_ME
	group by rank_ME;

   create table HL_ME as
   select 11 as rank_ME, mean(a.nfirms,b.nfirms) as nfirms, mean(a.min_nfirms,b.min_nfirms) as min_nfirms,
          a.ret_VW-b.ret_VW as ret_VW, a.ret_EW-b.ret_EW as ret_EW, min(a.nobs,b.nobs) as nobs
     from Mean_ME as a, Mean_ME as b
	where a.rank_ME=10 and b.rank_ME=1;

   create table Mean_ME as
   select * from Mean_ME
          union
   select * from HL_ME;

quit;
