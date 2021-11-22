

# Read Participant --------------------------------------------------------



## Still Has warning
test_that("read_participants() still has warning",{


  pp_cal_cleaned <- expect_warning(read_participants(paths.testdata$pp_cal),
                                   "One or more parsing issues")
  pp_mm2_cleaned <- expect_warning(read_participants(paths.testdata$pp_mm2),
                                   "One or more parsing issues")

})

## Check Class
test_that("read_participants() class works", {

  expect_s3_class(pp_cal_cleaned, "data.frame")
  expect_s3_class(pp_mm2_cleaned, "data.frame")
  expect_s3_class(pp_cal_cleaned, "zoom_participants")
  expect_s3_class(pp_mm2_cleaned, "zoom_participants")
})

## Check Attributes
test_that("read_participants() attribute works",{

  attr1 <- attributes(pp_cal_cleaned)
  attr_null <- attributes(pp_mm2_cleaned)
  nm <- c("Meeting_ID","Topic", "Start_Time",
          "End_Time", "Email", "Duration_Minute","Participants")

  ### Has "meeting_overview" attribute
  expect_true("meeting_overview" %in% names(attr1))
  ### Don't Have "meeting_overview" attribute
  expect_false("meeting_overview" %in% names(attr_null))
  ### Check names of "meeting_overview" attribute
  expect_named(attr1$meeting_overview, nm)

})

## Check Values
test_that("read_participants() values OK",{

  nm <- c("Name (Original Name)", "Name", "Name_Original", "Email", "Join_Time", "Leave_Time", "Duration_Minutes", "Guest", "Rec_Consent")

  expect_named(pp_cal_cleaned, nm)
  expect_named(pp_mm2_cleaned, nm)
})


# Parse date-time ---------------------------------------------------------


test_that("parse_pp_datetime() works",{

  # Format 1: `mm/dd/yyyy hh:mm:ss AM/PM`
  t1 <- "10/06/2021 09:20:31 AM"
  expect_equal(parse_pp_datetime(t1), mdy_hms(t1))

  # Format 2: `dd/mm/yyyy hh:mm:ss`
  t2 <- "19/11/2021 10:34:26"
  expect_equal(parse_pp_datetime(t2), dmy_hms(t2))

  # Other Format
  ## `yyyy/mm/dd hh:mm:ss`
  t3 <- "2021/10/20 09:20:31 AM"
  expect_equal(parse_pp_datetime(t3), ymd_hms(t3))
  ## `yyyy/dd/mm hh:mm:ss`
  t4 <- "2021/20/10 09:20:31"
  expect_equal(parse_pp_datetime(t4), ydm_hms(t4))

})
# Extract Current & Original Name -----------------------------------------


test_that("test extract_CurrOrig_name()",{

  t1 <- extract_CurrOrig_name("a(b)c(())(last (one))")
  np1 <- extract_CurrOrig_name("No Paren")
  np2 <- extract_CurrOrig_name("No :)")
  nl <- extract_CurrOrig_name("some (paren) (not) last")

  ## BUG That still not fixed
  bug1 <- extract_CurrOrig_name("som(e) :)") # This will Bug

  expect_s3_class(t1, "tbl") # Check Class

  expect_equal(t1, tibble::tibble(current = "a(b)c(())", original = "last (one)"))
  expect_equal(np1, tibble::tibble(current = "No Paren", original = NA_character_))
  expect_equal(np2, tibble::tibble(current = "No :)", original = NA_character_))
  expect_equal(nl, tibble::tibble(current = "some (paren) (not) last",
                                  original = NA_character_))
  ## Expect Bugged
  expect_equal(bug1, tibble::tibble(current = "som", original = "e"))

})
