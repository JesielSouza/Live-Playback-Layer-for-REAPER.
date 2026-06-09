# State Model

O núcleo operacional (Lua State Engine) baseia-se numa Máquina de Estados Finita (FSM) (implementada puramente e testável em `scripts/state.lua`) que garante controle previsível durante a reprodução.

## Estados Implementados

* `IDLE`: Inicializado, aguardando carregamento ou ações. Nenhuma música em fila.
* `SONG_LOADED`: Um projeto/música foi carregado e validado. Playhead parado.
* `PLAYING`: Reprodução ativa e normal da música atual.
* `SECTION_LOOPING`: Reprodução ativa, mas em loop dentro de uma section (Region) específica.
* `JUMP_PENDING`: Reprodução ativa. O sistema recebeu ordem para pular para outra section e aguarda o ponto de sincronismo (ex: final do compasso) para efetuar o pulo.
* `FADING_OUT`: Executando rotina de fade-out antes de parar ou transicionar para a próxima música.
* `STOPPED`: Reprodução parada, mas a música ainda está carregada (geralmente após o fim de uma música).
* `PANIC`: Parada emergencial sistêmica.
* `ERROR`: Estado não operável devido a falha sistêmica ou carregamento corrompido.

## Transições Permitidas
A FSM reforça rigorosamente:
* `IDLE` -> `SONG_LOADED`
* `SONG_LOADED` -> `PLAYING`
* `PLAYING` -> `JUMP_PENDING`
* `JUMP_PENDING` -> `PLAYING`
* `PLAYING` -> `SECTION_LOOPING`
* `SECTION_LOOPING` -> `PLAYING`
* `PLAYING` -> `FADING_OUT`
* `FADING_OUT` -> `STOPPED`
* `PLAYING` -> `STOPPED`
* `STOPPED` -> `PLAYING`
* `ANY` -> `PANIC`
* `PANIC` -> `STOPPED`
* `ANY` -> `ERROR`
* `ERROR` -> `SONG_LOADED` (se música carregada) ou `IDLE`
* `STOPPED` -> `SONG_LOADED`
* `SONG_LOADED` -> `STOPPED`

## Transições Proibidas Importantes Rejeitadas (Exemplos)
* `IDLE` -> `PLAYING` (deve carregar antes)
* `ERROR` -> `PLAYING` (exige resolução do erro)
* `PANIC` -> `PLAYING` (exige clear do panic e stop)
* `FADING_OUT` -> `JUMP_PENDING`
* `IDLE` -> `JUMP_PENDING`
* `IDLE` -> `SECTION_LOOPING`
* `IDLE` -> `FADING_OUT`

## Eventos de Dispatch Aceitos
Os eventos de intent que mudam a máquina são:
* `LOAD_SONG_SUCCESS`
* `PLAY_REQUESTED`
* `STOP_REQUESTED`
* `LOOP_ENABLED`
* `LOOP_DISABLED`
* `JUMP_REQUESTED`
* `JUMP_COMPLETED`
* `FADE_REQUESTED`
* `FADE_COMPLETED`
* `PANIC_REQUESTED`
* `PANIC_CLEARED`
* `ERROR_RAISED`
* `ERROR_CLEARED`
* `RESET_REQUESTED`

## Histórico em Memória e Logging
* Toda e qualquer tentativa de transição de estado (`dispatch` ou `transition`) é registrada em um histórico em memória interno à FSM (`state.get_history()`).
* Este registro marca o estado de origem (`from`), o alvo (`to`), o `event`, e a confirmação se foi aceito (`ok=true`) ou rejeitado (`ok=false`, com a propriedade `reason`).
* **Nota MVP 1.0:** No momento, o registro ocorre *apenas em memória*. A serialização disto para um log físico JSONL em arquivo ainda não está implementada nesta fase.
* **Nota de Escopo:** O gerenciador de estado atualmente orquestra o fluxo de permissões da lógica do projeto. Componentes físicos/visuais como UI, motor de Transporte real de DAW, parsing MIDI e gerenciamento de Setlist ainda não foram implementados.
