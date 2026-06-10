# Checklist de Teste Manual do MVP

## Smoke Test Inicial (REAPER nativo)
[ ] Criar um projeto vazio no REAPER.
[ ] Inserir os marcadores/regions de teste. Exemplo:
    - `INTRO|loop=0|next=VERSE_1`
    - `VERSE_1|loop=0|next=CHORUS_1`
    - `CHORUS_1|loop=1|next=ENDING`
    - `ENDING|loop=0`
[ ] Executar `scripts/reaper_smoke_test.lua` através de uma chamada à `SmokeTest.safe_main()` invocada por Action do REAPER.
[ ] Validar que o ReaScript console aparece sem crashes e com as 4 regiões processadas (Validation Ok: true).
[ ] Confirmar que nenhum transporte (play/stop/loop) foi acionado na DAW.
[ ] Confirmar visualmente que o projeto (Tracks, Regions) não foi adulterado/modificado pelo script.

## VS Real Dry Run Read-Only
[ ] Executar a checklist detalhada em `tests/vs-real-dry-run-checklist.md`.
[ ] Confirmar que a UI ReaImGui permanece read-only durante o ensaio.
[ ] Confirmar que nenhum transporte, seek, Play/Stop ou mutação de projeto é acionado pelo produto.

## Testes de Fim-a-Fim

Antes de considerar o MVP pronto para uso em palco, os seguintes cenários devem ser testados manualmente no REAPER. Todos os itens devem passar.

- [ ] **Música com 3 seções:** Carregar um `.RPP` que possua 3 regions sequenciais. A UI deve exibir as seções e o Play deve passar por elas corretamente.
- [ ] **Música com loop:** Clicar em "Loop" durante uma seção. O áudio deve voltar ao início da seção ao terminar, sem engasgos perceptíveis.
- [ ] **Música com jump:** Acionar "Jump/Next" durante o Play. O pulo só deve ocorrer no momento exato estipulado pelo compasso ou fim da seção, mantendo o clique no tempo.
- [ ] **Trigger MIDI:** Mapear uma nota ou pedal. Acioná-lo deve resultar em um Jump/Play, sem sofrer com múltiplos disparos devido a debounce curto.
- [ ] **Setlist com 2 músicas:** Carregar `culto-domingo.example.json`. O sistema deve listar as duas músicas, permitindo pular para a segunda quando a primeira acabar.
- [ ] **Arquivo Ausente:** Tentar carregar um setlist apontando para um `.RPP` que não existe. A UI deve mostrar log/erro e NÃO deve engasgar a engine nem crashear o script.
- [ ] **Region Inválida:** Tentar abrir um `.RPP` com regions sobrepostas de forma insana. O motor deve recusar ou aplicar fallback previsível sem erro fatal.
- [ ] **Panic Stop:** Durante a reprodução (Play), acionar o Panic Stop. O master deve mutar e o transporte parar em menos de 100ms.
- [ ] **Fade Out:** Disparar Fade Out. O volume deve descer de forma suave até 0, e em seguida a música deve parar.
- [ ] **Roteamento Básico:** Checar o output no log para atestar que o clique está direcionado apenas à saída de hardware isolada (sem master).
- [ ] **Operação de 30 minutos:** Deixar o script rodando em idle ou play por meia hora. Navegar na UI de vez em quando. O sistema não pode travar o frame rate do REAPER.

## Transport Execution Simulator
[ ] Rodar `scripts/reaper_ui.lua`.
[ ] Confirmar a secao `Transport Simulation`.
[ ] Confirmar `Simulated: true`.
[ ] Confirmar `Executed: false`.
[ ] Confirmar `Message: simulation_disabled`.
[ ] Confirmar que nenhum botao operacional de transporte aparece.
[ ] Confirmar que nada e executado no REAPER.

## Manual Confirmation State
[ ] Confirmar Manual Confirmation com `Status: NOT CONFIRMED`.
[ ] Clicar `Confirm Intent (dry-run)`.
[ ] Confirmar `Status: CONFIRMED`.
[ ] Confirmar `Count` incrementado.
[ ] Confirmar que Transport Gate continua `Executable: false`.
[ ] Confirmar que Transport Simulation continua `Executed: false`.
[ ] Mover o cursor para outra section e confirmar que a confirmacao anterior nao vale para a nova intent.
[ ] Clicar `Clear Confirmation` e confirmar `Status: NOT CONFIRMED`.
[ ] Confirmar que nada tocou, nada moveu e nada alterou o projeto.

