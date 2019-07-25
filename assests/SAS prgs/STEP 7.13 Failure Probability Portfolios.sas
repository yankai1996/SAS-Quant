***************************************************************************************************
* Failure Probability Portfolios
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


*** Construct components of FP (start in 1975 for enough coverage);
*** PRICE, EXRET, and RSIZE;
proc sql;

   *** PRICE (exclude penny stocks and winsorize above at $15);
   create table Distress_1 as
   select permno, date, ret, prc*shrout as ME,
          case when 1<=prc<15 then log(prc)
               when prc>=15   then log(15)
			   else . end as PRICE
     from cln.returns_all
    where year(date)>=1975; /** N=1,984,033 from 1975 to 2013 **/
  
   *** EXRET and RSIZE (relative to S&P500);
   create table Distress_2 as
   select a.permno, a.date, a.PRICE,
          log(1+a.ret)-log(1+b.sprtrn) as EXRET, 
          log(a.ME/(b.totval/1000))    as RSIZE
     from Distress_1 as a, raw.msp500_6113 as b
    where year(a.date)=year(b.caldt) and month(a.date)=month(b.caldt);

   *** EXRETAVG (past 12 months);
   create table tst.EXRETAVG as
   select distinct a.permno, a.date, 
          sum(b.EXRET*(2**(-1/3))**intck('month',b.date,a.date))*(1-2**(-1/3))/(15/16) as EXRETAVG
     from Distress_2 as a, Distress_2 as b
	where a.permno=b.permno and 0<=intck('month',b.date,a.date)<=11
	group by a.permno, a.date
   having count(b.EXRET)=12; /** N=1,742,006 from 12/1975 to 12/2013 **/

   create table Distress_3 as
   select a.permno, a.date, a.PRICE, a.RSIZE, b.EXRETAVG
     from Distress_2 as a
          left join
          tst.EXRETAVG as b
	   on a.permno=b.permno and a.date=b.date;

quit;


*** MB (quarterly);
proc sql;

   create table MB_1 as
   select a.permno, a.datadate,
          coalesce(a.SEQQ,a.CEQQ+a.PSTKQ,a.ATQ-a.LTQ)+coalesce(a.TXDITCQ,0)-coalesce(a.PSTKRQ,a.PSTKQ) as BEQ,
          b.prc*b.shrout as ME
     from raw.qacc6113 as a, raw.msf6113 as b
	where a.permno=b.permno and year(a.datadate)=year(b.date) and month(a.datadate)=month(b.date)
      and year(a.datadate)>=1975;

   *** Adjustment for BE;
   create table MB_2 as
   select *, case when BEQ+0.1*(ME-BEQ)>0 then BEQ+0.1*(ME-BEQ)
                  when coalesce(BEQ+0.1*(ME-BEQ),0.1)<=0 then 0.000001
				  else . end as BEQ_adj
	 from MB_1;

   create table MB_3 as
   select *, ME/BEQ_adj as MB
	 from MB_2
    where ME>0 and BEQ_adj>0; /** N=729,202 from 1975 to 2013 **/

   create table Distress_4 as
   select a.*, b.datadate, b.MB
     from Distress_3 as a
          left join
          MB_3 as b
	   on a.permno=b.permno
      and 4<=intck('month',b.datadate,a.date)<=6; /** Lag fiscal quarter end info by 4 months **/

quit;

*** For duplicates due to FQE change, keep the latest (N=168);
proc sort data=Distress_4; by permno date descending datadate; run;
proc sort data=Distress_4 (drop=datadate) nodupkey; by permno date; run;


