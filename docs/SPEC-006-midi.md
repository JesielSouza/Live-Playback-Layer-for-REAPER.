# SPEC-006 — MIDI Triggers e Automação Externa

## Objetivo
Permitir que pedais ou teclados MIDI acionem comandos de transporte remotamente.

## Requisitos
* Escutar mensagens MIDI ou Actions atreladas a CC/Notes do REAPER.
* Mapear os triggers para os comandos principais (`Play`, `Stop`, `Next Section`).

## Entradas
* `reaper.get_action_context()` ou atalhos atrelados a scripts paralelos.

## Saídas
* Evento propagado para a State Engine.

## Regras
* Debounce de pelo menos 200ms para evitar disparos duplos acidentais de pedal.

## Riscos
* Hardware defeituoso enviando spam de mensagens.

## Critérios de Aceite
* Pressionar a nota de "Next" marca `JUMP_PENDING` sem múltiplos disparos no mesmo frame.

## Testes Mínimos
* Enviar duas mensagens MIDI idênticas em menos de 50ms; o sistema processa apenas a primeira.
