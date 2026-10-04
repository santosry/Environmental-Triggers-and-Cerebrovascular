# 00_glmm_utils.R
# Utilitários compartilhados do GLMM logístico multinível.
# Normaliza a interface entre lme4::glmer e glmmTMB::glmmTMB para que os
# scripts de análise e de robustez usem a mesma extração de resultados.
#
# Motivo do duplo motor: lme4 com 295.701 registros e 254 grupos leva de
# 30 a 60 minutos por ajuste (custo dominado pelas iterações do otimizador,
# não pelo tamanho da amostra), enquanto glmmTMB resolve o mesmo modelo em
# cerca de 2 minutos. glmmTMB e usado como motor principal e lme4 como
# verificação independente da especificacao principal.
#
# Não usar source() fora do diretório raiz do projeto.

suppressWarnings({
  library(data.table)

  ## Ajuste normalizado
  fit_glmm <- function(fml, data, engine = "glmmTMB", optimizer = NULL,
                       optArgs = NULL, rel.tol = NULL, nAGQ = 1, maxfun = 1e4) {
    t0 <- Sys.time()
    engine <- match.arg(engine, c("glmmTMB", "lme4"))

    if (engine == "glmmTMB") {
      if (!requireNamespace("glmmTMB", quietly = TRUE)) stop("glmmTMB indisponivel")
      args <- list()
      if (!is.null(optimizer)) args$optimizer <- optimizer
      if (!is.null(optArgs)) args$optArgs <- optArgs
      if (!is.null(rel.tol)) args$rel.tol <- rel.tol
      ctrl <- do.call(glmmTMB::glmmTMBControl, args)
      call_args <- list(formula = fml, data = data,
                        family = stats::binomial("logit"), control = ctrl)
      if (!identical(nAGQ, 1)) call_args$nAGQ <- nAGQ
      m <- do.call(glmmTMB::glmmTMB, call_args)
      cf <- summary(m)$coefficients$cond
      vcl <- glmmTMB::VarCorr(m)$cond
      vc <- data.table(
        grp = names(vcl),
        vcov = vapply(vcl, function(M) as.numeric(M)[1], numeric(1)))
      vc[, sd := sqrt(vcov)]
      convergiu <- (m$fit$convergence == 0)
      singular <- !isTRUE(m$sdr$pdHess)
      msg <- paste0("convergence=", m$fit$convergence,
                    "; pdHess=", isTRUE(m$sdr$pdHess))
      fed <- as.numeric(fitted(m))
      lp <- tryCatch(as.numeric(predict(m, re.form = NA)),
                     error = function(e) NULL)
      if (is.null(lp)) {
        X <- stats::model.matrix(m)
        lp <- as.numeric(X %*% glmmTMB::fixef(m)$cond)
      }
      ret <- glmmTMB::ranef(m)$cond
      re <- rbindlist(lapply(names(ret), function(g) {
        df <- ret[[g]]
        data.table(grp = g, nivel = rownames(df), u = as.numeric(df[[1]]))
      }))
      prof_parm <- "theta_1_1"
    } else {
      ctrl <- if (is.null(optimizer)) lme4::glmerControl(optCtrl = list(maxfun = maxfun))
              else lme4::glmerControl(optimizer = optimizer,
                                      optCtrl = list(maxfun = maxfun))
      m <- lme4::glmer(fml, data = data, family = stats::binomial,
                       nAGQ = nAGQ, control = ctrl)
      cf <- summary(m)$coefficients
      vcd <- as.data.frame(lme4::VarCorr(m))
      vc <- data.table(grp = vcd$grp, vcov = vcd$vcov, sd = vcd$sdcor)
      convergiu <- length(m@optinfo$conv$lme4$messages) == 0
      singular <- tryCatch(performance::is_singular(m), error = function(e) NA)
      msg <- paste(m@optinfo$conv$lme4$messages, collapse = " | ")
      fed <- as.numeric(fitted(m))
      lp <- as.numeric(predict(m, type = "link", re.form = NA))
      re <- as.data.table(lme4::ranef(m), keep.rownames = "nivel")
      setnames(re, c("grp", "nivel", "u"))
      re[, grp := "CNES"]
      prof_parm <- ".sig01"
    }

    beta <- cf[, 1]; se <- cf[, 2]
    list(
      modelo = m, engine = engine, convergiu = convergiu, singular = singular,
      mensagem = msg, logLik = as.numeric(logLik(m)), AIC = as.numeric(AIC(m)),
      n = nrow(data), tempo_min = as.numeric(difftime(Sys.time(), t0, units = "mins")),
      coef = data.table(termo = rownames(cf), beta = beta, ep = se,
                        z = cf[, 3], p = cf[, 4],
                        or = exp(beta), lo = exp(beta - 1.96 * se),
                        hi = exp(beta + 1.96 * se)),
      vc = vc, fitted = fed, lp_marg = lp, ranef = re, prof_parm = prof_parm)
  }

  ## VPC/ICC e MOR a partir da variância do intercepto aleatório
  icc_mor <- function(s2) {
    icc <- s2 / (s2 + pi^2 / 3)
    mor <- exp(sqrt(2 * s2) * qnorm(0.75))
    list(icc = icc, mor = mor)
  }

  ## IC95% do desvio-padrão do intercepto aleatório
  ##   glmmTMB: IC de Wald, linha "Std.Dev.(Intercept)|<grupo>" de confint(method="wald")
  ##   lme4:    verossimilhança de perfil sobre .sig01 (lento, usado só na conferência)
  varcov_ci <- function(fit, grp = "CNES", lme4_parm = ".sig01") {
    if (fit$engine == "glmmTMB") {
      out <- tryCatch({
        ci <- stats::confint(fit$modelo, method = "wald")
        rn <- rownames(ci)
        i <- which(grepl("^Std\\.Dev", rn) & grepl(grp, rn, fixed = TRUE))
        if (!length(i)) i <- which(grepl("^Std\\.Dev", rn))
        if (!length(i)) return(NULL)
        as.numeric(ci[i[1], 1:2])
      }, error = function(e) NULL)
      if (is.null(out)) return(NULL)
      return(sort(abs(out)))
    }
    out <- tryCatch(
      as.numeric(stats::confint(fit$modelo, parm = lme4_parm, method = "profile")),
      error = function(e) NULL)
    if (is.null(out)) NULL else sort(abs(out))
  }

  ## Calibração: Hosmer-Lemeshow em decis de risco
  hosmer_lemeshow <- function(y, p, g = 10) {
    br <- unique(stats::quantile(p, probs = seq(0, 1, length.out = g + 1)))
    grp <- cut(p, breaks = br, include.lowest = TRUE, labels = FALSE)
    dt <- data.table(y = y, p = p, g = grp)[
      , .(n = .N, obs = sum(y), esp = sum(p), pbar = mean(p)), by = g][order(g)]
    stat <- sum((dt$obs - dt$esp)^2 / (dt$n * dt$pbar * (1 - dt$pbar)))
    gl <- nrow(dt) - 2
    list(tab = dt, stat = stat, gl = gl, p = 1 - stats::pchisq(stat, gl))
  }

  ## Formatacao de p em notacao cientifica (regra do Bloco 3)
  p_cient <- function(p) {
    ifelse(is.na(p), "NA",
           ifelse(p < 1e-3, formatC(p, format = "e", digits = 2),
                  formatC(p, format = "f", digits = 4)))
  }
})
