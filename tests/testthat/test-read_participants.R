
# Read Participant --------------------------------------------------------

path_pp_heroes <- zoomclass_example("participants_heroes.csv")
path_pp_heroes_full <- zoomclass_example("participants_heroes_full.csv")


pp_heroes <- zoomclass::read_participants(path_pp_heroes)
pp_heroes_full <- zoomclass::read_participants(path_pp_heroes_full)


# Check Read In -----------------------------------------------------------




test_that("read_participants() can read data", {

  expect_s3_class(read_participants(path_pp_heroes), "data.frame")
  expect_s3_class(read_participants(path_pp_heroes_full), "data.frame")

})


# Check zoom_participants class -------------------------------------------


test_that("read_participants() has  zoom_participants class", {

  expect_s3_class(read_participants(path_pp_heroes), "zoom_participants")
  expect_s3_class(read_participants(path_pp_heroes_full), "zoom_participants")

})

## Check Attributes
test_that("read_participants() has meeting_overview attribute",{

  no_mtov_attr <- attributes(pp_heroes)
  has_mtov_attr <- attributes(pp_heroes_full)

  nm <- c("Meeting_ID","Topic", "Start_Time",
          "End_Time", "Email", "Duration_Minute","Participants")

  ### Has "meeting_overview" attribute
  expect_true("meeting_overview" %in% names(has_mtov_attr))
  ### Don't Have "meeting_overview" attribute
  expect_false("meeting_overview" %in% names(no_mtov_attr))
  ### Check names of "meeting_overview" attribute
  expect_named(has_mtov_attr$meeting_overview, nm)

})


## Check Values
test_that("read_participants() values OK",{

  nm <- c("Name (Original Name)", "Name", "Name_Original", "Email", "Join_Time", "Leave_Time", "Duration_Minutes", "Guest", "Rec_Consent")

  expect_named(pp_heroes, nm)
  expect_named(pp_heroes_full, nm)
})


# Parse date-time ---------------------------------------------------------


test_that("parse_pp_datetime() works",{

  # Format 1: `mm/dd/yyyy hh:mm:ss AM/PM`
  t1 <- "10/06/2021 09:20:31 AM"
  expect_equal(parse_pp_datetime(t1), lubridate::mdy_hms(t1))

  # Format 2: `dd/mm/yyyy hh:mm:ss`
  t2 <- "19/11/2021 10:34:26"
  expect_equal(parse_pp_datetime(t2), lubridate::dmy_hms(t2))

  # Other Format
  ## `yyyy/mm/dd hh:mm:ss`
  t3 <- "2021/10/20 09:20:31 AM"
  expect_equal(parse_pp_datetime(t3), lubridate::ymd_hms(t3))
  ## `yyyy/dd/mm hh:mm:ss`
  t4 <- "2021/20/10 09:20:31"
  expect_equal(parse_pp_datetime(t4), lubridate::ydm_hms(t4))

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
