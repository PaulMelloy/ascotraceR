#context("makes some infected growing points infective or a source of innoculum")
load_all()
newly_infected_list <- fread(file = "tests/testthat/data-newly_infected_list.csv")
#newly_infected_list <- fread(file = "data-newly_infected_list.csv")

# create data and parameters
seeding_rate <- 40
paddock <- as.data.table(expand.grid(x = 1:100,
                                     y = 1:100))
paddock[, c("new_gp",
            "noninfected_gp",
            "infected_gp",
            "sporilating_gp",
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
  # i_date = sowing_date,  # day of the simulation (iterator)
  i_day = 1,
  # day = lubridate::yday(sowing_date),    # day of the year
  cdd = 50,    # cumulative degree days
  cwh = 0,    # cumulative wet hours
  cr = 0,     # cumulative rainfall
  gp_standard = seeding_rate,     # standard number of growing points for 1m^2 if not inhibited by infection (refUninfectiveGrowingPoints)
  new_gp = seeding_rate,    # new number of growing points for current iteration (refNewGrowingPoints)
  newly_infected = data.table(x = sample(paddock[,x],size = 5),
                              y = sample(paddock[,x],size = 5),
                              spores_per_packet = 1:5,
                              cdd_at_infection = 20)
)



test1 <- make_some_infective(daily_vals = daily_values,
                             latent_period = 200)

test_that("test1 returns daily_values list with no changes", {
  expect_is(test1, "list")
  expect_length(test1, 8)
  expect_is(test1[["paddock"]], "data.table")
  expect_is(test1[["newly_infected"]], "data.table")
  expect_equal(names(test1),
               c(
                 "paddock",
                 "i_day",
                 "cdd",
                 "cwh",
                 "cr",
                 "gp_standard",
                 "new_gp",
                 "newly_infected"
               ))

  expect_equal(test1[["paddock"]][, noninfected_gp], daily_values[["paddock"]][, noninfected_gp])
  expect_equal(test1[["paddock"]][, sporilating_gp], daily_values[["paddock"]][, sporilating_gp])
  expect_equal(test1[["newly_infected"]], daily_values[["newly_infected"]])
  expect_false(any(is.na(test1[["paddock"]])))
})

daily_values[["cdd"]] <- 250

test2 <- make_some_infective(daily_vals = daily_values,
                             latent_period = 200)

expect_equal(test2[["paddock"]][, sum(sporilating_gp)], # output
             daily_values[["paddock"]][, sum(sporilating_gp)]) # input

test_that("test2 returns changes now latent_period has elapsed",{
  expect_is(test2, "list")
  expect_length(test2, 8)
  expect_is(test2[["paddock"]], "data.table")
  expect_equal(names(test2),
               c(
                 "paddock",
                 "i_day",
                 "cdd",
                 "cwh",
                 "cr",
                 "gp_standard",
                 "new_gp",
                 "newly_infected"
               ))
  expect_equal(test2[["paddock"]][, sum(sporilating_gp)], # output
               daily_values[["paddock"]][, sum(sporilating_gp)]) # input
  expect_equal(nrow(daily_values[["newly_infected"]]) - nrow(test2[["newly_infected"]]),
               nrow(daily_values[["newly_infected"]]))
  expect_silent(test3 <- make_some_infective(daily_vals = daily_values))
  expect_false(any(is.na(test2[["paddock"]])))

  expect_equal(test2[["paddock"]][, sum(noninfected_gp)], 399845)

})
#
# # sp2 <- fread("tests/testthat/data-newly_infected_list.csv")
# sp2 <- fread("data-newly_infected_list.csv")
#
# test3 <- make_some_infective(spore_packet = sp2,
#                daily_vals = daily_values)
#
# test_that("test3 long dt input returns a list with changes to paddock", {
#   expect_is(test3, "list")
#   expect_length(test3, 7)
#   expect_is(test3[["paddock"]], "data.table")
#   expect_equal(names(test3),
#                c(
#                  "paddock",
#                  "i_day",
#                  "cdd",
#                  "cwh",
#                  "cr",
#                  "gp_standard",
#                  "new_gp"
#                ))
#   expect_equal(test3[["paddock"]][sporilating_gp > 0, .N ], 37)
#   expect_equal(test3[["paddock"]][sporilating_gp > 0, max(sporilating_gp) ], 8)
#   expect_true(all(test3[["paddock"]][, sporilating_gp + noninfected_gp] == 40))
#   expect_is(test3[["paddock"]][, noninfected_gp], "numeric")
#   expect_is(test3[["paddock"]][, sporilating_gp], "numeric")
#   expect_false(any(is.na(test3[["paddock"]])))
# })