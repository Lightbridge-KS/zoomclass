# Read and Processing --------------------------------------------------------------

path_pp_heroes_full <- zoomclass_example("participants_heroes_full.csv")

pp_heroes_full <- zoomclass::read_participants(path_pp_heroes_full)

pp_heroes_full_session <- class_session(pp_heroes_full,
                                        class_start = "10:00:00", class_end = "12:00:00")

pp_heroes_full_students <- class_students(pp_heroes_full,
                                  class_start = "10:00:00", class_end = "12:00:00",
                                  late_cutoff = "10:15:00")


# Class Session -----------------------------------------------------------


### Check Class

test_that("test class_session() class",{

  expect_s3_class(pp_heroes_full_session, c("zoom_class", "zoom_participants", "data.frame"))

})


### Check Attributes


test_that("test class_session() `meeting_overview` attribute",{

  attr_mt_nm <- c("Meeting_ID", "Topic", "Start_Time", "End_Time", "Email", "Duration_Minute", "Participants")
  expect_named(meeting_overview(pp_heroes_full_session), attr_mt_nm)

})


test_that("test class_session() `class_overview` attribute",{

  attr_cl_nm <- c("class_start", "class_end", "late_cutoff")
  expect_named(class_overview(pp_heroes_full_session), attr_cl_nm)

})



# Class Students -----------------------------------------------------------


### Check Class
test_that("test class_students() class",{

  expect_s3_class(pp_heroes_full_students, c("zoom_class", "zoom_participants", "data.frame"))

})


### Check Attributes

test_that("test class_students() `meeting_overview` attribute",{

  attr_mt_nm <- c("Meeting_ID", "Topic", "Start_Time", "End_Time", "Email", "Duration_Minute", "Participants")

  expect_named(meeting_overview(pp_heroes_full_students), attr_mt_nm)


})

test_that("test class_students() `class_overview` attribute",{

  attr_cl_nm <- c("class_start", "class_end", "late_cutoff")

  expect_named(class_overview(pp_heroes_full_students), attr_cl_nm)

})


