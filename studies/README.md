# Etapas do estudo

Este repositório documenta o **ciclo completo** de um único estudo sobre doenças
cerebrovasculares no estado do Rio de Janeiro (2010–2025), organizado em duas etapas
que se complementam.

> **Importante:** `studies/cerebrovascular-diseases-rj-2010-25/` **não** é um estudo
> paralelo. É a **etapa anterior** deste mesmo estudo — a base descritiva sobre a qual
> a modelagem DLNM/GAM (na raiz deste repositório) foi construída.

## Etapas

| Etapa | Diretório | Foco | Método |
|---|---|---|---|
| 1 — anterior (descritiva) | `studies/cerebrovascular-diseases-rj-2010-25/` | Epidemiologia descritiva da morbimortalidade por AVC (I60–I69) via SIH/SIM | Indicadores, séries temporais, estatística descritiva |
| 2 — atual (modelagem) | `./` (raiz) | Associação defasada e não linear entre temperatura/umidade e internações/óbitos (I60–I64) | DLNM + Bayesiano hierárquico |

A **Etapa 1** produziu a base de desfechos, o dicionário de variáveis, as definições de CID
(I60–I69), os fluxos de dados e os indicadores descritivos que fundamentam a **Etapa 2**
(a modelagem DLNM/GAM na raiz).

## Proveniência da Etapa 1 (estudo descritivo)

- Repositório de origem: <https://github.com/santosry/cerebrovascular-diseases-rj-2010-25>
- Branch importada: `main`
- Commit importado: `175173a8a85b0b78477998b9f2c4fe26be1a9a29`
- Tag de origem: `data-lock-2026-07-17` (congelamento da base analítica e resultados)
- Mecanismo de importação:
  `git subtree add --squash --prefix=studies/cerebrovascular-diseases-rj-2010-25`

O histórico completo da Etapa 1 permanece disponível no repositório de origem. Neste
compêndio, a importação foi condensada em um único commit (com referência ao commit de
origem) para manter o histórico do compêndio limpo e navegável.

## Como executar

Cada etapa é **autônoma** — possui o próprio `renv.lock`, `R/`, `config/`, `data-raw/`,
`scripts/` (ou pipeline) e `README.md`:

- **Etapa 2 (raiz):** consulte o `README.md` na raiz deste repositório.
- **Etapa 1 (descritiva):** consulte `studies/cerebrovascular-diseases-rj-2010-25/README.md`.

> **Nota de CI:** o arquivo `studies/cerebrovascular-diseases-rj-2010-25/.github/workflows/r-check.yaml`
> é mantido por fidelidade à origem. O GitHub Actions só executa workflows localizados em
> `.github/workflows/` na **raiz** do repositório; portanto, esse workflow aninhado fica inativo
> por padrão (o CI deste compêndio é o `.github/workflows/ci.yml` da raiz).
