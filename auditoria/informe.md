# Auditoría comercial — Luke, el perro más bueno del mundo

**Fecha:** 2026-10-23
**Método:** lectura completa del código y las escenas del proyecto (sin modificar nada) + 32 capturas reales in-engine (ventana renderizada de verdad, no `--headless`), guardadas en esta misma carpeta.
**Alcance:** evaluación del juego como producto para la franja de 7 a 10 años, pensando en un lanzamiento comercial (tienda de apps, Steam para familias, etc.).

> Aclaración importante sobre los tiempos de juego: no hay playtesting real con chicos de esa edad disponible para esta auditoría. Las duraciones estimadas salen de medir el ancho real de cada nivel, la cantidad de enemigos/obstáculos colocados, y la velocidad de movimiento de Luke, con un criterio conservador pensado para un jugador de 7-10 años que todavía no domina el control (no un speedrun adulto). Están marcadas como estimación en todo el informe.

---

## 1. Lista de mundos, niveles y jefes

El juego tiene 4 mundos de 4 pantallas cada uno (3 niveles + 1 jefe) = 16 pantallas jugables, más un minijuego final y una pantalla de cierre. La progresión es lineal (world_X_level_Y → world_X_boss → world_(X+1)_level_1).

| # | Mundo | Nivel | Ancho aprox. | Enemigos colocados | Duración estimada (niño 7-10) |
|---|-------|-------|:---:|:---:|---|
| 1 | Mundo 1 — Ciudad Segura | Nivel 1 | 6400 px | 4 (bird, thief) | 2–3 min |
| 2 | Mundo 1 — Ciudad Segura | Nivel 2 | 8400 px | 10 | 3–4 min |
| 3 | Mundo 1 — Ciudad Segura | Nivel 3 | 9820 px | 10 | 3.5–4.5 min |
| 4 | Mundo 1 — Ciudad Segura | **Jefe: Don Sombra** | 2000 px (arena) | — | 2–4 min |
| 5 | Mundo 2 — Corazones de Oro | Nivel 1 | 8400 px | 24 (bird, carterista) | 4–6 min |
| 6 | Mundo 2 — Corazones de Oro | Nivel 2 | 9480 px | 30 | 5–7 min |
| 7 | Mundo 2 — Corazones de Oro | Nivel 3 | 9200 px | 36 | 5–7 min |
| 8 | Mundo 2 — Corazones de Oro | **Jefe: La Bruja del Olvido** | 2000 px (arena) | — | 3–5 min |
| 9 | Mundo 3 — El Reino del Poder | Nivel 1 | 8400 px | 18 (bird, corrupt_lackey, corrupt_politician) | 3.5–5 min |
| 10 | Mundo 3 — El Reino del Poder | Nivel 2 | 9480 px | 21 | 4–5.5 min |
| 11 | Mundo 3 — El Reino del Poder | Nivel 3 | 9200 px | 24 | 4–5.5 min |
| 12 | Mundo 3 — El Reino del Poder | **Jefe: El Gran Codicia** | 2000 px (arena) | — | 3–5 min |
| 13 | Mundo 4 — Guardianes de la Naturaleza | Nivel 1 (selva) | 9480 px | 29 (bee, bird, fly, frog, slime, snail, spider) | 4.5–6.5 min |
| 14 | Mundo 4 — Guardianes de la Naturaleza | Nivel 2 (mar) | 9200 px | 10 + 22 anzuelos + piso letal | 5–7 min |
| 15 | Mundo 4 — Guardianes de la Naturaleza | Nivel 3 | 8800 px | 33 (bird, slime, snail, spider, worm) | 5–7 min |
| 16 | Mundo 4 — Guardianes de la Naturaleza | **Jefe: La Reina Veneno** | 2010 px (arena) | — | 4–6 min |
| — | — | Minijuego final: abrazar a 12 personas en 45 s | — | — | 2–4 min (con reintentos) |

Ver sección 8 para el cálculo de duración total del juego completo.

---

## 2. Mecánicas de Luke

Todo lo que Luke puede hacer, según `scripts/player/luke.gd`:

