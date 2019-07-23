***************************************************************************************************
* Composite Equity Issuance Portfolios (Daniel and Titman, 2006)
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


*** Composite Equity Issuance;
proc sql;

  *** Changes in log ME;
  create table logME_Jun as
  select permno, year(date) as myear, exchcd, prc, log(prc*shrout) as logME
    from raw.msf6113
   where prc*shrout>0 and month(date)=6;

  create table logME_chg as
  select a.permno, a.myear, a.exchcd, a.prc, a.logME-b.logME as logME_chg
    from logME_Jun as a, logME_Jun as b
   where a.permno=b.permno and a.myear-b.myear=5;

  *** 5-year cumulative log return;
  create table ret as
  select permno, date, year(intnx('month',date,+6)) as myear, ret
    from raw.msf6113
   where ^missing(ret); 

  create table logret as
  select permno, myear, sum(log(1+ret)) as logret
    from ret
   group by permno, myear
  having count(ret)=12;

  create table logret_5yr as
  select a.permno, a.myear, sum(b.logret) as logret_5yr
    from logret as a, logret as b
   where a.permno=b.permno and 0<=a.myear-b.myear<=4
   group by a.permno, a.myear
  having count(b.logret)=5;

  *** Composite Equity Issuance;
  create table CEI as
  select a.*, b.logret_5yr
    from logME_chg as a, logret_5yr as b
   where a.permno=b.permno and a.myear=b.myear;

  create table tst.CEI as
  select *, logME_chg-logret_5yr as CEI
    from CEI
   where 1966<=myear<=2013; /** N=141,480 from myear 1966 to 2013 **/

quit;


*** June-end CEI;
proc sql;
   create table Jun_CEI as
   select a.permno, a.exchcd, b.myear, b.CEI
     from cln.returns_all (where=(month(date)=6)) as a, tst.CEI as b
	where a.permno=b.permno and year(a.date)=b.myear
	  and a.ABM in (0,1) /** use ABM=1 to exclude micro stocks **/
    order by myear;
quit;

*** Rank on June-end CEI using NYSE breakpoints;
proc univariate data=Jun_CEI noprint;
   var CEI;
   by myear;
   where exchcd=1; *** Exclude this line for ALL breakpoints;
   output out=BP_CEI
          n=nfirms
          pctlpts=10 to 90 by 10
          pctlpre=P;
run;

proc sql;

   create table tst.Jun_CEI as
   select a.*, case when        a.CEI<b.P10 then 1
                    when b.P10<=a.CEI<b.P20 then 2
                    when b.P20<=a.CEI<b.P30 then 3
                    when b.P30<=a.CEI<b.P40 then 4
                    when b.P40<=a.CEI<b.P50 then 5
                    when b.P50<=a.CEI<b.P60 then 6
                    when b.P60<=a.CEI<b.P70 then 7
                    when b.P70<=a.CEI<b.P80 then 8
                    when b.P80<=a.CEI<b.P90 then 9
                    else 10 end as rank_CEI 
     from Jun_CEI as a, BP_CEI as b
	where a.myear=b.myear; /** N=114,330 or 55,316 for ABM **/

   *** Append ranking to July t to June t+1;
   create table tst.ret_CEI as
   select a.*, b.rank_CEI
     from cln.returns as a, tst.Jun_CEI as b
	where a.permno=b.permno and a.myear=b.myear and year(a.date)>=1967; /** N=1,300,121 or 636,164 for ABM **/

   *** Portfolio returns;
   create table tst.pret_CEI as
   select rank_CEI, year(date) as year, month(date) as month, count(*) as nfirms, 
          sum(ret*ME_beg)/sum(ME_beg)*100 as ret_VW, mean(ret)*100 as ret_EW,

		  /** Characteristics of VW portfolios (FF aggregation) **/
		  sum(ME*ME_beg)/sum(IFN(missing(ME),0,1)*ME_beg)/1000 as ME_VW, 
          sum(AT-AT_lag)/sum(AT_lag)*100 as I2A_VW, 
          sum(IBQ)/sum(BEQ_lag)*100      as ROE_VW,

		  /** Characteristics of EW portfolios (1/ME aggregation) **/
		  mean(ME)/1000 as ME_EW, 
		  sum((AT-AT_lag)*(1/ME_beg))/sum(AT_lag*(1/ME_beg))*100 as I2A_EW, 
          sum(IBQ*(1/ME_beg))/sum(BEQ_lag*(1/ME_beg))*100        as ROE_EW

	 from tst.ret_CEI
	group by rank_CEI, date;

   *** Quick check;
   create table Mean_CEI as
   select rank_CEI, mean(nfirms) as nfirms, min(nfirms) as min_nfirms, 
          mean(ret_VW) as ret_VW, mean(ret_EW) as ret_EW, count(*) as nobs
     from tst.pret_CEI
	group by rank_CEI;

   create table HL_CEI as
   select 11 as rank_CEI, mean(a.nfirms,b.nfirms) as nfirms, mean(a.min_nfirms,b.min_nfirms) as min_nfirms,
          a.ret_VW-b.ret_VW as ret_VW, a.ret_EW-b.ret_EW as ret_EW, min(a.nobs,b.nobs) as nobs
     from Mean_CEI as a, Mean_CEI as b
	where a.rank_CEI=10 and b.rank_CEI=1;

   create table Mean_CEI as
   select * from Mean_CEI
          union
   select * from HL_CEI;

quit;