*** SIGMA;
proc sql;

   create table dsf as
   select permno, year(date) as year, month(date) as month, ret,
          case when abs(ret)>0 then 1 else 0 end as nonzero /** dummy for nonzero return **/
     from raw.dsf6113
    where year(date)>=1975;

   *** Sum of squared returns each month;
   create table ret2_monthly as
   select permno, year, month, sum(ret**2) as ret2, count(ret) as nobs, sum(nonzero) as nobs_nz
     from dsf
	group by permno, year, month;

   *** Sum over the past 3 months;
   create table ret2_3month as
   select distinct a.permno, a.year, a.month, sum(b.ret2) as ret2, 
          sum(b.nobs) as nobs, sum(b.nobs_nz) as nobs_nz
     from ret2_monthly as a, ret2_monthly as b
	where a.permno=b.permno and 0<=(a.year*12+a.month)-(b.year*12+b.month)<=2
    group by a.permno, a.year, a.month;

   *** Annualized vol;
   *** Require at least 5 non-zero returns;
   create table tst.sigma as
   select permno, year, month, sqrt(ret2/(nobs-1)*252) as sigma, nobs, nobs_nz
     from ret2_3month
    where nobs_nz>=5; /** N=2,486,211 from 1975 to 2013 **/
 
   create table Distress_5 as
   select a.*, b.sigma
     from Distress_4 as a
          left join
          tst.sigma as b 
	   on a.permno=b.permno and year(a.date)=b.year and month(a.date)=b.month;

quit;


*** NIMTAAVG;
proc sql;

   *** NIMTA;
   create table NIMTA as
   select a.permno, a.datadate, a.NIQ/(a.LTQ+b.prc*b.shrout) as NIMTA
     from raw.qacc6113 as a, raw.msf6113 as b
	where a.permno=b.permno and year(a.datadate)=year(b.date) and month(a.datadate)=month(b.date)
      and ^missing(a.NIQ) and a.LTQ>=0 and b.prc*b.shrout>0;

   *** Lagged NIMTAs;
   create table NIMTAAVG_1 as
   select a.*, b.NIMTA as NIMTA_lag1 
     from NIMTA as a, NIMTA as b
	where a.permno=b.permno and intck('month',b.datadate,a.datadate)=3;

   create table NIMTAAVG_2 as
   select a.*, b.NIMTA as NIMTA_lag2
     from NIMTAAVG_1 as a, NIMTA as b
	where a.permno=b.permno and intck('month',b.datadate,a.datadate)=6;

   create table NIMTAAVG_3 as
   select a.*, b.NIMTA as NIMTA_lag3
     from NIMTAAVG_2 as a, NIMTA as b
	where a.permno=b.permno and intck('month',b.datadate,a.datadate)=9;

   *** NIMTAAVG;
   create table tst.NIMTAAVG as
   select permno, datadate, (NIMTA+NIMTA_lag1/2+NIMTA_lag2/4+NIMTA_lag3/8)*8/15 as NIMTAAVG
     from NIMTAAVG_3
    where year(datadate)>=1975; /** N=656,194 from 1975 to 2013 **/

   create table Distress_6 as
   select a.*, b.datadate, b.NIMTAAVG
     from Distress_5 as a
          left join
          tst.NIMTAAVG as b
	   on a.permno=b.permno 
      and 4<=intck('month',b.datadate,a.date)<=6; /** Lag fiscal quarter end by 4 months **/

quit; /** No duplicates due to FQE change **/


*** TLMTA;
proc sql;

   create table TLMTA as
   select a.permno, a.datadate, a.LTQ/(a.LTQ+b.prc*b.shrout) as TLMTA
     from raw.qacc6113 as a, raw.msf6113 as b
	where a.permno=b.permno and year(a.datadate)=year(b.date) and month(a.datadate)=month(b.date)
	  and a.LTQ>=0 and b.prc*b.shrout>0
      and year(a.datadate)>=1975; /** N=725,443 from 1975 to 2013 **/

   create table Distress_7 as
   select a.*, b.datadate, b.TLMTA
     from Distress_6 (drop=datadate) as a
          left join
          TLMTA as b
	   on a.permno=b.permno 
      and 4<=intck('month',b.datadate,a.date)<=6; /** Lag fiscal quarter end by 4 months **/

quit;

