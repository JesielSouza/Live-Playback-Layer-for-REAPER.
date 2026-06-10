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
