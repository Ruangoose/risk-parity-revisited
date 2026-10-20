# Writes the results: tables (CSV), chart data for the website (JSON) and rough charts (PNG).

STRATEGY_KEYS <- c(
  "Stocks" = "stocks", "60/40" = "sixty-forty", "Risk parity" = "risk-parity",
  "Risk parity, levered" = "risk-parity-levered", "Market" = "market", "Equal weights" = "equal-weights",
  "Inverse volatility" = "inverse-vol", "Equal risk" = "equal-risk"
)

write_outputs <- function(inputs, part1, part2, periods, falls, sensitivity, settings, end, dir = "output") {
  for (sub in c("tables", "site", "figures")) dir.create(file.path(dir, sub), showWarnings = FALSE, recursive = TRUE)

  # ---- Tables ----
  s1 <- summary_table(part1)
  s2 <- summary_table(part2)
  by_period <- do.call(rbind, lapply(names(periods), function(p) {
    cbind(period = p, from = periods[[p]][1], to = periods[[p]][2],
          summary_table(c(part1, part2[-1]), periods[[p]][1], periods[[p]][2]))
  }))
  everything <- c(part1, part2[-1])
  fall_table <- cbind(falls, do.call(rbind, lapply(seq_len(nrow(falls)), function(i) {
    vapply(everything, period_return, numeric(1), from = falls$from[i], to = falls$to[i])
  })))
  bond_years <- bond_check_table()

  write_csv(s1, file.path(dir, "tables", "summary-stocks-and-bonds.csv"))
  write_csv(s2, file.path(dir, "tables", "summary-factors.csv"))
  write_csv(by_period, file.path(dir, "tables", "summary-by-rate-period.csv"))
  write_csv(fall_table, file.path(dir, "tables", "stock-market-falls.csv"))
  write_csv(sensitivity, file.path(dir, "tables", "sensitivity.csv"))
  write_csv(bond_years, file.path(dir, "tables", "bond-return-check.csv"))

  # ---- Chart data for the website ----
  sf <- part1[["60/40"]]
  rp <- part1[["Risk parity"]]
  lv <- part1[["Risk parity, levered"]]
  first_month <- sf$month[1]
  base_month <- format(seq(as.Date(paste0(first_month, "-01")), by = "-1 month", length.out = 2)[2], "%Y-%m")

  risk_split <- list(
    from = first_month, to = end, window_months = settings$window,
    note = "Averages of the monthly forecasts over the whole period.",
    sixty_forty = list(
      money = list(stocks = 0.6, bonds = 0.4),
      risk = list(stocks = round(mean(sf$risk[, "Market"]), 4), bonds = round(mean(sf$risk[, "Bonds"]), 4))
    ),
    risk_parity = list(
      money = list(stocks = round(mean(rp$weights[, "Market"]), 4), bonds = round(mean(rp$weights[, "Bonds"]), 4)),
      risk = list(stocks = 0.5, bonds = 0.5)
    )
  )

  # Growth of $1 and the fall from peak, month by month, for the stocks-and-bonds strategies. (The factor
  # strategies' lines overlap almost exactly, so the site shows them as a table from summary.json.)
  series <- lapply(names(part1), function(name) {
    bt <- part1[[name]]
    list(
      key = STRATEGY_KEYS[[name]], label = name,
      growth = signif(c(1, growth(bt$return)), 4),
      drawdown = r3(c(0, drawdown(bt$return)))
    )
  })
  growth_json <- list(
    base_month = base_month, first_month = first_month, last_month = end,
    series = series,
    falls = rows(transform(falls, fall = r3(fall))),
    stats = rows(cbind(key = unname(STRATEGY_KEYS[s1$strategy]), s1))
  )

  corr <- rolling_correlation(inputs, "Market", "Bonds", settings$window, sf$month)
  risk_time <- list(
    first_month = first_month, last_month = end, window_months = settings$window,
    sixty_forty_stock_risk = r3(sf$risk[, "Market"]),
    risk_parity_stock_weight = r3(rp$weights[, "Market"]),
    levered_exposure = r3(rowSums(lv$weights)),
    stock_bond_correlation = r3(corr)
  )

  write_json(risk_split, file.path(dir, "site", "risk-split.json"))
  write_json(growth_json, file.path(dir, "site", "growth.json"))
  write_json(risk_time, file.path(dir, "site", "risk-over-time.json"))

  summary <- list(
    question = "Does a portfolio that balances risk across assets and factors hold up better than one that balances money, and what does it cost?",
    sample = list(first_month = first_month, last_month = end, months = length(sf$month)),
    settings = settings,
    data_vintage = data_vintage(),
    stocks_and_bonds = rows(s1),
    factors = rows(s2),
    rate_periods = rows(by_period),
    stock_market_falls = rows(fall_table),
    sensitivity = rows(sensitivity),
    risk = list(
      sixty_forty_stock_risk = spread3(sf$risk[, "Market"]),
      risk_parity_stock_weight = spread3(rp$weights[, "Market"]),
      levered_exposure = spread3(rowSums(lv$weights)),
      stock_bond_correlation = spread3(corr),
      factor_correlations = spread3(cor(inputs[inputs$month >= first_month, FACTORS])[upper.tri(diag(6))]),
      equal_risk_mean_weights = as.list(round(colMeans(part2[["Equal risk"]]$weights), 6)),
      equal_weight_mean_risk = as.list(round(colMeans(part2[["Equal weights"]]$risk), 6)),
      sixty_forty_stock_risk_over_100 = runs_where(sf$month, sf$risk[, "Market"] > 1),
      negative_correlation = runs_where(sf$month, corr < 0)
    ),
    falls_count = list(
      falls = nrow(fall_table),
      risk_parity_fell_less = sum(fall_table[["Risk parity"]] > fall_table[["60/40"]]),
      levered_fell_less = sum(fall_table[["Risk parity, levered"]] > fall_table[["60/40"]])
    ),
    assets = asset_stats(inputs, first_month, end),
    worst_falls = rows(do.call(rbind, lapply(names(everything), function(n) {
      cbind(strategy = n, worst_fall(everything[[n]]))
    })))
  )
  write_json(summary, file.path(dir, "site", "summary.json"))
  write_results_md(s1, s2, by_period, fall_table, sensitivity, summary, file.path(dir, "RESULTS.md"))

  # ---- Rough charts ----
  rough_charts(part1, part2, falls, corr, file.path(dir, "figures"))
  invisible(TRUE)
}

