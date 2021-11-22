
library(lubridate)

# Test: Late Time ---------------------------------------------------------


test_that("test get_late_time()",{

  t_time1 <- seq(dmy_hms("10/06/2021 10:00:00 AM"),
                 to = dmy_hms("10/06/2021 11:00:00 AM"), length.out = 5)

  late_time1 <- get_late_time(t_time1, dmy_hms("10/06/2021 10:30:00 AM"))

  # Test Class
  expect_s4_class(late_time1, "Period")
  # Check Values (Exactly ontime will not marked as late)
  expect_equal(late_time1, c(as.period(rep(NA,3)), minutes(15), minutes(30)))

})
