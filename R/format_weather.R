#' Format weather data into a blackspot.weather object for use in the blackspot
#'  model
#'
#' Formats raw weather data into an object suitable for use in
#'  \code{\link{run_blackspot}}, ensuring that the supplied weather data meet
#'  the requirements of the model to run.
#'  Internal support for multithreaded operations is provided through
#'   \CRANpkg{future}.  If more than one station is present, the process
#'   can be made faster by using \code{\link[future]{plan}}.
#'
#' @param x a \code{\link{data.frame}} object of weather station data for
#'  formatting.
#' @param YYYY column name or index in `x` that refers to the year when the
#'  weather was logged.
#' @param MM column name or index in `x` that refers to the month (numerical)
#'  when the weather was logged.
#' @param DD column name or index in `x` that refers to the day of month when
#'  the weather was logged.
#' @param hh column name or index in `x` that refers to the hour (24 hour)
#'  when the weather was logged.
#' @param mm column name or index in `x` that refers to the minute when the
#'  weather was logged.
#' @param POSIXct_time column name or index in `x` which contains a `POSIXct`
#'  formatted time, this can be used instead of arguments `YYYY`, `MM`, `DD`,
#'  `hh`, `mm.`
#' @param time_zone time zone (Olsen time zone format) where the weather station
#'  is located. May be in a column or supplied as a character string.
#'  Optional, see also `r`. See details.
#' @param rain column name or index in `x` that refers rainfall in millimetres.
#' @param ws column name or index in `x` that refers wind speed in km / h.
#' @param wd column name or index in `x` that refers wind direction in degrees.
#' @param wd_sd column name or index in `x` that refers wind speed in km / h,
#'  character.  This is only applicable if weather data is already summarised to
#'  hourly increments. See details.
#' @param station column name or index in `x` that refers to the weather station
#'  name or identifier. See details.
#' @param lon column name or index in `x` that refers to weather station
#'  longitude.  See details.
#' @param lat column name or index in `x` that refers to weather station
#'  latitude.  See details.
#' @param r Spatial raster which is intended to be used with this weather data
#'  in \code{\link{run_blackspot}}. Used to fetch time_zone if it is not
#'  supplied in data. Optional, see also `time_zone`.
#' @param lonlat_file a file path to a csv which included station name/id and
#'  longitude and latitude coordinates if they are not supplied in data.
#'  Optional, see also `lon` and `lat`.
#'
#' @details `time_zone`
#' All weather stations must fall within the same time zone.  If the required
#'  stations are located in differing time zones, separate `blackspot.weather`
#'  objects must be created for each time zone.  If a raster object of
#'  previous crops is provided that spans time zones, an error will be emitted.
#'
#' @details `wd_sd`
#' If weather data is provided in hourly increments, a column with the standard
#'  deviation of the wind direction over the hour is required to be provided.
#'  If the weather data are sub-hourly, these data will be calculated and
#'  returned automatically.
#'
#' @details `lon`, `lat` and `lonlat_file`
#' If `x` provides longitude and latitude values for station locations, these
#'  may be specified in the `lon` and `lat` columns.  If these data are not
#'  included, a separate file may be provided that contains the longitude,
#'  latitude and matching station name to provide station locations in the
#'  final `blackspot.weather` object that is created by specifying the
#'  file path to a \acronym{CSV file} using `lonlat_file`.
#' @return A \code{blackspot.weather} object (an extension of
#'  \CRANpkg{data.table}) containing the supplied weather aggregated to each
#'  hour in a suitable format for use with \code{\link{run_blackspot}}
#'  containing the following columns:
#' \tabular{rl}{
#'    **times**: \tab Time in POSIXct format \cr
#'    **rain**: \tab Rainfall in mm \cr
#'    **ws**: \tab Wind speed in km / h \cr
#'    **wd**: \tab Wind direction in compass degrees \cr
#'    **wd_sd**: \tab Wind direction standard deviation in compass degrees \cr
#'    **lon**: \tab Station longitude in decimal degrees \cr
#'    **lat**: \tab Station latitude in decimal degrees \cr
#'    **station**: \tab Unique station identifying name \cr
#'    **YYYY**: \tab Year \cr
#'    **MM**: \tab Month \cr
#'    **DD**: \tab Day \cr
#'    **hh**: \tab Hour \cr
#'    **mm**: \tab Minute \cr
#'               }
#'
#' @examples
#' # Fake weather data files for testing and examples have been included in
#' # \pkg{blackspot}.  The weather data files both are of the same format, so
#' # they will be combined for formatting here.
#'
#' scaddan <-
#'    system.file("extdata", "scaddan_weather.csv", package = "blackspot")
#' naddacs <-
#'    system.file("extdata", "naddacs_weather.csv", package = "blackspot")
#'
#' weather_file_list <- list(scaddan, naddacs)
#' weather_station_data <-
#'    lapply(X = weather_file_list, FUN = read.csv)
#'
#' weather_station_data <- do.call("rbind", weather_station_data)
#'
#' weather <- format_weather(
#'    x = weather_station_data,
#'    POSIXct_time = "Local.Time",
#'    ws = "meanWindSpeeds",
#'    wd_sd = "stdDevWindDirections",
#'    rain = "Rainfall",
#'    wd = "meanWindDirections",
#'    lon = "Station.Longitude",
#'    lat = "Station.Latitude",
#'    station = "StationID",
#'    r = eyre
#' )
#'
#' @export
#'
format_weather <- function(x,
                           YYYY = NULL,
                           MM = NULL,
                           DD = NULL,
                           hh = NULL,
                           mm = NULL,
                           POSIXct_time = NULL,
                           time_zone = NULL,
                           rain,
                           ws,
                           wd,
                           wd_sd,
                           station,
                           lon = NULL,
                           lat = NULL,
                           r = NULL,
                           lonlat_file = NULL) {
   # CRAN Note avoidance
   times <- NULL #nocov

   # Check x class
   if (!is.data.frame(x)) {
      stop(call. = FALSE,
           "`x` must be provided as a `data.frame` object for formatting.")
   }

   # Check for missing inputs before proceeding
   if (is.null(POSIXct_time) &&
       is.null(YYYY) && is.null(MM) && is.null(DD) && is.null(hh)) {
      stop(
         call. = FALSE,
         "You must provide time values either as a `POSIXct_time` column or ",
         "values for `YYYY``, `MM`, `DD` and `hh`."
      )
   }

   if (is.null(lon) && is.null(lat) && is.null(lonlat_file)) {
      stop(
         call. = FALSE,
         "You must provide lonlat values for the weather station(s) either in ",
         "the `lon` & `lat` cols or as a file through `lonlat_file`."
      )
   }

   # Ensure only one object is provided for a time zone (raster or time_zone)
   if (!is.null(r) & !is.null(time_zone)) {
      stop(
         call. = FALSE,
         "Please only provide one way of determining the time zone.\n",
         "Either the time zone as a character string, in a column or ",
         "provide a raster of the area of interest for the time zone to be ",
         "automatically derived from."
      )
   }

   if (is.null(r) & is.null(time_zone)) {
      stop(
         call. = FALSE,
         "Please ensure that either a raster object for the area of interest, ",
         "`r`, or `time_zone` is provided to calculate the time zone for the ",
         "area of interest."
      )
   }

   if (is.null(hh) & is.null(POSIXct_time)) {
      stop(
         call. = FALSE,
         "Can't detect the hour time increment in supplied data (hh), Weather ",
         "data defining hour increments, must be supplied"
      )
   }

   # Assign a `time_zone` based on the raster centroid and check to ensure only
   # one time zone is provided
   if (is.null(time_zone)) {
      time_zone <-
         unique(
            lutz::tz_lookup_coords(
               lat = stats::median(as.vector(raster::extent(r))[3:4]),
               lon = stats::median(as.vector(raster::extent(r))[1:2]),
               method = "accurate"
            )
         )
   }
   if (length(time_zone) > 1) {
      stop(
         call. = FALSE,
         "Separate weather inputs for the blackspot model are required for",
         "each time zone."
      )
   }

   # convert to data.table and start renaming and reformatting -----------------
   x <- data.table(x)

   # check missing args
   # If some input are missing input defaults
   if (missing(mm)) {
      x[, mm := rep(0, .N)]
      mm <- "mm"
   }
   if (missing(wd_sd)) {
      x[, wd_sd := rep(NA, .N)]
      wd_sd <- "wd_sd"
   }

   # import and assign longitude and latitude from a file if provided
   if (!is.null(lonlat_file)) {
      ll_file <- fread(lonlat_file)
      if (any(c("station", "lon", "lat") %notin% colnames(ll_file))) {
         stop(
            "The csv file of weather station coordinates should contain ",
            "column names 'station','lat' and 'lon'."
         )
      }

      r_num <-
         which(as.character(ll_file[, station]) ==
                  as.character(unique(x[, get(station)])))
      x[, lat := rep(ll_file[r_num, lat], nrow(x))]
      x[, lon := rep(ll_file[r_num, lon], nrow(x))]
   }

   # rename the columns if needed
   if (!is.null(YYYY)) {
      data.table::setnames(
         x,
         old = c(YYYY, MM, DD, hh, mm),
         new = c("YYYY", "MM", "DD", "hh", "mm"),
         skip_absent = TRUE
      )
   }

   data.table::setnames(x,
                        old = rain,
                        new = "rain",
                        skip_absent = TRUE)

   data.table::setnames(x,
                        old = ws,
                        new = "ws",
                        skip_absent = TRUE)

   data.table::setnames(x,
                        old = wd,
                        new = "wd",
                        skip_absent = TRUE)

   data.table::setnames(x,
                        old = wd_sd,
                        new = "wd_sd",
                        skip_absent = TRUE)

   data.table::setnames(x,
                        old = station,
                        new = "station",
                        skip_absent = TRUE)

   if (!is.null(lat)) {
      data.table::setnames(x,
                           old = lat,
                           new = "lat",
                           skip_absent = TRUE)
   }

   if (!is.null(lon)) {
      data.table::setnames(x,
                           old = lon,
                           new = "lon",
                           skip_absent = TRUE)
   }

   if (!is.null(POSIXct_time)) {
      data.table::setnames(x,
                           old = POSIXct_time,
                           new = "times",
                           skip_absent = TRUE)
      x[, YYYY := lubridate::year(x[, times])]
      x[, MM := lubridate::month(x[, times])]
      x[, DD := lubridate::day(x[, times])]
      x[, hh :=  lubridate::hour(x[, times])]
      x[, mm := lubridate::minute(x[, times])]

      # Add time_zone if there is no timezone for the station and coerce to
      # POSIXct class
      if (lubridate::tz(x[, times]) == "" ||
          lubridate::tz(x[, times]) == "UTC") {
         x[, times := lubridate::ymd_hms(x[, times],
                                         tz = time_zone,
                                         quiet = TRUE)]
      }
   } else {
      # if POSIX formatted times were not supplied, create a POSIXct
      # formatted column named 'times'
      x[, "times" :=
           lubridate::ymd_hm(paste(x[, YYYY],
                                   "-",
                                   x[, MM],
                                   "-",
                                   x[, DD],
                                   x[, hh],
                                   ":",
                                   x[, mm]),
                             tz = time_zone)]
   }

   if(any(is.na(x[, times]))) {
      stop(
         times,
         "Time records contain NA values or impossible time combinations, ie. 11:60 am, ",
         "Check time inputs"
      )
   }


   # workhorse of this function that does the reformatting
   .do_format <- function(x_dt,
                          YYYY = YYYY,
                          MM = MM,
                          DD = DD,
                          hh = hh,
                          mm = mm,
                          rain = rain,
                          ws = ws,
                          wd = wd,
                          wd_sd = wd_sd,
                          station = station,
                          lon = lon,
                          lat = lat,
                          lonlat_file = lonlat_file,
                          times = times,
                          time_zone = time_zone) {




      # calculate the approximate logging frequency of the weather data
      log_freq <-
         lubridate::int_length(lubridate::as.interval(x_dt[1, times],
                                                      x_dt[.N, times])) /
         (nrow(x_dt) * 60)

      # if the logging frequency is less than 50 minutes aggregate to hourly
      if (log_freq < 50) {
         w_dt_agg <- x_dt[, list(
            times = unique(lubridate::floor_date(times,
                                                 unit = "hours")),
            rain = sum(rain, na.rm = TRUE),
            ws = mean(ws, na.rm = TRUE),
            wd = as.numeric(
               circular::mean.circular(
                  circular::circular(wd,
                                     units = "degrees",
                                     modulo = "2pi"),
                  na.rm = TRUE
               ) # ** see line 310 below
            ),
            wd_sd = as.numeric(
               circular::sd.circular(
                  circular::circular(wd,
                                     units = "degrees",
                                     modulo = "2pi"),
                  na.rm = TRUE
               )
            ) * 57.29578,
            # this is equal to (180 / pi)
            # why multiply by (180 / pi) here but not on mean.circular above **
            lon = unique(lon),
            lat = unique(lat)
         ),
         by = list(YYYY, MM, DD, hh, station)]

         # insert a minute col that was removed during this aggregation
         w_dt_agg[, mm := rep(0, .N)]
         mm <- "mm"

         return(w_dt_agg)

      } else{
         if (all(is.na(x_dt[, wd_sd]))) {
            stop(
               "`format_weather()` was unable to detect or calculate `wd_sd`. ",
               "Please supply a standard deviation of wind direction."
            )
         }
         return(x_dt)
      }
   }

   if (length(unique(x[, station])) > 1) {
      # split data by weather station
      x <- split(x, by = "station")

      x_out <- future.apply::future_lapply(
         X = x,
         FUN = .do_format,
         YYYY = YYYY,
         MM = MM,
         DD = DD,
         hh = hh,
         mm = mm,
         rain = rain,
         ws = ws,
         wd = wd,
         wd_sd = wd_sd,
         station = station,
         lon = lon,
         lat = lat,
         lonlat_file = lonlat_file,
         times = times,
         time_zone = time_zone
      )
      x_out <- rbindlist(x_out)
   } else {
      x_out <- .do_format(
         x_dt = x,
         YYYY = YYYY,
         MM = MM,
         DD = DD,
         hh = hh,
         mm = mm,
         rain = rain,
         ws = ws,
         wd = wd,
         wd_sd = wd_sd,
         station = station,
         lon = lon,
         lat = lat,
         lonlat_file = lonlat_file,
         times = times,
         time_zone = time_zone
      )
   }

   setcolorder(
      x_out,
      c(
         "times",
         "rain",
         "ws",
         "wd",
         "wd_sd",
         "lon",
         "lat",
         "station",
         "YYYY",
         "MM",
         "DD",
         "hh",
         "mm"
      )
   )
   class(x_out) <- union("blackspot.weather", class(x_out))
   return(x_out)
}