
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
regarding Zoom meeting was found, it will be assigned to a
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

Next, 3 **`class_*`** functions will be introduced:

1.  **`class_session()`** summarizes time information about individual
    sessions of each students (If student has multiple sessions, output
    will show ≥ 1 rows per that student)
2.  **`class_students()`** summarizes time information of each students
    (1 row per student)
3.  **`class_studentsID()`** summarizes time information of each
    student’s ID extracted from student name (1 row per student’s ID)

The first argument of these functions receives input from
`zoom_participants` tibble as created by `read_participants()`.

A typical academic classroom usually has an explicit start and end time.
If students arrive to class later than certain cutoff time point,
teacher can mark them as late.

In the `class_*` functions, you must provide `class_start` and
`class_end` arguments by which they will used to compute 4 time
intervals that student spent before, during, and after Zoom class:

-   `Before_Class`: represent time interval that student spent in Zoom
    before class started
-   `During_Class`: represent time interval that student spent in Zoom
    during class
-   `After_Class`: represent time interval that student spent in Zoom
    after class ended
-   `Total_Time`: the sum of time `Before_Class` + `During_Class` +
    `After_Class`

For `class_students()` and `class_studentsID()`, you can compute late
time period of each student by providing `late_cutoff` argument.

All of theses time intervals are Period object from `{lubridate}`
package. (It can be converted to hours, minutes, or secound as well.)

Furthermore, `class_*` functions can tell you whether each students
joined Zoom with multiple devices at the same time period. The use case
of this might be when live-exam is conducted in Zoom, and you want to
check that each students joined with 1 device only (no cheating).

### Class Session

Suppose that our Zoom classroom was started at 10:00 and ended at 12:00,
I will call `class_session()` as follows:

(Input `class_start` and `class_end` as *24-hours clock time* with no AM
or PM)

``` r
pp_heroes_session <- 
  class_session(pp_heroes, 
                class_start = "10:00", # Official class started at 10:00 AM
                class_end = "12:00" # Official class ended at 12:00 PM
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

As previously stated, classroom-related time intervals were computed.

``` r
pp_heroes_session %>% 
  select(Name, ends_with("Class"), Total_Time) %>% 
  head()
#> # A tibble: 6 × 5
#>   Name                Before_Class During_Class After_Class Total_Time
#>   <chr>               <Period>     <Period>     <Period>    <Period>  
#> 1 001_Magus           NA           1H 15M 57S   1M 59S      1H 17M 56S
#> 2 002_She-Thing       NA           22M 59S      1M 58S      24M 57S   
#> 3 003_Power Girl      NA           1H 51M 34S   1M 58S      1H 53M 32S
#> 4 003_Power Girl      NA           1H 48M 29S   1M 58S      1H 50M 27S
#> 5 004_Angel Salvadore NA           1H 44M 49S   1M 58S      1H 46M 47S
#> 6 005_Donna Troy      NA           1H 50M 34S   1M 55S      1H 52M 29S
```

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

### Class Student

**`class_students()`** summarizes time information grouped by each
students (grouping variables is `Name (Original Name)` and `Email`). The
result will be a tibble with one row per student.

Most columns are the same as output from `class_session()`, except for
the followings:

-   `Session_Count`: show session counts of each student (how many times
    each student join and leave class)
-   `First_Join_Time`: if student has multiple sessions, this would
    choose only the earliest join time.
-   `Last_Leave_Time`: if student has multiple sessions, this would
    choose only the latest leave time.

New optional argument is `late_cutoff` from which student will be
considered late if first joined time is later than this cutoff. The late
time period will be shown in `Late_Time` column.

``` r
pp_heroes_students <- 
  class_students(pp_heroes, 
               class_start = "10:00",
               class_end = "12:00",
               late_cutoff = "10:15" # If student joined later than 10:15 will considered late
              )

