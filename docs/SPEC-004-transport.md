# SPEC-004 — Motor de Transporte ao Vivo

## Objetivo
Fornecer comandos seguros para mover o playhead sem estalos e no compasso certo.

## Requisitos
* Funções: `Play()`, `Stop()`, `JumpToSection(id)`, `ToggleLoop()`.

## Entradas
* Comandos emitidos pela State Engine e UI.

## Saídas
* Chamadas para `reaper.OnPlayButton()`, `reaper.SetEditCurPos()`, manipulação de loop regions.

## Regras
* Jumps solicitados durante o `PLAYING` entram na fila (`JUMP_PENDING`) e só executam ao final da section atual ou no tempo do click mais próximo.

## Riscos
* API do REAPER não responder imediatamente causando pulo fora do tempo.

## Critérios de Aceite
* O Jump ocorre sem dessincronizar o click.

## Testes Mínimos
* Enviar comando Jump durante Play; o sistema deve aguardar o marco de sync e então mover o cursor.
