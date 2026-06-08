# SPEC-002 — Schema de Metadados nas Regions

## Objetivo
Padronizar como metadados (como tipo de seção, propriedades de loop e pulos) são embutidos no nome das Regions nativas do REAPER.

## Requisitos
* O nome da Region deve usar o formato `SECTION_NAME|key=value|key=value`.
* O primeiro token (antes do primeiro `|`) é o nome da seção e é obrigatório.
* O parser deve ignorar espaços no início e fim.

## Entradas
* String do nome da Region (ex: `VERSE_1|loop=0|next=CHORUS_1`).

## Saídas
* Objeto Lua com `{ valid, id, name, meta, warnings }`.

## Regras
* Nomes vazios de Region a tornam inválida.
* `loop` aceita "0", "1", "inf" (default: "0").
* `jump_quant` aceita "immediate", "bar", "section_end" (default: "bar").
* `allow_prev` aceita "0", "1" (default: "1").
* Valores não permitidos para os campos acima geram warning e revertem para o valor default.
* Campos desconhecidos geram warning e são ignorados.
* Tokens subsequentes ao nome que não tenham `=` geram warning e são ignorados.

## Riscos
* Caracteres especiais (ex. `|` extra ou no nome da seção) podem gerar quebras no parser simples.

## Critérios de Aceite
* O parser retorna a tabela estruturada com os defaults corretos, não sofre crash e lista os `warnings` apropriadamente.

## Testes Mínimos
* Parse de `"INTRO"`.
* Parse de campos inválidos testando fallback para defaults.
* Parse de campos desconhecidos.
* Nomes vazios ou começando com `|`.
