# SPEC-003 — Motor de Leitura de Regions

## Objetivo
Ler e mapear todas as regions de um `.RPP` para a memória (State Engine) de maneira eficiente e segura, separando as seções válidas das inválidas.

## Requisitos
* Deve processar uma lista de regions brutas obtidas do REAPER e repassá-las ao `regions.parse_region_name`.
* Deve montar arrays separados para `sections` (válidas), `invalid` e `warnings`.

## Entradas
* Tabela de Regions brutas fornecidas pelo adapter em `project.lua`, que consome os dados do `reaper.EnumProjectMarkers`. Formato `{ name, start_pos, end_pos, index }`.

## Saídas
* Tabela Lua `{ sections = {}, invalid = {}, warnings = {} }`. `sections` ordenada por `start_pos`.

## Testabilidade Offline
* A integração com o REAPER na coleta real das Regions (API calls via `project.lua`) possui mock das funções em nível global `_G.reaper` para garantir a testabilidade fora da DAW.

## Regras
* Regions válidas devem conter a metadata normalizada, copiando também `start_pos`, `end_pos` e `index` originais.
* Regions com nome vazio caem no array `invalid` e geram warning.

## Riscos
* Ordenação instável se `start_pos` não estiver presente ou for idêntico.

## Critérios de Aceite
* Validar que as seções válidas estão ordenadas no tempo cronológico em `sections`.
* Separar corretamente as problemáticas em `invalid`.

## Testes Mínimos
* Varrer array vazio (retorna tabelas vazias).
* Varrer array misto de válidas e inválidas.
* Varrer array e checar se `sections` foi ordenado corretamente por `start_pos`.