*** For potential duplicates due to FQE change, keep the latest (N=166);
proc sort data=Distress_7; by permno date descending datadate; run;
proc sort data=Distress_7 (drop=datadate) nodupkey; by permno date; run;


*** CASHMTA;
proc sql;

   create table CASHMTA as
   select a.permno, a.datadate, a.CHEQ/(a.LTQ+b.prc*b.shrout) as CASHMTA
     from raw.qacc6113 as a, raw.msf6113 as b
	where a.permno=b.permno and year(a.datadate)=year(b.date) and month(a.datadate)=month(b.date)
      and ^missing(a.CHEQ) and a.LTQ>=0 and b.prc*b.shrout>0
      and year(a.datadate)>=1975; /** N=721,243 from 1975 to 2013 **/

   create table tst.Distress as
   select a.*, b.datadate, b.CASHMTA
     from Distress_7 as a
          left join
          CASHMTA as b
	   on a.permno=b.permno 
      and 4<=intck('month',b.datadate,a.date)<=6; /** Lag fiscal quarter end by 4 months **/

quit;

*** For potential duplicates due to FQE change, keep the latest (N=157);
proc sort data=tst.Distress; by permno date descending datadate; run;
proc sort data=tst.Distress (drop=datadate) nodupkey; by permno date; run; /** N=1,984,033 from 12/1975 to 12/2013 **/

*** 5/95 winsorization each month (instead of pooling over time);
*** Note that price is already truncated at $1 and winsorized at $15;
%winsorize_by_date(infile=tst.Distress, date=date, var=NIMTAAVG, low=5, high=95, outfile=tst.Distress);
%winsorize_by_date(infile=tst.Distress, date=date, var=TLMTA,    low=5, high=95, outfile=tst.Distress);
%winsorize_by_date(infile=tst.Distress, date=date, var=EXRETAVG, low=5, high=95, outfile=tst.Distress);
%winsorize_by_date(infile=tst.Distress, date=date, var=SIGMA,    low=5, high=95, outfile=tst.Distress);
%winsorize_by_date(infile=tst.Distress, date=date, var=RSIZE,    low=5, high=95, outfile=tst.Distress);
%winsorize_by_date(infile=tst.Distress, date=date, var=CASHMTA,  low=5, high=95, outfile=tst.Distress);
%winsorize_by_date(infile=tst.Distress, date=date, var=MB,       low=5, high=95, outfile=tst.Distress);


*** Failure Probability (Column 3 of Table 4 in Campbell et al.);
proc sql;

   create table FP as
   select permno, date, 
          -9.164 - 20.264*NIMTAAVG + 1.416*TLMTA - 7.129*EXRETAVG 
          + 1.411*SIGMA - 0.045*RSIZE - 2.132*CASHMTA + 0.075*MB - 0.058*PRICE as FP
	 from tst.Distress;

   create table tst.FP as
   select *
     from FP
	where FP^=.; /** N=1,424,419 from 12/1975 to 12/2013 **/

quit;


*** Month-end FP;
*** For enough coverage, start portfolio formation at the end of 1/1976;
proc sql;
   create table mon_FP as
   select a.*, b.FP
     from cln.returns_all as a, tst.FP as b
	where a.permno=b.permno and a.date=b.date
	  and mdy(1,1,1976)<=a.date<=mdy(11,30,2013) 
	  and a.ABM in (0,1) /** use ABM=1 to exclude micro stocks **/
    order by a.date;
quit;

*** Rank on Failure probability at the end of month t-1 (or the beginning of t);
proc univariate data=mon_FP noprint;
   var FP;
   by date;
   where exchcd=1; *** Exclude this line for ALL breakpoints;
   output out=BP_FP
          n=nfirms
          pctlpts=10 to 90 by 10
          pctlpre=P;
run;