r3 <- function(x) round(x, 3)

# Months where `flag` holds: how many, and the longest unbroken run.
runs_where <- function(month, flag) {
  r <- rle(flag)
  ends <- cumsum(r$lengths)
  starts <- ends - r$lengths + 1
  true_runs <- which(r$values)
  longest <- true_runs[which.max(r$lengths[true_runs])]
  list(
    months = sum(flag), share = round(mean(flag), 6),
    longest_from = month[starts[longest]], longest_to = month[ends[longest]],
    longest_months = r$lengths[longest],
    outside_longest = sum(flag) - r$lengths[longest]
  )
}

# The worst fall from a peak: when it peaked, when it bottomed and how far it fell.
worst_fall <- function(bt) {
  g <- c(1, growth(bt$return))
  months <- c(NA, bt$month)
  dd <- g / cummax(g) - 1
  trough <- which.min(dd)
  peak <- which.max(g[1:trough])
  data.frame(peak = if (peak == 1) "start" else months[peak], trough = months[trough], fall = round(dd[trough], 6))
}

# Each asset's own record over the results period, and the stock-bond correlation.
asset_stats <- function(inputs, from, to) {
  d <- inputs[inputs$month >= from & inputs$month <= to, ]
  stat <- function(r) list(return = round(prod(1 + r)^(12 / length(r)) - 1, 6), volatility = round(stats::sd(r) * sqrt(12), 6))
  list(
    stocks = stat(d$Market), bonds = stat(d$Bonds), cash = stat(d$Cash),
    stock_bond_correlation = round(stats::cor(d$Market, d$Bonds), 6)
  )
}

# Summary figures keep 6 decimals, so the website rounds them once, not twice.
spread3 <- function(x) as.list(round(c(mean = mean(x), min = min(x), max = max(x)), 6))

# A data frame as a list of row objects (a JSON array), numbers rounded to 6 decimals.
rows <- function(d) {
  unname(lapply(seq_len(nrow(d)), function(i) {
    lapply(as.list(d[i, , drop = FALSE]), function(v) if (is.numeric(v)) round(v, 6) else v)
  }))
}

write_csv <- function(d, path) {
  num <- vapply(d, is.numeric, logical(1))
  d[num] <- lapply(d[num], round, 5)
  utils::write.csv(d, path, row.names = FALSE)
}

write_json <- function(x, path) {
  jsonlite::write_json(x, path, auto_unbox = TRUE, digits = NA, pretty = FALSE)
}

