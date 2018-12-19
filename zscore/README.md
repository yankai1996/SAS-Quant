# Z-score of &Delta;EMP

## Signals 

We construct 3 signals:
$$
\begin{aligned}
& signal_1 = \Delta EMP/EMP \\
& signal_2 = \Delta EMP/COG \\
& signal_3 = \Delta EMP/SGA \\
\end{aligned}
$$

where $\Delta EMP = EMP_t - EMP_{t-1}$. 

* EMP: Employment Expenses
* COG: Cost of Goods
* SGA: Sales, General, and Administrative Expenses

## Z-score

Let $x$ be the signal variable and $r$ be the vector of ranks, $r_i = rank(x_i)$. Then the $z$-score of the ranks of $x$ is given by $z(x) = (r-\mu_r)/\sigma_r$, where $\mu_r$ and $\sigma_r$ are the cross-sectional mean and standard deviation of r.

For three signals, let $z_j = z(signal_j)$, then we have:
$$
z = mean(z_1, z_2, z_3)
$$
Finally, we use this $z$-score as the `rhs` to do one-way-sort at country, region, or world level with equal-weighted or value-weighted method to calculate the spread and slope.



# Combination of RD and EMP

We combine the z-score of RD and EMP as teh following steps:
$$
\begin{aligned}
& z_{RD} = mean(z_1, z_2, z_3) \\
& z_i = z(signal_i) = z(RD_i/SL) \\
& RD_1 = RD_t \\
& RD_2 = (RD_t + 0.8RD_{t-1} + 0.6RD_{t-2} + 0.4RD_{t-3} + 0.2RD_{t-4})/3 \\
& RD_3 = (RD_t + 0.8RD_{t-1} + 0.6RD_{t-2})/2.4 \\
& \\
& z_{EMP} = mean(z(\frac{\Delta EMP}{EMP}), z(\frac{\Delta EMP}{COG}), z(\frac{\Delta EMP}{SGA})) \\
& \Delta EMP = EMP_t - EMP_{t-1}
\end{aligned}
$$
Finally, we have

$$
z = mean(z_{RD}, -z_{EMP})
$$



# Filters

In `preprocess.sas`, we active three filters to get better results.

1. `if p_us_updated>=p_us_10;`

2. `if ret>-1 and ret<10;`

   `if ret_us>-1 and ret_us<10;`

3. `%winsor(dsetin=agret1, dsetout=agret1, byvar=country, vars=ret_us, type=winsor, pctl=1 99);`



### 