head(pp_heroes_students)
#> # A tibble: 6 × 16
#>   `Name (Original … Name  Name_Original Email  Session_Count Class_Start        
#>   <chr>             <chr> <chr>         <chr>          <int> <dttm>             
#> 1 001_Magus         001_… <NA>          magus…             1 2021-11-19 10:00:00
#> 2 002_She-Thing     002_… <NA>          she-t…             1 2021-11-19 10:00:00
#> 3 003_Power Girl (… 003_… Kara Zor-L    power…             2 2021-11-19 10:00:00
#> 4 004_Angel Salvad… 004_… <NA>          angel…             1 2021-11-19 10:00:00
#> 5 005_Donna Troy    005_… <NA>          donna…             1 2021-11-19 10:00:00
#> 6 006_Phoenix       006_… <NA>          phoen…             1 2021-11-19 10:00:00
#> # … with 10 more variables: Class_End <dttm>, First_Join_Time <dttm>,
#> #   Last_Leave_Time <dttm>, Before_Class <Period>, During_Class <Period>,
#> #   After_Class <Period>, Total_Time <Period>, Duration_Minutes <dbl>,
#> #   Multi_Device <lgl>, Late_Time <Period>
```

Let’s see who joined class late \> 10 minutes (later than 10:25).

``` r
pp_heroes_students %>% 
  filter(Late_Time > lubridate::minutes(10)) %>% 
  select(Name, First_Join_Time, Late_Time)
#> # A tibble: 5 × 3
#>   Name               First_Join_Time     Late_Time
#>   <chr>              <dttm>              <Period> 
#> 1 001_Magus          2021-11-19 10:44:03 29M 3S   
#> 2 002_She-Thing      2021-11-19 11:37:01 1H 22M 1S
#> 3 012_Shang-Chi      2021-11-19 11:18:16 1H 3M 16S
#> 4 021_Winter Soldier 2021-11-19 11:00:49 45M 49S  
#> 5 022_Dazzler        2021-11-19 11:01:02 46M 2S
```

### Class Student ID

Supposed that after you’ve checked class attendance of each student,
perhaps you want to merge this data into a database by some key columns
which is usually student’s ID.

First, you informed students to put student’s ID in their names, for
example: “001_Megus”.

**`class_studentsID()`** will help you summarizes time information
grouped by each student’s ID. Then, you can used these IDs to merge into
a database.

The internal processes are that `class_studentsID()` extracts student’s
ID from `Name (Original Name)` column using regular expression as
provided by `id_regex`. Then, time information will be summarized per
student’s ID (grouping variable is `ID`), and the rest of output columns
is similar to `class_students()`. Finally, the result will be a tibble
with one row per `ID`.

``` r
pp_heroes_studentsID <- 
  class_studentsID(pp_heroes, 
                   id_regex = "\\d+", # Extract digits from student name as student's ID
                   class_start = "10:00",
                   class_end = "12:00",
                   late_cutoff = "10:15" # If student joined later than 10:15 will considered late
                   )

