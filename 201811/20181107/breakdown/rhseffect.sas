
%let output = outpew;
*%let output = outpvm;

*%macro rhseffect(input, ret, sort, weighting1, weighting2, output, lags, outstat);

/*%sprd(&input, 10, 50, &ret, &sort, &weighting1, 3);
%sprd(&input, 50, 100000, &ret, &sort, &weighting1, 5);
data sprd; set sprd3 sprd5;
/*
%sprd(&input, 10, 100000, &ret, &sort, &weighting1, 1);
data sprd; set sprd1;
*/

/*%sprd(&input, 1, 30, &ret, &sort, &weighting1, 3);
%sprd(&input, 30, 100000, &ret, &sort, &weighting1, 5);

%sprd(&input, 4, 49, &ret, &sort, &weighting1, 3);
%sprd(&input, 50, 100000, &ret, &sort, &weighting1, 5);
*/
%sprd(&input, 4, 50, &ret, &sort, &weighting1, 3);
%sprd(&input, 51, 100000, &ret, &sort, &weighting1, 5);
/*data sprd; set sprd3 sprd5;*/
data sprd; set sprd5;

proc sort; by &sort portyear;
run;

/* rhs predictive regression slope */



proc sort data=&input; by &sort portyear;
run;
proc reg data=&input noprint outest=coef edf;
model &ret=rhs;
by &sort portyear;
weight &weighting2;
run;
data coef; set coef;
slope=rhs;
keep &sort portyear slope;
run;

/* all measures of rhs effect
/* combines the sort based and slope
/* now the portfolio year is from t to t+12
/* in reality is from t+6 to t+18 */

data &output; merge sprd coef;
by &sort portyear;
/* if (slope ne . and retsprd ne . and rhssprd ne .); */
expostyear = portyear + 1;
proc sort; by &sort;
run;

/* Country summary stats */
%NWavg(&output, &sort, &lags, &outstat);
*%mend;