rolling_correlation <- function(inputs, a, b, window, months) {
  idx <- match(months, inputs$month)
  vapply(idx, function(t) stats::cor(inputs[[a]][(t - window):(t - 1)], inputs[[b]][(t - window):(t - 1)]), numeric(1))
}

# Calendar-year returns on the 10-year bond in years worth checking against published figures.
bond_check_table <- function() {
  yearly <- function(d) tapply(d$Bonds, substr(d$month, 1, 4), function(r) prod(1 + r) - 1)
  a <- yearly(bond_returns(month_end_yield("DGS10")))
  e <- yearly(bond_returns(month_end_yield("DGS10"), exact = TRUE))
  g <- yearly(bond_returns(month_end_yield("GS10")))
  years <- c("1969", "1974", "1980", "1982", "1994", "1999", "2008", "2009", "2013", "2020", "2022")
  data.frame(year = years, duration_convexity = a[years], exact_repricing = e[years], monthly_average_yields = g[years])
}

# The month of CRSP data each French file was built from, and when the files were downloaded.
data_vintage <- function(dir = "data-raw") {
  first_line <- function(zip) {
    con <- unz(zip, utils::unzip(zip, list = TRUE)$Name[1])
    on.exit(close(con))
    readLines(con, n = 1, warn = FALSE)
  }
  crsp <- unique(sub(".*using the (\\d{6}) CRSP.*", "\\1",
                     vapply(file.path(dir, FRENCH_FILES), first_line, character(1))))
  list(
    french_crsp_database = crsp,
    downloaded = format(min(file.mtime(list.files(dir, full.names = TRUE))), "%Y-%m-%d")
  )
}

# A readable summary of the results, rewritten on every run so it always matches the tables.
write_results_md <- function(s1, s2, by_period, fall_table, sensitivity, summary, path) {
  pct <- function(x, d = 1) sprintf(paste0("%.", d, "f%%"), 100 * x)
  num <- function(x) sprintf("%.2f", ifelse(abs(x) < 0.005, 0, x))
  md_table <- function(d, cols, heads) {
    rows <- apply(d[, cols, drop = FALSE], 1, function(r) paste0("| ", paste(r, collapse = " | "), " |"))
    c(paste0("| ", paste(heads, collapse = " | "), " |"), paste0("|", strrep("---|", length(heads))), rows)
  }
  fmt <- function(d) {
    data.frame(strategy = d$strategy, return = pct(d$return), volatility = pct(d$volatility),
               sharpe = num(d$sharpe), max_dd = pct(d$max_dd, 0), turnover = num(d$turnover))
  }
  heads <- c("Strategy", "Return a year", "Volatility", "Sharpe ratio", "Worst fall", "Turnover a year")
  cols <- c("strategy", "return", "volatility", "sharpe", "max_dd", "turnover")
  s <- summary$sample
  r <- summary$risk

  lines <- c(
    "# Results",
    "",
    sprintf("Monthly, %s to %s (%d months). Written by `run.R`; don't edit by hand.", s$first_month, s$last_month, s$months),
    sprintf("Settings: %d-month covariance window, trading costs of %s bps per unit of turnover, borrowing at the bill rate plus %s a year.",
            summary$settings$window, format(1e4 * summary$settings$cost), pct(summary$settings$spread)),
    "",
    "## Stocks and bonds", "",
    md_table(fmt(s1), cols, heads), "",
    sprintf("60/40's stocks carried %s of its risk on average (between %s and %s). Risk parity held %s in stocks on average (between %s and %s). Levered risk parity's exposure averaged %.2f times capital (between %.2f and %.2f).",
            pct(r$sixty_forty_stock_risk[["mean"]], 0), pct(r$sixty_forty_stock_risk[["min"]], 0), pct(r$sixty_forty_stock_risk[["max"]], 0),
            pct(r$risk_parity_stock_weight[["mean"]], 0), pct(r$risk_parity_stock_weight[["min"]], 0), pct(r$risk_parity_stock_weight[["max"]], 0),
            r$levered_exposure[["mean"]], r$levered_exposure[["min"]], r$levered_exposure[["max"]]),
    "",
    "## Smart beta: six long-only factor portfolios", "",
    md_table(fmt(s2), cols, heads), "",
    sprintf("The six portfolios' correlations with each other range from %.2f to %.2f.", r$factor_correlations$min, r$factor_correlations$max),
    "",
    "## By interest-rate period", ""
  )
  for (p in unique(by_period$period)) {
    lines <- c(lines, paste0("**", p, "**"), "", md_table(fmt(by_period[by_period$period == p, ]), cols, heads), "")
  }
  falls <- fall_table
  strat <- setdiff(names(falls), c("from", "to", "fall"))
  ft <- data.frame(span = paste(falls$from, "to", falls$to), lapply(falls[strat], pct))
  lines <- c(lines, "## US stock market falls of more than 20%", "",
             "Return of each strategy from the market's peak to its trough.", "",
             md_table(ft, names(ft), c("Fall", strat)), "",
             "## Sensitivity: one choice changed at a time", "")
  sens <- sensitivity
  sens_fmt <- cbind(run = sens$run, fmt(sens))
  lines <- c(lines, md_table(sens_fmt, c("run", cols), c("Run", heads)), "")
  writeLines(lines, path, useBytes = TRUE)
}

