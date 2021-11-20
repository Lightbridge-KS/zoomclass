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


