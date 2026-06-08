# SPEC-003 — Motor de Leitura de Regions

## Objetivo
Ler e mapear todas as regions de um `.RPP` para a memória (State Engine) de maneira eficiente e segura.

## Requisitos
* Deve varrer o projeto atual aberto.
* Deve montar um array sequencial de sections em ordem de timeline.

## Entradas
* `reaper.EnumProjectMarkers`.

## Saídas
* Tabela Lua ordenada com dados de todas as regions (`ID`, `start`, `end`, `name`).

## Regras
* Se houver Regions sobrepostas, reportar erro ou assumir a que inicia primeiro.

## Riscos
* API nativa retornar IDs dessincronizados se o usuário editou recentemente durante a execução.

## Critérios de Aceite
* Ler 50 regions em menos de 10ms.
* Validar que todas estão ordenadas no tempo cronológico.

## Testes Mínimos
* Varrer projeto vazio (retorna array vazio).
* Varrer projeto com 5 regions e checar ordem cronológica.
