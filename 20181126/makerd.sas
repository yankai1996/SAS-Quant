/*
data rd; set agret0;
keep code country portyear rd;
proc sort data=rd nodup; 
by code portyear;
run; 

proc sql;
create table checkRD as 
select * from rd
group by code, country, portyear
having count(portyear) > 1;
;
quit;
*/

%macro makeRD();

data rd; set agret0;
keep code country portyear rd;
proc sort data=rd nodup; 
by code portyear;
run; 

%do i=0 %to 3;
%let j=%eval(&i+1);
data rd; set rd;
by code country;
lag0_rd=rd;
lag&j._rd=lag(lag&i._rd);
if first.country then lag&j._rd=.;
run;
%end;

data rd; set rd;
RD1 = rd;
RD2 = rd;
RD3 = rd;
run;

%do i=1 %to 4;
data rd; set rd;
RD2 = RD2 + (1-&i*0.2)*lag&i._rd;
if &i<3 then RD3 = RD2;
if &i=4 then do
RD2 = RD2/3;
RD3 = RD3/2.4;
end;
run;
%end;

%mend makeRD;

