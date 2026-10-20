# Contribuir a UR WAR ⚔️

¡Gracias por tu interés en contribuir a **UR WAR**! Este es un proyecto de código abierto multiplataforma desarrollado con Flutter, y toda la comunidad es bienvenida a colaborar con mejoras, corrección de bugs, nuevas funciones y optimizaciones.

---

## 📋 ¿Cómo empezar?

1. **Haz un Fork del repositorio** en GitHub.
2. **Clona tu fork** localmente:
   ```bash
   git clone https://github.com/Minicodeveloper/UR-WAR.git
   cd UR-WAR
   ```
3. **Instala las dependencias**:
   ```bash
   flutter pub get
   ```
4. **Crea una rama para tu función o arreglo**:
   ```bash
   git checkout -b feature/nueva-mecanica
   # o
   git checkout -b fix/error-resolucion
   ```

---

## 🛠️ Estructura del Proyecto

```
lib/
 ├── core/          # Constantes, temas y utilidades globales
 ├── models/        # Modelos de datos del juego
 ├── screens/       # Pantallas de la interfaz de usuario
 ├── widgets/       # Widgets reutilizables
 ├── game/          # Lógica, bucle y entidades del juego
 └── main.dart      # Punto de entrada de la aplicación
```

---

## 🚀 Flujo de Trabajo y Buenas Prácticas

- **Estilo de Código**: Sigue las directrices oficiales de Dart (`dart format` y `flutter analyze`).
- **Commits Claros**: Utiliza mensajes descriptivos (ej. `feat: añadir sistema de puntuación`, `fix: corregir renderizado en Web`).
- **Pruebas**: Si añades una nueva funcionalidad, incluye pruebas en la carpeta `test/`.
- **Pull Requests**:
  1. Asegúrate de que `flutter analyze` y `flutter test` pasen sin errores.
  2. Envía tu PR hacia la rama `main` explicando con claridad los cambios realizados.

---

## 🤝 Código de Conducta

Por favor mantén una actitud respetuosa y constructiva con todos los miembros de la comunidad. ¡Juntos hacemos crecer **UR WAR**!
