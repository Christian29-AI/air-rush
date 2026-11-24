# Arte y animación — versión 4

Herramienta: ImageGen integrada, sin CLI/API. Ambos PNG se incluyen en el proyecto.

- `arcade_clean.png`: edición del fondo original para eliminar los personajes y sus reflejos.
- `walk_sheet.png`: atlas RGBA transparente, cuatro columnas y dos filas. Los personajes se animan como sprites independientes en Godot.

Las pantallas se animan por código en `scripts/arcade_screens.gd`.

## Prompts finales

### clean

Edit this game background ONLY by removing both human characters (boy left in blue hoodie and gray pants; boy right in blue hoodie and red pants) completely, plus their character reflections on the floor. Reconstruct the arcade cabinets and blue tiled floor behind them cleanly. Preserve EXACT original room composition, camera, all cabinet locations and screens, lamps, walls, plants, colors, pixel art style and foreground red/blue mallets. No human figures or silhouettes anywhere. Do not add text or UI. Keep same image dimensions and layout. This is the clean background plate for a game where animated characters will be placed on top.

### walk

Create a transparent PNG game sprite sheet for Godot. Exactly FOUR equal columns and TWO equal rows, no spacing between cells, no grid lines, no text. Each of the eight cells has one full-body pixel-art walking character, facing RIGHT in side view. Row 1: brown haired boy, blue hoodie, gray trousers, red-white sneakers. Row 2: blond/light-brown haired boy, blue hoodie, red trousers, blue-white sneakers. Use the characters in supplied arcade image as style/appearance reference. Each row depicts FOUR consecutive walk-cycle poses: right foot forward contact, right foot supporting with left passing, left foot forward contact, left supporting with right passing. Legs and arms clearly change poses with opposite arm/leg swing. SAME sprite proportions, scale, head position, body centered horizontally, feet baseline consistent across ALL cells, total height about 80% of each cell; generous transparent margins so limbs never reach adjacent cell. Crisp professionally drawn 16-bit pixel art, dark navy outlines, detailed hair and hoodie shading, actual transparent background with alpha (no checkerboard drawn), NO room NO ground NO shadows NO text. Image aspect ratio 2:1; each cell is half as wide as tall. Eight separate consistently sized full-body sprites, strict aligned 4 by 2 grid. Characters are game sprites with natural walking anatomy, not bobbing or deformed.
