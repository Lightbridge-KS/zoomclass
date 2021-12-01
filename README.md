
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

Functions in [{zoomclass}](https://github.com/Lightbridge-KS/zoomclass)
package are divided in 2 categories which aims to analyse input from
(mainly) Zoom’s participants report `.csv` and Zoom’s chat `.txt` file.

``` r
library(zoomclass)
```

# Participants Report

In this category, High-level functions are design to analyse Zoom’s
participants report (`.csv` file), especially for checking student’s
attendance in Zoom classroom.

## Zoom’s Participant Report

The term I used “Zoom’s participant report”, basically, is a CSV log
file that host can downloaded after Zoom meeting has ended. It contains
the following columns:

-   **Name (Original Name):** show participant’s *current name* in Zoom
    meeting with optional *original name* in the last balanced
    parenthesis.
-   **User Email:** an email that participant signed in Zoom account
-   **Join Time:** join time of each participants by each individual
    sessions
-   **Leave Time:** leave time of each participants by each individual
    sessions
-   **Duration (Minutes):** computed by `Leave Time` - `Join Time` of
    each session
-   **Guest:** “Yes” means that person is a participants; “No” means
    he/she is a host
-   **Recording Consent:** “Y” means participant allowed recording in
    zoom

This package comes with an example data of Zoom’s participant report in
`.csv` which I will use for demo in this tutorial.

``` r
# List all example data in `zoomclass` package
zoomclass_example()
#> [1] "participants_heroes.csv"

# Get a path to specific example data
path_heroes <- zoomclass_example("participants_heroes.csv")
path_heroes
#> [1] "/Users/kittipos/Library/R/x86_64/4.1/library/zoomclass/extdata/participants_heroes.csv"
```

You can see all example files in file explorer by executing this
command.

``` r
if (interactive() && requireNamespace("fs")) {

  fs::file_show(system.file("extdata", package = "zoomclass"))
  
}
```

## Read Participants

`read_participants()` read the data in using `readr::read_csv()` and
then performs the followings steps:

1.  Read Zoom’s participant report into a tibble
2.  Clean column names, so that we can manipulate more easily in `R`
3.  Apply appropriate time formatting (POSIXct) for relevant columns
4.  Extract participant’s current (displayed) name and original name
    into `Name` and `Name_Original` columns, respectively.

The output is a tibble with `zoom_participants` subclass. If metadata
regarding Zoom meeting was found, it will be assign to a
`meeting_overview` attribute.

``` r
pp_heroes <- read_participants(path_heroes)

str(pp_heroes)
#> zoom_participants [31 × 9] (S3: zoom_participants/tbl_df/tbl/data.frame)
#>  $ Name (Original Name): chr [1:31] "015_Loki (Loki Laufeyson)" "019_Mockingbird" "014_Clea" "003_Power Girl (Kara Zor-L)" ...
#>  $ Name                : chr [1:31] "015_Loki" "019_Mockingbird" "014_Clea" "003_Power Girl" ...
#>  $ Name_Original       : chr [1:31] "Loki Laufeyson" NA NA "Kara Zor-L" ...
#>  $ Email               : chr [1:31] "loki_asgardian@marvel.com" "mockingbird_human@marvel.com" "clea_unknown@marvel.com" "power-girl_kryptonian@dc.com" ...
#>  $ Join_Time           : POSIXct[1:31], format: "2021-11-19 09:54:15" "2021-11-19 10:07:44" ...
#>  $ Leave_Time          : POSIXct[1:31], format: "2021-11-19 12:01:59" "2021-11-19 12:01:58" ...
#>  $ Duration_Minutes    : num [1:31] 128 115 10 114 52 114 113 113 112 112 ...
#>  $ Guest               : chr [1:31] "Yes" "Yes" "No" "Yes" ...
#>  $ Rec_Consent         : chr [1:31] "Y" "Y" NA "Y" ...
```

As you can see, almost all column names were cleaned with no spaces;
`Join_Time` and `Leave_Time` were formatted as POSIXct object,
correctly. Moreover, “015_Loki (Loki Laufeyson)” in original
`Name (Original Name)` column is extracted into “015_Loki” in `Name` and
“Loki Laufeyson” in `Name_Original`, respectively.

The output tibble `pp_heroes` contain sessions information of each
participants. If we count names of each participants, we can see that
some rows is duplicated.

``` r
library(dplyr)
```

``` r
pp_heroes %>% 
  count(`Name (Original Name)`, sort = TRUE) %>% 
  head()
#> # A tibble: 6 × 2
#>   `Name (Original Name)`          n
#>   <chr>                       <int>
#> 1 003_Power Girl (Kara Zor-L)     2
#> 2 010_Cyborg Superman             2
#> 3 017_Swarm                       2
#> 4 022_Dazzler                     2
#> 5 001_Magus                       1
#> 6 002_She-Thing                   1
```

For example, “Power Girl” has 2 rows because she had 2 sessions in Zoom
(join and leave 2 times).

``` r
pp_heroes %>% 
  filter(Name == "003_Power Girl") %>% 
  select(Name, Email, Join_Time, Leave_Time, Duration_Minutes)
#> # A tibble: 2 × 5
#>   Name           Email  Join_Time           Leave_Time          Duration_Minutes
#>   <chr>          <chr>  <dttm>              <dttm>                         <dbl>
#> 1 003_Power Girl power… 2021-11-19 10:08:26 2021-11-19 12:01:58              114
#> 2 003_Power Girl power… 2021-11-19 10:11:31 2021-11-19 12:01:58              111
```

But why `Join_Time` and `Leave_Time` is overlapped in these 2 sessions?
This might be the case that she’s joined Zoom with 2 devices at the same
time. As I will show you next, The upcoming functions in this package
can detect this scenario.

## Classroom in Zoom

Now that we have read Zoom’s participants data in, It’s time to analyse
participants in a context of a classroom. From now on, I’ll call a
“participant” as “student”.

A typical academic classroom usually has an explicit start and end time.
If students arrive to class later than certain cutoff time point,
teacher can mark them as late.

In the next family of functions: `class_*`, you must provide
`class_start` and `class_end` arguments by which they will used to
compute 4 time intervals in the corresponding columns:

-   `Before_Class`: represent time interval that student spent in Zoom
    before class started
-   `During_Class`: represent time interval that student spent in Zoom
    during class
-   `After_Class`: represent time interval that student spent in Zoom
    after class ended
-   `Total_Time`: the sum of time `Before_Class` + `During_Class` +
    `After_Class`

All of theses time periods are Period object from `{lubridate}` package.
(It can be converted to hours, minutes, or secound as well.)

Furthermore, `class_*` functions can tell you whether each students
joined Zoom with multiple devices at the same time period. The use case
of this might be when live-exam is conducted in Zoom, and you want to
check that each students joined with 1 device only (no cheating).

Next, 3 **`class_*`** functions will be introduced:

1.  **`class_session()`** summarizes time information about individual
    sessions of each students (If student has multiple sessions, output
    will show ≥ 1 rows per that student)
2.  **`class_students()`** summarizes time information of each students
    (1 row per student)
3.  **`class_students()`** summarizes time information of each student’s
    ID extracted from student name (1 row per student’s ID)

The first argument of these functions are `zoom_participants` tibble as
created by `read_participants()`.

### Class Session

Suppose that our Zoom classroom was started at 10:00 and ended at 12:00
(24 hours clock time), I will call `class_session()` as follows:

``` r
pp_heroes_session <- 
  class_session(pp_heroes, 
                class_start = "10:00",
                class_end = "12:00"
                )

pp_heroes_session
#> # A tibble: 31 × 17
#>    `Name (Original N… Name    Name_Original Email    Session Class_Start        
#>    <chr>              <chr>   <chr>         <chr>      <int> <dttm>             
#>  1 001_Magus          001_Ma… <NA>          magus_u…       1 2021-11-19 10:00:00
#>  2 002_She-Thing      002_Sh… <NA>          she-thi…       1 2021-11-19 10:00:00
#>  3 003_Power Girl (K… 003_Po… Kara Zor-L    power-g…       1 2021-11-19 10:00:00
#>  4 003_Power Girl (K… 003_Po… Kara Zor-L    power-g…       2 2021-11-19 10:00:00
#>  5 004_Angel Salvado… 004_An… <NA>          angel-s…       1 2021-11-19 10:00:00
#>  6 005_Donna Troy     005_Do… <NA>          donna-t…       1 2021-11-19 10:00:00
#>  7 006_Phoenix        006_Ph… <NA>          phoenix…       1 2021-11-19 10:00:00
#>  8 007_Birdman        007_Bi… <NA>          birdman…       1 2021-11-19 10:00:00
#>  9 008_Simon Baz      008_Si… <NA>          simon-b…       1 2021-11-19 10:00:00
#> 10 009_Juggernaut (C… 009_Ju… Cain Marko    juggern…       1 2021-11-19 10:00:00
#> # … with 21 more rows, and 11 more variables: Class_End <dttm>,
#> #   Join_Time <dttm>, Leave_Time <dttm>, Before_Class <Period>,
#> #   During_Class <Period>, After_Class <Period>, Total_Time <Period>,
#> #   Duration_Minutes <dbl>, Guest <chr>, Rec_Consent <chr>, Multi_Device <lgl>
```

As previously stated, classroom-related time intervals were computed
i.e., `Before_Class`, `During_Class`, and `After_Class`.

Let’s see who spend time during class all the time

``` r
pp_heroes_session %>% 
  filter(During_Class == lubridate::hours(2)) %>% 
  select(Name, ends_with("Class"))
#> # A tibble: 1 × 4
#>   Name     Before_Class During_Class After_Class
#>   <chr>    <Period>     <Period>     <Period>   
#> 1 015_Loki 5M 45S       2H 0M 0S     1M 59S
```

Or, may be Loki could cast illusion to attend Zoom till the end :-)

Now, let’s see who attend Zoom using multiple device at the same time by
filter `Multi_Device = TRUE`.

``` r
pp_heroes_session %>% 
  filter(Multi_Device  == TRUE) %>% 
  select(Name, Session, Join_Time, Leave_Time, Multi_Device)
#> # A tibble: 4 × 5
#>   Name           Session Join_Time           Leave_Time          Multi_Device
#>   <chr>            <int> <dttm>              <dttm>              <lgl>       
#> 1 003_Power Girl       1 2021-11-19 10:08:26 2021-11-19 12:01:58 TRUE        
#> 2 003_Power Girl       2 2021-11-19 10:11:31 2021-11-19 12:01:58 TRUE        
#> 3 017_Swarm            1 2021-11-19 10:14:30 2021-11-19 10:24:26 TRUE        
#> 4 017_Swarm            2 2021-11-19 10:24:12 2021-11-19 12:01:58 TRUE
```

`Session` column displays session number of each student as ranked by
`Join_Time`. Let’s see who joined Zoom more than 1 time.

As you can see, “Power Girl” and “Swarm” has session number = 2;
however, be aware that these two joined Zoom only one time using 2
devices.

``` r
pp_heroes_session %>% 
  filter(Session  > 1) %>% 
  select(Name, Session, Join_Time, Leave_Time, Multi_Device)
#> # A tibble: 4 × 5
#>   Name              Session Join_Time           Leave_Time          Multi_Device
#>   <chr>               <int> <dttm>              <dttm>              <lgl>       
#> 1 003_Power Girl          2 2021-11-19 10:11:31 2021-11-19 12:01:58 TRUE        
#> 2 010_Cyborg Super…       2 2021-11-19 11:28:11 2021-11-19 12:01:58 NA          
#> 3 017_Swarm               2 2021-11-19 10:24:12 2021-11-19 12:01:58 TRUE        
#> 4 022_Dazzler             2 2021-11-19 11:02:46 2021-11-19 11:29:38 NA
```

### Class Student (TO DO)

### Class Student ID (TO DO)

## Zoom Chat

The final functions of this package is design to parse program Zoom
[chat
file](https://support.zoom.us/hc/en-us/articles/115004792763-Saving-in-meeting-chat)
from `.txt` file to a tibble, just execute the followings:

``` r
read_zoom_chat("path/to/zoom_chat.txt")
```
