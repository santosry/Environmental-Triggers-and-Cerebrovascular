# Protocolo de auditoria dos dados

Cada execução deve produzir: disponibilidade por arquivo/período; metadados e hash dos extratos; contagem por ano/mês; períodos ausentes; duplicidades exatas e por chaves quando disponíveis; completude; CID inválido; idade, permanência e custo impossíveis; município fora do domínio do RJ; datas inválidas; mudanças mensais abruptas; fluxo bruto–processado–filtrado; e divergência residência–ocorrência.

Alertas não são removidos silenciosamente. Uma correção automática precisa aparecer no log, ter regra documentada e ser testada. Valores extremos plausíveis permanecem nos dados e são apenas sinalizados. Duplicidades potenciais não são excluídas sem uma chave e justificativa, pois AIHs e declarações distintas podem compartilhar atributos.

O limiar inicial de quebra temporal é variação absoluta de 30% contra o período anterior. Ele serve para triagem, não demonstra mudança epidemiológica. Quebras devem ser comparadas a sazonalidade, cobertura, revisões do sistema e eventos externos.

