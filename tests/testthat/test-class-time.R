
library(lubridate)



# Test: before class time -------------------------------------------------


test_that("test-get_before_class_time",{

  before1 <- get_before_class_time(start = c(10, 10), join = c(9, 11), leave = c(11, 12))
  before2 <- get_before_class_time(start = class_tm1$start, join = class_tm1$join,
                                   leave = class_tm1$leave)
  beforeNA <- get_before_class_time(start = c(NA, 10, 10), join = c(9, 11, 9),
                                    leave = c(11, 12, 9.5))

  expect_s4_class(before1, "Period")
  expect_s4_class(before2, "Period")

  expect_identical(before1, c(seconds(1), as.period(NA)))
  expect_identical(before2, hours(1))
  expect_identical(beforeNA, c(as.period(NA), as.period(NA), seconds(0.5)))

})

# Test: after class time -------------------------------------------------


test_that("test-get_after_class_time",{

  after1 <- get_after_class_time(end = c(12,12), join = c(10,10), leave = c(11,13))
  after2 <- get_after_class_time(end = class_tm1$end, join = class_tm1$join,
                                 leave = class_tm1$leave)
  afterNA <- get_after_class_time(end = c(12,12, 12), join = c(10,10, 13), leave = c(14,NA, 14))

  expect_s4_class(after1, "Period")
  expect_s4_class(after2, "Period")

  expect_identical(after1, c(as.period(NA), seconds(1)))
  expect_identical(after2, as.period(NA))
  expect_identical(afterNA, c(seconds(2), as.period(NA), seconds(1)))

})


# Test: during class time -------------------------------------------------


test_that("test get_during_class_time()",{


  ## First 3 In range, last 2 Not In Range
  class_tm2 <- data.frame(start = rep(10, 5), end = rep(12, 5),
                          join = c(9, 10.5, 11, 8, 13), leave = c(11, 11, 13, 9, 14))


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
                   c(seconds(1), seconds(0.5), seconds(1), as.period(NA), as.period(NA))
  )
  ## Check NA Value
  expect_identical(get_during_class_time(NA,1,2,3), as.period(NA))

})