| Mecánica | Detalle | Cómo se desbloquea |
|---|---|---|
| Caminar / correr | `move_left`/`move_right` + Shift para correr (walk 320 px/s, run 510 px/s por defecto; varía por nivel, p. ej. el mar usa física "flotante") | Disponible desde el inicio |
| Salto simple | Espacio | Disponible desde el inicio |
| Doble salto | Espacio en el aire | Disponible desde el inicio (no es un desbloqueable) |
| Golpe cuerpo a cuerpo | Ctrl/botón de ataque, 1 impacto por enemigo por golpe | Disponible desde el inicio |
| Huesito a distancia | Doble toque del botón de ataque | Se desbloquea la primera vez que se agarra un `bone_pickup` en el nivel (permanente para el resto de la partida) |
| Ladrido de onda expansiva | Reemplaza al huesito en el doble toque mientras haya munición comprada; atraviesa varios enemigos y hace **3x** el daño de un golpe normal | Se compra en la tienda ("Ladrido de onda expansiva x5", ver sección 4) o se encuentra una caja escondida con munición en la arena del jefe final |
| Aura protectora | Un golpe "gratis": absorbe el próximo daño en vez de quitar un corazón | Se consigue al tocar la carne (`meat_power_up`) repartida en los niveles |
| Velocidad extra temporal | Multiplica la velocidad x1.5 por 6 s | Hongo (`speed_power_up`) suelto en el nivel, o comprado en la tienda para el próximo nivel |
| Invencibilidad temporal | 6 s sin poder recibir daño (o 12 s si se compró en la tienda) | Estrella (`invincibility_power_up`) suelta en el nivel, o comprada en la tienda |
| Cosméticos (sombrero, traje+capa, medias) | Puramente visuales, no cambian la jugabilidad | Se compran en la tienda con monedas (ver sección 4) |

Notas de diseño relevantes para la auditoría:
- El golpe cuerpo a cuerpo sale en el mismo frame en que se aprieta el botón (sin delay), y el doble-tap no retrasa el golpe simple — es una mecánica pulida y con buena respuesta, algo que en un juego para chicos de esta edad es importante (la frustración por controles con lag es una causa común de abandono).
- La invulnerabilidad tras recibir daño dura 0.75 s, tiempo suficiente para alejarse de un enemigo antes de que vuelva a pegar.

---

## 3. Enemigos y obstáculos, por mundo

### Mundo 1 — Ciudad Segura (temática: robos/ladrones en una ciudad nocturna)
- **Enemigos:** `thief` (ladrón de a pie), `bird` (ave que patrulla volando)
- **Obstáculos:** pinchos (`damage_zone`), cajas rompibles, plataformas móviles (desde el nivel 2)
- **Jefe:** Don Sombra (`thief_boss`), 2.5 m de altura

### Mundo 2 — Corazones de Oro (temática: estafas/hurtos en la vía pública)
- **Enemigos:** `carterista` (arrebata, variante del ladrón), `bird`
- **Obstáculos:** los 3 niveles tienen **todo el piso cubierto de pinchos visibles** (`ground_spike_field`) salvo en zonas seguras de diseño — es el mundo con más densidad de peligro de piso de todo el juego
- **Jefe:** La Bruja del Olvido (`witch_boss`), 3.5 m de altura

### Mundo 3 — El Reino del Poder (temática: corrupción política)
- **Enemigos:** `corrupt_politician` (político corrupto), `corrupt_lackey` (su ayudante/ladrón político), `bird`
- **Obstáculos:** pinchos puntuales, cajas, plataformas móviles
- **Jefe:** El Gran Codicia (`corrupt_boss`), 4.5 m de altura

### Mundo 4 — Guardianes de la Naturaleza (3 ambientes distintos)
- **Nivel 1 (selva):** `bee`, `fly`, `frog`, `slime`, `snail`, `spider`, `bird` — el nivel con más **variedad** de enemigos distintos del juego (7 tipos)
- **Nivel 2 (mar):** `fish_blue`/`fish_yellow` (tiburones patrulleros), `fish_purple` (medusa, algunas sirven de plataforma), `barnacle`; además **22 anzuelos** que bajan desde arriba y un **piso marino 100% letal** (con cangrejos visibles que marcan la zona peligrosa) — el único camino seguro es saltar de medusa en medusa
- **Nivel 3:** `slime`, `snail`, `spider`, `worm`, `bird`
- **Jefe:** La Reina Veneno (`serpent_boss`), 5.5 m de altura, arranca parada en la plataforma más alta de la arena y hay que trepar para poder golpearla

### Peligros transversales (en todos los mundos)
- Pinchos de piso (`damage_zone`/`spike_strip`): quitan exactamente 1 corazón + invulnerabilidad breve, no matan de un golpe
- Contacto con un enemigo: igual que los pinchos, 1 corazón
- Caída fuera del nivel / agua del Mundo 4 Nivel 2: 1 corazón (mismo sistema de daño, no muerte instantánea)

---

## 4. Sistemas del juego

