
library(lubridate)


# Prep Time Data ----------------------------------------------------------




class_tm1 <- data.frame(start =  lubridate::dmy_hms("10/06/2021 10:00:00 AM"),
                        end = lubridate::dmy_hms("10/06/2021 11:00:00 AM"),
                        join = lubridate::dmy_hms("10/06/2021 09:00:00 AM"),
                        leave = lubridate::dmy_hms("10/06/2021 10:30:00 AM"))

class_tm2 <- data.frame(
  start = rep("10/06/2021 10:00:00 AM", 5),
  end = rep("10/06/2021 12:00:00 PM", 5),
  join = paste(
    "10/06/2021",
    c("09:00:00", "10:30:00", "11:00:00", "08:00:00", "13:00:00"),
    "AM"
  ),
  leave = paste(
    "10/06/2021",
    c("11:00:00", "11:00:00", "13:00:00", "09:00:00", "14:00:00"),
    "AM"
  )
) %>%
  purrr::modify(lubridate::dmy_hms)


# Helper: parse_time_flex -------------------------------------------------

test_that("parse_time_flex() works",{

  expect_equal(parse_time_flex("12:11:10"), hours(12) + minutes(11) + seconds(10))
  expect_equal(parse_time_flex("12:11"), hours(12) + minutes(11))
  ## Error
  expect_error(parse_time_flex("12"))

})

# Test: before class time -------------------------------------------------


test_that("test get_before_class_time() works",{

  before2 <- get_before_class_time(start = class_tm1$start, join = class_tm1$join,
                                   leave = class_tm1$leave)

  expect_s4_class(before2, "Period")
  expect_identical(before2, hours(1))

})

# Test: after class time -------------------------------------------------


test_that("test get_after_class_time()",{

  after2 <- get_after_class_time(end = class_tm1$end, join = class_tm1$join,
                                 leave = class_tm1$leave)
  expect_s4_class(after2, "Period")

  expect_identical(after2, as.period(NA))
})


# Test: during class time -------------------------------------------------



test_that("test get_during_class_time()",{

  during1 <- get_during_class_time(start = class_tm1$start, end = class_tm1$end,
                                   join = class_tm1$join, leave = class_tm1$leave)
  during2 <- get_during_class_time(start = class_tm2$start, end = class_tm2$end,
                                   join = class_tm2$join, leave = class_tm2$leave)

  ## Check Class
  expect_s4_class(during1, "Period")
  expect_s4_class(during2, "Period")
  ## Check Value
  expect_identical(during1, minutes(30))
  expect_identical(during2,
                   c(hours(1), minutes(30), hours(1), as.period(NA), as.period(NA))
  )

})
