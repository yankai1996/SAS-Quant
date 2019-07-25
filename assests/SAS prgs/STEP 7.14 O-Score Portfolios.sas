***************************************************************************************************
* O-Score Portfolios (Ohlson, 1980, Dichev, 1998, Griffin and Lemmon, 2002)
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


*** O-Score;
proc sql;

   create table O_1 as
   select a.permno, a.datadate, year(a.datadate)+1 as myear, 
          a.LT, a.DLC, a.DLTT, a.LCT, a.ACT, a.AT, a.NI, a.PI, b.NI as NI_lag
     from raw.acc6113 as a, raw.acc6113 as b
	where a.permno=b.permno and intck('month',b.datadate,a.datadate)=12;

   create table O_2 as
   select *,
          log(AT)       as logTA,
          (DLC+DLTT)/AT as TLTA,
		  (ACT-LCT)/AT  as WCTA, 
          LCT/ACT       as CLCA,
		  case when LT-AT>0 then 1 else 0 end as OENEG,
		  NI/AT as NITA, 
          PI/LT as FUTL,
		  case when NI<0 and NI_lag<0 then 1 else 0 end as INTWO,
		  (NI-NI_lag)/(abs(NI)+abs(NI_lag)) as CHIN
	 from O_1
    where AT>0 and ACT>0 and LT>0 and DLC^=. and DLTT^=. and LCT^=. and NI^=. and PI^=. and NI_lag^=.;

   *** O-score;
   *** Note that winsorization has little impact on sorting;
   create table O_3 as
   select *, 
          -1.32 -0.407*logTA +6.03*TLTA -1.43*WCTA +0.076*CLCA -1.72*OENEG
          -2.37*NITA -1.83*FUTL +0.285*INTWO -0.521*CHIN as O
	 from O_2;

   create table tst.O as
   select *
     from O_3
	where O^=. and 1966<=myear<=2013; /** N=166,968 from myear 1966 to 2013 **/

quit;


*** June-end O;
proc sql;
   create table Jun_O as
   select a.permno, a.exchcd, b.myear, b.O
     from cln.returns_all (where=(month(date)=6)) as a, tst.O as b
	where a.permno=b.permno and year(a.date)=b.myear
	  and a.ABM in (0,1) /** use ABM=1 to exclude micro stocks **/
    order by myear;
quit;

*** Rank on June-end O using NYSE breakpoints;
proc univariate data=Jun_O noprint;
   var O;
   by myear;
   where exchcd=1; *** Exclude this line for ALL breakpoints;
   output out=BP_O
          n=nfirms
          pctlpts=10 to 90 by 10
          pctlpre=P;
run;

proc sql;

   create table tst.Jun_O as
   select a.*, case when        a.O<b.P10 then 1
                    when b.P10<=a.O<b.P20 then 2
                    when b.P20<=a.O<b.P30 then 3
                    when b.P30<=a.O<b.P40 then 4
                    when b.P40<=a.O<b.P50 then 5
                    when b.P50<=a.O<b.P60 then 6
                    when b.P60<=a.O<b.P70 then 7
                    when b.P70<=a.O<b.P80 then 8
                    when b.P80<=a.O<b.P90 then 9
                    else 10 end as rank_O 
     from Jun_O as a, BP_O as b
	where a.myear=b.myear; /** N=147,962 or 62,372 for ABM **/

   *** Append ranking to July t to June t+1;
   create table tst.ret_O as
   select a.*, b.rank_O
     from cln.returns as a, tst.Jun_O as b
	where a.permno=b.permno and a.myear=b.myear and year(a.date)>=1967; /** N= 1,680,830 or 718,350 for ABM **/

   *** Portfolio returns;
   create table tst.pret_O as
   select rank_O, year(date) as year, month(date) as month, count(*) as nfirms, 
          sum(ret*ME_beg)/sum(ME_beg)*100 as ret_VW, mean(ret)*100 as ret_EW,

		  /** Characteristics of VW portfolios (FF aggregation) **/
		  sum(ME*ME_beg)/sum(IFN(missing(ME),0,1)*ME_beg)/1000 as ME_VW, 
          sum(AT-AT_lag)/sum(AT_lag)*100 as I2A_VW, 
          sum(IBQ)/sum(BEQ_lag)*100      as ROE_VW,

		  /** Characteristics of EW portfolios (1/ME aggregation) **/
		  mean(ME)/1000 as ME_EW, 
		  sum((AT-AT_lag)*(1/ME_beg))/sum(AT_lag*(1/ME_beg))*100 as I2A_EW, 
          sum(IBQ*(1/ME_beg))/sum(BEQ_lag*(1/ME_beg))*100        as ROE_EW

	 from tst.ret_O
	group by rank_O, date;

   *** Quick check;
   create table Mean_O as
   select rank_O, mean(nfirms) as nfirms, min(nfirms) as min_nfirms, 
          mean(ret_VW) as ret_VW, mean(ret_EW) as ret_EW, count(*) as nobs
     from tst.pret_O
	group by rank_O;

   create table HL_O as
   select 11 as rank_O, mean(a.nfirms,b.nfirms) as nfirms, mean(a.min_nfirms,b.min_nfirms) as min_nfirms,
          a.ret_VW-b.ret_VW as ret_VW, a.ret_EW-b.ret_EW as ret_EW, min(a.nobs,b.nobs) as nobs
     from Mean_O as a, Mean_O as b
	where a.rank_O=10 and b.rank_O=1;

   create table Mean_O as
   select * from Mean_O
          union
   select * from HL_O;

quit;

