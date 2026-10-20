# Reruns the whole study from a clean clone:
#   Rscript run.R            # uses data-raw/ if the downloads are already there
#   Rscript run.R --refresh  # downloads everything again first
#
# Steps: download the data, build monthly returns, run the checks, run the backtests and sensitivity
# runs, then write the tables (output/tables), the chart data for the website (output/site) and rough
# charts (output/figures).

args <- commandArgs(trailingOnly = TRUE)
for (f in list.files("R", pattern = "\\.R$", full.names = TRUE)) source(f)

# The last month in the study. The French library adds a month at a time and occasionally revises its
# history, so the end is pinned to keep reruns comparable. Move it forward deliberately.
END <- "2026-08"

download_all(refresh = "--refresh" %in% args)

inputs <- build_inputs(end = END, bond_series = BASELINE$bond_series)
source("tests/checks.R")
run_checks(inputs)

settings <- BASELINE
part1 <- run_strategies(inputs, part1_strategies(), settings)
part2 <- run_strategies(inputs, part2_strategies(), settings)

periods <- rate_periods(month_end_yield(BASELINE$bond_series), BASELINE$start, END)
falls <- market_falls(part1[["Stocks"]])

sensitivity <- do.call(rbind, lapply(names(SENSITIVITIES), function(name) {
  s <- modifyList(BASELINE, SENSITIVITIES[[name]])
  inp <- if (s$bond_series == BASELINE$bond_series) inputs else build_inputs(end = END, bond_series = s$bond_series)
  res <- c(run_strategies(inp, part1_strategies(), s), run_strategies(inp, part2_strategies(), s)[-1])
  cbind(run = name, summary_table(res))
}))

write_outputs(inputs, part1, part2, periods, falls, sensitivity, settings, END)
message("Done. Results are in output/.")