### Vidas
- 3 corazones por nivel (`GameState.DEFAULT_LIVES`). Perder el último corazón no reinicia el nivel solo: aparece la pantalla "Te has quedado sin vidas" con **CONTINUAR** (reinicia el nivel actual con 3 vidas, gasta un continue) o **GAME OVER** (vuelve al menú).
- Hay **3 continues por partida completa** (no por nivel). Agotados los 3, solo queda volver al menú.
- Ver `auditoria/00_game_over.png` — el arte de esta pantalla es mucho más oscuro en tono que el resto del juego (ver sección 9).

### Monedas
- Se juntan monedas sueltas por los niveles (entre 12 y 24 por pantalla según el conteo de escenas).
- El propio código documenta el balance económico pensado: ~24 monedas por visita a la tienda, ~350 monedas en total si se juega "prolijo" toda la partida.

### Tienda (aparece antes de cada nivel desde el Mundo 1 Nivel 2 en adelante, 15 visitas en total)

| Ítem | Tipo | Precio | Efecto |
|---|---|:---:|---|
| Gorro de lana | Cosmético (permanente) | 20 | Visual |
| Sombrero de explorador | Cosmético (permanente) | 35 | Visual |
| Galera elegante | Cosmético (permanente) | 50 | Visual |
| Corona dorada | Cosmético (permanente) | 70 | Visual |
| Traje rojo con capa | Cosmético (permanente) | 90 | Visual, la compra más cara del juego |
| Medias aurinegras | Cosmético (permanente) | 45 | Visual |
| Estrella | Consumible (1 nivel) | 20 | Invencibilidad 12 s al arrancar el próximo nivel |
| Hongo veloz | Consumible (1 nivel) | 15 | Velocidad extra al arrancar el próximo nivel |
| Corazón de repuesto | Consumible | 35 | +1 vida ya cargada |
| Aura protectora | Consumible (1 nivel) | 25 | Arranca el nivel con el escudo puesto |
| Ladrido de onda x5 | Munición | 25 | 5 cargas del ataque que hace 3x de daño |

Los cosméticos se compran una sola vez y después se pueden poner/sacar gratis (botón COMPRAR → PONER/SACAR). Ver `auditoria/00_tienda.png`.

### Guardado
- Botón "GUARDAR PARTIDA" dentro de la tienda: guarda nivel actual, monedas, vidas, continues, compras y sombrero equipado en un archivo en disco.
- "CARGAR PARTIDA" desde el menú principal restaura exactamente ese estado y reubica a Luke en el punto real donde se guardó.
- El guardado también ocurre automáticamente en varios eventos (al sumar monedas, comprar, pasar un checkpoint, completar un nivel), así que perder el progreso por no guardar a mano es poco probable.

### Contraseñas
- Sistema de 16 contraseñas (`LUKE01` a `LUKE16`) que permiten saltar directo a cualquier nivel sin jugar los anteriores, ingresadas desde el menú principal ("CONTRASEÑA").
- Es un atajo pensado para no obligar a rejugar todo, pero también significa que **cualquiera puede saltar directo al último jefe sin haber visto nada antes** — ver observación en sección 9.

### Secretos
- Cada uno de los 12 niveles regulares tiene **una vida extra escondida** en una caja rompible de acceso no obvio (hay que encontrar la plataforma/escalera secreta).
- La arena del jefe final (Mundo 4) tiene un secreto más elaborado: una escalera de plataformas que lleva a 3 vidas extra y una caja de munición de ladrido, pensada para que el jefe final sea superable incluso si no se compró munición en la tienda.
- No hay coleccionables adicionales (sin estrellas ocultas, sin trofeos, sin logros/achievements visibles en el código).

---

## 5. Curva de dificultad

Midiendo cantidad de enemigos colocados y densidad de pinchos por nivel (datos extraídos directamente de las escenas):

- **Mundo 1 (tutorial):** 4 → 10 → 10 enemigos, pinchos muy puntuales (1 → 5 → 7). Curva interna correcta y progresiva, buen ritmo de introducción.
- **Mundo 2 (pico marcado):** 24 → 30 → 36 enemigos, **todo el piso con pinchos visibles** en los 3 niveles. Es un salto brusco respecto al Mundo 1 (hasta 6x más enemigos de golpe al entrar al Nivel 1 del Mundo 2) sin un nivel "puente" que suavice la transición.
- **Mundo 3 (baja):** 18 → 21 → 24 enemigos, pinchos puntuales otra vez (4-7). La dificultad en términos de densidad de enemigos **baja** respecto al pico del Mundo 2, aunque los enemigos nuevos (político, ayudante) no son mecánicamente más difíciles que los anteriores.
- **Mundo 4 (dispareja, cambia de mecánica en vez de subir intensidad):** el Nivel 1 (selva) vuelve a subir a 29 enemigos con 7 tipos distintos (la mayor variedad del juego, exige aprender patrones nuevos rápido); el Nivel 2 (mar) baja a 10 enemigos pero suma precisión de plataformas (saltar solo entre medusas, piso 100% letal) y 22 anzuelos que caen desde arriba — es un tipo de desafío distinto (precisión/paciencia) más que de combate; el Nivel 3 vuelve a 33 enemigos, el número más alto de todo el juego.

