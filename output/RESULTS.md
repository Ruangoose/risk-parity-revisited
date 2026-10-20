# Results

Monthly, 1968-07 to 2026-08 (698 months). Written by `run.R`; don't edit by hand.
Settings: 36-month covariance window, trading costs of 10 bps per unit of turnover, borrowing at the bill rate plus 0.5% a year.

## Stocks and bonds

| Strategy | Return a year | Volatility | Sharpe ratio | Worst fall | Turnover a year |
|---|---|---|---|---|---|
| Stocks | 10.8% | 15.8% | 0.44 | -50% | 0.00 |
| 60/40 | 9.2% | 10.3% | 0.47 | -30% | 0.21 |
| Risk parity | 8.0% | 7.9% | 0.43 | -19% | 0.24 |
| Risk parity, levered | 8.8% | 10.8% | 0.41 | -32% | 0.53 |

60/40's stocks carried 89% of its risk on average (between 66% and 122%). Risk parity held 34% in stocks on average (between 19% and 50%). Levered risk parity's exposure averaged 1.40 times capital (between 1.02 and 2.26).

## Smart beta: six long-only factor portfolios

| Strategy | Return a year | Volatility | Sharpe ratio | Worst fall | Turnover a year |
|---|---|---|---|---|---|
| Market | 10.8% | 15.8% | 0.44 | -50% | 0.00 |
| Equal weights | 12.7% | 15.9% | 0.55 | -50% | 0.19 |
| Inverse volatility | 12.6% | 15.4% | 0.56 | -49% | 0.23 |
| Equal risk | 12.6% | 15.3% | 0.56 | -49% | 0.24 |

The six portfolios' correlations with each other range from 0.63 to 0.88.

## By interest-rate period

**1968-1981: rates rising**

| Strategy | Return a year | Volatility | Sharpe ratio | Worst fall | Turnover a year |
|---|---|---|---|---|---|
| Stocks | 5.6% | 16.7% | -0.03 | -47% | 0.00 |
| 60/40 | 5.0% | 11.4% | -0.16 | -30% | 0.21 |
| Risk parity | 4.1% | 8.6% | -0.33 | -16% | 0.25 |
| Risk parity, levered | 3.2% | 12.3% | -0.27 | -26% | 0.60 |
| Equal weights | 9.0% | 17.9% | 0.16 | -43% | 0.19 |
| Inverse volatility | 8.9% | 17.2% | 0.16 | -43% | 0.22 |
| Equal risk | 8.9% | 17.2% | 0.16 | -43% | 0.23 |

**1981-2020: rates falling**

| Strategy | Return a year | Volatility | Sharpe ratio | Worst fall | Turnover a year |
|---|---|---|---|---|---|
| Stocks | 11.7% | 15.4% | 0.55 | -50% | 0.00 |
| 60/40 | 10.9% | 9.7% | 0.72 | -29% | 0.21 |
| Risk parity | 10.2% | 7.5% | 0.83 | -12% | 0.24 |
| Risk parity, levered | 12.0% | 9.8% | 0.82 | -16% | 0.50 |
| Equal weights | 13.2% | 15.2% | 0.64 | -50% | 0.18 |
| Inverse volatility | 13.2% | 14.7% | 0.66 | -49% | 0.23 |
| Equal risk | 13.2% | 14.7% | 0.66 | -49% | 0.24 |

**2020-2026: rates rising**

| Strategy | Return a year | Volatility | Sharpe ratio | Worst fall | Turnover a year |
|---|---|---|---|---|---|
| Stocks | 16.2% | 16.0% | 0.83 | -25% | 0.00 |
| 60/40 | 8.4% | 11.3% | 0.50 | -22% | 0.19 |
| Risk parity | 2.7% | 8.7% | 0.00 | -19% | 0.19 |
| Risk parity, levered | 1.0% | 13.1% | -0.09 | -32% | 0.54 |
| Equal weights | 17.9% | 16.0% | 0.93 | -18% | 0.26 |
| Inverse volatility | 17.1% | 15.4% | 0.90 | -18% | 0.29 |
| Equal risk | 17.0% | 15.5% | 0.90 | -18% | 0.30 |

## US stock market falls of more than 20%

Return of each strategy from the market's peak to its trough.

| Fall | Stocks | 60/40 | Risk parity | Risk parity, levered | Equal weights | Inverse volatility | Equal risk |
|---|---|---|---|---|---|---|---|
| 1968-12 to 1970-06 | -33.6% | -22.3% | -13.7% | -22.0% | -35.6% | -33.6% | -33.7% |
| 1973-01 to 1974-09 | -46.5% | -30.3% | -15.9% | -25.9% | -42.5% | -42.6% | -42.6% |
| 1987-09 to 1987-11 | -29.9% | -17.4% | -11.0% | -12.7% | -30.1% | -29.9% | -29.9% |
| 2000-09 to 2002-09 | -45.0% | -20.8% | 5.4% | 3.6% | -24.5% | -24.0% | -22.7% |
| 2007-11 to 2009-02 | -50.3% | -28.8% | -11.4% | -15.2% | -49.9% | -48.6% | -48.6% |
| 2020-02 to 2020-03 | -20.2% | -9.4% | -1.3% | -2.3% | -22.9% | -21.8% | -21.8% |
| 2022-01 to 2022-09 | -24.8% | -21.6% | -19.0% | -31.4% | -18.3% | -18.4% | -18.4% |

## Sensitivity: one choice changed at a time

