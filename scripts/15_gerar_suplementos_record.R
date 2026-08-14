source("scripts/_bootstrap.R", encoding = "UTF-8")

aggregate_flow <- function(pattern) {
  files <- list.files(
    project_path("results", "audits"),
    pattern = pattern,
    full.names = TRUE
  )
  if (!length(files)) stop("Fluxos ausentes para: ", pattern)
  rows <- do.call(rbind, lapply(files, utils::read.csv))
  totals <- stats::aggregate(n ~ stage, rows, sum)
  stats::setNames(totals$n, totals$stage)
}

make_flow <- function(system, totals, residents, mapped) {
  labels <- c(
    "Registros extraídos da base",
    "Registros após processamento",
    "CID-10 I60-I69 no campo principal",
    "Residentes no estado do Rio de Janeiro",
    "População principal nas análises estaduais",
    "Subconjunto com município válido para análises geográficas"
  )
  values <- c(
    totals[["raw"]], totals[["processed"]], totals[["cid_i60_i69"]],
    residents, residents, mapped
  )
  data.frame(
    sistema = system,
    etapa = seq_along(labels),
    descricao = labels,
    n = as.integer(values),
    excluidos_desde_etapa_anterior = c(NA_integer_, -diff(values)),
    stringsAsFactors = FALSE
  )
}

sih_totals <- aggregate_flow("^sih_.*_flow[.]csv$")
sim_totals <- aggregate_flow("^sim_.*_flow[.]csv$")

sih_residence <- utils::read.csv(
  project_path("results", "audits", "sih_residencia_internacao.csv")
)
sih_residents <- sum(
  sih_residence$Freq[as.logical(sih_residence$residente_rj)],
  na.rm = TRUE
)
sih_geography <- utils::read.csv(
  project_path("results", "tables", "distribuicao_sih_nome_municipio.csv")
)
sim_geography <- utils::read.csv(
  project_path("results", "tables", "distribuicao_sim_nome_municipio.csv")
)
sih_mapped <- sum(
  sih_geography$n[
    !is.na(sih_geography$nome_municipio) &
      sih_geography$nome_municipio != "Ignorado/ausente"
  ],
  na.rm = TRUE
)
sim_mapped <- sum(
  sim_geography$n[
    !is.na(sim_geography$nome_municipio) &
      sim_geography$nome_municipio != "Ignorado/ausente"
  ],
  na.rm = TRUE
)

flow_sih <- make_flow("SIH/SUS", sih_totals, sih_residents, sih_mapped)
flow_sim <- make_flow(
  "SIM", sim_totals, sim_totals[["cid_i60_i69"]], sim_mapped
)
flow <- rbind(flow_sih, flow_sim)

write_csv_safe(
  flow_sih,
  project_path("results", "audits", "fluxo_record_sih.csv")
)
write_csv_safe(
  flow_sim,
  project_path("results", "audits", "fluxo_record_sim.csv")
)

if (requireNamespace("ggplot2", quietly = TRUE)) {
  flow$y <- ave(flow$etapa, flow$sistema, FUN = function(x) max(x) - x + 1)
  flow$rotulo <- paste0(flow$descricao, "\nn = ", format(
    flow$n, big.mark = ".", decimal.mark = ",", scientific = FALSE
  ))
  arrows <- flow[flow$etapa < max(flow$etapa), ]
  figure <- ggplot2::ggplot(flow, ggplot2::aes(x = 1, y = y)) +
    ggplot2::geom_segment(
      data = arrows,
      ggplot2::aes(x = 1, xend = 1, y = y - 0.36, yend = y - 0.78),
      arrow = grid::arrow(length = grid::unit(0.12, "inches")),
      colour = "#555555",
      linewidth = 0.45
    ) +
    ggplot2::geom_label(
      ggplot2::aes(label = rotulo),
      size = 3.1,
      linewidth = 0.3,
      label.padding = grid::unit(0.18, "lines"),
      fill = "white",
      colour = "#111111"
    ) +
    ggplot2::facet_wrap(~sistema, nrow = 1) +
    ggplot2::coord_cartesian(xlim = c(0.4, 1.6), clip = "off") +
    ggplot2::theme_void(base_family = "sans") +
    ggplot2::theme(
      strip.text = ggplot2::element_text(face = "bold", size = 11),
      plot.margin = ggplot2::margin(8, 8, 8, 8)
    )
  ggplot2::ggsave(
    project_path("results", "figures", "fluxo_selecao_record.png"),
    figure,
    width = 8.5,
    height = 7,
    dpi = 300,
    bg = "white"
  )
}

record_audit <- data.frame(
  item = c(
    "1.1", "1.2", "1.3", "6.1", "6.2", "6.3", "7.1",
    "12.1", "12.2", "12.3", "13.1", "19.1", "22.1"
  ),
  status = c(
    "Atendido", "Atendido", "Não aplicável", "Atendido", "Atendido",
    "Não aplicável", "Atendido", "Atendido", "Atendido",
    "Não aplicável", "Atendido", "Atendido", "Atendido"
  ),
  evidencia = c(
    "Título e resumo nomeiam dados administrativos SIH/SUS e registros SIM.",
    "Título e resumo informam Rio de Janeiro e períodos específicos por sistema.",
    "Não houve ligação entre bases; fontes analisadas independentemente.",
    "Métodos e suplemento descrevem seleção, campos e códigos por sistema.",
    "Validações publicadas são citadas; ausência de validação clínica local é declarada.",
    "Não houve ligação entre bases.",
    "Suplemento fornece códigos, campos e algoritmos completos.",
    "Métodos descrevem acesso integral aos arquivos públicos selecionados.",
    "Métodos e protocolo de auditoria descrevem limpeza e controle de cardinalidade.",
    "Não houve ligação entre bases.",
    "Fluxos separados apresentam contagens e exclusões de SIH e SIM.",
    "Discussão cobre finalidade administrativa, classificação, ausentes, confundimento e mudanças temporais.",
    "Seção de disponibilidade indica protocolo, código, suplementos e reconstrução dos dados."
  ),
  stringsAsFactors = FALSE
)
write_csv_safe(
  record_audit,
  project_path("results", "audits", "checklist_record_preenchido.csv")
)

stopifnot(
  sih_totals[["raw"]] == sih_totals[["processed"]],
  sim_totals[["raw"]] == sim_totals[["processed"]],
  sih_mapped == sih_residents,
  sim_mapped <= sim_totals[["cid_i60_i69"]],
  nrow(record_audit) == 13L
)

log_event(
  "INFO",
  "record_supplements_complete",
  "Fluxos e checklist RECORD gerados",
  list(sih = sih_mapped, sim = sim_mapped)
)
record_session_info(
  project_path("results", "logs", "record-session-info.txt")
)