**Picos bruscos detectados:**
1. **Mundo 1 → Mundo 2:** el salto de densidad de enemigos y de "todo el piso es peligroso" es el quiebre más fuerte de ritmo del juego. Para un chico de 7-10 años que recién terminó un Mundo 1 tranquilo, el Mundo 2 puede sentirse desproporcionadamente más duro.
2. **Jefes:** los 4 jefes son estructuralmente parecidos (misma plantilla de arena: cajas, monedas, vida extra escondida) pero escalan en tamaño (2.5 m → 5.5 m) y en mecánica — el jefe final exige trepar antes de poder golpearlo, mientras que los 3 anteriores se pelean desde el piso. Ese cambio de mecánica en el último jefe (sin un jefe intermedio que ya pida trepar) es otro salto, aunque menor.
3. **Dentro del Mundo 4**, el contraste Nivel 1 (combate denso) → Nivel 2 (precisión/plataformas, cero margen de error porque el agua mata) → Nivel 3 (combate denso otra vez) hace que el mundo final sea el más irregular en tipo de desafío, no solo en intensidad.

**Lo que está bien resuelto:** la progresión interna de cada mundo (nivel 1 más fácil que nivel 3) es consistente en los 4 mundos, y el daño siempre es de a 1 corazón (nunca muerte instantánea fuera de quedarse sin vidas), lo cual es apropiado para la edad.

---

## 6. Música y efectos de sonido

**Estado actual: el audio está COMPLETO en cobertura (no falta ningún evento ni pantalla) pero es un placeholder.** El propio comentario del código lo dice explícitamente: son archivos `.wav` **sintetizados** en estilo chiptune/8-bit, generados porque no había una referencia de audio real provista en ese momento del proyecto.

- **19 pistas de música**, una por nivel/jefe/pantalla (ninguna se repite literalmente entre niveles, aunque los 3 niveles de un mismo mundo comparten familia tonal/instrumental y el jefe tiene una versión más rápida/oscura). Duran entre 35 y 65 segundos y loopean.
- **14 efectos de sonido** puntuales: salto, ataque, daño, aura on/off, moneda, carne, abrazo, power-up de invencibilidad, power-up de velocidad, nivel completado, golpe a jefe, enemigo derrotado, pausa.
- Mezcla cuidada: hay un offset de volumen por efecto para que salto/ataque (muy frecuentes) suenen más discretos y daño/golpe de jefe (más importantes) suenen más fuerte.
- **Dato relevante para el roadmap:** en la raíz del proyecto existe una carpeta `musica_candidata/` con pistas de música real con licencia libre, ya elegidas, pendientes de integrar — esa integración es una tarea separada, todavía no hecha. Por ahora el juego suena 100% a chiptune sintético, incluida la música del menú y las cinemáticas.

---

## 7. Duración total estimada

Sumando las estimaciones de la tabla de la sección 1 (16 pantallas + minijuego final), para un jugador de 7 a 10 años en su primera vuelta, sin usar contraseñas para saltar contenido:

- **Niveles + jefes:** ~74 minutos (punto medio de los rangos de la tabla)
- **Minijuego final de abrazos:** ~3 minutos
- **Cinemáticas (intro + cierre de Mundo 1 + final) y menús/tienda** (15 visitas a la tienda, mirando y comprando): ~15-20 minutos adicionales

**Total estimado de una partida "prolija" sin grandes trabas: 1.5 a 2 horas.**

Considerando que a esta edad son esperables bastantes reintentos (sobre todo en el Mundo 2 por el pico de dificultad, y en los 4 jefes), un cálculo más realista de punta a punta del juego completo, en una o varias sesiones, es de **2.5 a 4 horas**. Es una duración razonable para un título infantil de este tipo (ni demasiado corto para sentirse "vacío", ni tan largo como para requerir guardado constante — aunque el guardado ya existe).

---

