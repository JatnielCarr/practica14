# Acertijo - Generador de Crucigramas

Un generador inteligente de crucigramas desarrollado en Flutter que utiliza algoritmos de backtracking y procesamiento paralelo con isolates para crear crucigramas válidos de manera eficiente.

## 📋 Descripción

Este proyecto es un generador de crucigramas que implementa técnicas avanzadas de programación en Dart/Flutter:

- **Backtracking inteligente** para colocar palabras de manera válida
- **Procesamiento paralelo** usando isolates de Dart
- **Estructuras de datos inmutables** con `built_value` y `built_collection`
- **Gestión de estado reactivo** con Riverpod
- **Interfaz de usuario responsiva** con visualización en tiempo real

## 🎯 Características

- ✅ Generación de crucigramas de múltiples tamaños (20x11 hasta 500x500)
- ✅ Algoritmo de backtracking con cola de trabajo optimizada
- ✅ Visualización en tiempo real del proceso de generación
- ✅ Validación automática de palabras cruzadas
- ✅ Interfaz adaptable con scroll bidimensional
- ✅ Medición y registro de tiempos de generación
- ✅ Soporte multiplataforma (Windows, macOS, Linux, Web, iOS, Android)

## 🏗️ Arquitectura del Proyecto

### Estructura de Directorios

```
lib/
├── main.dart                    # Punto de entrada de la aplicación
├── providers.dart               # Proveedores de Riverpod
├── model.dart                   # Modelos de datos inmutables
├── isolates.dart                # Lógica de procesamiento en isolates
├── utils.dart                   # Utilidades y extensiones
└── widgets/
    ├── crossword_generator_app.dart  # Widget principal de la app
    └── crossword_widget.dart         # Widget de visualización del crucigrama

assets/
└── words.txt                    # Lista de palabras para el crucigrama
```

### Modelos de Datos

#### **Location**
Representa una ubicación en el crucigrama con coordenadas (x, y) y métodos para navegar:
- `left`, `right`, `up`, `down` - Movimiento unitario
- `leftOffset`, `rightOffset`, `upOffset`, `downOffset` - Movimiento con offset

#### **Direction**
Enumeración para la dirección de las palabras:
- `across` - Horizontal
- `down` - Vertical

#### **CrosswordWord**
Representa una palabra en el crucigrama con:
- `word` - La palabra en sí
- `location` - Ubicación de inicio
- `direction` - Dirección de la palabra

#### **CrosswordCharacter**
Representa un carácter individual en el crucigrama:
- `character` - El carácter
- `acrossWord` - Palabra horizontal (si existe)
- `downWord` - Palabra vertical (si existe)

#### **Crossword**
El modelo principal del crucigrama:
- `width`, `height` - Dimensiones
- `words` - Lista de palabras
- `characters` - Mapa de caracteres por ubicación
- `valid` - Validación del crucigrama
- `addWord()` - Método para agregar palabras con validación

#### **WorkQueue**
Cola de trabajo para el algoritmo de backtracking:
- `crossword` - Crucigrama en construcción
- `locationsToTry` - Ubicaciones pendientes
- `badLocations` - Ubicaciones no válidas
- `candidateWords` - Palabras disponibles
- `isCompleted` - Estado de finalización

## 🔧 Tecnologías Utilizadas

### Dependencias Principales

```yaml
dependencies:
  flutter:
    sdk: flutter
  built_collection: ^5.1.1      # Colecciones inmutables
  built_value: ^8.10.1          # Valores inmutables
  characters: ^1.4.0            # Manejo de caracteres
  flutter_riverpod: ^2.6.1     # Gestión de estado
  riverpod_annotation: ^2.6.1  # Anotaciones para Riverpod
  two_dimensional_scrollables: ^0.3.7  # Scroll 2D
```

### Dependencias de Desarrollo

```yaml
dev_dependencies:
  build_runner: ^2.5.4          # Generación de código
  built_value_generator: ^8.10.1 # Generador para built_value
  riverpod_generator: ^2.6.5    # Generador para Riverpod
  riverpod_lint: ^2.6.5         # Linter para Riverpod
  custom_lint: ^0.7.6           # Linter personalizado
```

## 🚀 Instalación y Ejecución

### Requisitos Previos

- Flutter SDK (versión 3.9.0 o superior)
- Dart SDK (versión 3.9.0 o superior)

### Pasos de Instalación

