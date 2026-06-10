# Arquitetura do Sistema

A arquitetura do **Live Playback Layer for REAPER** é dividida em camadas, de modo a garantir a separação de responsabilidades e permitir a estabilidade da aplicação durante a performance ao vivo.

## Camadas

### 1. REAPER Project Layer
* **Responsabilidade:** Armazenamento das tracks de áudio, stems, click, guide, e o tempo da música. Serve como o motor de áudio. O acesso lógico a esta camada é fornecido via um Adapter (em `scripts/project.lua`) garantindo uma extração limpa e testável de dados das APIs do REAPER ou simulações.
* **Entradas:** Arquivos `.RPP` configurados (via REAPER aberto) ou mocks nas automações de teste.
* **Saídas:** Áudio roteado para as saídas físicas, eventos MIDI nativos, lista de regions exposta pelo Adapter.
* **Riscos:** Configuração incorreta do projeto por parte do usuário (arquivos faltantes, roteamento errado).
* **Critérios de Aceite:** O projeto deve abrir sem erros e todas as mídias devem estar online.

### 2. Metadata Layer
* **Responsabilidade:** Fornecer semântica para os blocos de tempo usando Regions e Markers do REAPER (nome das seções, metadados em texto padronizado).
* **Entradas:** Strings fornecidas pelo Adapter do projeto.
* **Saídas:** Objetos de dados estruturados para a Lua State Engine.
* **Riscos:** Padrões não correspondentes, Regions que se sobrepõem.
* **Critérios de Aceite:** Regions parseadas de forma correta sem falhar silenciosamente se houver formato inválido.

### 3. Lua State Engine
* **Responsabilidade:** Manter o estado da aplicação em uma Finite State Machine (FSM), validando transições permitidas, rejeitando intents proibidos, e orquestrando as outras camadas de forma pura. Foi concebida como um módulo testável (singleton) independente do REAPER em `scripts/state.lua`.
* **Entradas:** Eventos de dispatch atrelados a intents de sistema (ex: `PLAY_REQUESTED`, `JUMP_COMPLETED`).
* **Saídas:** Atualização de contexto, armazenamento de histórico de transições em memória (o logging em arquivo será atrelado posteriormente).
* **Riscos:** Concorrência e bloqueio se as operações de atualização de estado forem onerosas.
* **Critérios de Aceite:** Transições seguem estritamente as regras de grafos de estados definidos em `STATE-MODEL.md`.

### 4. Transport Control Layer
* **Responsabilidade:** Manipular a posição do playhead, Play, Stop, Loop, Jump de forma segura.
* **Entradas:** Comandos da Lua State Engine.
* **Saídas:** Chamadas para API de transporte nativo do REAPER.
* **Riscos:** Latência no acionamento, pulos que causam "clicks" de áudio se não feitos no momento certo.
* **Critérios de Aceite:** Pulos, loops e play/stop acionados de forma previsível e auditivamente segura.

### 5. MIDI Trigger Layer
* **Responsabilidade:** Ovir comandos MIDI (controladores, pedais) para disparar ações como Play, Stop, Próxima Música.
* **Entradas:** Sinais MIDI.
* **Saídas:** Eventos injetados na Lua State Engine.
* **Riscos:** Flutuações de sinal, mapeamento incorreto.
* **Critérios de Aceite:** Mapeamento fixo de notas/CC disparando ações do sistema com debounce.

### 6. ReaImGui UI Layer
* **Responsabilidade:** Renderizar a interface de usuário "Modo Palco", mostrando informações visuais grandes e claras.
* **Entradas:** Estado atual fornecido pela Lua State Engine.
* **Saídas:** Cliques e ações do usuário.
* **Riscos:** Queda de framerate.
* **Critérios de Aceite:** Renderização a 30fps+ consistente, sem travar o processamento de áudio; feedback visual imediato.
* **Nota Atual:** A UI ReaImGui implementada nesta fase é estritamente read-only. O teste em VS real é um dry run operacional: nenhuma função de playback, transporte, seek ou mutação de projeto foi implementada ainda.

