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

