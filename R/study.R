# The study's settings and strategies.

# Baseline choices, fixed before looking at results. The sensitivity runs change one at a time.
BASELINE <- list(
  window = 36,        # months of returns in each covariance estimate (as in Asness, Frazzini and Pedersen, 2012)
  cost = 0.001,       # 10 bps of the value traded
  spread = 0.005,     # borrowing costs the bill rate plus 0.5% a year
  start = "1968-07",  # first month of results: 60 months after July 1963, so every window has full history
  bond_series = "DGS10"
)

SIXTY_FORTY <- c(Market = 0.6, Bonds = 0.4)
FACTORS <- c("Small", "Value", "Momentum", "Profitability", "Investment", "Low variance")

# Part 1: stocks and bonds.
part1_strategies <- function() list(
  "Stocks"                = list(assets = "Market", fn = fixed_weights(c(Market = 1))),
  "60/40"                 = list(assets = names(SIXTY_FORTY), fn = fixed_weights(SIXTY_FORTY)),
  "Risk parity"           = list(assets = names(SIXTY_FORTY), fn = erc()),
  "Risk parity, levered"  = list(assets = names(SIXTY_FORTY), fn = levered_erc(SIXTY_FORTY))
)

# Part 2: smart beta across the six long-only factor portfolios.
part2_strategies <- function() list(
  "Market"              = list(assets = "Market", fn = fixed_weights(c(Market = 1))),
  "Equal weights"       = list(assets = FACTORS, fn = equal_weights()),
  "Inverse volatility"  = list(assets = FACTORS, fn = inverse_vol()),
  "Equal risk"          = list(assets = FACTORS, fn = erc())
)

run_strategies <- function(inputs, strategies, settings = BASELINE) {
  lapply(strategies, function(s) backtest(
    inputs, s$assets, s$fn,
    window = settings$window, cost = settings$cost, spread = settings$spread, start = settings$start
  ))
}

summary_table <- function(results, from = NULL, to = NULL) {
  rows <- lapply(results, summarise_backtest, from = from, to = to)
  out <- as.data.frame(do.call(rbind, rows))
  out <- cbind(strategy = names(results), out)
  rownames(out) <- NULL
  out
}

# The periods used to split the results, taken from the 10-year yield itself: rising rates up to its
# highest month-end, falling rates down to its lowest month-end after that, then rising rates again.
rate_periods <- function(yields, start, end) {
  y <- yields[yields$month >= start & yields$month <= end, ]
  peak <- y$month[which.max(y$yield)]
  after <- y[y$month > peak, ]
  low <- after$month[which.min(after$yield)]
  next_month <- function(m) format(seq(as.Date(paste0(m, "-01")), by = "month", length.out = 2)[2], "%Y-%m")
  label <- function(a, b, what) paste0(substr(a, 1, 4), "-", substr(b, 1, 4), ": rates ", what)
  setNames(
    list(c(start, peak), c(next_month(peak), low), c(next_month(low), end)),
    c(label(start, peak, "rising"), label(next_month(peak), low, "falling"), label(next_month(low), end, "rising"))
  )
}

# Sensitivity runs: one choice changed at a time from the baseline.
SENSITIVITIES <- list(
  "Baseline"                       = list(),
  "60-month window"                = list(window = 60),
  "No trading costs"               = list(cost = 0),
  "Trading costs 25 bps"           = list(cost = 0.0025),
  "Borrowing at the bill rate"     = list(spread = 0),
  "Borrowing at bills + 1%"        = list(spread = 0.01),
  "Bonds from monthly-average yields (GS10)" = list(bond_series = "GS10")
)

# Stock market falls: every episode in which the market fell more than `threshold` from a month-end peak.
# Each runs from the first month after the peak to the trough.
market_falls <- function(bt, threshold = -0.2) {
  g <- growth(bt$return)
  peak <- cummax(pmax(g, 1))
  dd <- g / peak - 1
  out <- list()
  i <- 1
  n <- length(dd)
  while (i <= n) {
    if (dd[i] < 0) {
      j <- i
      while (j <= n && dd[j] < 0) j <- j + 1
      span <- i:(j - 1)
      trough <- span[which.min(dd[span])]
      if (dd[trough] <= threshold) {
        out[[length(out) + 1]] <- data.frame(from = bt$month[i], to = bt$month[trough], fall = dd[trough])
      }
      i <- j
    } else {
      i <- i + 1
    }
  }
  do.call(rbind, out)
}
