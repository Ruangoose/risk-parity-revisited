# Risk parity and smart beta, revisited

**Does a portfolio that balances risk across assets and factors hold up better than one that balances money,
and what does it cost?**

My MCom thesis (Stellenbosch University, 2021) was on portfolio construction with risk parity and smart beta.
This project asks the same question again on public US data that runs to 2026, through the crashes of 1973-74,
1987, 2000-02, 2008, 2020 and 2022.

It has two parts:
1. **Stocks and bonds.** A 60/40 portfolio of US stocks and 10-year Treasuries against risk parity (equal risk
   from each), both unlevered and levered to 60/40's volatility.
2. **Smart beta.** Six long-only factor portfolios (small, value, momentum, profitability, investment and low
   variance), weighted by equal risk, against equal weights and the cap-weighted market.

The results are in [output/RESULTS.md](output/RESULTS.md), which every run rewrites.

## What I found
- **Where the risk sits.** 60/40 puts 60% of its money in stocks, but stocks carried most of its risk: 89% on
  average over the period. Risk parity evens that out by holding about a third in stocks.
- **Crashes.** Unlevered risk parity fell less than 60/40 in each of the seven US stock market falls of more than
  20% since 1968. Levered to 60/40's volatility, it fell less in six of them, but lost more than stocks in 2022,
  when stocks and bonds fell together.
- **Over the whole period**, risk parity's return per unit of risk (Sharpe ratio) was about the same as 60/40's,
  not better. It did better while interest rates fell from 1981 to 2020, and worse while they rose.
- **The cost.** Unlevered, risk parity gave up return for lower volatility. Levered, it paid for borrowing,
  traded more and had a deeper worst fall.
- **Smart beta.** The factor portfolios beat the market, before the cost of running them. Weighting them by risk
  instead of money made little difference, because all six are mostly the same stock market risk.

None of this is investment advice or a recommendation.

## Data
Downloaded by the code at run time. Only derived results are committed; the raw files stay in `data-raw/`,
which git ignores.

- **Stocks:** [Kenneth R. French Data Library](https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html),
  by Eugene F. Fama and Kenneth R. French:
  - the Fama/French 5 factors (2x3), monthly from July 1963. The market's total return is Mkt-RF plus RF;
  - the univariate sorts on size, book-to-market, operating profitability, investment and variance, and the
    10 portfolios on prior (12-2) returns. Each factor portfolio is the value-weighted top or bottom fifth
    of US stocks on its characteristic (momentum: deciles 9 and 10 combined by market value).
- **Bonds and cash:** Board of Governors of the Federal Reserve System (US), H.15 Selected Interest Rates,
  retrieved from [FRED](https://fred.stlouisfed.org/), Federal Reserve Bank of St. Louis:
  - [DGS10](https://fred.stlouisfed.org/series/DGS10): Market Yield on U.S. Treasury Securities at 10-Year
    Constant Maturity, daily (month-end values used);
  - [GS10](https://fred.stlouisfed.org/series/GS10): the same yield as a monthly average (a sensitivity run);
  - [TB3MS](https://fred.stlouisfed.org/series/TB3MS): 3-Month Treasury Bill Secondary Market Rate,
    Discount Basis.

## Method
- **Bonds:** each month, a new 10-year par bond is bought at last month's yield and valued at this month's:
  carry plus duration and convexity. A check reprices the bond exactly; the two agree to within a few basis
  points a month. Calendar-year returns are checked against known episodes such as 1994 and 2022.
- **Cash:** 3-month Treasury bills, earning the rate known at the start of each month.
- **Weights:** set at each month-end from a covariance matrix of the previous 36 months only, and held for the
  next month. Rebalanced monthly.
- **Equal risk contribution:** long-only weights that give each asset the same share of forecast variance. With
  two assets this is the same as weighting by inverse volatility.
- **Leverage:** risk parity scaled each month so its forecast volatility matches 60/40's, borrowing at the
  bill rate plus 0.5% a year.
- **Costs:** 10 bps of the value traded (turnover counts buys and sells).
- **Measures:** compound annual return, volatility, Sharpe ratio (over bills), worst fall from a peak and
  turnover a year.
- **Results** start in July 1968, 60 months after the data starts, so every covariance window has full history.
- **Choices tested,** one at a time: a 60-month window, costs of 0 and 25 bps, borrowing at the bill rate and at
  bills + 1%, and bonds built from monthly-average yields. The baseline was fixed before any results were run.
  This is a check that the answer doesn't hang on one setting, not a search for the best backtest.

## Limits
- One bond, the 10-year Treasury, built from yields rather than an investable index. No credit,
  inflation-linked bonds, commodities or markets outside the US.
- The period holds one 40-year fall in interest rates, which favoured bonds and so favoured risk parity.
- Trading costs cover only trades between portfolios. The factor portfolios' own rebalancing isn't costed, and
  their premiums are measured on the same US data in which most of them were first found.
- Monthly data, so falls within a month don't show.

## Rerun it
Needs R (4.6 was used) and an internet connection.

```r
# in R, from the project folder
renv::restore()   # installs the pinned packages (jsonlite; renv itself)
```

```bash
Rscript run.R            # downloads the data if needed, runs the checks, writes output/
Rscript run.R --refresh  # downloads everything again first
```

The study ends in August 2026 (`END` in `run.R`). The French library is updated monthly and occasionally revises
its history, so a later download can move results slightly.

## What's here
- `run.R`: the entry script.
- `R/`: downloads, inputs, portfolio rules and the backtest engine, measures, settings and outputs.
- `tests/checks.R`: checks run before any results are written (the solver, no look-ahead, bond returns).
- `output/RESULTS.md`: all the tables.
- `output/tables/`: the same tables as CSV.
- `output/site/`: small JSON files that the charts on ruangoosen.co.za are drawn from.
- `output/figures/`: rough charts for checking.

## Licence
Code: MIT (see `LICENSE`). The data belong to their providers; see their terms.
