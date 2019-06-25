
data siccode; set db.siccode; 
keep code WC07021;
proc sort; by code;
run;

data agret0; set nnnDS.agret0;
keep code country mthyr;
proc sort; by code;
run;

data all; merge agret0(in=a) siccode(in=b);
if a and b;
by code;
run;

proc sql;
	create table all as
	select b.country as country, a.*
	from all as a
	left join db.ctycode as b on a.country=b.cty;
quit;


%ind_ff38(all, all2, WC07021, indcode, indcode);



%let sumvars=indcode1 indcode2 indcode3 indcode4 indcode5 indcode6 indcode7 indcode8 indcode9 indcode10 
		indcode11 indcode12 indcode13 indcode14 indcode15 indcode16 indcode17 indcode18 indcode19 indcode20 
		indcode21 indcode22 indcode23 indcode24 indcode25 indcode26 indcode27 indcode28 indcode29 indcode30 
		indcode31 indcode32 indcode33 indcode34 indcode35 indcode36 indcode37 indcode38;

%macro indnumber(country);

data &country; set all2;
if country="&country";
proc sort; by mthyr;
proc means noprint; by mthyr;
var &sumvars;
output out=&country sum=&sumvars;
run;

data pwd.&country; set &country;
drop _type_;
run;

%mend;


/*if country in ("AU", "BD", "CH", "CN", "FN", "FR", "GR", "HK", "IN", "IS", 
"IT", "JP", "KO", "MY","SD", "SG", "SW", "TA", "TK", "UK", "US");*/
%indnumber(AU);
%indnumber(BD);
%indnumber(CH);
%indnumber(CN);
%indnumber(FN);
%indnumber(FR);
%indnumber(GR);
%indnumber(HK);
%indnumber(IN);
%indnumber(IS);
%indnumber(IT);
%indnumber(JP);
%indnumber(KO);
%indnumber(MY);
%indnumber(SD);
%indnumber(SG);
%indnumber(SW);
%indnumber(TA);
%indnumber(TK);
%indnumber(UK);
%indnumber(US);
