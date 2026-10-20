# Builds the monthly return inputs from the raw downloads:
# - equities: the US market and six long-only factor portfolios, from the Kenneth French Data Library;
# - bonds: a 10-year US Treasury par bond, from the 10-year constant-maturity yield (FRED DGS10);
# - cash: 3-month Treasury bills, from FRED TB3MS.
# All returns are simple monthly returns in decimals, keyed by month ("YYYY-MM").

# ---- Kenneth French files ---------------------------------------------------------------------------

# Reads one section of a French CSV inside its zip. `section` is a regex for the section's title line,
# for example "^Value Weight(ed)? Returns -- Monthly". The first table in the file has no title line,
# so `section = NULL` reads the first table instead. Values come back as decimals (the files use percent),
# except where `percent = FALSE` (firm counts and sizes).
read_french <- function(zip_path, section = NULL, percent = TRUE) {
  csv <- utils::unzip(zip_path, list = TRUE)$Name[1]
  con <- unz(zip_path, csv)
  on.exit(close(con))
  lines <- readLines(con, warn = FALSE)
  lines <- sub("\\s+$", "", lines)

  if (is.null(section)) {
    start <- which(grepl("^\\s*,", lines))[1]
  } else {
    title <- which(grepl(section, trimws(lines)))
    if (length(title) == 0) stop("Section not found in ", basename(zip_path), ": ", section)
    start <- which(grepl("^\\s*,", lines) & seq_along(lines) > title[1])[1]
  }
  header <- trimws(strsplit(lines[start], ",")[[1]])
  header[1] <- "yyyymm"

  rows <- character(0)
  i <- start + 1
  while (i <= length(lines) && grepl("^\\s*\\d{6}\\s*,", lines[i])) {
    rows <- c(rows, lines[i])
    i <- i + 1
  }
  values <- do.call(rbind, lapply(strsplit(rows, ","), function(x) as.numeric(trimws(x))))
  colnames(values) <- header
  out <- as.data.frame(values)
  out$yyyymm <- as.integer(out$yyyymm)
  num <- setdiff(names(out), "yyyymm")
  for (col in num) {
    v <- out[[col]]
    v[v <= -99.99] <- NA
    out[[col]] <- if (percent) v / 100 else v
  }
  out$month <- sprintf("%04d-%02d", out$yyyymm %/% 100, out$yyyymm %% 100)
  out[, c("month", num)]
}

VW_MONTHLY <- "^(Average )?Value Weight(ed)? Returns -- Monthly"

# The six long-only factor portfolios: the value-weighted top (or bottom) fifth of US stocks on each
# characteristic, from the univariate sorts. Momentum has deciles only, so its top fifth is deciles 9
# and 10 combined by their total market value at the start of each month.
build_factor_portfolios <- function(dir = "data-raw") {
  f <- function(key) file.path(dir, FRENCH_FILES[[key]])

  pick <- function(key, column, label) {
    d <- read_french(f(key), VW_MONTHLY)
    setNames(d[, c("month", column)], c("month", label))
  }
  small   <- pick("size", "Lo 20", "Small")
  value   <- pick("value", "Hi 20", "Value")
  profit  <- pick("profit", "Hi 20", "Profitability")
  invest  <- pick("invest", "Lo 20", "Investment")
  lowvar  <- pick("variance", "Lo 20", "Low variance")

  prior_r <- read_french(f("prior"), VW_MONTHLY)
  prior_n <- read_french(f("prior"), "^Number of Firms in Portfolios", percent = FALSE)
  prior_s <- read_french(f("prior"), "^Average Firm Size", percent = FALSE)
  stopifnot(identical(prior_r$month, prior_n$month), identical(prior_r$month, prior_s$month))
  mv9  <- prior_n[["PRIOR 9"]] * prior_s[["PRIOR 9"]]
  mv10 <- prior_n[["Hi PRIOR"]] * prior_s[["Hi PRIOR"]]
  momentum <- data.frame(
    month = prior_r$month,
    Momentum = (mv9 * prior_r[["PRIOR 9"]] + mv10 * prior_r[["Hi PRIOR"]]) / (mv9 + mv10)
  )

  out <- Reduce(function(a, b) merge(a, b, by = "month"),
                list(small, value, momentum, profit, invest, lowvar))
  out[order(out$month), ]
}

# The US market (all CRSP stocks, value-weighted): Mkt-RF plus French's RF. RF is used only to rebuild
# the market's total return; cash in the study comes from TB3MS.
build_market <- function(dir = "data-raw") {
  ff <- read_french(file.path(dir, FRENCH_FILES[["factors5"]]))
  data.frame(month = ff$month, Market = ff[["Mkt-RF"]] + ff[["RF"]])
}

