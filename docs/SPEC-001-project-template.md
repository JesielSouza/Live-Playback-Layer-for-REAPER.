# SPEC-001 — Estrutura Padrão de Projeto REAPER

## Objetivo
Definir como um projeto REAPER (`.RPP`) deve ser organizado para ser reconhecido e operado pelo sistema de Live Playback.

## Requisitos
* O projeto deve ter um andamento (BPM) definido na root.
* Deve conter uma track específica para Click.
* Deve conter uma track específica para Guide/Cues.
* Tracks de Áudio/Stems devem ser agrupadas de forma padronizada.

## Entradas
* Arquivo `.RPP`.

## Saídas
* O projeto devidamente reconhecido pelo Validator.

## Regras
* Nomes de Tracks chaves (Click, Guide) devem corresponder a padrões configurados (ex: regex `(?i)click`).

## Riscos
* Nomenclatura livre causando a não detecção da track de Click, o que poderia comprometer o roteamento automático.

## Critérios de Aceite
* Validator aprova um `.RPP` em conformidade e reprova os fora do padrão.

## Testes Mínimos
* Submeter `.RPP` com nomes de track corretos (Pass).
* Submeter `.RPP` sem track de Click (Fail).
