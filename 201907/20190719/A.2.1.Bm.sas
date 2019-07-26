
data agret1; set us.agret1;
keep code data mthyr portyear ret SEQ TXDITC CEQ PSTK AT LT PSTKRV PSTKL PSTK CSHO;
*keep DP DVC DLC DLTT SSTK PRSTKC;
proc means;
run;
