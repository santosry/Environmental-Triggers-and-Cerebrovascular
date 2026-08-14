testthat::test_that("tentativas reexecutam a operação até sucesso", {
  calls <- 0L
  operation <- function() {
    calls <<- calls + 1L
    if (calls < 3L) stop("falha transitória")
    "ok"
  }
  testthat::expect_equal(
    suppressMessages(with_retries(operation, attempts = 3L, wait_seconds = 0)),
    "ok"
  )
  testthat::expect_equal(calls, 3L)
})
