test_that("multiplication works", {
  expect_equal(2 * 2, 4)
})

# test_that("read_zoom_chat is working",{
#   # Full & Abbreviated
#   chat_df_full <- readzoom::read_zoom_chat(("tests/testdata/Zoom-chat-ex.txt"))
#   chat_df_abbr <- readzoom::read_zoom_chat(("tests/testdata/Zoom-chat-ex-abbr.txt"))
#
#   expect_s3_class(chat_df_full, "tbl_df")
#   expect_s3_class(chat_df_abbr, "tbl_df")
#
# })

#system.file("testdata","Zoom-chat-ex.txt",package="readzoom") %>% readzoom::read_zoom_chat()


test_that("read_zoom_chat is working",{
  # Full & Abbreviated
  chat_df_full <- readzoom::read_zoom_chat(system.file("testdata","Zoom-chat-ex.txt",package="readzoom"))
  expect_s3_class(chat_df_full, "tbl_df")

})
