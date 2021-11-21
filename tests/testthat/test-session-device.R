

test_that("is_overlap() works",{

  start1 <- c(1, 1.5, 4)
  end1 <- c(2, 3, 5)

  # Give Only 1 range return FALSE
  expect_identical(is_overlap(1, 2), FALSE)
  # 2 Pairs
  expect_identical(is_overlap(c(1,3),c(2,4)), c(FALSE, FALSE))
  expect_identical(is_overlap(c(1,2),c(3,4)), c(TRUE, TRUE))
  expect_identical(is_overlap(c(1,3),c(3,4)), c(FALSE, FALSE)) # Exclusively
  # 3 Pairs
  expect_identical(is_overlap(start1, end1),c(TRUE, TRUE, FALSE))
  expect_identical(is_overlap(rev(start1), rev(end1)),c(FALSE, TRUE, TRUE)) # Reverse Order

})
