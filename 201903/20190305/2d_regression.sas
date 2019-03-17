
libname twoDsprd "C:\TEMP\sprd\REG2DSE";
libname sprd "C:\TEMP\sprd";


dm 'log;clear;';
%let pwd = "C:\TEMP\displace\20190306\REG2DSE";
x md &pwd;
x cd &pwd;
libname pwd &pwd;


%macro twoDtest(lhs, rhs, output);

data gobar_country; set twoDsprd.gobar20; 
drop _type_ _freq_; 
run;

data &lhs; set sprd.&lhs;
mthyr=portyear;
portyear=floor(mthyr/100);
if mthyr-portyear*100<7 then portyear=portyear-1;
keep country mthyr portyear retsprd;
proc sort; by country portyear;
run;


data testdata; merge gobar_country(in=a) &lhs(in=b);
by country portyear;
if a and b;
run;

%REG2DSE(retsprd, &rhs, country, mthyr, 0, testdata, &output);

data pwd.&output; set &output; run;
ods tagsets.tablesonlylatex file="&output..tex"  (notop nobot) stylesheet="sas.sty"(url="sas"); proc print data=&output; run; quit;
ods tagsets.tablesonlylatex close;

%mend twoDtest;


%twoDtest(top33_rhs4_country, pvgobar1, top33_rhs4_country_pvgobar1);
%twoDtest(top33_rhs4_country, pvgobar2, top33_rhs4_country_pvgobar2);
%twoDtest(top33_rhs4_country, pvgobar3, top33_rhs4_country_pvgobar3);
%twoDtest(top33_rhs4_country, pmbar, top33_rhs4_country_pmbar);


%twoDtest(bm_country, pvgobar1, output);
%twoDtest(benchmark_rhs4_country, pvgobar1, output);

%REG2DSE(retsprd, pvgobar2, country, mthyr, 0, pvgo_top33_rhs4_country, output);
%REG2DSE(retsprd, pvgobar3, country, mthyr, 0, pvgo_top33_rhs4_country, output);
%REG2DSE(retsprd, pebar, country, mthyr, 0, pvgo_top33_rhs4_country, output);
