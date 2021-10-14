
<!-- README.md is generated from README.Rmd. Please edit that file -->

# ZoomAnalytics

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

This package contains function to parse & analyze program Zoom [chat
file](https://support.zoom.us/hc/en-us/articles/115004792763-Saving-in-meeting-chat)
and participant report file.

## Installation

You can install the development version from
[GitHub](https://github.com/) with:

``` r
# install.packages("remotes")
remotes::install_github("Lightbridge-KS/ZoomAnalytics")
```

## Example

To parse Zoom chat report from `.txt` file to a tibble, just execute the
followings:

``` r
library(ZoomAnalytics)

read_zoom_chat("path/to/zoom_chat.txt")
```
