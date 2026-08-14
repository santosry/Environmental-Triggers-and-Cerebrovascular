testthat::test_that("CID I60-I69 é incluído e G45 excluído", {
  x <- c("I60", "I63.9", "i690", "G45", "I59", "I70", NA)
  testthat::expect_equal(
    is_cerebrovascular_cid(x, sprintf("I%02d", 60:69)),
    c(TRUE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE)
  )
})
