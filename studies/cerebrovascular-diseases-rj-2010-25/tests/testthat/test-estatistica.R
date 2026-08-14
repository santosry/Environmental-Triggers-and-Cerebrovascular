testthat::test_that("intervalo de Wilson contém a proporção observada", {
  interval <- wilson_interval(10, 100)
  testthat::expect_equal(interval$proportion, 0.1)
  testthat::expect_lt(interval$lower, 0.1)
  testthat::expect_gt(interval$upper, 0.1)
})

testthat::test_that("V de Cramér identifica associação perfeita", {
  contingency <- matrix(c(50, 0, 0, 50), nrow = 2)
  testthat::expect_equal(
    cramers_v(contingency, bias_corrected = FALSE), 1
  )
})

testthat::test_that("tabela esparsa aciona simulação de Monte Carlo", {
  data <- data.frame(
    grupo = c(rep("A", 20), rep("B", 2), "C"),
    obito = c(rep(FALSE, 20), TRUE, FALSE, TRUE)
  )
  result <- chi_square_association(
    data, "grupo", "obito",
    simulations = 999L, seed = 42L
  )
  testthat::expect_match(result$summary$metodo, "Monte Carlo")
  testthat::expect_equal(result$summary$simulacoes, 999L)
  testthat::expect_true(is.finite(result$summary$p_valor))
})

testthat::test_that("inclinação de Sen recupera tendência linear", {
  testthat::expect_equal(sen_slope(2010:2015, seq(0, 10, by = 2)), 2)
})

testthat::test_that("Mann-Kendall reconhece série monotônica", {
  testthat::skip_if_not_installed("Kendall")
  result <- mann_kendall_result(1:10, 1:10, "teste")
  testthat::expect_equal(result$tau, 1, tolerance = 1e-6)
  testthat::expect_lt(result$p_valor, 0.01)
  testthat::expect_equal(result$sen_slope, 1)
})
