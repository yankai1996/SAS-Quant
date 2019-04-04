

%macro summary(i, j, k, l);

%if &i=1 %then %let obs=4k;
%else %let obs=5k;

%if &j=1 %then %let type=winsor;
%else %let type=truncate;

%if &k=1 %then %let by=country-portyear;
%else %let by=portyear;

%if &l=1 %then %let weight=ew;
%else %let weight=vw;

%let output=summary&i&j&k&l;

libname sprd "C:\TEMP\displace\20190402\&obs-obs\&type.1-&by";
/*
%if &j=0 %then %do;
	libname sprd "C:\TEMP\displace\20190402\&obs-obs\nochange";
%end;
/*				
proc means data=sprd.country_&weight._slope noprint;
output out=&output;
proc transpose data=&output out=&output;
var slope;
id _stat_;
run;*/

proc univariate data=sprd.country_&weight._slope noprint;
var slope;
output out=&output mean=MEAN n=N std=std PCTLPTS=0 1 25 50 75 99 100 pctlpre=pctl;
run;

data &output; set &output;
obs="&obs";
type="&type";
by=put("&by", $16.);
%if &j=0 %then %do;
	type="x";
	by="x";
%end;
weight="&weight";
drop _name_;
run;

%mend summary;

%macro summary_slope();

proc datasets library=work noprint;
   delete summary:;
run;

%do i=1 %to 2;
	%do j=1 %to 2;
		%do k=1 %to 2;
			%do l=1 %to 2;
				%summary(&i, &j, &k, &l);
			%end;
		%end;
	%end;
	/*%do l=1 %to 2;
		%summary(&i, 0, 0, &l);;
	%end;*/
%end;

data slope_summary; retain obs type by weight;
set summary:;
proc sort; by obs descending type by weight;
run;

%mend ;

%summary_slope();

/*
proc univariate data=sprd.country_ew_slope noprint;
var slope;
output out=junk mean=MEAN n=N std=std PCTLPTS=0 1 25 50 75 99 100 pctlpre=pctl;
run;
*/

libname pwd "C:\TEMP\displace\20190401";
data pwd.slope_summary; set slope_summary;
run;



data pe; set merged;
if portyear<=2011 then upto2011=pe_new;
else after2011=pe_new;
run;

proc means data=pe noprint;
by country;
var pe_old pe_new upto2011 after2011;
output out=pe25_summary;
run;

data pwd.pe25_summary; set pe25_summary;
run;
