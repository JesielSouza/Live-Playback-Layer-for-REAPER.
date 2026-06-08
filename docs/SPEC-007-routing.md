# SPEC-007 — Roteamento de Áudio

## Objetivo
Garantir que Click, Guide e Stems saiam nas portas corretas de hardware (Hardware Outputs).

## Requisitos
* Checar roteamento das tracks de Click e Guide antes do Play.
* (MVP) Confia na configuração pré-salva no `.RPP`, mas no futuro fará auto-routing.

## Entradas
* `.RPP` carregado.

## Saídas
* Log de validação de roteamento.

## Regras
* Se Click e Master saírem na mesma porta, avisar em Log, pois pode vazar click no PA.

## Riscos
* API do REAPER não revelar as rotas de hardware claramente dependendo da interface de áudio.

## Critérios de Aceite
* O log aponta para onde a track Click está roteada.

## Testes Mínimos
* Validar roteamento de click (Simples verificação visual nos logs).
