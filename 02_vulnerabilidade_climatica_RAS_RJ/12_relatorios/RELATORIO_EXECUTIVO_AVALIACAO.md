# RELATÓRIO EXECUTIVO — AVALIAÇÃO DA FRENTE 02

**Projeto:** Morbimortalidade cerebrovascular e organização da Rede de Atenção à Saúde no
Rio de Janeiro (2010–2024)
**Documento:** avaliação de gestor e de cientista sobre bases, análises e adequação de uso
**Data:** 3 de outubro de 2026

---

## 1. Sumário executivo

O estudo entrega um achado central sólido e auditado: **cerca de 14,95% da variação da
letalidade intra-hospitalar por doenças cerebrovasculares decorre do estabelecimento**
onde o paciente é internado (IC95% 12,29–18,06; MOR 2,065), e um quarto dessa variação é
explicado por natureza jurídica e complexidade do procedimento. A carga cresce
(94,76 → 125,97 internações/100.000) e é territorialmente desigual. As bases SIH e SIM
estão internas e externamente consistentes, e toda a análise é reprodutível.

A estrutura de saúde do estado é descrita **pelo próprio Plano Estadual de Saúde
2024-2027** (420 hospitais públicos e privados, 272 com leitos de UTI; 9 regiões de
saúde; apoio institucional às 9 regiões pactuado na CIB; linha de cuidado do AVC entre as
metas). Isso substitui, com fonte oficial e verificável, a tentativa de medir capacidade
por microdados administrativos.

**Recomendação de gestão:** prosseguir para a submissão com as análises auditadas e com o
enquadramento de apoio institucional ancorado no Plano Estadual.

---

## 2. Bases utilizadas

| Base | Fonte | Cobertura | Situação |
|---|---|---|---|
| SIH-RD/SUS | DATASUS (`microdatasus`) | 191 competências; DT_INTER 2010–2024 | **Usada** (acesso 3/10/2026) |
| SIM-DO | DATASUS (`microdatasus`) | 2010–2024 | **Usada** (acesso 3/10/2026) |
| População | IBGE/SIDRA (tabela 6579, Censo 2022, interpolação) | 92 municípios, 2010–2025 | **Usada** |
| IPCA | IBGE/SIDRA (tabela 1737) | 2010–2024 | **Usada** (deflação a dez/2024) |
| Plano Estadual de Saúde | SES-RJ, 2024–2027 | estrutura, RAS, governança | **Usada** (estrutura de saúde) |

---

## 3. O que está pronto e auditado

- **Coorte analítica:** 295.673 internações (I60–I69 + G45/G46), 55.827 óbitos (18,88%),
  254 estabelecimentos, 9 regiões de saúde.
- **Mortalidade:** 147.551 óbitos por I60–I69 (+60 por G45/G46 = 147.611 no recorte).
- **GLMM multinível:** VPC/ICC 14,95% (faixa defensável 14,78%–17,25%; MOR 2,065);
  18 cenários de robustez convergentes; conferência `glmmTMB` × `lme4` (diferença 0,04%).
- **Padronização etária direta** (referência Censo 2010), como sensibilidade.
- **Auditoria:** 75 verificações aprovadas, 0 erro, 1 ressalva esperada (competência
  2025-12 ainda não publicada).
- **Repositório:** scripts em `02_scripts/`, sem nomenclatura de “legado”; recortes CID
  versionados; manuscrito e documentos de submissão não versionados (a pedido).

---

## 4. Avaliação de adequação (veredito)

| Componente | Veredito | Fundamento |
|---|---|---|
| SIH (internações) | **Usar** | Base completa e consistente; auditoria sem erro. |
| SIM (óbitos) | **Usar** | Idem; G45/G46 = 60 óbitos, sem impacto nas conclusões. |
| GLMM principal | **Usar** | Convergência, robustez e conferência entre motores. |
| Padronização etária | **Usar com cautela** | Estrutura de 2010 fixa; reportar como sensibilidade. |
| Custos (IPCA) | **Usar** | Totais conferidos (R$ 535,1 mi correntes; R$ 790,6 mi a dez/2024). |
| Sensibilidade a I64 | **Usar** | Cenário S8 já existente na robustez. |
| Plano Estadual | **Usar** | Fonte oficial para estrutura de saúde, RAS e governança. |
| Microdados administrativos de capacidade | **Não usar** | Fontes públicas consultadas não oferecem painel contínuo 2010–2024; risco de viés. |
| Mapa coroplético | **Não usar** | Sem shapefile das regiões de saúde. |

