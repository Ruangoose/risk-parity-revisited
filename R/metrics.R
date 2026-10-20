# Performance measures, from monthly returns.

growth <- function(r) cumprod(1 + r)

drawdown <- function(r) {
  g <- growth(r)
  g / cummax(pmax(g, 1)) - 1
}

# Annualised figures:
#   return:     compound annual growth rate;
#   volatility: standard deviation of monthly returns x sqrt(12);
#   sharpe:     mean monthly return over cash x 12, divided by the volatility of that excess return;
#   max_dd:     largest fall from a previous peak in the month-end value;
#   turnover:   average monthly turnover x 12 (1.0 = trading the whole portfolio once a year).
summarise_returns <- function(r, cash, turnover = NULL) {
  years <- length(r) / 12
  excess <- r - cash
  c(
    return = prod(1 + r)^(1 / years) - 1,
    volatility = stats::sd(r) * sqrt(12),
    sharpe = mean(excess) * 12 / (stats::sd(excess) * sqrt(12)),
    max_dd = min(drawdown(r)),
    turnover = if (is.null(turnover)) 0 else mean(turnover) * 12
  )
}

summarise_backtest <- function(bt, from = NULL, to = NULL) {
  keep <- in_span(bt$month, from, to)
  summarise_returns(bt$return[keep], bt$cash[keep], bt$turnover[keep])
}

# Return over a span of months (from the end of the month before `from` to the end of `to`).
period_return <- function(bt, from, to) {
  prod(1 + bt$return[in_span(bt$month, from, to)]) - 1
}

# Months from `from` to `to`, inclusive; NULL or NA leaves that end open.
in_span <- function(month, from = NULL, to = NULL) {
  keep <- rep(TRUE, length(month))
  if (length(from) && !is.na(from)) keep <- keep & month >= from
  if (length(to) && !is.na(to)) keep <- keep & month <= to
  keep
}
