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

## Instalação Futura
No futuro, a instalação se dará copiando os scripts para a pasta de `Scripts` do REAPER e importando a action principal que chamará o script `main.lua`, montando a UI sobre a instância aberta do projeto ou configurando ações de atalho.

## Estado Atual
O projeto superou o estágio de Bootstrap Inicial. Já implementa:
* Parser lógico puro de Regions (`scripts/regions.lua`).
* Adapter testável de projeto REAPER (`scripts/project.lua`).
* A Máquina de Estados Finita Core em memória (`scripts/state.lua`), ainda desvinculada de Logging de arquivo, UI e Transport.
* O Validator Core para checar a integridade do projeto (`scripts/validator.lua`).
* O Bootstrap Integration Pipeline que integra as camadas Base de forma testável (`scripts/bootstrap.lua`).
* Logger Core JSONL para gravação isolada de logs sem dependências (`scripts/logger.lua` e utilitários), ainda não integrado com Bootstrap/State.

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
