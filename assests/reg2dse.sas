/*July ,2015*/
/*This sas macro code is modified by Mark (Shuai) Ma based on the two-way clustered SE code from Professor John McInnis *******/

/*According to Petersen (2008) and Thompson (2011), there are three steps to estimate two-way clustered SEs: */
/*1. estimate firm-clustered VARIANCE-COVARIANCE matrix V firm,*/
/*2. estimate time-clustered VARIANCE-COVARIANCE matrix V time,*/
/*3. estimate heteroskedasticity robust white VARIANCE-COVARIANCE matrix (V white) when there is only one observations each firm-time intersection,*/
/*or, estimate firm-time intersection clustered VARIANCE-COVARIANCE matrix (V firm-time) when there is more than one observations each firm-time intersection,*/
/*This code allows the user to closely follows the formula given by Petersen (2008) and Thompson (2011).*/

/********************************************************************************************************************************/
/*If you use this code, please add a footnote:*/
/*To obtain unbiased estimates in finite samples,the clustered standard error is adjusted by (N-1)/(N-P)× G/(G-1),where N is the sample size, P is the number of independent variables, and G is the number of clusters. */
/*For details, please see my note on two-way clustered standard errors avaiable on SSRN and my website https://sites.google.com/site/markshuaima/home.*/


/*Lastly, I post this code for the communication purpose without any warranty or guaranty of accuracy or support.*/
/*I tried my best to ensure the accuracy of the codes, but I could not exclude the possibility that there might still be errors. If any error is found, please get me know immediately.*/


/********************************************************************************************************************************/
/*Input explanations */

/* After running the macro code below, you will need to run the following command,
you only need to change the names of datasets and variables and "multi" value in the following command, and results will be in dataset "A.results"*/

/*****************command*******************************************************************************************************/
/*%REG2DSE(y=DV, x=INDV, firm=firmid, time=timeid, multi=0, dataset=A.data, output=A.results);*/


/**************Variable Explanation*********************************************************************************************/
/* 1. A.data: A is your library name, data is your input dataset name,*/
/*A.results : A is your library name, results is the name you want for your output dataset ,*/

/*2. DV: the dependent variable, */
/*INDV: the list of your independent variable(s),*/

/*3.  firmid: the firm identifier (such as gvkey, permno) ,*/
/*timeid: the time identifier (such as fyear, date),*/

/*4. multi=0 or 1 (you need to choose whether you use 0 or 1  )  */
/* if you have one observation per firm-time (intersection of two dimendions), you need to have multi=0*/
/* if you have multiple observations per firm-time (intersection of two dimendions) , you need to have multi=1*/

/********************************************************************************************************************************/
/************************The macro code is as follows*************************************/


%MACRO REG2DSE(y, x, firm, time, multi, dataset, output);

proc surveyreg data=&dataset;
cluster &firm;
model &Y = &X /covb ;
ods output covb=firm;
ods output FitStatistics=fit;
run;quit;


proc surveyreg data=&dataset;
cluster &time;
model &Y = &X /covb ;
ods output covb=time;
run;quit;

%if &multi=1  %then %do;

proc surveyreg data=&dataset;
cluster &time &firm;
model &y = &x /  covb;
ods output covb=both ;
ods output parameterestimates=parm;
run;quit;

data parm; set parm;keep parameter estimate;run;

%end;


%else %if &multi=0  %then %do;

proc reg data=&dataset;
model &y = &x /hcc  acov  covb;
ods output acovest=both ;
ods output parameterestimates=parm;
run;quit;

data both; set both; parameter=Variable; run;

data both; set both;drop variable  Dependent  Model;run;

data parm; set parm;parameter=Variable;Estimates=Estimate;keep parameter estimates;run;

%end;

data parm1; set parm;
n=_n_;m=1;keep m n;run;

data parm1;set parm1;
by m;if last.m;keep n;run;
 
data both; set both;
keep intercept &x;
run;
data firm; set firm;
keep intercept &x;
run;
data time; set time;
keep intercept &x;
run;

data fit1; set fit;
parameter=Label1;
Estimates=nValue1;
if parameter="R-square" then output;
run;

data fit1; set fit1;
n=1;
keep parameter Estimates n;
run;
proc iml;use both;read all var _num_ into Z;print Z;use firm;read all var _num_ into X;print X;
use time;read all var _num_ into Y;print Y;use parm1;
read all var _num_ into n;print n;B=X+Y-Z;C=I(n);D=J(n,1);E=C#B;
F=E*D;G=F##.5;
print B;print G;
create b from G [colname='stderr']; append from G;quit;

data results; merge  parm B ;
tstat=estimates/stderr;n=0;run;

data resultsfit; merge results  fit1;by n;
run;

data &output; set resultsfit;
drop n;
run;

%MEND REG2DSE;