### 7. Setlist Persistence Layer
* **Responsabilidade:** Carregar e salvar as playlists de músicas.
* **Entradas:** Arquivos locais JSON.
* **Saídas:** Estrutura de dados carregada em memória apontando para os `.RPP` corretos.
* **Riscos:** Caminhos de arquivos inválidos.
* **Critérios de Aceite:** Validação do arquivo JSON no carregamento, reportando falhas de arquivos inexistentes antecipadamente.

### 8. Logging Layer
* **Responsabilidade:** Registrar tudo o que acontece (Play, Stop, Jumps, Erros) para depuração.
* **Entradas:** Mensagens da aplicação.
* **Saídas:** Escrita em arquivo local `JSONL`.
* **Riscos:** I/O bloqueante afetando a performance.
* **Critérios de Aceite:** Logs assíncronos ou bufados que não afetam o thread principal.
* **Nota Atual:** O Core JSONL foi implementado gerando eventos estruturados localmente. Os Hooks de integração do Logger já conectam os eventos de Bootstrap e as transições do State Engine em memória, contudo a UI não está presente.

### 9. Validation / Safe Mode Layer
* **Responsabilidade:** Verificar antes da execução se o projeto está pronto, travando edições perigosas ("Safe Mode").
* **Entradas:** Metadados do projeto, configs.
* **Saídas:** Bloqueios de UI ou avisos.
* **Riscos:** Falsos positivos que bloqueiam o uso normal.
* **Critérios de Aceite:** Bloquear Play se o projeto atual estiver "quebrado" estruturalmente (ex: sem metadados mínimos).

### 10. Bootstrap Integration Pipeline
* **Responsabilidade:** Conectar o Project Adapter, o Validator e a State Machine, orquestrando a inicialização da aplicação sem depender da UI.
* **Fluxo:** Extrai os dados lógicos de `Project.scan_current_project()`, passa para `Validator.validate_project()` e aplica o resultado na Lua State Engine.
* **Regras de Transição:** Se a validação for `ready` ou `warning`, as seções são injetadas no State que transita para `SONG_LOADED`. Se for `blocked`, o State transita para `ERROR`.
* **Nota:** Nesta etapa arquitetural, **ainda não há UI** e **ainda não há transporte real**.

### 11. Console/Debug Runner
* **Responsabilidade:** Testar as lógicas do Bootstrap Pipeline (simulando payloads) de modo puro e gerar relatórios textuais. Prepara o terreno para o REAPER Smoke Test.
* **Entradas:** `project_scan_override` (com cenários *ready*, *warning* ou *blocked*).
* **Saídas:** Relatório text-based de validação, contagem de seções, state final e contagem de eventos de log gerados.
* **Nota Atual:** É puramente offline; ainda não chama APIs do REAPER diretamente nem implementa UI/Transporte.

### 12. REAPER Smoke Test Entrypoint
* **Responsabilidade:** Prover o primeiro script a ser carregado **dentro do ambiente REAPER**.
* **Fluxo:** Executa o Bootstrap Pipeline invocando o Adapter real sobre o projeto aberto no momento e retorna um log analítico usando a API do console do REAPER (`ShowConsoleMsg`).
* **Regras de Segurança:** É completamente **read-only**, não interage com ações destrutivas ou transporte real, sendo apenas uma demonstração do arcabouço FSM base para o REAPER.

## Transport Simulation Note
The transport simulator runs in memory only. It returns `executed=false` and does not call REAPER APIs, move the cursor, seek, or mutate the project.

## Manual Confirmation Session Note
Manual confirmation is stored in a local UI session only. It can feed the transport gate and simulator as state, but it does not execute transport actions or call REAPER transport APIs.

## Transport Preflight Note
Transport preflight consolidates intent, gate, simulator, and manual confirmation state into a read-only report. It does not execute transport, move the cursor, seek, or mutate the project.

## Operational Safety Dashboard Note
The safety dashboard summarizes the current read-only guarantees for the UI. It keeps real transport disabled and execution blocked while surfacing gate, preflight, simulation, and manual confirmation state.

## Locked Transport Adapter Note
The transport adapter defines the future real execution interface, but this implementation is locked. It reports disabled capabilities and returns blocked execution results only.
