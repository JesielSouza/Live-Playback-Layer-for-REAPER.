# SPEC-005 — UI de Palco com ReaImGui

## Objetivo
Criar a interface visual focada no operador/músico.

## Requisitos
* Fontes grandes, modo Dark.
* Exibição de: Nome da Música, Seção Atual, Próxima Seção.
* Botões gigantes de Play, Stop, Jump Next, Loop.

## Entradas
* Tabela de Estado vinda da Lua State Engine.

## Saídas
* Comandos clicados enviados para a State Engine.
* Renderização a 30fps na tela.

## Regras
* A UI não processa lógica de áudio, ela é estritamente passiva visualmente, apenas emite intents (eventos).

## Riscos
* Overhead do ImGui travando a thread principal.

## Critérios de Aceite
* A UI atualiza dinamicamente conforme o playhead move.

## Testes Mínimos
* Renderização manual da UI sem projeto aberto deve mostrar estado "IDLE".
