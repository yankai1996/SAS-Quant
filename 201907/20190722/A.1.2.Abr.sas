
libname daily "V:\data_for_kai\Daily data";
libname us "V:\data_for_kai\Compustat&CRSP merged\";

data retd; set daily.us; 
proc sort data=retd; by date;
run;

proc sql;
create table retd as 
select a.*, b.mc_mth as lagmc
from retd as a, us.agret1 as b
where a.permno=b.code and intck("month", b.date, a.date)=1;
quit;

proc means data=retd noprint;
by date;
var retx;
weight lagmc;
output out=mktret mean=mktret;
run;

data retd; merge retd mktret;
by date;
format date YYMMDDN8.;
drop _freq_ _type_;
run;


proc sql;
create table rdq as
select distinct code, rdq 
from us.agret1
where rdq~=.;

create table agret3 as 
select distinct a.code, a.rdq, b.retx as ret, b.date, b.mktret 
from rdq as a, retd as b
where a.code=b.permno and -2<=intck('day',a.rdq,b.date)<=1
group by a.code, a.rdq;

create table abr as 
select distinct code, rdq, sum(ret-mktret) as Abr
from agret3
group by code, rdq
having count(ret)=4;

create table abr as
select a.code, a.date, a.mthyr, a.portyear, a.ret, b.abr, b.rdq
from us.agret1 as a, abr as b
where a.code=b.code and a.date>b.rdq
group by a.code, a.date
having a.date-b.rdq=min(a.date-b.rdq);
quit;
