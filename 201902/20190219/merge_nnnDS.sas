
libname DB 'V:\data_for_kai';
libname nnnDS 'V:\data_for_kai\WSDS20190215';


%macro abbr_country(input);

data &input; set &input;
if country="AUSTRALIA" then country="AU";
else if country="GERMANY" then country="BD";
else if country="CHINA" then country="CH";
else if country="CANADA" then country="CN";
else if country="FINLAND" then country="FN";
else if country="FRANCE" then country="FR";
else if country="GREECE" then country="GR";
else if country="HONG KONG" then country="HK";
else if country="SOUTH KOREA" then country="KO";
else if country="ISRAEL" then country="IS";
else if country="INDIA" then country="IN";
else if country="ITALY" then country="IT";
else if country="JAPAN" then country="JP";
else if country="MALAYSIA" then country="MY";
else if country="SWEDEN" then country="SD";
else if country="SINGAPORE" then country="SG";
else if country="SWITZERLAND" then country="SW";
else if country="TAIWAN" then country="TA";
else if country="TURKEY" then country="TK";
else if country="UNITED KINGDOM" then country="UK";
else if country="UNITED STATES" then country="US";
run;

%mend abbr_country;


data ret0; set nnnDS.retm;
code=dscd;
country=GEOGN;
annee=year(date);
mois=month(date);
mthyr=annee*100+mois;
portyear=annee;
if mois<=6 then portyear = annee-1;
keep code country mthyr portyear ri;
proc sort; by code mthyr;
run;
data ret; set ret0;
by code mthyr;
ret=ri/lag(ri)-1;
if first.code then ret=.;
if ret=0 & lag(ret)=0 then delete;
if (1+ret)*(1+lag(ret))<1.5 and (ret>3 or lag(ret)>3) then delete;
if ret~=.;
ret_us=ret;
drop ri;
proc sort; by code portyear;
run;


data price; set nnnDS.retm;
if month(date)=12;
code=dscd;
portyear=year(date);
p_us_updated=p;
keep code portyear p_us_updated;
proc sort; by code portyear;
run;


data acct; retain code; set nnnDS.acct;
code=dscd;
portyear=year+1;
drop geogn dscd;
proc sort; by code portyear;
run;


data agret0; merge ret(in=a) acct(in=b) price(in=c);
by code portyear;
if a & b & c;
run;


data mvdec; set nnnds.retm;
if month(date)=12;
code=dscd;
year=year(date);
portyear=year+1;
mv=MC;
mv_us=MCUS;
if mv~=.;
keep code year portyear mv mv_us;
proc sort; by code portyear;
run;


data nnnDS.agret0; set agret0; run;
data nnnDS.mvdec; set mvdec; run;


data junk2; set agret0;
if country="CHANNEL ISLANDS";
run;