head(pp_heroes_studentsID)
#> # A tibble: 6 × 15
#>   ID    Name      Email    Session_Count Class_Start         Class_End          
#>   <chr> <chr>     <chr>            <int> <dttm>              <dttm>             
#> 1 001   001_Magus magus_u…             1 2021-11-19 10:00:00 2021-11-19 12:00:00
#> 2 002   002_She-… she-thi…             1 2021-11-19 10:00:00 2021-11-19 12:00:00
#> 3 003   003_Powe… power-g…             2 2021-11-19 10:00:00 2021-11-19 12:00:00
#> 4 004   004_Ange… angel-s…             1 2021-11-19 10:00:00 2021-11-19 12:00:00
#> 5 005   005_Donn… donna-t…             1 2021-11-19 10:00:00 2021-11-19 12:00:00
#> 6 006   006_Phoe… phoenix…             1 2021-11-19 10:00:00 2021-11-19 12:00:00
#> # … with 9 more variables: First_Join_Time <dttm>, Last_Leave_Time <dttm>,
#> #   Before_Class <Period>, During_Class <Period>, After_Class <Period>,
#> #   Total_Time <Period>, Duration_Minutes <dbl>, Multi_Device <lgl>,
#> #   Late_Time <Period>
```

(If the same `ID` is founded in multiple names (e.g. “001_Magus”,
“001_magus”), the `Name` column will contain all combinations of names
for that particular `ID`.)

### Merge Data

Here, I will give an example of merging student data to a database.

This package provides `heroes_students` data frame that contain names
and ID of student who enrolled the course in this semester.

``` r
head(heroes_students)
#>    ID            Name Comment
#> 1 001           Magus    <NA>
#> 2 004 Angel Salvadore    <NA>
#> 3 005      Donna Troy    <NA>
#> 4 006         Phoenix    <NA>
#> 5 008       Simon Baz    <NA>
#> 6 009      Juggernaut    <NA>
```

You can join `heroes_students` with `pp_heroes_studentsID` using
`dplyr::*_join` functions by `ID`.

#### Check Students NOT in Zoom Class

To check whether students joined Zoom class room or not, it can be
obtained by using a filtering join function: `dplyr::anti_join()`.

These students below are in the `heroes_students` data frame, but not in
`pp_heroes_studentsID`, which means that they didn’t join Zoom
classroom.

``` r
heroes_students %>% 
  anti_join(pp_heroes_studentsID, by = "ID")
#>    ID         Name               Comment
#> 1 031      Impulse                  <NA>
#> 2 032  Marvel Girl    on a space mission
#> 3 033      Giganta                  <NA>
#> 4 034       Vision last seen in Westview
#> 5 036 Silk Spectre                  <NA>
```

#### Check Non-Student in Zoom Class

Likewise, You can also check participants who joined Zoom classroom but
not in the `heroes_students` data frame (non-students). Again,
`dplyr::anti_join()` can be used.

``` r
pp_heroes_studentsID %>% 
  anti_join(heroes_students, by = "ID")
#> # A tibble: 5 × 15
#>   ID    Name      Email    Session_Count Class_Start         Class_End          
#>   <chr> <chr>     <chr>            <int> <dttm>              <dttm>             
#> 1 002   002_She-… she-thi…             1 2021-11-19 10:00:00 2021-11-19 12:00:00
#> 2 003   003_Powe… power-g…             2 2021-11-19 10:00:00 2021-11-19 12:00:00
#> 3 007   007_Bird… birdman…             1 2021-11-19 10:00:00 2021-11-19 12:00:00
#> 4 013   013_Thun… thunder…             1 2021-11-19 10:00:00 2021-11-19 12:00:00
#> 5 018   018_Bliz… blizzar…             1 2021-11-19 10:00:00 2021-11-19 12:00:00
#> # … with 9 more variables: First_Join_Time <dttm>, Last_Leave_Time <dttm>,
#> #   Before_Class <Period>, During_Class <Period>, After_Class <Period>,
#> #   Total_Time <Period>, Duration_Minutes <dbl>, Multi_Device <lgl>,
#> #   Late_Time <Period>
```

#### Merge All

Finally, one of the best approach is to merge everything.
`dplyr::full_join()` is a mutating join function that merge 2 data frame
without any rows lost from either one.

In this example, I fully joined 2 data frame `pp_heroes_studentsID` and
`heroes_students` by `ID`. Suffix “\_from_ID” and “\_from_Zoom”
represents unmatched rows from the list of students (`heroes_students`)
and Zoom classroom, respectively.

``` r
# Merge to Zoom data by `ID`
heroes_students_joined <- heroes_students %>% 
  full_join(pp_heroes_studentsID, by = "ID", suffix = c("_from_ID", "_from_Zoom")) %>% 
  relocate(ID, starts_with("Name"))