| Run | Strategy | Return a year | Volatility | Sharpe ratio | Worst fall | Turnover a year |
|---|---|---|---|---|---|---|
| Baseline | Stocks | 10.8% | 15.8% | 0.44 | -50% | 0.00 |
| Baseline | 60/40 | 9.2% | 10.3% | 0.47 | -30% | 0.21 |
| Baseline | Risk parity | 8.0% | 7.9% | 0.43 | -19% | 0.24 |
| Baseline | Risk parity, levered | 8.8% | 10.8% | 0.41 | -32% | 0.53 |
| Baseline | Equal weights | 12.7% | 15.9% | 0.55 | -50% | 0.19 |
| Baseline | Inverse volatility | 12.6% | 15.4% | 0.56 | -49% | 0.23 |
| Baseline | Equal risk | 12.6% | 15.3% | 0.56 | -49% | 0.24 |
| 60-month window | Stocks | 10.8% | 15.8% | 0.44 | -50% | 0.00 |
| 60-month window | 60/40 | 9.2% | 10.3% | 0.47 | -30% | 0.21 |
| 60-month window | Risk parity | 7.9% | 8.0% | 0.42 | -19% | 0.21 |
| 60-month window | Risk parity, levered | 8.6% | 10.7% | 0.39 | -32% | 0.40 |
| 60-month window | Equal weights | 12.7% | 15.9% | 0.55 | -50% | 0.19 |
| 60-month window | Inverse volatility | 12.7% | 15.4% | 0.56 | -48% | 0.20 |
| 60-month window | Equal risk | 12.7% | 15.4% | 0.56 | -48% | 0.21 |
| No trading costs | Stocks | 10.8% | 15.8% | 0.44 | -50% | 0.00 |
| No trading costs | 60/40 | 9.3% | 10.3% | 0.47 | -30% | 0.21 |
| No trading costs | Risk parity | 8.0% | 7.9% | 0.44 | -19% | 0.24 |
| No trading costs | Risk parity, levered | 8.8% | 10.8% | 0.42 | -32% | 0.53 |
| No trading costs | Equal weights | 12.8% | 15.9% | 0.55 | -50% | 0.19 |
| No trading costs | Inverse volatility | 12.7% | 15.4% | 0.56 | -49% | 0.23 |
| No trading costs | Equal risk | 12.6% | 15.3% | 0.56 | -49% | 0.24 |
| Trading costs 25 bps | Stocks | 10.8% | 15.8% | 0.44 | -50% | 0.00 |
| Trading costs 25 bps | 60/40 | 9.2% | 10.3% | 0.46 | -30% | 0.21 |
| Trading costs 25 bps | Risk parity | 7.9% | 7.9% | 0.43 | -19% | 0.24 |
| Trading costs 25 bps | Risk parity, levered | 8.7% | 10.8% | 0.40 | -32% | 0.53 |
| Trading costs 25 bps | Equal weights | 12.7% | 15.9% | 0.55 | -50% | 0.19 |
| Trading costs 25 bps | Inverse volatility | 12.6% | 15.4% | 0.55 | -49% | 0.23 |
| Trading costs 25 bps | Equal risk | 12.6% | 15.3% | 0.55 | -49% | 0.24 |
| Borrowing at the bill rate | Stocks | 10.8% | 15.8% | 0.44 | -50% | 0.00 |
| Borrowing at the bill rate | 60/40 | 9.2% | 10.3% | 0.47 | -30% | 0.21 |
| Borrowing at the bill rate | Risk parity | 8.0% | 7.9% | 0.43 | -19% | 0.24 |
| Borrowing at the bill rate | Risk parity, levered | 9.0% | 10.8% | 0.43 | -32% | 0.53 |
| Borrowing at the bill rate | Equal weights | 12.7% | 15.9% | 0.55 | -50% | 0.19 |
| Borrowing at the bill rate | Inverse volatility | 12.6% | 15.4% | 0.56 | -49% | 0.23 |
| Borrowing at the bill rate | Equal risk | 12.6% | 15.3% | 0.56 | -49% | 0.24 |
| Borrowing at bills + 1% | Stocks | 10.8% | 15.8% | 0.44 | -50% | 0.00 |
| Borrowing at bills + 1% | 60/40 | 9.2% | 10.3% | 0.47 | -30% | 0.21 |
| Borrowing at bills + 1% | Risk parity | 8.0% | 7.9% | 0.43 | -19% | 0.24 |
| Borrowing at bills + 1% | Risk parity, levered | 8.6% | 10.8% | 0.39 | -32% | 0.53 |
| Borrowing at bills + 1% | Equal weights | 12.7% | 15.9% | 0.55 | -50% | 0.19 |
| Borrowing at bills + 1% | Inverse volatility | 12.6% | 15.4% | 0.56 | -49% | 0.23 |
| Borrowing at bills + 1% | Equal risk | 12.6% | 15.3% | 0.56 | -49% | 0.24 |
| Bonds from monthly-average yields (GS10) | Stocks | 10.8% | 15.8% | 0.44 | -50% | 0.00 |
| Bonds from monthly-average yields (GS10) | 60/40 | 9.2% | 10.2% | 0.47 | -31% | 0.21 |
| Bonds from monthly-average yields (GS10) | Risk parity | 7.8% | 7.2% | 0.45 | -18% | 0.23 |
| Bonds from monthly-average yields (GS10) | Risk parity, levered | 8.8% | 10.7% | 0.42 | -34% | 0.59 |
| Bonds from monthly-average yields (GS10) | Equal weights | 12.7% | 15.9% | 0.55 | -50% | 0.19 |
| Bonds from monthly-average yields (GS10) | Inverse volatility | 12.6% | 15.4% | 0.56 | -49% | 0.23 |
| Bonds from monthly-average yields (GS10) | Equal risk | 12.6% | 15.3% | 0.56 | -49% | 0.24 |

