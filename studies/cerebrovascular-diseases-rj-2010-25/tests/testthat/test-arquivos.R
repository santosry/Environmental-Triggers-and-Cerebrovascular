testthat::test_that("nomes de extratos seguem padrão", {
  sih <- sprintf("sih_rd_rj_%04d_%02d_raw.rds", 2024, 1)
  sim <- sprintf("sim_do_rj_%04d_%s_raw.rds", 2024, "definitivo")
  testthat::expect_match(sih, "^sih_rd_rj_[0-9]{4}_[0-9]{2}_raw[.]rds$")
  testthat::expect_match(sim, "^sim_do_rj_[0-9]{4}_(definitivo|preliminar)_raw[.]rds$")
})
