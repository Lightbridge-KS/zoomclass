### Helper functions for test

# Get Path to testdata folder ---------------------------------------------

path_testdata <- function(..., package = "readzoom") {

  system.file("testdata", ... ,package = package)

}


# Path to test data -------------------------------------------------------

paths.testdata <- list(
  pp_cal = path_testdata("participants/original", "participants_213ClinCa.csv"),
  pp_mm2 = path_testdata("participants/original", "participants_MM-2021-11-19.csv")
)


# Read Zoom Participants --------------------------------------------------


pp_cal_cleaned <- read_participants(paths.testdata$pp_cal)
pp_mm2_cleaned <- read_participants(paths.testdata$pp_mm2)


# Class Session -----------------------------------------------------------


pp_cal_session <- class_session(pp_cal_cleaned,
                                class_start = "10:00:00", class_end = "12:00:00")
pp_mm2_session <- class_session(pp_mm2_cleaned,
                                class_start = "10:00:00", class_end = "12:00:00")


# Class Student -----------------------------------------------------------

pp_cal_students <- class_students(pp_cal_cleaned,
  class_start = "10:00:00", class_end = "12:00:00",
  late_cutoff = "10:15:00"
)

pp_mm2_students <- class_students(pp_mm2_cleaned,
               class_start = "10:00:00", class_end = "12:00:00",
               late_cutoff = "10:15:00")


# Class Time --------------------------------------------------------------


class_tm1 <- data.frame(start =  lubridate::dmy_hms("10/06/2021 10:00:00 AM"),
                        end = lubridate::dmy_hms("10/06/2021 11:00:00 AM"),
                        join = lubridate::dmy_hms("10/06/2021 09:00:00 AM"),
                        leave = lubridate::dmy_hms("10/06/2021 10:30:00 AM"))



