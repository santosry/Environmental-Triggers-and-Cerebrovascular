testthat::test_that("intervalo de anos é validado", {
  testthat::expect_equal(validate_year_range(2010, 2012, upper = 2025), 2010:2012)
  testthat::expect_error(validate_year_range(2025, 2010, upper = 2025))
})

testthat::test_that("municípios do RJ são padronizados", {
  testthat::expect_equal(normalize_municipality_code(c("3304557", "330170")), c("330455", "330170"))
  testthat::expect_true(all(validate_municipality_code(c("330455", "3301707"))))
  testthat::expect_false(validate_municipality_code("355030"))
})

testthat::test_that("duplicidades exatas e potenciais são detectadas", {
  x <- data.frame(id = c(1, 1, 2), value = c("a", "b", "c"))
  flags <- duplicate_flags(x, "id")
  testthat::expect_equal(sum(flags$exact), 0)
  testthat::expect_equal(sum(flags$potential), 2)
})
