# Validación v6.1

Motor: Godot 4.7.2.stable.mono.official.ed1daf0bf en Windows. Renderizador Compatibility, NVIDIA GTX 1660 SUPER.

## Gameplay

66 comprobaciones automatizadas correctas, 0 fallos:

- Menú, nombres, inicio, controles de dos jugadores y salida.
- Puck móvil, velocidad mínima/máxima y protección de ambas porterías.
- Seis poderes: duración, aparición, multibola sin puntuación, límite de mini-pucks e imán que curva sin alterar la rapidez.
- Goles principales de exactamente +50, fichas de exactamente +2, ausencia de doble puntuación y efectos distintos.
- 25 fichas equivalen a 50 puntos, sin añadir un gol principal.
- Siete goles principales deciden la victoria aunque el ganador tenga menos puntos totales.
- Activación a 170 segundos y limpieza a 200; no se repite el evento.
- Recogida, recompensas, disparos y reflexión de fichas con escudos.
- Límite de objetos, estabilidad del número de nodos y conservación de poderes al terminar el evento.
- Simulación continua de 210 segundos atravesando ambos límites; pausa, revancha y retorno al juego normal.
- Seis escenarios de esquinas con el BOT, combinando tres dificultades y las dos esquinas de su lado.
- Canales de audio separados, duración del loop y existencia de todos los sonidos.

## Audio real

Comprobación de reproducción durante 17,5 segundos con el motor gráfico:

- Pico medido del bus Music: aproximadamente −15,86 dB.
- Pico medido del bus SFX: aproximadamente −11,30 dB.
- El loop de 16 segundos volvió a comenzar y continuó reproduciéndose.

Esto comprueba reproducción y señal de audio, además de la configuración de archivos; no representa una evaluación musical subjetiva.

## Revisión visual

Capturas del partido normal, comienzo y desarrollo del MID GAME MODE, fin del evento, victoria, seis poderes, reglas, opciones y volúmenes. Se detectó y corrigió un caso de triangulación con fichas diminutas durante su aparición; el dibujo final utiliza figuras de píxeles sin esa triangulación.

La importación y las ejecuciones finales no presentaron errores de parser, excepciones de GDScript ni errores de triangulación. El proyecto mantiene la opción de tratar advertencias de GDScript como errores.

En este entorno restringido, el ejecutable de Godot imprime `Failed to read the root certificate store`. Es un mensaje del motor al consultar certificados del sistema, ajeno a los scripts; no impide el juego local, que no utiliza internet.

El equilibrio de la IA y la música pueden ajustarse después de probar partidas con personas. El MID GAME MODE solo aparece si la partida sigue activa al alcanzar 02:50; no se retrasa la victoria a siete goles para forzarlo.

Se repitieron además las 13 pruebas de nombres e interacción de la versión 5.1: 13 correctas, 0 fallos. Total: 79 comprobaciones automatizadas, además de la reproducción de audio y revisión gráfica.

## Revisión de la actualización visual v6.1

Se repitieron las 66 pruebas de gameplay y las 13 pruebas de nombres e interacción después de adaptar las dimensiones de la mesa: 79 correctas, 0 fallos. Se revisaron capturas nativas del partido, evento, victoria y páginas del menú. Los temporizadores se ajustaron para mejorar su legibilidad. La reproducción de audio documentada arriba corresponde a v6; el sistema y los recursos de audio permanecen iguales en v6.1.
