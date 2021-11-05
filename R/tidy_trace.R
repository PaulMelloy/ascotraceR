#' Tidy up a trace_asco output nested list
#'
#' Creates a tidy \CRANpkg{data.table} from the output of [trace_asco()].
#'
#' @param trace a nested list output from [trace_asco()]
#'
#' @return A tidy \CRANpkg{data.table} of [trace_asco()] output.
#' @seealso [summarise_trace()], [trace_asco()]
#' @export
#'
#' @examples
#' Newmarracarra <-
#'    read.csv(system.file("extdata",
#'             "1998_Newmarracarra_weather_table.csv", package = "ascotraceR"))
#' station_data <-
#'    system.file("extdata", "stat_dat.csv", package = "ascotraceR")
#'
#' weather_dat <- format_weather(
#'    x = Newmarracarra,
#'    POSIXct_time = "Local.Time",
#'    temp = "mean_daily_temp",
#'    ws = "ws",
#'    wd_sd = "wd_sd",
#'    rain = "rain_mm",
#'    wd = "wd",
#'    station = "Location",
#'    time_zone = "Australia/Perth",
#'    lonlat_file = station_data)
#'
#' traced <- trace_asco(
#'   weather = weather_dat,
#'   paddock_length = 100,
#'   paddock_width = 100,
#'   initial_infection = "1998-06-10",
#'   sowing_date = as.POSIXct("1998-06-09"),
#'   harvest_date = as.POSIXct("1998-06-09") + lubridate::ddays(100),
#'   time_zone = "Australia/Perth",
#'   primary_infection_foci = "centre")
#'
#' tidied <- tidy_trace(traced)
#'
#' # take a look at the infectious growing points on day 102
#' ggplot(data = filter(tidied, i_day == 102),
#'        aes(x = x, y = y, fill = infectious_gp)) +
#'   geom_tile()
tidy_trace <- function(trace) {

  i_date <- t(as.data.table(lapply(X = trace, `[[`, 2)))
  sub_trace <- setDT(purrr::map_df(trace, ~ unlist(.[3:9])))
  sub_trace[, i_date := lubridate::as_date(i_date)]
  sub_trace[, new_gp := NULL] # this is a duplicated value
  setkey(sub_trace, i_day)

  paddock <- rbindlist(lapply(trace, `[[`, 1),
                       idcol = "i_day")
  setkey(paddock, i_day)

  tidy_trace_dt <- merge(x = paddock, y = sub_trace, all.x = TRUE)

  setcolorder(tidy_trace_dt, c("i_day", "i_date", "day"))
  return(tidy_trace_dt)
}