# Rough charts in base R graphics, for checking the results. The website draws its own.
rough_charts <- function(part1, part2, falls, corr, dir) {
  to_date <- function(m) as.Date(paste0(m, "-01"))
  cols <- c("grey40", "#c9a227", "#3b6fb6", "#b3263c")
  shade <- function(lo, hi) {
    for (i in seq_len(nrow(falls))) {
      graphics::rect(to_date(falls$from[i]), lo, to_date(falls$to[i]), hi, col = "grey90", border = NA)
    }
  }
  png_open <- function(name, h = 5) grDevices::png(file.path(dir, name), width = 9, height = h, units = "in", res = 110)

  for (part in list(list(res = part1, file = "growth-stocks-and-bonds.png"), list(res = part2, file = "growth-factors.png"))) {
    res <- part$res
    x <- to_date(res[[1]]$month)
    g <- sapply(res, function(bt) growth(bt$return))
    d <- sapply(res, function(bt) drawdown(bt$return))
    png_open(part$file, 7)
    graphics::layout(matrix(1:2), heights = c(2, 1))
    graphics::par(mar = c(2, 4.5, 2, 1))
    graphics::plot(x, g[, 1], type = "n", log = "y", ylim = range(g), xlab = "", ylab = "Growth of $1 (log scale)")
    shade(1e-3, 1e4)
    graphics::matlines(x, g, lty = 1, lwd = 1.6, col = cols)
    graphics::legend("topleft", names(res), col = cols, lty = 1, lwd = 2, bty = "n")
    graphics::plot(x, d[, 1], type = "n", ylim = range(d), xlab = "", ylab = "Fall from peak")
    shade(-2, 1)
    graphics::matlines(x, d, lty = 1, lwd = 1.2, col = cols)
    grDevices::dev.off()
  }

  sf <- part1[["60/40"]]
  rp <- part1[["Risk parity"]]
  m <- cbind(
    "60/40: money" = c(0.6, 0.4),
    "60/40: risk" = colMeans(sf$risk),
    "Risk parity: money" = colMeans(rp$weights),
    "Risk parity: risk" = c(0.5, 0.5)
  )
  png_open("risk-split.png", 4.5)
  graphics::par(mar = c(3, 3, 2, 1))
  b <- graphics::barplot(m, col = c("#c9a227", "#3b6fb6"), border = NA, ylim = c(0, 1.08))
  graphics::text(rep(b, each = 2), apply(m, 2, function(v) cumsum(v) - v / 2), sprintf("%.0f%%", 100 * m))
  graphics::legend("top", c("Stocks", "Bonds"), fill = c("#c9a227", "#3b6fb6"), horiz = TRUE, bty = "n", border = NA)
  grDevices::dev.off()

  x <- to_date(sf$month)
  png_open("risk-over-time.png")
  graphics::par(mar = c(2, 3, 2, 1))
  graphics::plot(x, sf$risk[, "Market"], type = "n", ylim = range(c(-0.8, 1.3)), xlab = "", ylab = "")
  shade(-2, 2)
  graphics::abline(h = c(0, 0.5, 1), col = "grey70")
  graphics::lines(x, sf$risk[, "Market"], col = "#b3263c", lwd = 1.6)
  graphics::lines(x, rp$weights[, "Market"], col = "#c9a227", lwd = 1.6)
  graphics::lines(x, corr, col = "grey40", lwd = 1.2)
  graphics::legend("bottomleft", c("60/40: stocks' share of risk", "Risk parity: stocks' share of money",
                                   "Stock-bond correlation (36 months)"),
                   col = c("#b3263c", "#c9a227", "grey40"), lty = 1, lwd = 2, bty = "n")
  grDevices::dev.off()
}