## Transport Preflight Report
[ ] Confirmar a secao `Transport Preflight`.
[ ] Antes de confirmar, validar `Status: blocked`.
[ ] Antes de confirmar, validar `Manual Confirmed: false`.
[ ] Antes de confirmar, validar `Gate Executable: false`.
[ ] Antes de confirmar, validar `Summary: preflight_blocked`.
[ ] Apos clicar `Confirm Intent (dry-run)`, confirmar `Manual Confirmed: true`.
[ ] Confirmar que `Gate Executable` continua `false`.
[ ] Confirmar que nada tocou, nada moveu e nada alterou o projeto.

## Operational Safety Dashboard
[ ] Confirmar a secao `Operational Safety Dashboard`.
[ ] Antes de confirmar, validar `Safety Level: locked`.
[ ] Antes de confirmar, validar `Transport Real Enabled: false`.
[ ] Antes de confirmar, validar `Execution Blocked: true`.
[ ] Antes de confirmar, validar `Manual Confirmation Active: false`.
[ ] Apos clicar `Confirm Intent (dry-run)`, validar `Safety Level: review`.
[ ] Apos confirmar, validar `Manual Confirmation Active: true`.
[ ] Confirmar as garantias `transport_real_disabled`, `no_play_stop_calls`, `no_command_dispatch`, `no_cursor_move`, `no_seek` e `no_project_mutation`.
[ ] Confirmar que nada tocou, nada moveu e nada alterou o projeto.

## Locked Transport Adapter
[ ] Confirmar que `scripts/transport_adapter.lua` permanece travado.
[ ] Confirmar que capacidades reais retornam `false`.
[ ] Confirmar que qualquer tentativa de execucao real retorna `real_transport_locked` ou outro bloqueio de validacao.
[ ] Confirmar que nada tocou, nada moveu e nada alterou o projeto.

## Real Transport Adapter Status
[ ] Confirmar a secao `Real Transport Adapter`.
[ ] Confirmar `Backend: reaper`.
[ ] Confirmar `Real Transport Supported: false`.
[ ] Confirmar `Real Transport Enabled: false`.
[ ] Confirmar `Can Play Stop: false`.
[ ] Confirmar `Can Seek: false`.
[ ] Confirmar `Can Mutate Project: false`.
[ ] Confirmar `Reason: real_transport_locked`.
[ ] Confirmar que nenhum botao operacional novo apareceu.
[ ] Confirmar que nada tocou, nada moveu e nada alterou o projeto.

## Locked Seek Plan
[ ] Confirmar que `scripts/seek_plan.lua` apenas constroi plano logico.
[ ] Confirmar que plano valido retorna `reason=seek_plan_locked`.
[ ] Confirmar que validacao de plano valido retorna `seek_execution_locked`.
[ ] Confirmar que nada tocou, nada moveu e nada alterou o projeto.

## Seek Plan UI
[ ] Confirmar a secao `Seek Plan`.
[ ] Confirmar `Action: go_next`.
[ ] Confirmar `Current Section` conforme posicao atual.
[ ] Confirmar `Target Section` conforme proxima section.
[ ] Confirmar `Target Position` com a posicao inicial da section alvo ou `nil` se nao resolvida.
[ ] Confirmar `Seek Required: true` para plano valido.
[ ] Confirmar `Locked: true`.
[ ] Confirmar `Reason: seek_plan_locked` ou bloqueio esperado.
[ ] Confirmar que nenhum botao operacional novo apareceu.
[ ] Confirmar que nada tocou, nada moveu e nada alterou o projeto.

## Real Transport Readiness
[ ] Confirmar a secao `Real Transport Readiness`.
[ ] Antes de confirmar, validar `Status: blocked`.
[ ] Antes de confirmar, validar `Ready: false`.
[ ] Antes de confirmar, validar `Summary: readiness_blocked`.
[ ] Confirmar `manual_confirmed: false`.
[ ] Confirmar `adapter_supported: false`.
[ ] Confirmar `adapter_enabled: false`.
[ ] Confirmar `gate_executable: false`.
[ ] Confirmar `seek_plan_ok: true`.
[ ] Confirmar `seek_plan_unlocked: false`.
[ ] Apos `Confirm Intent (dry-run)`, validar `Status: review`.
[ ] Apos confirmar, validar `Summary: readiness_review`.
[ ] Confirmar que nenhum botao operacional novo apareceu.
[ ] Confirmar que nada tocou, nada moveu e nada alterou o projeto.
