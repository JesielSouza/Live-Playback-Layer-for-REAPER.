# Critérios do MVP

Este documento define os critérios exatos para que o Minimum Viable Product (MVP) da Live Playback Layer seja considerado funcional e pronto para testes de palco.

O MVP deve cumprir exclusivamente estes pontos:

1. **Abre no REAPER:** O script inicializa a interface (ReaImGui) sobre o projeto REAPER.
2. **Detecta Dependências:** Verifica na inicialização se ReaImGui e SWS estão instalados.
3. **Lê Regions:** Realiza o parse das Regions nativas do projeto para criar a timeline estruturada (sections).
4. **Mostra Seções:** A UI apresenta as sections extraídas visualmente ao usuário.
5. **Executa Play/Stop:** Controle básico de transporte atrelado à máquina de estados.
6. **Faz Jump:** Capaz de agendar pulo e executar de maneira musicalmente no tempo (sincronizado no compasso/batida).
7. **Faz Loop:** Capaz de segurar uma seção em loop.
8. **Dispara Trigger MIDI:** Mapeamento mínimo de nota MIDI para acionar o próximo Jump/Play.
9. **Carrega Setlist:** Processa um arquivo JSON local contendo no mínimo 2 músicas (arquivos `.RPP`).
10. **Registra Logs:** Salva as ações e mudanças de estado em arquivo `.jsonl`.
11. **Tem Panic Stop:** Botão ou atalho que interrompe todo o áudio imediatamente e reseta o transporte.
12. **Opera por 30 Minutos:** O sistema roda em simulação de show (com timer e trocas esporádicas) sem travar a interface ou causar crashes.
13. **Bloqueia Play (Safe Mode):** Não permite `Play` se o projeto atual não tiver seções válidas carregadas.
