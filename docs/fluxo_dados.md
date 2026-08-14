# Fluxo de processamento

```mermaid
flowchart TD
  A["Consultar disponibilidade DATASUS"] --> B["Baixar extrato bruto com microdatasus"]
  B --> C["Salvar RDS bruto, hash e metadados"]
  C --> D["Processar com process_sih ou process_sim"]
  D --> E["Criar aliases e validar esquema"]
  E --> F["Filtrar CID-10 I60-I69"]
  F --> G["Auditar bruto, processado e filtrado"]
  G --> H["Agregar cada sistema separadamente"]
  H --> I["Empilhar séries em formato longo para visualização"]
  I --> J["Calcular indicadores sem denominador"]
  K["População compatível e validada"] --> L{"Chaves completas?"}
  L -->|Sim| M["Calcular taxas"]
  L -->|Não| N["Bloquear taxa e registrar lacuna"]
  J --> O["Tabelas, figuras e relatório"]
  M --> O
```

SIH e SIM são fontes independentes. Não há pareamento, junção ou correlação entre
registros ou agregados dos dois sistemas. Quando aparecem na mesma tabela longa
ou figura, as séries são apenas empilhadas e identificadas pelo campo `sistema`.
