# Downloads the raw data into data-raw/ (git-ignored). Nothing here is committed: the repo publishes
# only derived results.
#
# Sources:
# - Kenneth R. French Data Library (Fama and French factors and portfolios).
# - FRED, Federal Reserve Bank of St. Louis: DGS10, GS10 and TB3MS, from the Federal Reserve Board's H.15
#   release. Read from FRED's public CSV links, not its API.

FRENCH_BASE <- "https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/"

FRENCH_FILES <- c(
  factors5  = "F-F_Research_Data_5_Factors_2x3_CSV.zip",
  momentum  = "F-F_Momentum_Factor_CSV.zip",
  size      = "Portfolios_Formed_on_ME_CSV.zip",
  value     = "Portfolios_Formed_on_BE-ME_CSV.zip",
  profit    = "Portfolios_Formed_on_OP_CSV.zip",
  invest    = "Portfolios_Formed_on_INV_CSV.zip",
  prior     = "10_Portfolios_Prior_12_2_CSV.zip",
  variance  = "Portfolios_Formed_on_VAR_CSV.zip"
)

FRED_SERIES <- c("DGS10", "GS10", "TB3MS")

download_all <- function(dir = "data-raw", refresh = FALSE) {
  dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  log <- list()
  for (key in names(FRENCH_FILES)) {
    dest <- file.path(dir, FRENCH_FILES[[key]])
    if (refresh || !file.exists(dest)) {
      fetch(paste0(FRENCH_BASE, FRENCH_FILES[[key]]), dest)
    }
    log[[key]] <- dest
  }
  for (id in FRED_SERIES) {
    dest <- file.path(dir, paste0(id, ".csv"))
    if (refresh || !file.exists(dest)) {
      fetch(paste0("https://fred.stlouisfed.org/graph/fredgraph.csv?id=", id), dest)
    }
    log[[id]] <- dest
  }
  invisible(log)
}

fetch <- function(url, dest) {
  message("Downloading ", url)
  status <- utils::download.file(url, dest, mode = "wb", quiet = TRUE)
  if (status != 0 || !file.exists(dest) || file.size(dest) == 0) stop("Download failed: ", url)
}