# ---- FRED: bonds and cash ---------------------------------------------------------------------------

read_fred <- function(id, dir = "data-raw") {
  d <- utils::read.csv(file.path(dir, paste0(id, ".csv")), stringsAsFactors = FALSE)
  names(d) <- c("date", "value")
  d$value <- suppressWarnings(as.numeric(d$value))
  d <- d[!is.na(d$value), ]
  d$date <- as.Date(d$date)
  d
}

# Month-end yields: the last daily observation in each month (DGS10), or the monthly average (GS10).
month_end_yield <- function(id = "DGS10", dir = "data-raw") {
  d <- read_fred(id, dir)
  d$month <- format(d$date, "%Y-%m")
  d <- d[order(d$date), ]
  last <- !duplicated(d$month, fromLast = TRUE)
  data.frame(month = d$month[last], yield = d$value[last] / 100)
}

# Price of a bond per 100 face with annual coupon rate `coupon`, paid twice a year, at annual yield `y`
# (compounded twice a year), with `years` to maturity. Includes accrued interest (a dirty price).
bond_price <- function(y, coupon, years) {
  n <- ceiling(years * 2 - 1e-9)
  t <- years - (n - seq_len(n)) / 2          # times of the remaining cash flows, in years
  cf <- rep(100 * coupon / 2, n)
  cf[n] <- cf[n] + 100
  sum(cf / (1 + y / 2)^(2 * t))
}

# Modified duration and convexity of a 10-year par bond at yield y (semi-annual coupons).
par_bond_risk <- function(y, years = 10) {
  n <- years * 2
  t <- seq_len(n) / 2
  cf <- rep(100 * y / 2, n)
  cf[n] <- cf[n] + 100
  disc <- (1 + y / 2)^(-2 * t)
  p <- sum(cf * disc)
  dur <- sum(t * cf * disc) / p / (1 + y / 2)
  conv <- sum(cf * disc * t * (t + 0.5)) / p / (1 + y / 2)^2
  c(duration = dur, convexity = conv)
}

# Monthly total return on a 10-year par bond, from yield changes: carry plus duration and convexity.
# Each month a new 10-year par bond is bought at last month's yield y0 and valued at this month's y1:
#   r = y0 / 12 - D * (y1 - y0) + 0.5 * C * (y1 - y0)^2
# `exact = TRUE` reprices the bond instead (coupon y0, 9 years 11 months left, at y1), which also
# captures the small roll-down; it is used as a check.
bond_returns <- function(yields, exact = FALSE) {
  y0 <- head(yields$yield, -1)
  y1 <- tail(yields$yield, -1)
  r <- vapply(seq_along(y0), function(i) {
    if (exact) {
      bond_price(y1[i], y0[i], 10 - 1 / 12) / 100 - 1
    } else {
      risk <- par_bond_risk(y0[i])
      dy <- y1[i] - y0[i]
      y0[i] / 12 - risk[["duration"]] * dy + 0.5 * risk[["convexity"]] * dy^2
    }
  }, numeric(1))
  data.frame(month = tail(yields$month, -1), Bonds = r)
}

# Cash: 3-month Treasury bills. TB3MS is a monthly average on a discount basis. The bill held through
# month t earns the rate known at its start, so month t uses TB3MS for month t-1, converted from a
# discount rate to a holding-period return.
cash_returns <- function(dir = "data-raw") {
  d <- read_fred("TB3MS", dir)
  d$month <- format(d$date, "%Y-%m")
  disc <- d$value / 100
  price <- 1 - disc * 91 / 360
  monthly <- (1 / price)^(1 / 3) - 1
  data.frame(month = tail(d$month, -1), Cash = head(monthly, -1))
}

# ---- Everything together ----------------------------------------------------------------------------

build_inputs <- function(dir = "data-raw", start = "1963-07", end = NULL, bond_series = "DGS10") {
  market  <- build_market(dir)
  factors <- build_factor_portfolios(dir)
  bonds   <- bond_returns(month_end_yield(bond_series, dir))
  cash    <- cash_returns(dir)
  all <- Reduce(function(a, b) merge(a, b, by = "month"), list(market, bonds, cash, factors))
  all <- all[order(all$month), ]
  if (is.null(end)) end <- max(all$month)
  all <- all[all$month >= start & all$month <= end, ]
  if (anyNA(all)) stop("Missing values in the inputs")
  months <- seq(as.Date(paste0(start, "-01")), as.Date(paste0(end, "-01")), by = "month")
  if (!identical(all$month, format(months, "%Y-%m"))) stop("The inputs have gaps")
  rownames(all) <- NULL
  all
}
