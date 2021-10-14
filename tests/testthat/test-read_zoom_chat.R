test_that("multiplication works", {
  expect_equal(2 * 2, 4)
})


# Test path to "testdata" folder ------------------------------------------


test_that("`system.file path works`",{
  path <- system.file("testdata", package="readzoom")
  expect_false(path == "")
})


# read_zoom_chat ----------------------------------------------------------


test_that("read_zoom_chat is working",{
  # Full & Abbreviated
  chat_df_full <- readzoom::read_zoom_chat(system.file("testdata","Zoom-chat-ex.txt",package="readzoom"))
  chat_df_abbr <- readzoom::read_zoom_chat(system.file("testdata","Zoom-chat-ex-abbr.txt",package="readzoom"))
   expect_s3_class(chat_df_full, "tbl_df")
   expect_s3_class(chat_df_abbr, "tbl_df")

})
