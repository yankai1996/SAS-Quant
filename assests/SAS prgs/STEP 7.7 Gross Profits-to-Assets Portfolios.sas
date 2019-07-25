***************************************************************************************************
* Gross Profits-to-Assets Portfolios (Novy-Marx, 2013)
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


*** Gross Profits to CURRENT Assets;
proc sql;

   create table GP2A as
   select permno, datadate, year(datadate)+1 as myear, REVT, COGS, AT, (REVT-COGS)/AT as GP2A
	 from raw.acc6113
    where (REVT-COGS)^=. and AT>0 and 1966<=year(datadate)+1<=2013;

   *** For duplicates due to FYE chang, keep the latest;
   create table tst.GP2A as
   select *
     from GP2A
	group by permno, myear
   having datadate=max(datadate);

quit; /** N=215,924 from myear 1966 to 2013 **/


*** June-end GP/A;
proc sql;
   create table Jun_GP2A as
   select a.permno, a.exchcd, b.myear, b.GP2A
     from cln.returns_all (where=(month(date)=6)) as a, tst.GP2A as b
	where a.permno=b.permno and year(a.date)=b.myear
	  and a.ABM in (0,1) /** use ABM=1 to exclude micro stocks **/
    order by myear;
quit;

*** Rank on June-end GP/A using NYSE breakpoints;
proc univariate data=Jun_GP2A noprint;
   var GP2A;
   by myear;
   where exchcd=1; *** Exclude this line for ALL breakpoints;
   output out=BP_GP2A
          n=nfirms
          pctlpts=10 to 90 by 10
          pctlpre=P;
run;

proc sql;

   create table tst.Jun_GP2A as
   select a.*, case when        a.GP2A<b.P10 then 1
                    when b.P10<=a.GP2A<b.P20 then 2
                    when b.P20<=a.GP2A<b.P30 then 3
                    when b.P30<=a.GP2A<b.P40 then 4
                    when b.P40<=a.GP2A<b.P50 then 5
                    when b.P50<=a.GP2A<b.P60 then 6
                    when b.P60<=a.GP2A<b.P70 then 7
                    when b.P70<=a.GP2A<b.P80 then 8
                    when b.P80<=a.GP2A<b.P90 then 9
                    else 10 end as rank_GP2A 
     from Jun_GP2A as a, BP_GP2A as b
	where a.myear=b.myear; /** N=168,438 or 68,798 for ABM **/

   *** Append ranking to July t to June t+1;
   create table tst.ret_GP2A as
   select a.*, b.rank_GP2A
     from cln.returns as a, tst.Jun_GP2A as b
	where a.permno=b.permno and a.myear=b.myear and year(a.date)>=1967; /** N= 1,911,706 or 791,615 for ABM **/

   *** Portfolio returns;
   create table tst.pret_GP2A as
   select rank_GP2A, year(date) as year, month(date) as month, count(*) as nfirms, 
          sum(ret*ME_beg)/sum(ME_beg)*100 as ret_VW, mean(ret)*100 as ret_EW,

		  /** Characteristics of VW portfolios (FF aggregation) **/
		  sum(ME*ME_beg)/sum(IFN(missing(ME),0,1)*ME_beg)/1000 as ME_VW, 
          sum(AT-AT_lag)/sum(AT_lag)*100 as I2A_VW, 
          sum(IBQ)/sum(BEQ_lag)*100      as ROE_VW,

		  /** Characteristics of EW portfolios (1/ME aggregation) **/
		  mean(ME)/1000 as ME_EW, 
		  sum((AT-AT_lag)*(1/ME_beg))/sum(AT_lag*(1/ME_beg))*100 as I2A_EW, 
          sum(IBQ*(1/ME_beg))/sum(BEQ_lag*(1/ME_beg))*100        as ROE_EW

	 from tst.ret_GP2A
	group by rank_GP2A, date;

   *** Quick check;
   create table Mean_GP2A as
   select rank_GP2A, mean(nfirms) as nfirms, min(nfirms) as min_nfirms, 
          mean(ret_VW) as ret_VW, mean(ret_EW) as ret_EW, count(*) as nobs
     from tst.pret_GP2A
	group by rank_GP2A;

   create table HL_GP2A as
   select 11 as rank_GP2A, mean(a.nfirms,b.nfirms) as nfirms, mean(a.min_nfirms,b.min_nfirms) as min_nfirms,
          a.ret_VW-b.ret_VW as ret_VW, a.ret_EW-b.ret_EW as ret_EW, min(a.nobs,b.nobs) as nobs
     from Mean_GP2A as a, Mean_GP2A as b
	where a.rank_GP2A=10 and b.rank_GP2A=1;

   create table Mean_GP2A as
   select * from Mean_GP2A
          union
   select * from HL_GP2A;

quit;
