# SPEC-012 — Testes e Validação do MVP

## Objetivo
Estabelecer o checklist final para garantir que o MVP cumpre o propósito de ser rodado ao vivo com segurança.

## Requisitos
* Executar as tasks descritas em `tests/manual-test-checklist.md`.
* Simular cenário real com troca de setlist no meio e panic.

## Entradas
* Sistema completamente montado no REAPER.

## Saídas
* Checklist preenchido com aprovação de 100% dos testes.

## Regras
* Qualquer falha que cause "crash" no script REAPER (ReaScript Error) exige correção imediata antes de release.

## Riscos
* Testes manuais não cobrirem todas as combinações de hardware (Mac, PC, ASIO, CoreAudio).

## Critérios de Aceite
* Checklist manual passando sem problemas.

## Testes Mínimos
* Execução sequencial da simulação de 30 minutos sem travamentos da futura UI.
