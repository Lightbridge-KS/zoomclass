test_that("multiplication works", {
  expect_equal(2 * 2, 4)
})


# Test path to "testdata" folder ------------------------------------------


test_that("`system.file path works`",{
  path <- system.file("testdata", package="zoomclass")
  expect_false(path == "")
})


# read_zoom_chat ----------------------------------------------------------


test_that("read_zoom_chat is working",{
  # Full & Abbreviated
  chat_df_full <- zoomclass::read_zoom_chat(path_testdata("chat/Zoom-chat-ex.txt"))
  chat_df_abbr <- zoomclass::read_zoom_chat(path_testdata("chat/Zoom-chat-ex-abbr.txt"))
   expect_s3_class(chat_df_full, "tbl_df")
   expect_s3_class(chat_df_abbr, "tbl_df")

})
