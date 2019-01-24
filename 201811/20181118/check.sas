proc sql;
create table regioncount as 
select distinct region from region
quit;

proc sql;
create table country0 as 
select distinct country from agret0
quit;

proc sql;
create table country00 as 
select distinct country from agret00
quit;

proc sql;
create table country1 as 
select distinct country, region from agret1
quit;

proc sql;
create table countryAgret as 
select distinct country, region from agret
quit;

proc sql;
create table countryTem as 
select distinct country, region from tem
quit;

proc sql;
create table country2 as 
select distinct country, region from workable2
quit;

proc sql;
create table countryrank as 
select distinct country, region from rank
quit;

proc sql;
create table country3 as 
select distinct country from sprd3
quit;

proc sql;
create table country5 as 
select distinct country from sprd5
quit;

proc sql;
create table countrysprd as 
select distinct country from sprd
quit;


%macro export(output);
ods tagsets.tablesonlylatex file="&output..tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=&output; run; quit;
ods tagsets.tablesonlylatex close;
%mend export;

%export(country_ew);
%export(country_vw);
%export(region_ew);
%export(region_vw);
%export(world_ew);
%export(world_vw);


data missing; merge country_ew country0; 
by country;
run;

data noregion; merge country0 region;
by country;
run;

data disp.region; set region; run;
