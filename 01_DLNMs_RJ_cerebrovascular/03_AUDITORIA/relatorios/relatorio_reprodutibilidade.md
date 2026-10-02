# Relatorio metodologico de reprodutibilidade

Todos os diretorios derivados foram removidos antes da execucao.
FORCE_RAW_DOWNLOAD: TRUE
O pipeline unico executa downloads, processamento, cruzamentos, DLNM, validacao bayesiana, artigo e apresentacao.
Dados brutos originais ficam em data_raw; resultados novos ficam em data_processed e outputs, com auditorias centralizadas em 04_AUDITORIA.
A execucao falha se detectar caracteres invalidos, series climaticas duplicadas, macrorregiao sem dados ou modelo com alerta de convergencia.
