# RELATÓRIO EXECUTIVO — AVALIAÇÃO INTEGRADA DA FRENTE 02

**Projeto:** Vulnerabilidade climática, morbimortalidade cerebrovascular e organização da Rede de Atenção à Saúde no Rio de Janeiro (2010–2024)
**Documento:** avaliação de gestor e de cientista sobre bases, análises e adequação de uso
**Data:** 3 de outubro de 2026
**Responsável técnico:** equipe da Frente 02

---

## 1. Sumário executivo

O estudo tem um achado central sólido e auditado: **cerca de 14,95% da variação da
letalidade intra-hospitalar por doenças cerebrovasculares decorre do estabelecimento** onde
o paciente é internado (IC95% 12,29–18,06; MOR 2,065), e um quarto dessa variação é
explicado por natureza jurídica e complexidade do procedimento. A carga cresce
(94,76 → 125,97 internações/100.000) e é territorialmente desigual. As bases SIH e SIM
estão internamente consistentes e reprodutíveis.

A tentativa de medir a **capacidade instalada** (leitos, imagem, serviços) pelo CNES/SIA
por meio da API pública de Dados Abertos **não produziu dados adequados**: o extrato
disponível é descontínuo e incompleto para 2010–2024. Por decisão técnica, esses dados
**não foram usados** em nenhuma estimativa do artigo — permanecem apenas como material
exploratório, com reserva explícita.

**Recomendação de gestão:** prosseguir para a submissão com as análises auditadas,
tratar a capacidade instalada como agenda futura e reforçar o enquadramento de apoio
institucional com os indicadores já disponíveis (fluxo, concentração e funil).

---

## 2. Escopo e bases utilizadas

| Base | Fonte | Cobertura | Situação |
|---|---|---|---|
| SIH-RD/SUS | DATASUS (`microdatasus`) | 191 competências, 2010-01 a 2025-11; recorte DT_INTER 2010–2024 | **Usada** |
| SIM-DO | DATASUS (`microdatasus`) | 2010–2024 | **Usada** |
| População | IBGE/SIDRA (tabela 6579, Censo 2022, interpolação) | 92 municípios, 2010–2025 | **Usada** (12,5% interpolados) |
| IPCA | IBGE/SIDRA (tabela 1737) | 2010–2024 | **Usada** (deflação a dez/2024) |
| CNES/SIA | API de Dados Abertos/MS | extrato descontínuo | **Não usada** (incompleta) |
| Clima (temperatura, umidade, PM2,5) | INMET/VIGIAR | não analisado neste artigo | **Fora de escopo** |

---

## 3. O que está pronto e auditado

- **Coorte analítica:** 295.673 internações (I60–I69 + G45/G46), 55.827 óbitos (18,88%),
  254 estabelecimentos, 9 regiões de saúde.
- **Mortalidade:** 147.551 óbitos por I60–I69 (+60 por G45/G46 = 147.611 no recorte).
- **GLMM multinível:** VPC/ICC 14,95% (faixa defensável 14,78%–17,25%; MOR 2,065);
  18 cenários de robustez convergentes; conferência `glmmTMB` × `lme4` (diferença 0,04%).
- **Padronização etária direta:** implementada (referência Censo 2010); mantém o padrão
  e revela que a composição etária não explica o gradiente regional.
- **Auditoria:** 75 verificações aprovadas, 0 erro, 1 ressalva esperada (competência
  2025-12 ainda não publicada).
- **Repositório:** scripts numerados em `02_scripts/`, sem pasta de “legado”; recortes
  CID versionados; manuscrito e documentos de submissão **não versionados** (a pedido).

---

## 4. Avaliação de adequação (veredito)

| Componente | Veredito | Fundamento |
|---|---|---|
| SIH (internações) | **Usar** | Base completa, interna e externamente consistente; auditoria sem erro. |
| SIM (óbitos) | **Usar** | Idem; G45/G46 somam 60 óbitos e não alteram conclusões. |
| GLMM principal | **Usar** | Convergência, robustez e conferência entre motores. |
| Padronização etária | **Usar com cautela** | Usa a estrutura de 2010 como referência fixa; reportar como sensibilidade, não como série principal. |
| Custos (IPCA) | **Usar** | Totais conferidos (R$ 535,1 mi correntes; R$ 790,6 mi a dez/2024). |
| Sensibilidade a I64 | **Usar** | Cenário S8 já existente na robustez. |
| CNES/SIA (capacidade) | **Não usar** | Extrato público descontínuo: em 2024, apenas 6 CNES com leitos, 1 com equipamentos, 0 com serviços/profissionais; SIA só 2024. Números de UTI/imagem seriam artefato da incompletude. |
| Clima | **Não usar** | Não há análise no artigo; assumido como limitação. |
| Mapa coroplético | **Não usar** | Sem shapefile das regiões de saúde. |

