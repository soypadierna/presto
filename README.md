# Presto 💰

Aplicación móvil local para gestión de préstamos y cobros con múltiples rutas. Desarrollada en Flutter, funciona 100% offline.

---

## Capturas de pantalla

> Agregar capturas aquí

---

## Funcionalidades

- Gestión de múltiples rutas/usuarios independientes
- Crear clientes con 4 tipos de cobro:
  - **Diario** — días específicos de la semana
  - **Semanal** — un día fijo a la semana
  - **Quincenal** — dos fechas del mes
  - **Mensual** — un día del mes
- Lista del día con swipe para registrar cobros
  - Swipe derecha → registrar pago con monto y nota
  - Swipe izquierda → registrar "no dio" con justificación
  - Long press → deshacer registro
- Reordenamiento manual de clientes (drag & drop)
- Búsqueda de clientes por nombre
- Informe del día:
  - Base del día
  - Total cobrado
  - Registro de gastos
  - Neto final
  - Compartir o copiar por WhatsApp u otras apps
- Historial de pagos por cliente
- Estadísticas mensuales con gráfico de barras
- Historial de días trabajados
- Modo oscuro / claro / sistema
- Respaldo y restauración de datos (.presto)
- Funciona 100% offline

---

## Arquitectura
```
lib/
├── core/
│   ├── backup/          # Servicio de respaldo
│   ├── database/        # SQLite helper
│   ├── theme/           # Temas claro y oscuro
│   └── utils/           # Formatters y helpers
├── features/
│   ├── clients/         # Gestión de clientes
│   ├── home/            # Navegación principal
│   ├── report/          # Informes y estadísticas
│   ├── routes/          # Gestión de rutas
│   └── today/           # Lista del día y cobros
└── main.dart
```

**Stack técnico:**
- Flutter + Dart
- SQLite (sqflite)
- Provider (state management)
- Arquitectura por features

---

## Requisitos

- Flutter 3.x o superior
- Dart 3.x o superior
- Android 5.0+ (API 21+) o iOS 12+

---

## Instalación
```bash
# Clonar el repositorio
git clone https://github.com/tu-usuario/presto.git

# Entrar al proyecto
cd presto

# Instalar dependencias
flutter pub get

# Correr la app
flutter run
```

---

## Generar assets (ícono y splash)
```bash
# Convertir SVGs a PNG
svgexport assets/icon/app_icon.svg assets/icon/app_icon.png 1024:1024
svgexport assets/icon/app_icon_foreground.svg assets/icon/app_icon_foreground.png 768:768
svgexport assets/splash/splash_logo.svg assets/splash/splash_logo.png 512:512

# Generar íconos
dart run flutter_launcher_icons

# Generar splash
dart run flutter_native_splash:create
```

---

## Dependencias principales

| Paquete | Uso |
|---|---|
| `sqflite` | Base de datos local |
| `provider` | Manejo de estado |
| `intl` | Formato de fechas y números |
| `share_plus` | Compartir informes |
| `shared_preferences` | Persistir preferencias |
| `path_provider` | Acceso a directorios |
| `file_picker` | Seleccionar archivos de respaldo |
| `flutter_native_splash` | Pantalla de splash |
| `flutter_launcher_icons` | Ícono de la app |

---

## Versionado

Este proyecto usa [Semantic Versioning](https://semver.org/).
Ver [CHANGELOG.md](CHANGELOG.md) para el historial de cambios.

---

## Licencia

Uso privado. Todos los derechos reservados.