# SPEC-002 — Schema de Metadados nas Regions

## Objetivo
Padronizar como metadados (como tipo de seção, energia) são embutidos no nome das Regions nativas do REAPER.

## Requisitos
* O nome da Region deve conter o nome da seção.
* (Opcional no MVP) Tags em colchetes ou chaves para metadados (ex: `[Chorus]`, `[V1]`).

## Entradas
* String do nome da Region.

## Saídas
* Objeto Lua com `{ name, type, start_pos, end_pos }`.

## Regras
* Nomes vazios de Region geram uma seção com nome "Untitled_X".
* Regions devem ter um start e end válidos.

## Riscos
* Caracteres especiais que quebrem o parser de texto Lua.

## Critérios de Aceite
* O Parser extrai corretamente strings simples.

## Testes Mínimos
* Parse de `"Intro"`.
* Parse de `"[Chorus] Chorus 1"`.
