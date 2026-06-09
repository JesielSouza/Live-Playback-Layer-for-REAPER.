# SPEC-010 — Logging e Auditoria Local

## Objetivo
Registrar o uso da ferramenta para fins de debug e auditoria de erros de operação pós-culto/show.

## Requisitos
* Escrever em formato JSONL (JSON Lines).
* Campos mínimos: `timestamp`, `level`, `event`, `details`.

## Entradas
* Chamadas de `logger.info`, `logger.error`, etc.

## Saídas
* Escrita assíncrona/bufada em `logs/session_YYYYMMDD.jsonl`.

## Regras
* Em caso de falha de I/O de disco, o logger desativa a escrita, envia para o console nativo do REAPER e continua a operação.

## Riscos
* Lotar o disco ou travar a thread de áudio se for escrita bloqueante intensa.

## Critérios de Aceite
* O log é escrito corretamente após cada ação de transporte.

## Testes Mínimos
* Injetar 100 mensagens e verificar se 100 linhas foram gravadas no arquivo ao fim da sessão.

## Estado Atual
* O Logger Core JSONL já foi implementado de forma isolada, gerando eventos estruturados e gravando em arquivo.
* Ainda **não** há integração automática desta camada com o Bootstrap ou a State Engine. Esta integração será feita futuramente.
* Ainda não existe UI, transporte real, MIDI ou Setlist no projeto.
