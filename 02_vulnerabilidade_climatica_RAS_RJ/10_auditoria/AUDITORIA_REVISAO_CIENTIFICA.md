# AUDITORIA DE REVISÃO CIENTÍFICA (LOCK) — FRENTE 02

**Data:** 3 de outubro de 2026
**Revisor:** revisão científica sênior (epidemiologia, saúde pública e doenças cerebrovasculares)
**Backup da versão original:** `BACKUP_LOCK_2026-10-03_1651/`

---

## 1. Arquivos analisados

| Arquivo | Papel |
|---|---|
| `08_manuscrito/manuscrito.md` | **Documento principal** (artigo original) |
| `08_manuscrito/folha_de_rosto.md`, `carta_apresentacao.md`, `declaracao_etica.md`, `termo_autoria_responsabilidade.md` | Documentos de submissão |
| `README.md`, `LEIA-ME.md` | Documentação técnica do projeto |
| `07_literatura/MATRIZ_LITERATURA.md` | Matriz de referências |
| `12_relatorios/RELATORIO_EXECUTIVO_AVALIACAO.md`, `RELATORIO_FINAL.md`, `RELATORIO_EXECUTIVO_FINAL.md`, `COMPARACAO_ANALISE_ANTIGA_NOVA.md` | Relatórios |
| `04_resultados/DICIONARIO_VARIAVEIS_SIH.md` | Dicionário de variáveis |
| `10_auditoria/*.md` | Auditorias anteriores |

## 2. Volume

- **285 parágrafos** analisados no conjunto (61 no manuscrito principal).
- **25 parágrafos/segmentos modificados**, quase todos no manuscrito principal.
- Nenhuma alteração em números, efeitos, IC, p-valores ou resultados do estudo.

## 3. Principais problemas científicos encontrados

1. **Ambiguidade epidemiológica no resumo:** “295.673 internações e 147.611 óbitos” podia
   ser lida como se 147 mil tivessem morrido entre as 295 mil internações. Corrigido para
   distinguir **55.827 óbitos intra-hospitalares (SIH)** de **147.611 óbitos por causa
   básica (SIM)** nos três idiomas.
2. **DCV tratado como sinônimo de AVC.** A coorte inclui I60–I69 e G45/G46, não apenas
   AVC. A Introdução passou a usar “doenças cerebrovasculares (DCV)” para a carga e o
   estudo, reservando “AVC” para a linha de cuidado priorizada no Plano.
3. **Causalidade indevida:** verbos como “produzir”, “tende a ampliar”, “depende de”,
   “confirma” e “revelou-se” foram substituídos por “pode estar associada”, “pode
   contribuir”, “é consistente com”, “está associado” e “é compatível com”.
4. **Excesso de certeza na codificação:** “não descreve a realidade clínica e reflete a
   qualidade do registro” → “não corresponde à distribuição esperada na prática clínica e
   é consistente com limitações de codificação diagnóstica”.
5. **Generalização temporal:** “séries nacionais recentes” para a referência 9 (dados até
   2015) → “análises nacionais anteriores”.
6. **Afirmação de capacidade não medida:** a concentração de “capacidade tempo-dependente”
   foi reformulada para “a concentração de internações e o fluxo observados sugerem oferta
   especializada concentrada”, pois o estudo não mede capacidade instalada.
7. **Inventário diagnóstico G46:** “passou de 18 para 1.349 internações” podia sugerir
   mudança temporal; reformulado como comparação com uma lista parcial anterior de códigos.
8. **Transições e tópicos frasais:** inserção de conectivos (“Nesse sentido”, “Ademais”,
   “Além disso”, “Nesse contexto”, “Posto isso”, “Portanto”, “Quanto a…”).

## 4. Principais problemas de referências encontrados

1. **Referência 13 (Nilson et al.) usada para reabilitação/linha de cuidado pós-AVC** — não
   sustenta a afirmação (é sobre custos de obesidade, hipertensão e diabetes no SUS).
   Trocada para **referência 8 (Souto et al., iniquidades raciais no acesso à reabilitação
   após AVC)**, que sustenta o enunciado. A referência 13 passou a apoiar o enunciado
   sobre custos no SUS.
2. **Referências 1 e 10 usadas para “desigualdades de oferta, acesso e organização em
   rede”** — a 1 é de carga de DCV e a 10 é de códigos *garbage*. Reatribuídas: a **10**
   apoia a codificação diagnóstica e as **3 e 11** (regionalização e atenção
   especializada/transporte) apoiam as desigualdades de oferta e acesso.
