# AUDITORIA METODOLÓGICA

Revisão crítica dos métodos do estudo-base e plano metodológico da nova fase.

---

## 1. Métodos do estudo-base (conforme artigo)

| Componente | Descrito no artigo | Avaliação |
|---|---|---|
| Desenho | Ecológico de séries temporais, retrospectivo | Adequado |
| Período | 2010–2024 (mas resultados citam 2025) | **Inconsistente** |
| Fonte | SIH-RD via microdatasus | Adequado (não usou SIM) |
| Critério de inclusão | DIAG_PRINC I60–I69, residentes RJ | Adequado |
| Unidade | Município → 9 regiões → 3 macrorregiões | Adequado |
| Denominador | SIDRA 6579 (2010 interpolado; 2022–2024 = proxy 2021) | **Frágil** |
| Tendência | Mann-Kendall | Adequado |
| Proporção de óbito | Cochran-Armitage | Adequado |
| Diferenças regionais | Kruskal-Wallis + Dunn (Bonferroni) | Adequado |
| Associações | qui-quadrado + Monte Carlo | Adequado |
| Padronização etária | **não feita** | Limitação |

---

## 2. Testes estatísticos — adequação e premissas

| Teste | Premissa | Compatibilidade com os dados | Veredito |
|---|---|---|---|
| Mann-Kendall | série sem normalidade; detecta tendência monótona | Taxas anuais (n=15) | Adequado |
| Kruskal-Wallis | independência; mesma forma de distribuição | Custos/permanência por região | Adequado |
| Dunn pós-hoc | múltiplas comparações | 3–9 grupos | Adequado (Bonferroni conservador) |
| qui-quadrado | frequências esperadas ≥5 | tabelas categóricas | Adequado; Monte Carlo quando células <5 |
| Cochran-Armitage | tendência em proporção binária ordenada | proporção de óbito por ano | Adequado |

**Ampliações avaliadas (apenas se justificável):**

| Método | Justificativa potencial | Decisão |
|---|---|---|
| Spearman | correlação entre indicadores regionais | Avaliar |
| Regressão binomial negativa | contagens com sobredispersão (internações por região/ano) | Avaliar |
| Regressão logística | mortalidade hospitalar (fatores associados) | Avaliar |
| Modelos de permanência/custo | distribuição assimétrica (gamma/log-normal) | Avaliar |
| Joinpoint | mudança de tendência temporal | Avaliar |
| Moran global / LISA | autocorrelação espacial entre regiões | Avaliar (9 unidades — baixo poder) |

**Princípio:** não introduzir complexidade sem suporte; priorizar interpretabilidade para
gestão.

---

## 3. Reposicionamento para o marco de gestão

A nova fase conecta (sem afirmar causalidade):

```
exposição ambiental (temperatura, umidade, PM2,5)
        ↓ (compatibilidade espacial/temporal)
carga cerebrovascular (internação SIH + óbito SIM)
        ↓
desfechos assistenciais (permanência, custo, mortalidade)
        ↓
território (região de saúde, macrorregião, fluxo residência→internação, CNES)
        ↓
evidência para regionalização / planejamento / RAS / vigilância territorializada
```

---

## 4. Vulnerabilidade — decisão

- **Não** construir índice composto automaticamente.
- Investigar se os dados sustentam um indicador multidimensional (exposição, carga,
  mortalidade, estrutura assistencial, acesso/fluxos).
- Se construído: documentar variáveis, normalização, pesos, agregação, sensibilidade e
  limitações. Se não houver sustentação, apresentar a vulnerabilidade como fenômeno
  multidimensional descritivo (sem índice único).

---

## 5. Ética e transparência

- Dados secundários, agregados e anonimizados de domínio público (SIH/SIM).
- **CNS 510/2016** dispensa apreciação por CEP (reavaliada para a inclusão do SIM —
  permanece aplicável, pois o SIM é igualmente banco público anonimizado).
- LGPD: dados sem identificação pessoal.
- **Remover declaração de uso de IA** da nova versão (incompatível com o edital-alvo),
  salvo exigência da revista.
