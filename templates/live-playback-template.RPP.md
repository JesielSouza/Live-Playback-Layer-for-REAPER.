# Live Playback Template (.RPP)

*Nota: Este arquivo serve apenas como documentação do template esperado, não é um arquivo real executável do REAPER nesta etapa inicial.*

O projeto modelo (template) esperado deve seguir a seguinte estrutura de Tracks:

1. **CLICK** (Track de áudio para o metrônomo)
2. **GUIDE** (Track de áudio para cues/guias vocais)
3. **DRUMS** (Stem/Folder de bateria)
4. **BASS** (Stem/Folder de baixo)
5. **GTRS** (Stem/Folder de guitarras)
6. **KEYS** (Stem/Folder de teclados)
7. **BGV** (Stem/Folder de backing vocals)

## Metadados

O projeto deve ser construído na raiz temporal (0:00.000).

* **Tempo:** Definido na master.
* **Regions:** Cada seção musical (Intro, Verso, Refrão, etc.) deve ser englobada por uma Region do REAPER com nomes legíveis (ex: `[V1] Verso 1`).

## Roteamento
As tracks de `CLICK` e `GUIDE` devem estar roteadas para as saídas de hardware independentes, e não devem ser mandadas para a track Master (evitando vazamentos para o PA).
