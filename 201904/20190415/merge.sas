

proc contents data=tmp2._all_ out=country noprint;
run;
data country; set country;
country=put(MEMNAME, $2.);
keep country;
proc sort nodup; by country;
run;


%let list=AE AR AU BD BG 
BL BR CB CH CL 
CN CP CT CY CZ
DK ES EY FN FR
GR HK HN ID IN 
IR IS IT JM JO
JP KN KO KW KZ 
LN LV LX MC MX
MY NG NL NW NZ 
OE PE PH PK PO
PT QA RM RS SA
SD SG SI SJ SW 
SX TA TH TK TU 
UA UK VE VI ZI;



%let list_usd=AE AR AU BD BG 
BL BR CB CH CL 
CN CO CP CT CY CZ
DK ES EY FN FR
GR HK HN ID IN 
IR IS IT JM JO
JP KN KO KW KZ 
LN LV LX MC MX
MY NG NL NW NZ 
OE PE PH PK PO
PT QA RE RM RS SA
SD SG SI SJ SW 
SX TA TH TK TR TU 
UA UK VE VI ZI;


%macro loop1(vlist);
%let nwords=%sysfunc(countw(&vlist));

%do i=1 %to &nwords;
	%let country = %scan(&vlist, &i);
	data tmp&country; merge tmp1.&country._price_lc tmp1.&country._ri_lc;
	by dscd date;
	country="&country";
	run;
%end;

%mend;

%loop1(&list); 


data all_p_ri_lc; set tmp:;
proc sort; by country;
run;



%macro loop2(vlist);
%let nwords=%sysfunc(countw(&vlist));

%do i=1 %to &nwords;
	%let country = %scan(&vlist, &i);
	data tmp&country; set tmp2.&country._ret;
	country="&country";
	keep dscd date country tdvol;
	run;
%end;

%mend;

%loop2(&list); 

data all_vol_lc; set tmp:;
proc sort; by country dscd date;
run;


data all_lc; merge all_p_ri_lc(in=a) all_vol_lc(in=b);
by country dscd date;
if a & b;
run;

libname tmp3 "T:\SASData3";
data tmp3.all_lc; set all_lc;
run;




%macro loop3(vlist);
%let nwords=%sysfunc(countw(&vlist));

%do i=1 %to &nwords;
	%let country = %scan(&vlist, &i);
	data tmp&country; merge tmp2.&country._ret tmp2.&country._tdvol_usd;
	by dscd date;
	country="&country";
	keep country dscd date ri price tdvol_usd;
	run;
%end;

%mend;

%loop3(&list_usd); 

libname tmp3 "T:\SASData3";
data tmp3.all_usd; set tmp:;
proc sort; by country dscd date;
run;
