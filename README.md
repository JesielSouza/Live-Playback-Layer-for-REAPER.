# Live Playback Layer for REAPER

## O que é o projeto
Este projeto é uma camada operacional construída sobre o REAPER para transformá-lo em uma plataforma de reprodução de músicas ao vivo. É focado no uso em igrejas, bandas, cultos, shows e apresentações que utilizam stems, click, guide, cues, seções, setlists e automações MIDI de forma estável e previsível.

## O que ele NÃO é
* **NÃO** é uma nova DAW (Digital Audio Workstation).
* **NÃO** é um clone completo do Playback da MultiTracks no MVP.
* **NÃO** possui um backend na nuvem, banco de dados ou integração cloud.
* **NÃO** possui login, marketplace ou app mobile.

## Escopo do MVP
O MVP (Minimum Viable Product) foca em uma solução estritamente local e offline, operando de maneira segura e robusta. O sistema é baseado no REAPER e utilizará scripts e metadados locais para gerenciar e executar as apresentações.

## Stack Técnica
* **Motor Base:** REAPER
* **Linguagem de Script:** ReaScript em Lua
* **Interface (UI):** ReaImGui
* **Metadados:** Regions e Markers nativos do REAPER
* **Ações:** Actions nativas do REAPER (SWS Extension usada de forma muito pontual e apenas quando necessário)
* **Persistência e Configuração:** Arquivos JSON locais para setlists e configurações
* **Log:** JSONL local para auditoria e logs

## Dependências Esperadas
* REAPER (versão recomendada mais recente)
* ReaImGui
* SWS Extension (apenas o estritamente necessário)

## Testes Locais
Para rodar os testes da lógica do projeto localmente (sem a necessidade de abrir o REAPER), certifique-se de ter o `lua5.3` instalado e rode:
```bash
lua tests/run_tests.lua
```
Nota: O adapter que realiza as chamadas de API nativas para interagir com o REAPER (`scripts/project.lua`) possui fallbacks seguros em modo offline para garantir que não ocorram crashes e que a validação lógica seja confiável, mockando a tabela global `_G.reaper` nos testes.

## VS Real Dry Run
Para validar a UI read-only em um Virtual Soundcheck ou ensaio real, use a checklist operacional em [`tests/vs-real-dry-run-checklist.md`](tests/vs-real-dry-run-checklist.md). Esta fase é apenas dry run: a UI observa o runtime e não aciona transporte nem altera o projeto.

O primeiro registro de execução do dry run está em [`tests/vs-real-dry-run-report.md`](tests/vs-real-dry-run-report.md).

## Instalação Futura
No futuro, a instalação se dará copiando os scripts para a pasta de `Scripts` do REAPER e importando a action principal que chamará o script `main.lua`, montando a UI sobre a instância aberta do projeto ou configurando ações de atalho.

## Estado Atual
O projeto superou o estágio de Bootstrap Inicial. Já implementa:
* Parser lógico puro de Regions (`scripts/regions.lua`).
* Adapter testável de projeto REAPER (`scripts/project.lua`).
* A Máquina de Estados Finita Core em memória (`scripts/state.lua`), ainda desvinculada de Logging de arquivo, UI e Transport.
* O Validator Core para checar a integridade do projeto (`scripts/validator.lua`).
* O Bootstrap Integration Pipeline que integra as camadas Base de forma testável (`scripts/bootstrap.lua`).
* Logger Core JSONL para gravação isolada de logs sem dependências (`scripts/logger.lua` e utilitários).
* Logger Integration Hooks embutidos nas camadas de Bootstrap e State para registro de eventos (transições e validações) em memória.
* Console/Debug Runner (`scripts/debug_runner.lua`), preparando o terreno para o REAPER Smoke Test.
* REAPER Smoke Test Entrypoint (`scripts/reaper_smoke_test.lua`), validando read-only a injeção do sistema diretamente dentro do ambiente da DAW.

## Testando o Smoke Test no REAPER
1. Abra um projeto vazio no REAPER.
2. Insira algumas Regions simples e válidas no timeline como: `INTRO|loop=0|next=VERSE_1`, `VERSE_1|loop=0|next=CHORUS_1`, `CHORUS_1|loop=1|next=ENDING` e `ENDING|loop=0`.
3. Carregue o script `scripts/reaper_smoke_test.lua` através do painel de *Actions*.
4. Edite a última linha ou adicione um wrapper que invoque `SmokeTest.safe_main()` (atualmente o módulo só é exportado para uso limpo por testes).
5. O console exibirá o relatório validado com zero ações que alterem a reprodução do projeto.

## Guardrails
* **Extensão C++ é proibida** nesta fase do projeto.
* Nenhuma implementação ou dependência de Servidor.
* Sem interface Frontend Web.
* Sem gerenciador de pacotes externo sem estrita necessidade.
* Nenhuma dependência externa complexa.
* Nenhuma integração Cloud ou de Banco de Dados.
* Sem features de Login ou Marketplace.
* Sem App Mobile.
* Sem suporte a roteamento avançado MIDI nesta etapa inicial.

## Próximos Passos (Planejamento)
1. **Repository Bootstrap & Docs Pack** (Esta etapa)
2. Definição fina do schema de regions e marcadores
3. Implementação do motor de parse de regions e leitura
4. Implementação da engine de State (State Machine) e Transport Base
5. Criação da UI de Palco (ReaImGui)
6. Implementação do carregamento e transição de projetos (Setlists)
7. Finalização do MVP (Logs, Safe Mode, testes integrados)

## Transport Simulation
O simulador de transporte (`scripts/transport_simulator.lua`) roda apenas em memoria. Ele mostra na UI o que teria acontecido com a intent de transporte, mas sempre retorna `executed=false` e nao chama APIs do REAPER, nao move cursor, nao faz seek e nao altera o projeto. Por padrao, a UI exibe `simulation_disabled`.

## Manual Confirmation State
A UI mantem uma confirmacao manual em memoria (`scripts/ui_session.lua`). Os botoes `Confirm Intent (dry-run)` e `Clear Confirmation` alteram apenas esse estado local de UI; eles nao acionam transporte, nao movem cursor e nao alteram o projeto.

## Transport Preflight
O relatorio de preflight (`scripts/transport_preflight.lua`) consolida intent, gate, simulacao e confirmacao manual em memoria. Ele e apenas read-only e informa se a intent esta bloqueada, pronta para simulacao ou simulada, sem executar transporte.

## Operational Safety Dashboard
O dashboard de seguranca (`scripts/safety_dashboard.lua`) consolida garantias read-only antes de qualquer execucao futura. Ele mantem transporte real desabilitado, execucao bloqueada e lista as garantias operacionais exibidas na UI.

## Locked Transport Adapter
O adapter de transporte (`scripts/transport_adapter.lua`) prepara a interface futura de execucao real, mas permanece travado por configuracao. Todas as capacidades reais retornam `false`, `execute_real` nunca executa e o motivo padrao e `real_transport_locked`.
