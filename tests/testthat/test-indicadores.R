testthat::test_that("taxas usam denominador válido", {
  testthat::expect_equal(safe_rate(10, 10000), 100)
  testthat::expect_true(is.na(safe_rate(10, 0)))
  testthat::expect_true(is.na(safe_rate(10, NA)))
})

testthat::test_that("totais do filtro são consistentes", {
  x <- data.frame(cid = c("I60", "I63.9", "G45", "I70"))
  y <- filter_cerebrovascular(x, "cid", sprintf("I%02d", 60:69))
  flow <- compare_stage_totals(raw = x, filtered = y)
  testthat::expect_equal(flow$n, c(4L, 2L))
  testthat::expect_equal(flow$excluded_from_previous[2], 2L)
})

testthat::test_that("taxa estadual inclui municípios sem evento", {
  population <- data.frame(
    ano = c(2020L, 2020L), municipio = c("330001", "330002"),
    populacao = c(1000, 3000)
  )
  events <- data.frame(
    ano = 2020L, municipio = "330001", internacoes = 4L
  )
  municipal <- complete_population_rates(
    events, population,
    count = "internacoes"
  )
  state <- state_rates(municipal, "internacoes")
  testthat::expect_equal(nrow(municipal), 2L)
  testthat::expect_equal(sum(municipal$internacoes), 4L)
  testthat::expect_equal(state$populacao, 4000)
  testthat::expect_equal(state$taxa_100mil, 100)
})

testthat::test_that("interpolação populacional calcula o ponto intermediário", {
  population <- data.frame(
    municipio = c("330001", "330002", "330001", "330002"),
    nome_municipio = c("A", "B", "A", "B"),
    ano = c(2022L, 2022L, 2024L, 2024L),
    populacao = c(1000, 2000, 1200, 1800),
    fonte = "teste", metodo = "teste"
  )
  result <- interpolate_population_year(population, 2022L, 2024L, 2023L)
  testthat::expect_equal(result$populacao, c(1100L, 1900L))
  testthat::expect_true(all(result$ano == 2023L))
  testthat::expect_true(all(result$metodo == "interpolacao_linear_2022_2024"))
})
