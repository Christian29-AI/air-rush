# AIR RUSH · versión 6.1 — Godot 4.7.2.stable.mono

## Abrir

Extrae `AirHockeyArcade-v6.1.zip` en una carpeta nueva. Importa `AirHockeyArcade/project.godot` en Godot 4.7.2 y pulsa F5. Para F6 abre `scenes/main.tscn`. El editor correcto es 2D. No se necesitan complementos, C#, internet ni recursos externos.

Si trabajas en Antigravity, abre esta carpeta nueva que contiene `project.godot`; las copias de versiones anteriores permanecen separadas.

## Partida

El HUD muestra los nombres, los puntos y el tiempo. Los poderes activos y su tiempo restante aparecen en la bandeja inferior para el jugador rojo y arriba a la derecha para el azul/BOT. No se muestran iconos inactivos ni información duplicada. Las instrucciones están en el menú, no sobre la mesa.

- Gol con el **puck principal: exactamente +50 puntos**.
- Ficha que entra en una portería: **exactamente +2 puntos**.
- **Gana quien marque siete goles con el puck principal**, incluso si el rival acumuló más puntos con fichas. El resultado final muestra también los goles principales.
- No hay victoria por agotarse el tiempo. Una partida que termina antes de 02:50 no alcanza el modo fichas.
- Recoger una ficha no suma puntos directamente: activa su recompensa y la dispara hacia la portería contraria. Puede ser devuelta por una paleta o rebotar en un escudo. Solo puntúa una vez al entrar.
- Ningún poder ni combo multiplica los valores +50 y +2. Veinticinco fichas equivalen a 50 puntos, pero no cuentan como un gol principal.

Se mantienen los nombres personalizados, dos jugadores locales, tres dificultades del BOT, logros, pausa, revancha, ajustes guardados y personajes/pantallas animados del menú.

## Controles

| Acción | Control |
|---|---|
| Paleta roja | W/S arriba/abajo, A/D lateral |
| Paleta azul en local | Flechas |
| Ratón para la paleta roja | Activar en Opciones; WASD vuelve al teclado |
| Pausa / continuar | P o Escape |
| Reiniciar | R |
| Silenciar todo | M |
| Volver al menú desde pausa o victoria | X o botón MENU |

El reloj avanza durante juego activo. Pausas, saques y celebraciones de gol congelan la acción. Cada paleta permanece en su mitad.

## Seis poderes normales

| Poder | Efecto |
|---|---|
| Escudo | Refleja el puck y las fichas en tu portería durante 6 segundos. |
| Súper golpe | Carga el próximo golpe, disponible durante 12 segundos. Al usarlo, dispara a 730 px/s y deja energía morada durante 2,8 segundos. |
| Aceleración | Velocidad de paleta +45% durante 5 segundos. |
| Fuego | Impulsa el puck y cambia color/estela durante 4 segundos. |
| Multibola | Tres mini-pucks de colores durante 6 segundos. Rebotan contra bandas y paletas. Son señuelos: no marcan, no bloquean al puck y no son fichas. Máximo seis, tres por jugador. |
| Imán | Atracción suave a menos de 145 píxeles de la paleta durante 6 segundos. Cambia dirección sin aumentar la rapidez ni inmovilizar el puck. |

Los poderes aparecen escalonadamente, uno a los 2,5 segundos y después cada 4–6,5 segundos, con un máximo de dos disponibles. Se recogen con la paleta. Al preparar un nuevo saque se limpian, como en versiones anteriores. Terminar el modo fichas no cancela poderes normales.

El puck mantiene una velocidad mínima, aceleración progresiva y máximo normal de 620 px/s. Con fuego o súper golpe el máximo temporal es 760 px/s. Conserva la liberación de esquinas y física a 120 Hz con cuatro subpasos.

## MID GAME MODE

Se activa una sola vez cuando el reloj cruza **02:50**. Aparecen 72 fichas pequeñas con animación escalonada, siete colores y tres variaciones. Se reponen gradualmente hasta un límite total de 84 fichas/proyectiles. No tienen colisión con el puck principal.

