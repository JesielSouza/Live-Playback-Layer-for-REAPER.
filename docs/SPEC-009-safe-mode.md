# SPEC-009 — Safe Mode de Palco

## Objetivo
Impedir o operador de realizar ações que destruam a performance enquanto ao vivo.

## Requisitos
* Enquanto `PLAYING`, fechar ou carregar novo projeto é bloqueado (via UI futura).
* Evita duplo clique acidental nas actions (debounce).

## Entradas
* Estado atual.
* Tentativas de ações do usuário.

## Saídas
* Bloqueio ou permissão da ação.

## Regras
* Apenas ações de Transporte e Panic são permitidas no estado `PLAYING`.

## Riscos
* Bloquear falsamente ações necessárias para recuperar erro.

## Critérios de Aceite
* No futuro, o botão "Load Setlist" ou "Next Song" da UI ficará desabilitado (cinza) se `PLAYING` for verdadeiro.

## Testes Mínimos
* Iniciar transporte, tentar invocar Load Song via API (deve ser rejeitado com log).
