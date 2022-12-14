# test_data.rda contains lat/lon and date values for the following tests
load(test_path("newly_infected_list.rda"))

# create data and parameters
seeding_rate <- 40
paddock <- CJ(x = 1:100,
              y = 1:100)
paddock[, c("new_gp",
            "susceptible_gp",
            "exposed_gp",
            "infectious_gp",
            "cdd_at_infection") :=
          list(
            seeding_rate,
            fifelse(x >= 53 &
                      x <= 57 &
                      y >= 53 &
                      y <= 57, seeding_rate - 5,
                    seeding_rate),
            0,
            fifelse(x >= 53 &
                      x <= 57 &
                      y >= 53 &
                      y <= 57, 5,
                    0),
            0
          )]

set.seed(666)

daily_values <- list(
  paddock = paddock,
  i_day = 1,
  cdd = 50,
  # cumulative degree days
  cwh = 0,
  # cumulative wet hours
  cr = 0,
  # cumulative rainfall
  gp_standard = seeding_rate,
  # standard number of growing points for 1m^2 if not inhibited by infection
  # (refUninfectiveGrowingPoints)
  new_gp = seeding_rate,
  # new number of growing points for current iteration (refNewGrowingPoints)
  exposed_gps = data.table(
    x = sample(paddock[, x], size = 5),
    y = sample(paddock[, x], size = 5),
    spores_per_packet = 1:5,
    cdd_at_infection = 20
  )
)



test1 <- make_some_infective(daily_vals = daily_values,
                             latent_period = 200)

test_that("test1 returns daily_values list with no changes", {
  expect_is(test1, "list")
  expect_length(test1, 8)
  expect_s3_class(test1[["paddock"]], "data.table")
  expect_s3_class(test1[["exposed_gps"]], "data.table")
  expect_equal(
    names(test1),
    c(
      "paddock",
      "i_day",
      "cdd",
      "cwh",
      "cr",
      "gp_standard",
      "new_gp",
      "exposed_gps"
    )
  )

  expect_equal(test1[["paddock"]][, susceptible_gp],
               daily_values[["paddock"]][, susceptible_gp])
  expect_equal(test1[["paddock"]][, infectious_gp],
               daily_values[["paddock"]][, infectious_gp])
  expect_equal(test1[["exposed_gps"]], daily_values[["exposed_gps"]])
  expect_false(any(is.na(test1[["paddock"]])))
})

daily_values[["cdd"]] <- 250

test2 <- make_some_infective(daily_vals = daily_values,
                             latent_period = 200)

expect_equal(test2[["paddock"]][, sum(infectious_gp)], # output
             daily_values[["paddock"]][, sum(infectious_gp)]) # input

test_that("test2 returns changes now latent_period has elapsed", {
  expect_is(test2, "list")
  expect_length(test2, 8)
  expect_s3_class(test2[["paddock"]], "data.table")
  expect_equal(
    names(test2),
    c(
      "paddock",
      "i_day",
      "cdd",
      "cwh",
      "cr",
      "gp_standard",
      "new_gp",
      "exposed_gps"
    )
  )
  expect_equal(test2[["paddock"]][, sum(infectious_gp)], # output
               daily_values[["paddock"]][, sum(infectious_gp)]) # input
  expect_equal(nrow(daily_values[["exposed_gps"]]) -
                 nrow(test2[["exposed_gps"]]),
               nrow(daily_values[["exposed_gps"]]))
  expect_silent(test3 <-
                  make_some_infective(daily_vals = daily_values))
  expect_false(any(is.na(test2[["paddock"]])))

  expect_equal(test2[["paddock"]][, sum(susceptible_gp)], 399845)

})