Tocar una ficha elimina el objeto flotante, activa la recompensa y lo transforma en un disparo. Hay un intervalo mínimo de 0,16 segundos entre recogidas por jugador. Las recompensas refrescan una duración corta, sin acumularla ilimitadamente.

| Color | Recompensa al recoger |
|---|---|
| Amarillo | Disparo de ficha rápido hacia la portería; +2 si entra. |
| Verde | Turbo de paleta durante al menos 1,5 segundos. |
| Azul | Escudo corto de 1,2 segundos. |
| Morado | Carga un súper golpe durante 4 segundos. |
| Rojo | Fuego corto de 0,8 segundos y pequeño impulso. |
| Naranja | Cada impacto válido suma dos escalones de combo durante 3 segundos; el combo sigue limitado a x4 y no multiplica puntos. |
| Cian | Imán de 1,5 segundos y disparo de ficha rápido. |

A **03:20** desaparecen todas las fichas y sus disparos; continúa la partida normal. Un gol principal pausa el modo junto con el reloj, sin volver a activarlo ni reiniciar sus 30 segundos. La victoria o el regreso al menú limpian sus objetos. La revancha reinicia el evento.

## Audio

Música electrónica original de 16 segundos en loop incluida. Opciones → Volumen música / efectos ofrece dos deslizadores independientes, con guardado automático. La música se pausa con el partido y se detiene al volver al menú o al ganar.

Los buses `Music` y `SFX` son independientes. Hay tonos de respaldo para eventos sin archivo. Incluye audios especiales de gol, entrada del modo fichas y victoria, además de activaciones diferentes para los seis poderes. Los efectos pequeños de fichas tienen menor volumen y límite de frecuencia.

Puedes sustituir `audio/arcade_loop.wav` y los eventos `.wav` o `.ogg`: `hit`, `wall`, `pickup`, `activate_0` hasta `activate_5`, `goal`, `victory`, `select`, `button`, `pause`, `start`, `mid_start`, `token_pickup`, `token_goal`.

## Código y recursos

- `scenes/main.tscn`: escena principal y sistemas.
- `scripts/game.gd`: fases, controles, física, puntos separados de goles y guardado.
- `scripts/rules.gd`: dimensiones y constantes compartidas.
- `scripts/power_system.gd`: seis poderes, duración, apariciones e imán.
- `scripts/mid_game.gd`: evento temporal, fichas, proyectiles y dibujo desde un solo nodo.
- `scripts/mini_pucks.gd`: mini-pucks sin puntuación, también desde un solo nodo.
- `scripts/air_bot.gd`: perfiles y decisiones, incluida búsqueda de fichas cercanas cuando no peligra la portería.
- `scripts/combo_system.gd`: combos y su caducidad.
- `ui/game_hud.gd`: marcador mínimo, iconos, animaciones y pausa/victoria.
- `scripts/arena.gd`: mesa ampliada, metal y luces.
- `audio/arcade_audio.gd`: buses, reproducción, loop y sonidos de respaldo.
- `effects/`: marcos e iconos de los seis poderes.
- `assets/`: arte y animaciones conservados del menú.

Las fichas usan arrays limitados y se dibujan en lote; no crean cientos de nodos. Los mini-pucks están limitados a seis, las partículas a 180 y los mensajes flotantes de puntuación a 24. No se utiliza un nodo por ficha, partícula o rastro.

Los ajustes, volúmenes, nombres y logros están en `user://air_rush_profile.cfg`. El ZIP no incluye perfiles personales ni caché `.godot`.

Lee `VALIDACION.md` para conocer las comprobaciones ejecutadas en Godot 4.7.2.

## Apariencia v6.1

Arena metálica cyberpunk basada en la nueva referencia: logo, retratos, porterías luminosas, luces animadas, destellos y estelas. El fondo es arte integrado; todos los elementos jugables permanecen independientes y funcionales. El aviso MID GAME MODE dura un segundo. Se conserva el sistema +50/+2 y la victoria a siete goles principales. El registro de arte está en `assets/ARTE-v6.1.md`.
