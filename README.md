
<!-- README.md is generated from README.Rmd. Please edit that file -->

# zoomclass

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

<!-- badges: end -->

> **A high-level data analysis R package for Zoom’s participants report
> `.csv` and Zoom’s chat `.txt` file.**

## Installation

You can install the development version from
[GitHub](https://github.com/) with:

``` r
# install.packages("remotes")
remotes::install_github("Lightbridge-KS/zoomclass")
```

[{zoomclass}](https://github.com/Lightbridge-KS/zoomclass) aims to
analyse Zoom participants reports and Zoom chat files.

### Analyse Zoom participants report

Functions in this category were constructed to perform an analysis of
Zoom’s participants report `.csv` in the setting of an online-classroom
using Zoom. Student’s time information such as time spent before,
during, and after class will be computed, also time period of students
who joined the classroom late can also be computed.

First, read data from Zoom’s participants report `.csv` into a data
frame using `read_participants()`, and then execute classroom analysis
by one of the `class_*()` functions.

There are 3 main `class_*()` functions.

1.  **`class_session()`** summarizes time information about individual
    sessions of each students (If student has multiple sessions, output
    will show ≥ 1 rows per that student)
2.  **`class_students()`** summarizes time information of each students
    (1 row per student)
3.  **`class_studentsID()`** summarizes time information of each
    student’s ID extracted from student name (1 row per student’s ID)

### Combine Zoom Chat

`read_zoom_chat()` can be used to parse program Zoom [chat
file](https://support.zoom.us/hc/en-us/articles/115004792763-Saving-in-meeting-chat)
from `.txt` file to a tibble, just execute the followings:

``` r
read_zoom_chat("path/to/zoom_chat.txt")
```
