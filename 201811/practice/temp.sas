*** Clear the work folder;
proc delete data=work._all_; run;


option NOERRORABEND;
options noxwait;

libname prospect "o:\projects\prospect";
libname season "o:\projects\seasonality";
libname season2 "o:\projects\seasonality2";



data retmonthly; set prospect.msf2a;
mthyr = year(date)*100+month(date);
retnew = coalesce(ret,dlret,ret+dlret);
if shrcd~=10 & shrcd~=11 then delete;
me = abs(prc)*shrout;
/*if retnew~=.;*/ 
keep me mthyr ret permno retnew date dlret prc;
run;

proc sort data=retmonthly; by permno mthyr;
data retmonthly; set retmonthly;
by permno mthyr;
lagme = lag(me);
lagret = 0;
lag1retnew = lag(retnew);
lagprc = lag(prc);
if first.permno then do
	lagme=.;
	lag1retnew = .;
end;
run;
%macro fairecum(rhs);
%do i = 0 %to 11;
%let j=%eval(&i+1);
data retmonthly; set retmonthly;
by permno mthyr;
cum0&rhs = 0;
lag0&rhs = &rhs;
lag&j&rhs = lag(lag&i&rhs);
if first.permno then lag&j&rhs = .;
cum&j&rhs = (1+cum&i&rhs)*(1+lag&j&rhs)-1; 
run;
%end;
%mend;



proc sql;
   create table R11 as
   select distinct a.permno, a.date, a.me, a.mthyr, a.retnew, a.lagprc, a.lag1retnew, exp(sum(log(1+b.retnew)))-1 as lagret
     from retmonthly (where=(year(date)>=1970)) as a, 
          retmonthly (where=(year(date)>=1969)) as b
	where a.permno=b.permno and 2<=intck('month',b.date,a.date)<=12
	group by a.permno, a.date
    having count(b.retnew)=11; 
quit;

