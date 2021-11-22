
# Class Session -----------------------------------------------------------



### Check Class
test_that("test class_session() class",{

  pp_cal_session <- class_session(pp_cal_cleaned,
                                  class_start = "10:00:00", class_end = "12:00:00"
  )
  expect_s3_class(pp_cal_session, "zoom_class") # Child Class
  expect_s3_class(pp_cal_session, "zoom_participants") # Parent class
  expect_s3_class(pp_cal_session, "data.frame") # DF

})
### Check Attributes
test_that("test class_session() attribute",{

  pp_cal_session <- class_session(pp_cal_cleaned,
                                  class_start = "10:00:00", class_end = "12:00:00"
  )
  attr_mt_nm <- c("Meeting_ID", "Topic", "Start_Time", "End_Time", "Email", "Duration_Minute", "Participants")

  attr_cl_nm <- c("class_start", "class_end", "late_cutoff")

  expect_named(meeting_overview(pp_cal_session), attr_mt_nm)

  expect_named(class_overview(pp_cal_session), attr_cl_nm)

})


# Class Students -----------------------------------------------------------


### Check Class
test_that("test class_students() class",{

  pp_cal_students <- class_students(pp_cal_cleaned,
                                  class_start = "10:00:00", class_end = "12:00:00",
                                  late_cutoff = "10:15:00"
  )
  expect_s3_class(pp_cal_students, "zoom_class") # Child Class
  expect_s3_class(pp_cal_students, "zoom_participants") # Parent class
  expect_s3_class(pp_cal_students, "data.frame") # DF

})


### Check Attributes
test_that("test class_students() attribute",{

  pp_cal_students <- class_students(pp_cal_cleaned,
                                  class_start = "10:00:00", class_end = "12:00:00",
                                  late_cutoff = "10:15:00"
  )
  attr_mt_nm <- c("Meeting_ID", "Topic", "Start_Time", "End_Time", "Email", "Duration_Minute", "Participants")

  attr_cl_nm <- c("class_start", "class_end", "late_cutoff")

  expect_named(meeting_overview(pp_cal_students), attr_mt_nm)

  expect_named(class_overview(pp_cal_students), attr_cl_nm)

})

