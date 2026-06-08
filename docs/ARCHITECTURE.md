# Arquitetura do Sistema

A arquitetura do **Live Playback Layer for REAPER** é dividida em camadas, de modo a garantir a separação de responsabilidades e permitir a estabilidade da aplicação durante a performance ao vivo.

## Camadas

### 1. REAPER Project Layer
* **Responsabilidade:** Armazenamento das tracks de áudio, stems, click, guide, e o tempo da música. Serve como o motor de áudio.
* **Entradas:** Arquivos `.RPP` configurados.
* **Saídas:** Áudio roteado para as saídas físicas, eventos MIDI nativos.
* **Riscos:** Configuração incorreta do projeto por parte do usuário (arquivos faltantes, roteamento errado).
* **Critérios de Aceite:** O projeto deve abrir sem erros e todas as mídias devem estar online.

### 2. Metadata Layer
* **Responsabilidade:** Fornecer semântica para os blocos de tempo usando Regions e Markers do REAPER (nome das seções, metadados em JSON ou texto padronizado).
* **Entradas:** Regions e Markers lidos através da API do REAPER.
* **Saídas:** Objetos de dados estruturados para a Lua State Engine.
* **Riscos:** Padrões não correspondentes, Regions que se sobrepõem.
* **Critérios de Aceite:** Regions parseadas de forma correta sem falhar silenciosamente se houver formato inválido.

### 3. Lua State Engine
* **Responsabilidade:** Manter o estado da aplicação (máquina de estados), gerenciar transições e orquestrar as outras camadas.
* **Entradas:** Comandos de UI, triggers MIDI, eventos de timer e posição do playhead.
* **Saídas:** Atualização de estado, chamadas para Transport Control e Logging.
* **Riscos:** Concorrência com os threads do REAPER, loops bloqueantes.
* **Critérios de Aceite:** Responde em tempo real sem travar a interface do REAPER; estados bem definidos sem condições de corrida.

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

### 9. Validation / Safe Mode Layer
* **Responsabilidade:** Verificar antes da execução se o projeto está pronto, travando edições perigosas ("Safe Mode").
* **Entradas:** Metadados do projeto, configs.
* **Saídas:** Bloqueios de UI ou avisos.
* **Riscos:** Falsos positivos que bloqueiam o uso normal.
* **Critérios de Aceite:** Bloquear Play se o projeto atual estiver "quebrado" estruturalmente (ex: sem metadados mínimos).
