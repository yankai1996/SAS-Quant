# Z-score of RD

## Signals 

We construct 3 signals, and $signal_i = RD_i/c$, where $c$ can be MC(market cap), TA(total assests), be4, SL(Sales), and $RD_i$ is defined as:
$$
\begin{aligned}
& RD_1 = RD_t \\
& RD_2 = (RD_t + 0.8 RD_{t-1} + 0.6 RD_{t-2} + 0.4 RD_{t-3} + 0.2 RD_{t-4})/3 \\
& RD_3 = (RD_t + 0.8 RD_{t-1} + 0.6 RD_{t-2})/2.4
\end{aligned}
$$

## Z-score

Let $x$ be the signal variable and $r$ be the vector of ranks, $r_i = rank(x_i)$. Then the $z$-score of the ranks of $x$ is given by $z(x) = (r-\mu_r)/\sigma_r$, where $\mu_r$ and $\sigma_r$ are the cross-sectional mean and standard deviation of r.

For three signals, let $z_j = z(signal_j)$, then we have 2 ways to define the final $z$-score:

1. $z = mean(z_1, z_2, z_3)$
2. $z = coalesce(z_1, mean(z_1, z_3), mean(z_1, z_2, z_3))$



Finally, we use this $z$-score as the `rhs` to do one-way-sort at country, region, or world level with equal-weighted or value-weighted method to calculate the spread and slope.