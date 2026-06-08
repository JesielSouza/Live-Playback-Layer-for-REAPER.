# SPEC-011 — Instalador/Template Inicial

## Objetivo
Documentar a estrutura de como o usuário final instala isso no REAPER.

## Requisitos
* Exigir que os arquivos sejam copiados para a pasta Scripts.
* Prover um `.RPP` de template de música para que o usuário não comece do zero.

## Entradas
* Pacote ZIP do repositório.

## Saídas
* Action do REAPER que abre a interface.

## Regras
* O script Lua deve resolver seus caminhos de include (requires) relativamente de forma independente de qual OS está rodando.

## Riscos
* Separadores de diretório `/` vs `\` no Windows/Mac.

## Critérios de Aceite
* O projeto carrega com sucesso tanto no Windows quanto no macOS.

## Testes Mínimos
* Instalar manualmente no REAPER local e rodar a Action.
