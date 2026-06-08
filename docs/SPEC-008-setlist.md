# SPEC-008 — Setlist Local

## Objetivo
Gerenciar uma fila de músicas em ordem, baseada num arquivo JSON.

## Requisitos
* Carregar arquivo `setlist.json`.
* Interpretar os campos básicos: array de músicas, caminhos dos `.RPP`.

## Entradas
* Caminho do arquivo JSON.

## Saídas
* Tabela em memória com os dados do setlist carregado.

## Regras
* Caminhos relativos devem ser resolvidos em relação ao arquivo json.

## Riscos
* Arquivo JSON mal formatado (Syntax error) crashando o script Lua.

## Critérios de Aceite
* Em caso de falha de parse no JSON, retornar erro legível e impedir inicialização do setlist (retornar para `IDLE`).

## Testes Mínimos
* Carregar JSON válido.
* Tentar carregar JSON com sintaxe quebrada (esperado: Error/Log, não crash silencioso).
