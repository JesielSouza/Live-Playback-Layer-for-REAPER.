# State Model

O núcleo operacional (Lua State Engine) baseia-se numa Máquina de Estados Finita (FSM) que garante controle previsível durante a reprodução.

## Estados

* `IDLE`: Inicializado, aguardando carregamento ou ações. Nenhuma música em fila.
* `SONG_LOADED`: Um projeto/música foi carregado e validado. Playhead parado.
* `PLAYING`: Reprodução ativa e normal da música atual.
* `SECTION_LOOPING`: Reprodução ativa, mas em loop dentro de uma section (Region) específica.
* `JUMP_PENDING`: Reprodução ativa. O sistema recebeu ordem para pular para outra section e aguarda o ponto de sincronismo (ex: final do compasso) para efetuar o pulo.
* `FADING_OUT`: Executando rotina de fade-out antes de parar ou transicionar para a próxima música.
* `STOPPED`: Reprodução parada, mas a música ainda está carregada (geralmente após o fim de uma música).
* `PANIC`: Parada emergencial, desliga áudio e MIDI imediatamente (mute all).
* `ERROR`: Estado não operável devido a falha sistêmica ou carregamento corrompido.

## Transições Permitidas
* `IDLE` -> `SONG_LOADED`
* `SONG_LOADED` -> `PLAYING`
* `PLAYING` -> `STOPPED` | `SECTION_LOOPING` | `JUMP_PENDING` | `FADING_OUT` | `PANIC`
* `SECTION_LOOPING` -> `PLAYING` | `STOPPED` | `JUMP_PENDING` | `FADING_OUT` | `PANIC`
* `JUMP_PENDING` -> `PLAYING` | `SECTION_LOOPING` | `PANIC`
* `FADING_OUT` -> `STOPPED` | `PANIC`
* `STOPPED` -> `SONG_LOADED` | `PLAYING`
* `*` -> `PANIC`
* `*` -> `ERROR` (qualquer falha grave)
* `PANIC` -> `IDLE` (apenas reset manual)
* `ERROR` -> `IDLE` (apenas reset manual)

## Transições Proibidas
* `IDLE` -> `PLAYING` (deve carregar antes)
* `PANIC` -> `PLAYING` (exige reset e recarregamento)
* `ERROR` -> `PLAYING` (exige resolução do erro)
* Pulos de `JUMP_PENDING` direto para `STOPPED` (o jump deve ser finalizado ou abortado para `FADING_OUT` / `PANIC`).

## Eventos
* `CMD_LOAD`: Carrega música.
* `CMD_PLAY`: Inicia transporte.
* `CMD_STOP`: Para transporte.
* `CMD_JUMP`: Define próximo alvo de pulo.
* `CMD_LOOP`: Ativa loop na section atual.
* `CMD_PANIC`: Emergência.
* `EV_SYNC_POINT_REACHED`: Ponto de sincronismo (fim da section, etc.) alcançado pelo playhead.

## Regra de Recuperação
No caso de `PANIC` ou `ERROR`, o sistema desarma imediatamente e volta para `IDLE` de forma limpa, não tentando restaurar o transporte sozinho. O operador precisa intervir e enviar `CMD_LOAD`.

## Regras de Logging
* Toda e qualquer transição de estado deve ser registrada na camada de Log, com timestamp e a causa/evento que provocou a transição.
* Transições para `PANIC` e `ERROR` registram o máximo de contexto (posição do playhead, música atual, stack trace se aplicável).
