
%macro RD_EMP();

x md "C:\TEMP\displace\20181207\RD_EMP";
x cd "C:\TEMP\displace\20181207\RD_EMP";

%zscore(tem, country, portyear, EMP1, EMP2, EMP3, EMP);
%zscore(zscore, country, portyear, RD1, RD2, RD3, RD);
%zcombine(zscore, country, portyear);
%zeffect(zscore, ret_us, country, ew, country_ew);
%zeffect(zscore, ret_us, country, lagmv_us, country_vw);

%zscore(tem, region, portyear, EMP1, EMP2, EMP3, EMP);
%zscore(zscore, region, portyear, RD1, RD2, RD3, RD);
%zcombine(zscore, region, portyear);
%zeffect(zscore, ret_us, region, ew, region_ew);
%zeffect(zscore, ret_us, region, lagmv_us, region_vw);

%zscore(tem, world, portyear, EMP1, EMP2, EMP3, EMP);
%zscore(zscore, world, portyear, RD1, RD2, RD3, RD);
%zcombine(zscore, world, portyear);
%zeffect(zscore, ret_us, world, ew, world_ew);
%zeffect(zscore, ret_us, world, lagmv_us, world_vw);

%mend RD_EMP;

%RD_EMP();



%macro getz(input, neutral, timevar, z);

proc means data=&input noprint;
by &neutral &timevar;
var &z;
output out=zn n=n;
run;
data &input; merge &input zn;
by &neutral &timevar;
drop _type_ _freq_;
z = &z;
if z~=.;
run;

%mend;



%macro singlez(label);
x md "C:\TEMP\displace\20181207\&label";
x cd "C:\TEMP\displace\20181207\&label";

%zscore(tem, country, portyear, &label.1,  &label.2,  &label.3,  &label);
%getz(zscore, country, portyear, z&label);
%zeffect(zscore, ret_us, country, ew, country_ew);
%zeffect(zscore, ret_us, country, lagmv_us, country_vw);

%zscore(tem, region, portyear, &label.1,  &label.2,  &label.3,  &label);
%getz(zscore, region, portyear, z&label);
%zeffect(zscore, ret_us, region, ew, region_ew);
%zeffect(zscore, ret_us, region, lagmv_us, region_vw);

%zscore(tem, world, portyear, &label.1,  &label.2,  &label.3,  &label);
%getz(zscore, world, portyear, z&label);
%zeffect(zscore, ret_us, world, ew, world_ew);
%zeffect(zscore, ret_us, world, lagmv_us, world_vw);

%mend singlez;

%singlez(EMP);