3. **Referência 7 (vulnerabilidade social) na Introdução** para “concentração da oferta”:
   mantida apenas com enquadramento de planejamento e acesso no SUS, junto da 6 e da 11.

Observação: não foi criada, alterada ou inventada nenhuma referência, DOI, autor ou
número. A lista de referências (17 itens) foi preservada; apenas a **atribuição** de
algumas citações foi corrigida.

## 5. Principais alterações conceituais

- Separação explícita das duas fontes e dos dois desfechos (internação/óbito hospitalar ×
  óbito por causa básica).
- Distinção rigorosa entre **DCV** (população do estudo) e **AVC** (subconjunto e linha de
  cuidado).
- Rebaixamento do grau de certeza das afirmações de mecanismo (acesso, fluxo,
  porta-agulha, qualidade assistencial) para o terreno da associação e da hipótese.
- Registro de que a padronização etária foi aplicada **como análise de sensibilidade**,
  não como série principal.
- Ajuste dos relatórios correntes ao recorte SIM com G45/G46 (147.611; 65,68→58,38).

## 6. Afirmações que permanecem exigindo verificação documental

1. **Unidades de AVC no Rio de Janeiro:** não foi localizada fonte que enumere ou
   quantifique unidades de AVC no estado. A menção foi removida e substituída por “leitos
   de terapia intensiva”/“recursos tempo-dependentes”. Se houver dado oficial, pode ser
   reinserido com citação.
2. **Referências 6, 7 e 11 na Introdução:** sustentam o contexto geral de planejamento,
   vulnerabilidade e atenção especializada no SUS, mas **não** demonstram, isoladamente, a
   concentração do cuidado cerebrovascular no RJ. O enunciado foi redigido de forma
   compatível com essa limitação; uma referência específica sobre oferta de cuidado
   tempo-dependente no RJ fortaleceria o trecho.
3. **Relatórios históricos** (`RELATORIO_FINAL.md`, `RELATORIO_EXECUTIVO_FINAL.md`) citam
   147.551 óbitos e ISU 92,38%, referentes à série **I60–I69 apenas**. São versões
   anteriores à inclusão de G45/G46 e **não foram regerados** (o `RELATORIO_EXECUTIVO_AVALIACAO.md`,
   que é o documento corrente, foi alinhado). Recomenda-se regerar ou marcar como histórico.
4. **Custo total** depende do índice de deflação (IPCA) e da base I60–I69; declarado como
   limitação.

## 7. Pontos que um parecerista ainda pode questionar

1. **Codificação (I64 ≈ 56,6%):** limita a interpretação por subtipo; já declarado, mas
   permanece o ponto mais vulnerável.
2. **Ausência de padronização etária nas séries principais:** mitigado pela sensibilidade;
   pode ser pedido o cálculo ano a ano (Censos 2010 e 2022).
3. **UTI como covariável:** combina gravidade, capacidade e posição na rede; tratado por
   Mundlak e com faixa de ICC, mas o OR não é causal.
4. **Componente hospitalar residual (≈ três quartos):** sem variáveis de estrutura/processo
   (ensino, volume, habilitações), a explicação é limitada.
5. **Fluxo intermunicipal e “vazios assistenciais”:** descrição ecológica; não demonstra
   causalidade de acesso.
6. **Custos:** comparação intemporal sensível ao deflator; custo médio maior no Noroeste
   pode refletir casuística.
7. **Ausência de mapa:** sem shapefile, não há análise espacial formal.

## 8. Verificação final (terceira leitura)

- Números do estudo preservados e coerentes entre resumo, resultados e conclusão
  (295.673; 55.827; 147.611; 14,95%; 11,69%; 25,7%; 17,7%; 33,6%; 65,68→58,38).
- Sem travessões; citações em `<sup>` sem espaço anterior; tabelas/figuras na ordem
  Tabela 1 → Figura 1 → Tabela 2 → Tabela 3 → Figura 2.
- Todas as 17 referências citadas no texto.
- Resumos: PT 247, EN 246, ES 246 palavras.
- A ideia, o argumento e a intenção originais foram preservados; as mudanças elevaram a
  precisão e a defesa, sem alterar resultados.

## 9. Ponto que NÃO pôde ser validado

- **Não foi possível validar, em fonte documental disponível no diretório, a existência
  ou o número de unidades de AVC no Rio de Janeiro.** Por isso o termo foi removido. Todo
  o restante das afirmações numéricas foi confrontado com os resultados e as tabelas do
  próprio estudo, que constam no repositório.
