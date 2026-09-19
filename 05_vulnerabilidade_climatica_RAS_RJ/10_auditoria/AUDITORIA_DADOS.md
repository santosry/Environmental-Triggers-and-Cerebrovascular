# AUDITORIA DE DADOS

Auditoria da camada de dados do estudo-base e das decisões de reanálise da nova fase.

---

## 1. Fontes e formatos

| Base | Sistema | Origem | Arquivos | Esquema |
|---|---|---|---|---|
| SIH-RD | Internações hospitalares SUS | microdatasus (R) | 192 `.rds` mensais (2010–2025) | 87 (2010) → 96 (2013) → 114 (2024) colunas |
| SIM | Óbitos (causa básica) | microdatasus (R) | 15 `.rds` anuais (2010–2024) + 96 mensais (2017–2024) | 60 colunas |
| População | IBGE/SIDRA tabela 6579 | — | CSV derivado | — |

**Regra de uso:** arquivos SIH mensais 2010–2025 (para capturar internações de dez/2024
com alta em 2025); arquivos SIM anuais 2010–2024 (a série mensal 2017–2024 é redundante
com a anual — usada apenas a anual para evitar dupla contagem).

---

## 2. Problemas de codificação detectados (e solução)

1. **Campos de texto livre fora do UTF-8** (SIH a partir de 2013): bytes como `0xA8`
   aparecem em campos de justificativa (ex.: "LIBERA…O", "N…O POSSUI CNS"). São campos
   de texto livre (AUD_JUST, SIS_JUST, CID_NOTIF etc.) **não utilizados nas análises
   principais**. Solução: leitura via `rdata` com `default_encoding="latin-1"` e
   `force_default_encoding=True`; os campos numéricos/códigos (CID, sexo, município,
   raça/cor, caráter, custo, permanência) são ASCII e não são afetados.

2. **R indisponível para leitura**: `readRDS` (R 4.6.1) apresenta falha de segmentação
   (segfault) em qualquer operação de serialização. Impossível reexecutar o
   `fetch_datasus` do microdatasus no ambiente. Usados os `.rds` pré-empacotados do
   compêndio (que são a saída do microdatasus), lidos via Python.

---

## 3. Erros de período e denominador (auditados)

| Item | Estudo-base | Auditoria | Decisão |
|---|---|---|---|
| Período declarado | 2010–2024 | Resultados citam "2025" (123,38/100k; 14% óbito; 232,56/100k) | **Corrigir: usar apenas 2010–2024** |
| Internações | 269.751 | Recontagem a partir do bruto | Em execução |
| População 2010 | interpolada 2009–2011 | Denominador impreciso | Documentar limitação; usar IBGE quando disponível |
| População 2022–2024 | replicada de 2021 | Ausência de projeção pós-Censo | Documentar limitação |

---

## 4. Duplicidade

- SIH mensal contém **sobreposição administrativa** (mesma AIH em mais de um arquivo
  mensal). Deduplicação por chave `N_AIH + IDENT + DT_INTER + DT_SAIDA + DIAG_PRINC +
  MUNIC_RES + SEXO + IDADE`, mantendo a primeira ocorrência.
- O estudo DLNM anterior documentou 29.564 duplicatas (10,3%) removidas no subconjunto
  I60–I69 2010–2025. A nova fase recalcula para o período 2010–2024.

---

## 5. Variáveis críticas para a interpretação

| Variável | Completude observada | Cautela |
|---|---|---|
| `INSTRU` (escolaridade SIH) | ~99,6% com valor `0` (sem instrução/não informado) | Excluir de inferência; documentar |
| `RACA_COR` (SIH) | ~25% "sem informação/ignorado" (a confirmar) | Não inferir desigualdade sem cautela |
| `IDADE` SIM | formato DATASUS 3 dígitos (4xx=anos, 3xx=meses, 2xx=horas, 1xx=minutos) | Conversão correta aplicada |
| `MORTE` (SIH) | 0/1 | Óbito hospitalar ≠ óbito por causa básica (SIM) |
| `VAL_TOT` (custo) | reais correntes | Deflacionar (IPCA) para comparar anos |

---

## 6. Diferenças SIH × SIM (não misturar)

- **Óbito hospitalar (SIH, `MORTE`)** = óbito ocorrido durante a internação por DCV.
- **Óbito por DCV (SIM, `CAUSABAS` I60–I69)** = causa básica de morte na população,
  incluindo óbitos fora do hospital (domicílio, via pública) e óbitos hospitalares.
- As duas medidas capturam construtos distintos e serão apresentadas **separadamente**,
  com integração apenas para indicadores explicitamente definidos (ex.: razão
  óbitos/internações por região).