### Por que o CNES/SIA foi descartado
A API devolve o histórico de um estabelecimento, mas o extrato disponível é esparso e
descontínuo no tempo. Exemplo da verificação: `api_cnes_equipamentos.rds` tem 2.549
registros, mas **apenas 1 CNES com competência em 2024**; `api_cnes_leitos.rds` tem
**6 CNES em 2024**; `api_cnes_servicos_especializados.rds` e `api_cnes_profissionais.rds`
não têm registro em 2024. Conclusão técnica: **não serve para quantificar capacidade**.
Também não há série 2010–2024 de CNES/SIA por essa via.

---

## 5. Decisões tomadas

1. **Manter** SIH, SIM, GLMM, custos e padronização etária (com ressalva).
2. **Retirar do manuscrito** os números de capacidade hospitalar derivados do CNES/SIA
   (leitos de UTI, tomografia, ressonância, hemodinâmica, serviço de neurologia) e
   registrar nos Métodos que o extrato foi insuficiente.
3. **Renomear** os scripts de apoio, removendo o sufixo “legado” (`16`, `17`, `18`).
4. **Preservar** o download via API (solução para o bloqueio do FTP) e os `.rds` brutos,
   como **material exploratório/futuro**, sem uso inferencial.
5. **Manter** a costura com o apoio institucional apoiada nos indicadores auditados
   (fluxo intermunicipal, concentração, funil hospitalar).

---

## 6. Riscos e mitigações

| Risco | Probabilidade | Impacto | Mitigação |
|---|---|---|---|
| Aderência ao dossiê de apoio institucional | Média | Alto | Reforço textual na Introdução/Discussão; uso de indicadores de pactuação e planejamento regional. |
| Codificação diagnóstica (I64 ≈ 56,6%) | Alta | Médio | Declarada como limitação; sensibilidade sem I64. |
| Ausência de gravidade clínica | Alta | Médio | UTI tratada como marcador de gravidade, com decomposição de Mundlak. |
| Padronização etária com estrutura de 2010 | Média | Médio | Reportada como sensibilidade. |
| Verificação anti-IA/plágio na revista | Baixa | Alto | Declaração de uso de IA; revisão humana final. |
| Manuscrito não versionado | Média | Alto | Backup datado local; recomenda-se cópia externa. |

---

## 7. Recomendações e próximos passos

**Imediatos (antes de 30/10/2026):**
1. Preencher a folha de rosto (autores, ORCID, autor correspondente) e assinar o termo.
2. Revisão ortográfica/gramatical final e conferência dos limites do edital.
3. Converter/validar os `.docx` no Word e numerar tabelas/figuras.
4. Submeter com a expressão obrigatória “SUBMISSÃO Apoio Institucional (RIO DE JANEIRO) Nº 02/2026”.

**Curto prazo (fortalecimento):**
5. Obter CNES/SIA completos por via FTP institucional ou BigQuery e, só então, medir
   capacidade instalada sem risco de viés.
6. Buscar shapefile das regiões de saúde para o mapa (previsto no plano).
7. Padronização etária ano a ano (Censo 2010 e 2022) como análise de sensibilidade.

**Médio prazo:**
8. Vincular estrutura/processo (habilitações, ensino, volume) à heterogeneidade residual.
9. Explorar reinternações e desfechos pós-alta, se houver identificador.
10. Integrar a exposição climática (frente 01/DLNM) em artigo companheiro.

---

## 8. Indicadores-chave

| Indicador | Valor |
|---|---|
| Internações (coorte) | 295.673 |
| Óbitos intra-hospitalares | 55.827 (18,88%) |
| Óbitos SIM (I60–I69 / com G45/G46) | 147.551 / 147.611 |
| Estabelecimentos / regiões | 254 / 9 |
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

O produto científico é **adequado para submissão** nas partes sustentadas por SIH, SIM e
GLMM. A base de capacidade instalada (CNES/SIA) **não é adequada** no extrato público
obtido e foi corretamente excluída das inferências. O artigo ganha robustez por assumir
essa lacuna em vez de mascará-la. A mensagem para a gestão permanece: existe variação
relevante entre hospitais, mas ela é majoritariamente sistêmica — o que pede cooperação
regional e qualificação, não punição de serviços.

> **Decisão registrada:** não usar CNES/SIA publicamente disponível para estimativas de
> capacidade; usar apenas como diagnóstico exploratório.

⬅️ [Voltar ao README](../README.md)
