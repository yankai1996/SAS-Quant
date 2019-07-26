
libname us "V:\data_for_kai\Compustat&CRSP merged\";


proc sort data=us.comp_qua out=comp_qua; by gvkey fyearQ FQTR;
data comp_qua; set comp_qua;
by gvkey fyearQ FQTR;
if last.FQTR;
DateQ=datadate;
format DateQ YYMMDDn8.;
keep gvkey fyearQ FQTR DateQ IBQ SEQQ CEQQ PSTKQ ATQ LTQ TXDITCQ PSTKRQ NIQ CHEQ;
run;


/*** items to be downloaded, dummy variables for test only ***/
data junk; set comp_qua;
EPSPXQ=NIQ;
AJEXQ=1;
code=gvkey;
rhs=EPSPXQ/AJEXQ;
keep code fyearQ FQTR DAteQ rhs EPSPXQ AJEXQ;
run;


proc sql;
	create table junk2 as
	select distinct a.code, a.fyearQ, a.FQTR, a.DateQ, b.rhs-a.rhs as diff
	from junk as a, junk as b
	where a.code=b.code and a.fyearQ=b.fyearQ-1 and a.FQTR=b.FQTR;

	create table junk3 as
	select distinct a.code, a.fyearQ, a.FQTR, a.DateQ, a.diff as diff, b.diff as lagdiff
	from junk2 as a, junk2 as b
	where a.code=b.code
		and 1<=(a.fyearQ-b.fyearQ)*4+a.FQTR-b.FQTR<=8
	group by a.code, a.fyearQ, a.FQTR
	having count(b.diff)>=6;

	create table junk4 as 
	select distinct code, fyearQ, FQTR, DateQ, diff/std(lagdiff) as Sue
	from junk3
	group by code, fyearQ, FQTR;
quit;

