


test_that("zoomclass_example() give paths", {

  type <- "character"

  expect_type(zoomclass_example("participants_heroes.csv"), type)
  expect_type(zoomclass_example("participants_heroes_full.csv"), type)
  expect_type(zoomclass_example("zoom-chat-2.txt"), type)
  expect_type(zoomclass_example("zoom-chat-1.txt"), type)

})