head(heroes_students_joined)
#>    ID    Name_from_ID              Name_from_Zoom Comment
#> 1 001           Magus                   001_Magus    <NA>
#> 2 004 Angel Salvadore         004_Angel Salvadore    <NA>
#> 3 005      Donna Troy              005_Donna Troy    <NA>
#> 4 006         Phoenix                 006_Phoenix    <NA>
#> 5 008       Simon Baz               008_Simon Baz    <NA>
#> 6 009      Juggernaut 009_Juggernaut (Cain Marko)    <NA>
#>                                Email Session_Count         Class_Start
#> 1           magus_unknown@marvel.com             1 2021-11-19 10:00:00
#> 2 angel-salvadore_unknown@marvel.com             1 2021-11-19 10:00:00
#> 3           donna-troy_amazon@dc.com             1 2021-11-19 10:00:00
#> 4          phoenix_mutant@marvel.com             1 2021-11-19 10:00:00
#> 5             simon-baz_human@dc.com             1 2021-11-19 10:00:00
#> 6        juggernaut_human@marvel.com             1 2021-11-19 10:00:00
#>             Class_End     First_Join_Time     Last_Leave_Time Before_Class
#> 1 2021-11-19 12:00:00 2021-11-19 10:44:03 2021-11-19 12:01:59         <NA>
#> 2 2021-11-19 12:00:00 2021-11-19 10:15:11 2021-11-19 12:01:58         <NA>
#> 3 2021-11-19 12:00:00 2021-11-19 10:09:26 2021-11-19 12:01:55         <NA>
#> 4 2021-11-19 12:00:00 2021-11-19 10:19:40 2021-11-19 12:01:54         <NA>
#> 5 2021-11-19 12:00:00 2021-11-19 10:11:26 2021-11-19 12:01:59         <NA>
#> 6 2021-11-19 12:00:00 2021-11-19 10:10:49 2021-11-19 12:01:56         <NA>
#>   During_Class After_Class Total_Time Duration_Minutes Multi_Device Late_Time
#> 1   1H 15M 57S      1M 59S 1H 17M 56S               78           NA    29M 3S
#> 2   1H 44M 49S      1M 58S 1H 46M 47S              107           NA       11S
#> 3   1H 50M 34S      1M 55S 1H 52M 29S              113           NA      <NA>
#> 4   1H 40M 20S      1M 54S 1H 42M 14S              103           NA    4M 40S
#> 5   1H 48M 34S      1M 59S 1H 50M 33S              111           NA      <NA>
#> 6   1H 49M 11S      1M 56S  1H 51M 7S              112           NA      <NA>
```

Student who didn’t joined Zoom classroom will have `NA` presented in the
`Name_from_Zoom` column, whereas participants who joined Zoom classroom
but not in the list of students will have `NA` presented in the
`Name_from_ID` column.

``` r
heroes_students_joined %>% 
  filter(if_any(starts_with("Name"), is.na)) %>% 
  select(ID, starts_with("Name"), Comment)
#>     ID Name_from_ID              Name_from_Zoom               Comment
#> 1  031      Impulse                        <NA>                  <NA>
#> 2  032  Marvel Girl                        <NA>    on a space mission
#> 3  033      Giganta                        <NA>                  <NA>
#> 4  034       Vision                        <NA> last seen in Westview
#> 5  036 Silk Spectre                        <NA>                  <NA>
#> 6  002         <NA>               002_She-Thing                  <NA>
#> 7  003         <NA> 003_Power Girl (Kara Zor-L)                  <NA>
#> 8  007         <NA>                 007_Birdman                  <NA>
#> 9  013         <NA>          013_Thunderbird II                  <NA>
#> 10 018         <NA>             018_Blizzard II                  <NA>
```

## Zoom Chat

The final functions of this package is design to parse program Zoom
[chat
file](https://support.zoom.us/hc/en-us/articles/115004792763-Saving-in-meeting-chat)
from `.txt` file to a tibble, just execute the followings:

``` r
read_zoom_chat("path/to/zoom_chat.txt")
```
