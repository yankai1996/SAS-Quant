
%macro numberPE(input, output, number);

data &output; set &input;
if dec0~=.;
if country in ("AU", "BD", "CH", "CN", "FN", "FR", "GR", "HK", "IN", "IS", 
"IT", "JP", "KO", "MY","SD", "SG", "SW", "TA", "TK", "UK", "US");
n=1;
keep country portyear n;
proc sort; by portyear;
proc means noprint; by portyear;
output out=&output sum=&number;
run;

%mend;

%numberPE(bk.new_pe_bk, new_pe, n_pe_new);
%numberPE(bk.old_pe_bk, old_pe, n_pe_old);
%numberPE(bk.new_pvgo_bk, new_pvgo, n_pvgo_new);
%numberPE(bk.old_pvgo_bk, old_pvgo, n_pvgo_old);


data pvgo_pe_coalesce; set pvgo_pe;
if country in ("AU", "BD", "CH", "CN", "FN", "FR", "GR", "HK", "IN", "IS", 
"IT", "JP", "KO", "MY","SD", "SG", "SW", "TA", "TK", "UK", "US");
proc sort; by portyear;
proc means noprint; by portyear;
var pvgo2 pe;
output out=coalesce n=n_pvgo_coalesce n_pe_coalesce;
run;


data number21; retain portyear n_pvgo:;
merge old_pvgo new_pvgo old_pe new_pe coalesce;
by portyear;
drop _type_ _freq_;
run;

libname pwd "C:\TEMP\displace\20190610";
data pwd.number21; set number21; run;
