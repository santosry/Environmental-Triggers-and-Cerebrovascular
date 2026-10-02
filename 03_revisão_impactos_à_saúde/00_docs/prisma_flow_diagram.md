# Diagrama de fluxo PRISMA 2020

**Referência:** Page MJ, et al. The PRISMA 2020 statement. *BMJ*. 2021;372:n71.
doi:10.1136/bmj.n71 (Figura 1 — modelo revisado do fluxo).
**Implementação:** `01_scripts/00_pipeline_revisao_sistematica.R (seção 18)` com o pacote `PRISMA2020`
(Haddaway NR, et al. *Campbell Syst Rev*. 2022;18(2):e1230. doi:10.1002/cl2.1230).

## Estrutura do fluxo (três níveis)

```
IDENTIFICATION
  Registros identificados em bases/registros (n = ...)
    - PubMed/MEDLINE    (n = ...)
    - Scopus            (n = ...)
  Registros identificados em outras fontes (literatura cinzenta, citações) (n = ...)

SCREENING
  Registros após remoção de duplicatas (n = ...)
  Registros triados por título/abstrato (n = ...)
  Registros excluídos (n = ...)
  Relatórios buscados para recuperação (n = ...)
  Relatórios não recuperados (n = ...)
  Relatórios avaliados para elegibilidade (n = ...)
  Relatórios excluídos, com motivos (n = ...)

INCLUDED
  Estudos incluídos na síntese (n = ...)
  Relatórios dos estudos incluídos (n = ...)
```

## Contagens de identificação

As contagens por base são geradas automaticamente pela busca e salvas em
`03_resultados/tabelas/prisma_identificacao.csv`. O arquivo consolidado de contagens
para o diagrama é `03_resultados/tabelas/prisma_contagens.csv`.

| Base | Registros |
|---|---|
| PubMed/MEDLINE | 5.093 |
| Scopus | 13.908 |
| SciELO | 26 |
| **Total identificado** | **19.027** |
| **Duplicatas removidas** | 3.505 |
| **Após deduplicação (triagem)** | **14.978** |

## Motivos de exclusão (texto completo)

Devem ser tabulados com frequência (PRISMA 2020, item 16b):
1. População não humana / sem dados humanos.
2. Exposição não ambiental.
3. Desfecho sem CID-10 I60–I69.
4. Delineamento inelegível (revisão, resumo, editorial).
5. Fora do período (2020–2026).
6. Idioma não elegível.
7. Sem medida de associação quantitativa.
8. População sobreposta/duplicata.
9. Qualidade criticamente baixa.

## Geração do diagrama

```bash
# rode com EXEC$prisma = TRUE (seção 18 do script único)
Rscript 01_scripts/00_pipeline_revisao_sistematica.R
```

Saídas:
- `03_resultados/figuras/prisma_flow_diagram.png`
- (alternativa) `03_resultados/figuras/prisma_flow_diagram.html`

> Se `PRISMA_save()` não puder exportar (ausência de webshot2/chromium), o script salva
> o widget em HTML; a conversão para PNG pode ser feita com
> `webshot2::webshot()` ou manualmente.
