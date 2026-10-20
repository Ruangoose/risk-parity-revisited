# Weighting rules, risk contributions and the backtest engine.

# Share of portfolio variance from each asset: w_i * (Sigma w)_i / (w' Sigma w). Sums to 1.
risk_contributions <- function(w, sigma) {
  m <- as.vector(sigma %*% w)
  rc <- w * m / sum(w * m)
  setNames(rc, colnames(sigma))
}

inverse_vol_weights <- function(sigma) {
  w <- 1 / sqrt(diag(sigma))
  w / sum(w)
}

# Equal risk contribution (long-only, fully invested). Solves
#   min 0.5 x' Sigma x - (1/n) sum(log x)
# by Newton's method; at the optimum x_i (Sigma x)_i = 1/n for every i, so x / sum(x) has equal risk
# contributions. The problem is strictly convex, so the solution is unique.
erc_weights <- function(sigma, tol = 1e-12, max_iter = 100) {
  n <- ncol(sigma)
  b <- rep(1 / n, n)
  x <- 1 / sqrt(diag(sigma))
  x <- x / sqrt(sum(x * (sigma %*% x)))
  for (iter in seq_len(max_iter)) {
    grad <- as.vector(sigma %*% x) - b / x
    if (max(abs(grad)) < tol) break
    hess <- sigma + diag(b / x^2, n)
    step <- solve(hess, grad)
    a <- 1
    while (any(x - a * step <= 0)) a <- a / 2   # stay positive
    x <- x - a * step
  }
  w <- x / sum(x)
  rc <- risk_contributions(w, sigma)
  if (max(abs(rc - 1 / n)) > 1e-8) stop("ERC solver did not converge")
  setNames(w, colnames(sigma))
}

# ---- Strategies ---------------------------------------------------------------------------------------
# A strategy is a function of (sigma, history) returning the target weights on the risky assets for the
# coming month. Weights that sum to less than 1 hold the rest in cash; weights that sum to more than 1
# borrow the difference.

fixed_weights <- function(w) function(sigma, ...) w[colnames(sigma)]
equal_weights <- function() function(sigma, ...) setNames(rep(1 / ncol(sigma), ncol(sigma)), colnames(sigma))
inverse_vol   <- function() function(sigma, ...) inverse_vol_weights(sigma)
erc           <- function() function(sigma, ...) erc_weights(sigma)

# Risk parity scaled each month so that its forecast volatility equals that of `target` (fixed weights),
# both forecast with the same covariance estimate. `max_leverage` caps the gross exposure.
levered_erc <- function(target, max_leverage = Inf) function(sigma, ...) {
  w <- erc_weights(sigma)
  tw <- target[colnames(sigma)]
  k <- sqrt(sum(tw * (sigma %*% tw)) / sum(w * (sigma %*% w)))
  w * min(k, max_leverage)
}

# ---- Backtest -----------------------------------------------------------------------------------------

# Runs one strategy on the risky assets in `returns` (a data frame with `month`, the asset columns and
# `Cash`). At the end of each month t-1 it estimates the covariance matrix from months t-W .. t-1 only,
# sets target weights, and holds them through month t.
#   cost:   charged on turnover, as a fraction of the value traded (0.001 = 10 bps per unit of turnover).
#   spread: added to the cash rate on any borrowing, a year (0.005 = 0.5% a year).
#   start:  the first month of returns; earlier months are used only for estimation.
# Turnover each month is sum |w_target - w_drifted|, where w_drifted are last month's weights after
# a month of returns. The first month's build is free.
backtest <- function(returns, assets, strategy, window = 36, cost = 0.001, spread = 0.005,
                     start = NULL) {
  months <- returns$month
  r <- as.matrix(returns[, assets, drop = FALSE])
  cash <- returns$Cash
  first <- if (is.null(start)) window + 1 else match(start, months)
  if (is.na(first) || first <= window) stop("Not enough history before the start month")

  n <- length(assets)
  periods <- first:length(months)
  out_w <- matrix(NA_real_, length(periods), n, dimnames = list(NULL, assets))
  out_rc <- out_w
  ret <- gross <- turnover <- vol_forecast <- numeric(length(periods))
  drifted <- NULL

  for (j in seq_along(periods)) {
    t <- periods[j]
    hist <- r[(t - window):(t - 1), , drop = FALSE]
    sigma <- stats::cov(hist)
    w <- strategy(sigma, hist)
    w <- w[assets]

    turnover[j] <- if (is.null(drifted)) 0 else sum(abs(w - drifted))
    cash_w <- 1 - sum(w)
    borrow <- if (cash_w < 0) spread / 12 else 0
    gross[j] <- sum(w * r[t, ]) + cash_w * (cash[t] + borrow)
    ret[j] <- gross[j] - cost * turnover[j]

    out_w[j, ] <- w
    out_rc[j, ] <- risk_contributions(w, sigma)
    vol_forecast[j] <- sqrt(sum(w * (sigma %*% w)) * 12)
    drifted <- w * (1 + r[t, ]) / (1 + gross[j])
  }

  list(
    month = months[periods],
    return = ret,
    gross = gross,
    cash = cash[periods],
    turnover = turnover,
    weights = out_w,
    risk = out_rc,
    vol_forecast = vol_forecast,
    settings = list(assets = assets, window = window, cost = cost, spread = spread)
  )
}
