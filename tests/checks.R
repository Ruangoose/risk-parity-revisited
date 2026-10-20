# Checks that run before any results are written. Each one stops the run if it fails.

run_checks <- function(inputs) {
  check <- function(ok, what) {
    if (!isTRUE(ok)) stop("Check failed: ", what, call. = FALSE)
    message("ok  ", what)
  }

  # Equal risk contribution: equal shares of risk, and inverse volatility when there are two assets.
  set.seed(1)
  a <- matrix(rnorm(36), 6)
  sigma <- crossprod(a) + diag(0.1, 6)
  colnames(sigma) <- rownames(sigma) <- letters[1:6]
  w <- erc_weights(sigma)
  check(all(abs(risk_contributions(w, sigma) - 1 / 6) < 1e-9) && abs(sum(w) - 1) < 1e-12 && all(w > 0),
        "ERC weights are long-only, fully invested and equalise risk")
  s2 <- matrix(c(0.04, -0.002, -0.002, 0.0049), 2, dimnames = list(c("x", "y"), c("x", "y")))
  check(all(abs(erc_weights(s2) - inverse_vol_weights(s2)) < 1e-10),
        "With two assets, ERC equals inverse volatility")

  # No look-ahead: changing returns from month t on must not change any weight set before month t.
  assets <- c("Market", "Bonds")
  base <- backtest(inputs, assets, erc(), window = 36, start = BASELINE$start)
  bumped <- inputs
  t <- match("2000-01", inputs$month)
  bumped[t:nrow(bumped), assets] <- bumped[t:nrow(bumped), assets] * 3 + 0.05
  alt <- backtest(bumped, assets, erc(), window = 36, start = BASELINE$start)
  k <- match("2000-01", base$month)
  check(identical(base$weights[1:k, ], alt$weights[1:k, ]) && !identical(base$weights, alt$weights),
        "Weights use only data up to the month before")

  # Bond returns: the duration and convexity approximation against exact repricing of the bond.
  y <- month_end_yield("DGS10")
  approx <- bond_returns(y)
  exact <- bond_returns(y, exact = TRUE)
  check(max(abs(approx$Bonds - exact$Bonds)) < 0.001,
        "Bond returns are within 10 bps a month of exact repricing")

  # Bond returns in known episodes: losses in 1994 and 2022, gains in 1982 and 2008.
  yearly <- tapply(approx$Bonds, substr(approx$month, 1, 4), function(r) prod(1 + r) - 1)
  check(yearly[["1994"]] < -0.05 && yearly[["1994"]] > -0.10, "1994: the 10-year lost 5-10%")
  check(yearly[["2022"]] < -0.12 && yearly[["2022"]] > -0.20, "2022: the 10-year lost 12-20%")
  check(yearly[["1982"]] > 0.25 && yearly[["2008"]] > 0.15, "1982 and 2008: large gains")

  # Inputs: plausible ranges, and the factor portfolios move with the market.
  r <- inputs[, setdiff(names(inputs), "month")]
  check(all(abs(as.matrix(r)) < 0.5), "No monthly return beyond +/-50%")
  check(all(cor(inputs$Market, inputs[, FACTORS]) > 0.5), "Every factor portfolio moves with the market")
  invisible(TRUE)
}