## 8. Cosas incompletas o que se sienten repetitivas

**Incompleto:**
- **Música real sin integrar.** Como se detalla en la sección 6, todo el audio es sintetizado; hay pistas con licencia libre ya elegidas esperando en `musica_candidata/` sin usar todavía.
- **Sin sistema de logros/trofeos ni coleccionables más allá de la vida extra escondida por nivel.** Para un público infantil, metas extra (estrellas ocultas, insignias, "encontraste los 12 secretos") suelen aumentar mucho la rejugabilidad.
- **El minijuego final es el único minijuego de todo el recorrido.** El resto del juego es 100% plataformero, sin variación de formato (sin niveles bonus, sin carreras, sin modos alternativos).

**Repetitivo:**
- **Solo 1-2 tipos de enemigo "con nombre" por mundo (Mundos 1 a 3).** Mundo 1 tiene thief+bird, Mundo 2 carterista+bird, Mundo 3 político+ayudante+bird: en los primeros 3 mundos el ave (`bird`) es el único enemigo que se repite en los 3, y cada mundo apenas suma un enemigo humano nuevo. El Mundo 4 es la excepción (hasta 7 tipos en un solo nivel), lo cual hace que la variedad de bichos se sienta concentrada al final en vez de repartida.
- **Las 4 arenas de jefe comparten la misma plantilla de layout** (misma cantidad aproximada de monedas, cajas rompibles, cartel de misión, vida extra escondida) y los 4 jefes comparten el mismo script base (`boss_base.gd`) con la misma lógica de salto/ataque, solo cambiando sprite, tamaño y algunos parámetros. Visualmente son bien distintos (confirmado en las 4 capturas `jefeN_*.png`), pero mecánicamente la pelea se siente parecida de principio a fin: acercarse, esquivar el salto, pegar.
- **Fondos repetidos por tile.** Los niveles largos (8000-9800 px) arman el fondo repitiendo 3 a 5 copias de la misma imagen de fondo una al lado de la otra (`BackgroundTile2`, `BackgroundTile3`...), así que un jugador que mire el fondo con atención puede notar el patrón que se repite cada ~3000 px.
- **Los 3 niveles regulares de cada mundo usan los mismos 1-2 tipos de enemigo y los mismos obstáculos (cajas, monedas, pinchos, plataforma móvil) con la única variación de cantidad/posición.** No hay una mecánica nueva que aparezca a mitad de mundo (salvo el Mundo 4, que sí varía selva/mar/selva-otra-vez entre sus 3 niveles).

**Observación de tono (no pedida explícitamente, pero relevante para "evaluar como producto comercial para niños"):** la pantalla de Game Over (`00_game_over.png`) muestra una ciudad en ruinas en blanco y negro, con Luke y una familia entera llorando, bajo el texto "TE HAS QUEDADO SIN VIDAS PARA SALVAR EL MUNDO". Es un contraste fuerte con el tono alegre del resto del juego (menú colorido, "el perro más bueno del mundo") y con el hecho de que perder vidas en un juego de plataformas para esta edad es algo que va a pasar seguido. Vale la pena revisar si esa intensidad visual es la buscada para la franja de 7 a 10 años, especialmente porque es una pantalla que muchos chicos van a ver varias veces por partida.

También vale mencionar que la temática de 3 de los 4 mundos es sátira social/política explícita (ladrones, corrupción, un político caricaturizado frente a un edificio tipo Casa Blanca con cartel "NO AL ROBO" de fondo en el Mundo 1). No es un problema de calidad, pero para un producto pensado para 7-10 años es una decisión editorial que conviene confirmar a propósito (algunos padres/plataformas de distribución pueden pedir un IGRF/rating y leer esos temas con más atención que la violencia de plataformeo en sí).

---

## 9. Capturas incluidas en esta carpeta

| Archivo | Contenido |
|---|---|
| `00_menu_principal.png` | Menú principal |
| `00_tienda.png` | Tienda, catálogo completo visible |
| `00_pausa.png` | Pantalla de pausa (REANUDAR / SALIR AL MENÚ PRINCIPAL) |
| `00_game_over.png` | Pantalla de "sin vidas" con CONTINUAR / GAME OVER |
| `mundoX_nivelY_inicio.png` / `_mitad.png` | Los 12 niveles regulares, inicio y mitad (24 capturas) |
| `jefe1_don_sombra.png` ... `jefe4_reina_veneno.png` | Los 4 jefes en plena pelea (Luke atacando, barra de vida visible) |

Total: 32 capturas, todas renderizadas en motor real (ventana visible, no `--headless`).
