testthat::test_that("processamento SIM preserva uma linha por declaração", {
  raw <- data.frame(
    NATURAL = c("44", "44"),
    DTOBITO = c("01012020", "02012020"),
    IDADE = c("450", "460"),
    CAUSABAS = c("I64", "I63"),
    CODMUNRES = c("3304557", "3304557"),
    CODMUNOCOR = c("3304557", "3304557"),
    stringsAsFactors = FALSE
  )
  processed <- process_sim_extract(raw)
  testthat::expect_equal(nrow(processed), nrow(raw))
  testthat::expect_identical(processed$NATURAL, raw$NATURAL)
  testthat::expect_equal(processed$causa_basica, c("I64", "I63"))
})
