
# Read Full & Abbreviated
chat_df_full <- zoomclass::read_zoom_chat(zoomclass_example("zoom-chat-2.txt"))
chat_df_abbr <- zoomclass::read_zoom_chat(zoomclass_example("zoom-chat-1.txt"))


# read_zoom_chat ----------------------------------------------------------

test_that("read_zoom_chat() is working",{

  expect_s3_class(chat_df_full, "zoom_chat")
  expect_s3_class(chat_df_abbr, "zoom_chat")

})

test_that("read_zoom_chat() column names OK",{

  expect_named(chat_df_full, c("Time", "Name", "Target", "Content"))
  expect_named(chat_df_abbr, c("Time", "Name", "Content"))


})