1. **Clonar el repositorio**
   ```bash
   git clone <url-del-repositorio>
   cd acertijo
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

3. **Generar archivos de código**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Ejecutar la aplicación**
   
   Para Windows:
   ```bash
   flutter run -d windows
   ```
   
   Para otras plataformas:
   ```bash
   flutter run -d <platform>
   # Opciones: macos, linux, chrome, android, ios
   ```

### Modo Desarrollo con Hot Reload

Para desarrollo continuo con generación automática de código:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

En otra terminal:
```bash
flutter run
```

## 📊 Algoritmo de Generación

### Estrategia de Backtracking

El algoritmo utiliza una estrategia de búsqueda con backtracking optimizado:

1. **Inicialización**
   - Se crea una cola de trabajo (`WorkQueue`) con el crucigrama vacío
   - Se filtran palabras que no caben en las dimensiones

2. **Búsqueda de Intersecciones**
   - En lugar de colocar palabras aleatoriamente, busca ubicaciones de intersección
   - Intenta palabras que contengan el carácter de intersección

3. **Validación**
   - Verifica que la palabra no esté duplicada
   - Comprueba que coincida con caracteres existentes
   - Valida que no haya conflictos de dirección

4. **Backtracking**
   - Si una ubicación falla, se marca como "mala"
   - Se elimina de la cola y se intenta la siguiente
   - Las estructuras inmutables facilitan el retroceso

5. **Optimizaciones**
   - Límite de 1000 intentos por ubicación
   - Procesamiento en isolates para no bloquear la UI
   - Actualización incremental de la cola de trabajo

### Ejemplo de Flujo

```
1. Crear WorkQueue con crucigrama vacío
2. Mientras la cola no esté completa:
   a. Seleccionar ubicación aleatoria de locationsToTry
   b. Buscar palabras candidatas en isolate:
      - Si la ubicación está vacía → palabra aleatoria
      - Si hay carácter → palabras que contengan ese carácter
   c. Para cada palabra candidata:
      - Intentar colocarla en todas las posiciones posibles
      - Si es válida → actualizar WorkQueue y continuar
      - Si falla → marcar ubicación como mala
3. Crucigrama completado
```

## 🎨 Interfaz de Usuario

### Componentes Principales

#### **CrosswordGeneratorApp**
- AppBar con menú de configuración
- Selector de tamaño de crucigrama
- Inicialización eager de proveedores

#### **CrosswordWidget**
- TableView con scroll bidimensional
- Renderizado eficiente con Consumer
- Actualización selectiva de celdas
- Visualización en tiempo real

#### **Menú de Configuración**
Tamaños disponibles:
- Small: 20 x 11
- Medium: 40 x 22 (por defecto)
- Large: 80 x 44
- XLarge: 160 x 88
- XXLarge: 500 x 500

### Optimizaciones de Renderizado

- **Consumer granular**: Solo actualiza celdas que cambian
- **select() en providers**: Evita reconstrucciones innecesarias
- **TableView**: Renderizado eficiente de grandes cuadrículas
- **Lazy loading**: Solo renderiza celdas visibles

## 📈 Rendimiento

### Tiempos de Generación Aproximados

| Tamaño | Dimensiones | Tiempo Aproximado |
|--------|-------------|-------------------|
| Small | 20 x 11 | < 10 segundos |
| Medium | 40 x 22 | 30-60 segundos |
| Large | 80 x 44 | 1-3 minutos |
| XLarge | 160 x 88 | 5-15 minutos |
| XXLarge | 500 x 500 | Variable |

*Nota: Los tiempos varían según la lista de palabras y el hardware*

### Mejoras de Rendimiento Implementadas

1. **Cola de trabajo inteligente**: Evita búsquedas redundantes
2. **Isolates**: No bloquea la UI durante la generación
3. **Estructuras inmutables**: Backtracking eficiente sin copias profundas
4. **Límite de intentos**: Evita bucles infinitos
5. **Filtrado previo**: Solo considera palabras que caben

## 🛠️ Desarrollo

### Generar Código

Después de modificar archivos con anotaciones:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Verificar Errores

```bash
flutter analyze
```

### Formatear Código

```bash
dart format .
```

### Testing

```bash
flutter test
```

## 🧩 Extensiones Útiles

### DurationFormat
Formatea duraciones de manera legible:

```dart
final duration = Duration(minutes: 2, seconds: 30);
print(duration.formatted); // "2:30"
```

### RandomElements
Obtiene un elemento aleatorio de un BuiltSet:

```dart
final set = BuiltSet<String>(['palabra1', 'palabra2']);
final random = set.randomElement();
```

## 📝 Notas Técnicas

### Archivos Generados

Los archivos `.g.dart` son generados automáticamente y no deben editarse manualmente:
- `model.g.dart` - Generado por built_value_generator
- `providers.g.dart` - Generado por riverpod_generator

### Lista de Palabras

El archivo `assets/words.txt` contiene la lista de palabras disponibles:
- Una palabra por línea
- Solo caracteres a-z (minúsculas)
- Palabras de 3+ caracteres
- Palabras muy largas se filtran según el tamaño del crucigrama

### Limitaciones Conocidas

1. El tiempo de generación aumenta exponencialmente con el tamaño
2. No todos los crucigramas llegan al 100% de completitud
3. La lista de palabras afecta significativamente la calidad del resultado
4. Crucigrama muy grandes (500x500) pueden no completarse

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor:

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## 🙏 Agradecimientos

- Tutorial basado en el codelab oficial de Flutter
- Paquetes de la comunidad de Dart/Flutter
- Algoritmo de backtracking basado en principios clásicos de IA

## 📞 Contacto

Para preguntas o sugerencias, por favor abre un issue en el repositorio.

---

**Desarrollado con ❤️ usando Flutter**
