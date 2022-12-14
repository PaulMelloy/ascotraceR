#' Simulates the spread of Ascochyta blight in a chickpea field
#'
#' Simulate the spatiotemporal development of Ascochyta blight in a chickpea
#' paddock over a growing season. Both host and pathogen activities are
#' simulated in one square metre cells.
#'
#' @param weather weather data for a representative chickpea paddock for a
#'   complete chickpea growing season for the model's operation.
#' @param paddock_length length of a paddock in metres (y).
#' @param paddock_width width of a paddock in metres (x).
#' @param sowing_date a character string of a date value indicating sowing date
#'   of chickpea seed and the start of the \sQuote{ascotraceR} model. Preferably
#'   in ISO8601 format (YYYY-MM-DD), _e.g._ \dQuote{2020-04-26}. Assumes there
#'   is sufficient soil moisture to induce germination and start the crop
#'   growing season.
#' @param harvest_date a character string of a date value indicating harvest
#'   date of chickpea crop, which is also the last day to run the
#'   \sQuote{ascotraceR} model. Preferably in ISO8601 format (YYYY-MM-DD),
#'   \emph{e.g.}, \dQuote{2020-04-26}.
#' @param seeding_rate indicate the rate at which chickpea seed is sown per
#'   square metre. Defaults to `40`.
#' @param gp_rr refers to rate of increase in chickpea growing points per degree
#'   Celsius per day. Defaults to `0.0065`.
#' @param max_gp_lim maximum number of chickpea growing points (meristems)
#'   allowed per square metre. Defaults to `5000`.
#' @param max_new_gp Maximum number of new chickpea growing points (meristems),
#'   which develop per day, per square metre. Defaults to `350`.
#' @param primary_infection_foci refers to the inoculated coordinates where the
#'   infection starts. Accepted inputs are: `centre`/`center` or `random`
#'   (Default) or a `data.frame` with column names \sQuote{x}, \sQuote{y} and
#'   \sQuote{load}. The `data.frame` inputs inform the model of specific grid
#'   cell/s coordinates where the epidemic should begin. The \sQuote{load}
#'   column is optional and can specify the `primary_inoculum_intensity` for
#'   each coordinate.
#' @param primary_inoculum_intensity Refers to the amount of primary infection
#'   as lesions on chickpea plants at the time of `initial_infection`. On the
#'   date of initial infection in the experiment. The sources of primary
#'   inoculum can be infected seed, volunteer chickpea plants or infested
#'   stubble from the previous seasons. Defaults to `1`.
#' @param latent_period_cdd latent period in cumulative degree days (sum of
#'   daily temperature means) is the period between infection and production of
#'   lesions on susceptible growing points. Defaults to `150`.
#' @param initial_infection a character string of a date value referring to the
#'   initial or primary infection on seedlings, resulting in the production of
#'   infectious growing points.
#' @param time_zone refers to time in Coordinated Universal Time (UTC).
#' @param spores_per_gp_per_wet_hour number of spores produced per infectious
#'   growing point during each wet hour. Also known as the `spore_rate`. Value
#'   is dependent on the susceptibility of the host genotype.
#' @param n_foci Quantifies the number of primary infection foci. The value is
#'   `1` when `primary_infection_foci = "centre"` and can be greater than `1` if
#'   `primary_infection_foci = "random`.
#' @param splash_cauchy_parameter a parameter used in the Cauchy distribution
#'   and describes the median distance spores travel due to rain splashes.
#'   Default to `0.5`.
#' @param wind_cauchy_multiplier a scaling parameter to estimate a Cauchy
#'   distribution which resembles the possible distances a conidium travels due
#'   to wind driven rain. Defaults to `0.015`.
#' @param daily_rain_threshold minimum cumulative rainfall required in a day to
#'   allow hourly spore spread events. See also `hourly_rain_threshold`.
#'   Defaults to `2`.
#' @param hourly_rain_threshold minimum rainfall in an hour to trigger a spore
#'   spread event in the same hour (assuming daily_rain_threshold is already
#'   met). Defaults to `0.1`.
#' @param susceptible_days the number of days for which conidia remain viable on
#'   chickpea after dispersal. Defaults to `2`. Conidia remain viable on the
#'   plant for at least 48 hours after a spread event
#' @param rainfall_multiplier logical values will turn on or off rainfall
#'   multiplier default method. The default method increases the number of
#'   spores spread per growing point if the rainfall in the spore spread event
#'   hour is greater than one. Numeric values will scale the number of spores
#'   spread per growing point against the volume of rainfall in the hour.
#'   Defaults to `FALSE`.
#'
#' @return a nested `list` object where each sub-list contains daily data for
#'   the day `i_day` (the model's iteration day) generated by the model
#'   including: * **paddock**, an 'x' 'y' \CRANpkg{data.table} containing: *
#'   **x**, location of quadrat on x-axis in paddock, * **y**, location of
#'   quadrat on y-axis in paddock, * **new_gp**, new growing points produced in
#'   the last 24 hours, * **susceptible_gp**, susceptible growing points in the
#'   last 24 hours, * **exposed_gp**, exposed growing points in the last 24
#'   hours, * **infectious_gp**, infectious growing points in the last 24 hours,
#'   * **i_day**, model iteration day, * **cumulative daily weather data**, a
#'   \CRANpkg{data.table} containing: * **cdd**, cumulative degree days, *
#'   **cwh**, cumulative wet hours, * **cr**, cumulative rainfall in mm, *
#'   **gp_standard**, standard growing points assuming growth is not impeded by
#'   infection, * **infected_coords**, a \CRANpkg{data.table} of only infectious
#'   growing point coordinates, * **new_infections**, a \CRANpkg{data.table} of
#'   newly infected growing points, * **exposed_gps**, a \CRANpkg{data.table} of
#'   exposed growing points in the latent period phase of infection.
#'
#' @seealso [tidy_trace()], [summarise_trace()]
#'
#' @examplesIf interactive()
#' # First weather data needs to be imported and formatted with `format_weather`
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
#' # Now the `trace_asco` function can be run to simulate disease spread
#' traced <- trace_asco(
#'   weather = weather_dat,
#'   paddock_length = 100,
#'   paddock_width = 100,
#'   initial_infection = "1998-06-10",
#'   sowing_date = "1998-06-09",
#'   harvest_date = "1998-06-30",
#'   time_zone = "Australia/Perth",
#'   gp_rr = 0.0065,
#'   primary_inoculum_intensity = 40,
#'   spores_per_gp_per_wet_hour = 0.22,
#'   primary_infection_foci = "centre")
#'
#' traced[[23]] # extracts the model output for day 23
#'
#' @export
#'
trace_asco <- function(weather,
                       paddock_length,
                       paddock_width,
                       sowing_date,
                       harvest_date,
                       initial_infection,
                       seeding_rate = 40,
                       gp_rr = 0.0065,
                       max_gp_lim = 5000,
                       max_new_gp = 350,
                       latent_period_cdd = 150,
                       time_zone = "UTC",
                       primary_infection_foci = "random",
                       primary_inoculum_intensity = 1,
                       n_foci = 1,
                       spores_per_gp_per_wet_hour = 0.22,
                       splash_cauchy_parameter = 0.5,
                       wind_cauchy_multiplier = 0.015,
                       daily_rain_threshold = 2,
                       hourly_rain_threshold = 0.1,
                       susceptible_days = 2,
                       rainfall_multiplier = FALSE){


  x <- y <- load <- susceptible_gp <- NULL

  if (!"asco.weather" %in% class(weather)) {
    stop(
      call. = FALSE,
      "'weather' must be class \"asco.weather\"",
      "Please use `format_weather()` to properly format the weather data.")
  }

  if (primary_inoculum_intensity <= 0) {
    stop(
      call. = FALSE,
      "`primary_inoculum_intensity` has to be > 0 for the model to simulate",
      " disease spread"
    )
  }

  # convert times to POSIXct -----------------------------------------------
  initial_infection <-
    lubridate::ymd(.vali_date(initial_infection), tz = time_zone) +
    lubridate::dhours(0)

  sowing_date <-
    lubridate::ymd(.vali_date(sowing_date), tz = time_zone) +
    lubridate::dhours(0)

  harvest_date <-
    lubridate::ymd(.vali_date(harvest_date), tz = time_zone) +
    lubridate::dhours(23)

  # check epidemic start is after sowing date
  if (initial_infection <= sowing_date) {
    stop(call. = FALSE,
      "The `initial_infection` occurs on or before `sowing_date`. ",
      "Please use an `initial_infection` date which occurs after `crop_sowing`."
    )
  }

  # makePaddock equivalent ------
  paddock <- CJ(x = 1:paddock_width,
                y = 1:paddock_length)

  # sample a paddock location randomly if a starting foci is not given
  if ("data.frame" %in% class(primary_infection_foci) == FALSE) {
    if (class(primary_infection_foci) == "character") {
      if (primary_infection_foci == "random") {
        primary_infection_foci <-
          paddock[sample(seq_len(nrow(paddock)),
                         size = n_foci,
                         replace = TRUE),
                  c("x", "y")]

      } else {
        if (primary_infection_foci == "centre" ||
            primary_infection_foci == "center") {
          primary_infection_foci <-
            paddock[x == as.integer(round(paddock_width / 2)) &
                      y == as.integer(round(paddock_length / 2)),
                    c("x", "y")]
        } else{
          stop(call. = FALSE,
               "`primary_infection_foci` input not recognised")
        }
      }
    } else {
      if (is.vector(primary_infection_foci)) {
        if (length(primary_infection_foci) != 2 |
            is.numeric(primary_infection_foci) == FALSE) {
          stop(
            call. = FALSE,
            "`primary_infection_foci` should be supplied as a numeric vector ",
            "of length two"
          )
        }
        primary_infection_foci <-
          as.data.table(as.list(primary_infection_foci))

        setnames(x = primary_infection_foci,
                 old = c("V1", "V2"),
                 new = c("x", "y"),
                 skip_absent = TRUE)
      }
    }
  } else{
    if (is.data.table(primary_infection_foci) == FALSE &
        is.data.frame(primary_infection_foci)) {
      setDT(primary_infection_foci)
      if (all(c("x", "y") %in% colnames(primary_infection_foci)) == FALSE) {
        stop(
          call. = FALSE,
          "The `primary_infection_foci` data.frame should contain colnames ",
          "'x' and 'y'"
        )
      }
    }
  }


  # get rownumbers for paddock data.table that need to be set as infected
  infected_rows <- which_paddock_row(paddock = paddock,
                                     query = primary_infection_foci)
  if ("load" %in% colnames(primary_infection_foci) == FALSE) {
    primary_infection_foci[, load := primary_inoculum_intensity]
  } else{
    if (all(colnames(primary_infection_foci) %in% c("x", "y"))) {
      stop(call. = FALSE,
           "Colnames for `primary_infection_foci` are not 'x', 'y' & 'load'.")
    }
  }


  # define paddock variables at time 1
  # need to update so can assign a data.table of things primary infection foci!!
  paddock[, c(
    "new_gp", # Change in the number of growing points since last iteration
    "susceptible_gp",
    "exposed_gp",
    "infectious_gp" # replacing InfectiveElementList
  ) :=
    list(
      seeding_rate,
      seeding_rate,
      0,
      0
    )]

  # calculate additional parameters
  # Paul's interpretation of this calculation
  # For a particular spread event (point in time), in space of all growing
  # points the maximum number of susceptible growing are 15000/350 = 42.86
  # The highest probability of a spore landing on the area of these 42
  # susceptible growing points is 0.00006 * 42.86. However, as the crop is
  # always changing, we need to calculate the actual probability of interception
  # depending on the density of the crop canopy for that given time. See the
  # function `interception_probability()`
  spore_interception_parameter <- 0.00006 * (max_gp_lim/max_new_gp)

  # define max_gp
  max_gp <- max_gp_lim * (1 - exp(-0.138629 * seeding_rate))


  # Notes: as area is 1m x 1m many computation in the mathematica
  #  code are redundant because they are being multiplied by 1.
  #  I will reduce the number of objects containing the same value,
  #  Below is a list of Mathematica values consolidated into 1
  #
  # refUninfectiveGPs <- minGrowingPoints <- seeding_rate

  # Create a clean daily values list with no infection in paddocks
  daily_vals_list <- list(
    list(
      paddock = paddock, # data.table each row is a 1 x 1m coordinate
      i_date = sowing_date,  # day of the simulation (iterator)
      i_day = 1,
      day = yday(sowing_date),    # day of the year
      cdd = 0,    # cumulative degree days
      cwh = 0,    # cumulative wet hours
      cr = 0,     # cumulative rainfall
      gp_standard = seeding_rate,     # standard number of growing points for 1m^2 if not inhibited by infection (refUninfectiveGrowingPoints)
      new_gp = seeding_rate,    # new number of growing points for current iteration (refNewGrowingPoints)
      infected_coords = data.table(x = numeric(),
                                   y = numeric()),  # data.table
      exposed_gps =  data.table(x = numeric(),
                                   y = numeric(),
                                   spores_per_packet = numeric(),
                                   cdd_at_infection = numeric()) # data.table of infected growing points still in latent period and not sporulating (exposed_gp)
    )
  )

  time_increments <- seq(sowing_date,
                         harvest_date,
                         by = "days")

  daily_vals_list <- rep(daily_vals_list,
                         length(time_increments) + 1)

  for (i in seq_len(length(time_increments))) {
    # update time values for iteration of loop
    daily_vals_list[[i]][["i_date"]] <- time_increments[i]
    daily_vals_list[[i]][["i_day"]] <- i
    daily_vals_list[[i]][["day"]] <- yday(time_increments[i])

    # currently working on one_day
    daily_vals_list[[i + 1]] <- one_day(
      i_date = time_increments[i],
      daily_vals = daily_vals_list[[i]],
      weather_dat = weather,
      gp_rr = gp_rr,
      max_gp = max_gp,
      spore_interception_parameter = spore_interception_parameter,
      spores_per_gp_per_wet_hour = spores_per_gp_per_wet_hour,
      splash_cauchy_parameter = splash_cauchy_parameter,
      wind_cauchy_multiplier = wind_cauchy_multiplier,
      daily_rain_threshold = daily_rain_threshold,
      hourly_rain_threshold = hourly_rain_threshold,
      susceptible_days = susceptible_days,
      rainfall_multiplier = rainfall_multiplier
    )

    # When the time of initial infection occurs, infect the paddock coordinates
    if (initial_infection == time_increments[i]) {

      # if primary_inoculum_intensity exceeds the number of growing points send
      #  warning
      if (primary_inoculum_intensity > daily_vals_list[[i]][["gp_standard"]]) {
        warning(
          call. = FALSE,
          "`primary_inoculum_intensity` exceeds the number of growing points ",
          "at time of infection `growing_points`: ",
          daily_vals_list[[i]][["gp_standard"]],
          "\nThis may cause an overestimation of disease spread"
        )
      }

      # update the remaining increments with the primary infected coordinates
      daily_vals_list[i:length(daily_vals_list)] <-
        lapply(daily_vals_list[i:length(daily_vals_list)], function(dl) {
          # Infecting paddock
          pad1 <- copy(dl[["paddock"]])

          pad1[infected_rows,
               c("susceptible_gp",
                 "infectious_gp") :=
                 list(
                   fifelse(
                     test = primary_infection_foci[, load] > susceptible_gp,
                     yes = susceptible_gp,
                     no = susceptible_gp - primary_infection_foci[, load]
                   ),
                   primary_infection_foci[, load]
                 )]
          dl[["paddock"]] <- pad1

          # Edit infected_coordinates data.table
          dl[["infected_coords"]] <-
            primary_infection_foci[, c("x", "y")]
          return(dl)
        })
    }
  }

  daily_vals_list[[length(daily_vals_list)]][["i_date"]] <-
    daily_vals_list[[length(daily_vals_list)]][["i_date"]] + lubridate::ddays(1)
  daily_vals_list[[length(daily_vals_list)]][["i_day"]] <-
    length(daily_vals_list)
  daily_vals_list[[length(daily_vals_list)]][["day"]] <-
    yday(daily_vals_list[[length(daily_vals_list)]][["i_date"]])

  return(daily_vals_list)
}

#' Check date inputs for validity
#'
#' @param x an object for checking
#'
#' @return a POSIXct date-time object
#' @keywords internal
#' @noRd
#'
.vali_date <- function(x) {
  tryCatch(
    # try to parse the date format using lubridate
    x <- lubridate::parse_date_time(x,
                                    c(
                                      "Ymd",
                                      "dmY",
                                      "mdY",
                                      "BdY",
                                      "Bdy",
                                      "bdY",
                                      "bdy"
                                    )),
    warning = function(w) {
      stop(call. = FALSE,
           "`",
           x,
           "` is not a valid entry for date.\n",
           "Please enter as `YYYY-MM-DD`.\n")
    }
  )
  return(x)
}