---

## 5. Decisões tomadas

1. **Manter** SIH, SIM, GLMM, custos e padronização etária (com ressalva).
2. **Não usar** microdados administrativos de capacidade instalada: em vez disso, descrever
   a estrutura de saúde pelo **Plano Estadual de Saúde 2024-2027**, com indicação de página.
3. **Renomear** os scripts de apoio, removendo o sufixo “legado”.
4. **Ancorar o apoio institucional** no Plano: apoio institucional às 9 regiões pactuado na
   CIB (pág. 356), coordenação do Planejamento Regional Integrado com apoiadores regionais do
   COSEMS-RJ (pág. 364), linha de cuidado do AVC (pág. 480) e metas de leitos (pág. 461).

---

## 6. Riscos e mitigações

| Risco | Probabilidade | Impacto | Mitigação |
|---|---|---|---|
| Aderência ao dossiê de apoio institucional | Média | Alto | Ênfase na Introdução/Discussão; citações do Plano com página. |
| Codificação diagnóstica (I64 ≈ 56,6%) | Alta | Médio | Declarada como limitação; sensibilidade sem I64. |
| Ausência de gravidade clínica | Alta | Médio | UTI tratada como marcador de gravidade (Mundlak). |
| Padronização etária com estrutura de 2010 | Média | Médio | Reportada como sensibilidade. |
| Verificação anti-IA/plágio na revista | Baixa | Alto | Declaração de uso de IA; revisão humana final. |
| Manuscrito não versionado | Média | Alto | Backup datado local; recomenda-se cópia externa. |

---

## 7. Recomendações e próximos passos

**Imediatos (antes de 30/10/2026):**
1. Preencher a folha de rosto (autores, ORCID, autor correspondente) e assinar o termo.
2. Revisão ortográfica/gramatical final e conferência dos limites do edital.
3. Validar os `.docx` no Word e numerar tabelas/figuras.
4. Submeter com a expressão obrigatória “SUBMISSÃO Apoio Institucional (RIO DE JANEIRO) Nº 02/2026”.

**Curto prazo:**
5. Buscar shapefile das regiões de saúde para o mapa (previsto no plano).
6. Padronização etária ano a ano (Censos 2010 e 2022) como sensibilidade.

**Médio prazo:**
7. Vincular estrutura/processo (habilitações, ensino, volume) à heterogeneidade residual,
   caso se obtenha uma fonte contínua e validável.
8. Explorar reinternações e desfechos pós-alta, se houver identificador.

---

## 8. Indicadores-chave

| Indicador | Valor |
|---|---|
| Internações (coorte) | 295.673 |
| Óbitos intra-hospitalares | 55.827 (18,88%) |
| Óbitos SIM (I60–I69 / com G45/G46) | 147.551 / 147.611 |
| Estabelecimentos / regiões de saúde | 254 / 9 |
| Hospitais no estado (Plano, pág. 181) | 420 (272 com UTI) |
| VPC/ICC (faixa) | 14,95% (14,78%–17,25%) |
| MOR | 2,065 |
| Variância hospitalar explicada (M4) | 25,7% |
| Funil: ingênuos → ajustados | 102 → 3 (de 206) |
| AUC condicional / marginal | 0,740 / 0,690 |
| Taxa de internação 2010 → 2024 | 94,76 → 125,97/100.000 |
| Mortalidade populacional 2010 → 2024 | 65,66 → 58,33/100.000 |
| Custo (corrente / dez-2024) | R$ 535,1 mi / R$ 790,6 mi |
| ISU estadual | 92,39% |
| Auditoria | 75 OK, 0 erro |

---

## 9. Conclusão

O produto é **adequado para submissão**. O artigo assume suas lacunas (sem gravidade
clínica, sem mapa) e usa o **Plano Estadual de Saúde** como fonte oficial para estrutura e
governança — o que fortalece, e não fragiliza, o argumento de apoio institucional. A
mensagem para a gestão permanece: existe variação relevante entre hospitais, mas ela é
majoritariamente sistêmica, o que pede cooperação regional e qualificação, não punição de
serviços.

⬅️ [Voltar ao README](../README.md)