proc sql;
   create table tst.mon_FP as
   select a.*,
          case when        a.FP<b.P10 then 1
               when b.P10<=a.FP<b.P20 then 2
               when b.P20<=a.FP<b.P30 then 3
               when b.P30<=a.FP<b.P40 then 4
               when b.P40<=a.FP<b.P50 then 5
               when b.P50<=a.FP<b.P60 then 6
               when b.P60<=a.FP<b.P70 then 7
               when b.P70<=a.FP<b.P80 then 8
               when b.P80<=a.FP<b.P90 then 9
               else 10 end as rank_FP
	 from mon_FP as a, BP_FP as b
	where a.date=b.date;
quit; /** N=1,421,775 or 640,675 for ABM from 1/1976 to 11/2013 **/


*** Hold the portfolios from t to t+J-1;
%let J=;

proc sql;

   create table tst.ret_FP_&J as
   select distinct a.permno, a.date, a.ret, a.ME_beg, a.ME, a.AT, a.AT_lag, a.IBQ, a.BEQ_lag,
          b.rank_FP as rank_FP_&J, b.date as form_date label='formation date'
     from cln.returns as a, tst.mon_FP as b
	where a.permno=b.permno and 1<=intck('month',b.date,a.date)<=&J;	
    /** J=1: N=1,414,030 or   637,722 for ABM **/
    /** J=6: N=8,301,832 or 3,758,426 for ABM **/

   *** Portfolio returns;
   create table pret_FP_&J as
   select rank_FP_&J, date, form_date, count(*) as nfirms, 
          sum(ret*ME_beg)/sum(ME_beg)*100 as ret_VW, mean(ret)*100 as ret_EW,

		  /** Characteristics of VW portfolios (FF aggregation) **/
		  sum(ME*ME_beg)/sum(IFN(missing(ME),0,1)*ME_beg)/1000 as ME_VW, 
          sum(AT-AT_lag)/sum(AT_lag)*100 as I2A_VW, 
          sum(IBQ)/sum(BEQ_lag)*100      as ROE_VW,

		  /** Characteristics of EW portfolios (1/ME aggregation) **/
		  mean(ME)/1000 as ME_EW, 
		  sum((AT-AT_lag)*(1/ME_beg))/sum(AT_lag*(1/ME_beg))*100 as I2A_EW, 
          sum(IBQ*(1/ME_beg))/sum(BEQ_lag*(1/ME_beg))*100        as ROE_EW

	 from tst.ret_FP_&J
	group by rank_FP_&J, date, form_date;

   *** Average over formation dates;
   create table tst.pret_FP_&J as
   select rank_FP_&J, year(date) as year, month(date) as month, mean(nfirms) as nfirms, 
          mean(ret_VW) as ret_VW, mean(ret_EW) as ret_EW, count(*) as nobs,
		  mean(ME_VW)  as ME_VW,  mean(I2A_VW) as I2A_VW, mean(ROE_VW)  as ROE_VW,
          mean(ME_EW)  as ME_EW,  mean(I2A_EW) as I2A_EW, mean(ROE_EW)  as ROE_EW
	 from pret_FP_&J
	group by rank_FP_&J, date;

   *** Quick check;
   create table Mean_FP_&J as
   select rank_FP_&J, mean(nfirms) as nfirms, min(nfirms) as min_nfirms, 
          mean(ret_VW) as ret_VW, mean(ret_EW) as ret_EW, count(*) as nobs
     from tst.pret_FP_&J
	group by rank_FP_&J;

   create table HL_FP_&J as
   select 11 as rank_FP_&J, mean(a.nfirms,b.nfirms) as nfirms, mean(a.min_nfirms,b.min_nfirms) as min_nfirms,
          a.ret_VW-b.ret_VW as ret_VW, a.ret_EW-b.ret_EW as ret_EW, min(a.nobs,b.nobs) as nobs
     from Mean_FP_&J as a, Mean_FP_&J as b
	where a.rank_FP_&J=10 and b.rank_FP_&J=1;

   create table Mean_FP_&J as
   select * from Mean_FP_&J
          union
   select * from HL_FP_&J;

quit;
