# Summary - May 14, 2019

### Libname

```SAS
libname db "V:\data_for_kai";
libname nnnDS "V:\data_for_kai\WSDS20190215";
libname us "V:\data_for_kai\Compustat&CRSP merged";
```



### Table 1

##### Code Path

 `V:\data_for_kai\20190430\sas-data\table1.sas`

##### Data Input

`nnnDS.agret0`, `nnnDS.mvdec`

##### Filters

* We use the 21 countries' data up to 201807
* `if ret>-1 & ret<=10;`
* Each portyear must have no less than 6 months 



### Table 2

##### Code Path

 `V:\data_for_kai\20190502\sas-data\table2.sas`

`V:\data_for_kai\20190502\sas-data\mth_port_analysis_short.sas`

`V:\data_for_kai\20190502\sas-data\rhseffect.sas`

##### Data Input

`nnnDS.agret0`, `nnnDS.mvdec`

##### Data Output

Besides table2, this code will also generate 6 time series files `g_ew_sprd`, `g_vw_sprd`, `cn_ew_sprd`, `cn_vw_sprd`, `cn_xus_ew_sprd`, and `cn_xus_vw_sprd`, which can be found in `V:\data_for_kai\20190502\sas-data\`.

##### Filters

* We use the 21 countries' data up to 201807.

* We remove the extreme returns

* ```SAS
  if (1+ret_us)*(1+lagret_us)<1.5 and (ret_us>3 or lagret_us>3) then delete;
  if ret>-1 and ret<10;
  if ret_us>-1 and ret_us<10; 
  if ret_us~=.;
  if RD>0 & MC>0;
  ```

* Then we remove those price<p10.

* `%winsor(dsetin=agret1, dsetout=agret1, byvar=portyear country, vars=lagmv_us RD MC, type=winsor, pctl=1 99);`



### Table 3

##### Code Path

 `V:\data_for_kai\20190502\sas-data\table3.sas`

`V:\data_for_kai\20190502\sas-data\twowaysprd.sas`

##### Input Data, Filters

(The same as **Table 2**)



### Table 4

##### Code path

`V:\data_for_kai\20190506\table4_hkk.sas`

`V:\data_for_kai\20190506\table4.sas`

##### Data

* First, we use HKK methods extending our data MOM, C/P, and Rm_Rf. 
  * Instead of 21 countries, we use all countries data we have
  * The code is in `table4_hkk.sas`
  * Rf data is from Ken.French
  * Old hkk data are imported from `V:\data_for_kai\hkk_factors_2010.xls`
* Then, we use the extended HKK data to do regression with return spreads.
  * Sprd data are in `V:\data_for_kai\20190502\sas-data\`, which was generated when we did table2.



### Table 5 ~ 8 Data

##### Code Path

`V:\data_for_kai\20190503\data_20190503.sas`

##### Data Output

`V:\data_for_kai\20190503\annual_201905.csv`

`V:\data_for_kai\20190503\monthly_201905.csv`

There are MOM, AG, BM, BMjune, MC, MCjune, ROE, SICCODE (mereged from db.siccode), and INDCODE (merged from db.indcode).

##### PF

My code didn't got PF since Interest Expense was missing (Only Interest Expense on Debt(01251) db.acct).



### Table 11

##### Results

There are two results are close to the old pattern.

1.  `PE=MC/NI`, in `V:\data_for_kai\20190410\`
2. `PE=PE=MC/NIBPRFED`, in `V:\data_for_kai\20190411\`

Both are from `./k4_winsor_portyear.sas7bdat`, with the same id.

##### Data Input

There are 8 sets, see `V:\data_for_kai\20190411\4k-obs\ ` and `5k-obs\`.

`5k` removed p10 at the very beginning, while `4k` did this after other filters.

##### Code Path

`V:\data_for_kai\20190411\all_loop.sas`



### Table 12, 13 Data (Daily Data)

##### Code Path

`V:\data_for_kai\Daily data\irisk_20190510.sas`

##### xUS Data

* `daily.all_lc`, `nnnDS.mvdec`

##### US Data

* US data `daily.us` were newly downloaded from Crsp
* MvDec of US is `us.mvdec`
* We use Ken.French's mkt_rf as the US vwmktret. See `V:\data_for_kai\Daily data\F-F_Research_Data_Factors_daily.CSV`

##### Data Output

* `irisk` - IRISK at country level, with old and new
* `irisk_xus_company`, `irisk_us_company` - IRISK of companies
* `dvol` - DVOL old and new, and two alternative: dvol_ew (ew dvol / sum MC), dvol_sum (sum dvol / sum MC)
* `pbsprd` - Pbsprd old and new
* `snipo` - new NIPO data

