# Changelog — Presto

Todos los cambios importantes de cada versión están documentados aquí.
El formato está basado en [Keep a Changelog](https://keepachangelog.com/es/1.0.0/).

---

## [2.1.1] - 2026-03-23

### Corregido
- Error null al cambiar tipo de cobro en formulario de cliente nuevo
- Bottom Sheets no podían acceder a TodayProvider por contexto separado

---

## [2.1.0] - 2026-03-23

### Mejorado
- Dialog de pago reemplazado por Bottom Sheet más espacioso y natural
- Dialog de "no dio" reemplazado por Bottom Sheet con autofocus
- Selector de método de pago con botones grandes e íconos
- Preview de imagen de comprobante dentro del Bottom Sheet
- Indicador de carga al registrar un pago

---

## [2.0.0] - 2026-03-23

### Agregado
- Editar pagos históricos desde el historial del cliente
- Agregar pagos faltantes en el historial del cliente con selector de fecha
- Eliminar pagos históricos con swipe en el historial
- Editar pagos desde el detalle del día en estadísticas
- Agregar pagos a días anteriores desde el detalle del día
- `PaymentEditDialog` widget reutilizable para crear y editar pagos
- Selector de clientes sin pago al agregar desde el detalle del día
- Validación para evitar pagos duplicados en el mismo día

### Mejorado
- `DayDetailScreen` ahora recibe `routeId` para recargar datos
- El resumen del día se actualiza en tiempo real al editar pagos

---

## [1.9.0] - 2026-03-23

### Agregado
- Filtros en la lista del día: Todos, Pendientes, Pagaron, No dieron
- Contador de clientes por cada filtro
- Mensaje específico por filtro cuando no hay resultados
- Botón "Ver todos" para limpiar el filtro activo

### Mejorado
- El scroll se mantiene en la misma posición al registrar un pago
- Animación suave al cambiar entre filtros

---

## [1.8.0] - 2026-03-23

### Agregado
- Tipos de pago: efectivo y transferencia
- Adjuntar imagen de comprobante en pagos por transferencia
- Opción de tomar foto o seleccionar de galería
- Preview de imagen en el dialog de pago
- Miniatura del comprobante en el historial del cliente
- Visor de imagen en pantalla completa con zoom
- `ImageHelper` para gestión de imágenes locales
- Migración de DB a versión 2 con columnas `payment_method` e `image_path`
- Al eliminar un pago se elimina su imagen asociada automáticamente

### Corregido
- Al cancelar el dialog de pago se limpia la imagen temporal

---

## [1.7.0] - 2026-03-23

### Agregado
- Eliminar ruta con todos sus datos en cascada usando transacción SQLite
- Dialog de confirmación muestra conteo de clientes, pagos y gastos antes de eliminar
- `RouteDeleteStats` para obtener estadísticas antes de eliminar
- `forceDeleteRoute` en `RouteProvider` para eliminación en cascada

---

## [1.6.0] - 2026-03-15

### Agregado
- Configuración de firma de release para APK y AAB de Android
- Reglas ProGuard para Flutter, Google Play Core, SQLite y Kotlin
- Soporte para `minifyEnabled` y `shrinkResources` en builds de release

### Corregido
- Paquete migrado de `com.example.presto` a `com.presto.app`
- Java actualizado a versión 17 para eliminar warnings obsoletos

---

## [1.5.0] - 2026-03-15

### Mejorado
- Listas optimizadas con `RepaintBoundary` y `cacheExtent: 500`
- Tabs mantienen estado con `AutomaticKeepAliveClientMixin`
- `ValueKey` en lugar de `Key` para identificación más precisa de items
- `TodayScreen`, `ClientListScreen` y `ReportScreen` mantienen
  su estado al cambiar de tab sin recargar

### Corregido
- Eliminados operadores `==` y `hashCode` inválidos en widgets
  (no permitidos en subclases de `Widget`)

---

## [1.4.0] - 2026-03-15

### Agregado
- Unit tests para `ClientModel.isScheduledForDate` — todos los tipos de cobro
- Unit tests para `ReportGenerator.generate` — cálculo de neto y formato
- Unit tests para `Formatters` — montos, fechas y labels

---

## [1.3.0] - 2026-03-15

### Agregado
- Validación completa del archivo de respaldo antes de importar
- Verificación de magic bytes SQLite para detectar archivos corruptos
- Verificación de tablas y columnas requeridas por Presto
- Pantalla de confirmación muestra el contenido del respaldo antes de restaurar
- `BackupValidator` con resultado detallado y `BackupInfo`

---

## [1.2.0] - 2026-03-15

### Corregido
- Reemplazar `withOpacity` por `withValues` en todos los archivos
- Reemplazar `MaterialStateProperty` por `WidgetStateProperty`
- Reemplazar `MaterialState` por `WidgetState`
- Reemplazar `background` por `surface` en `ColorScheme`
- Reemplazar `onBackground` por `onSurface` en `ColorScheme`
- Reemplazar `surfaceVariant` por `surfaceContainerHighest` en `ColorScheme`
- Reemplazar `value` por `initialValue` en `payment_config_widget.dart`
- Agregar llaves en `if` sin bloque en `today_client_tile.dart`
- Actualizar versión a `1.2.0+3` en `pubspec.yaml`

### Agregado
- Manejo global de errores con `ErrorHandler` y `AppErrorWidget`
- Pantalla de error amigable reemplaza la pantalla roja de Flutter
- `AsyncErrorBoundary` widget reutilizable para secciones con operaciones async
- `ErrorListenerMixin` reutilizable para escuchar errores en todas las pantallas
- `errorMessage` en todos los providers: `RouteProvider`, `ClientProvider`,
  `TodayProvider`, `ReportProvider`, `StatsProvider`
- SnackBar de error automático en todas las pantallas al fallar una operación

### Mejorado
- `RouteSelectScreen` convertido a `StatefulWidget` para soportar el mixin de errores

---

## [1.1.0] - 2026-03-15

### Corregido
- Al eliminar un cliente desaparece inmediatamente de la lista del día
- Al crear un cliente aparece inmediatamente si corresponde al día actual
- Bug en `TodayProvider.loadTodayClients` con `firstWhere` y orElse nulo

### Mejorado
- Cliente diario ahora permite elegir días específicos incluyendo domingo
- Pantalla bloqueada en orientación vertical
- Paleta de colores cambiada a escala de grises elegante
- Colores funcionales mantenidos solo para estados críticos (pagado/no dio/error)

---

## [1.0.0] - 2026-03-15

### Agregado

#### Rutas
- Crear múltiples rutas independientes
- Editar nombre de ruta con long press
- Eliminar ruta con validación (no se puede eliminar si tiene clientes activos)
- Selección de ruta al iniciar la app

#### Clientes
- Crear clientes con nombre, crédito y tipo de cobro
- 4 tipos de cobro: diario, semanal, quincenal, mensual
- Reordenamiento manual con drag & drop
- Búsqueda por nombre en tiempo real
- Swipe derecha para editar
- Swipe izquierda para eliminar con confirmación
- Historial de pagos por cliente
- Soft delete (los clientes eliminados conservan su historial)

#### Lista del día
- Filtrado automático de clientes según tipo de cobro y fecha actual
- Swipe derecha para registrar pago con monto y nota
- Swipe izquierda para registrar "no dio" con justificación
- Long press para deshacer un registro
- Monto pre-llenado con el crédito del cliente
- Resumen del día: total cobrado, pagaron, no dieron, pendientes
- Búsqueda por nombre

#### Informe
- Base del día configurable
- Registro y edición de gastos
- Resumen financiero: base, cobrado, gastos, neto
- Generación de texto de informe con formato profesional
- Copiar informe al portapapeles
- Compartir informe por WhatsApp u otras apps

#### Estadísticas
- Resumen del mes actual con total cobrado, gastos, neto y días trabajados
- Gráfico de barras de neto por día del mes
- Historial de días trabajados ordenado del más reciente
- Detalle de cada día con lista de cobros
- Copiar y compartir informe de días anteriores

#### Ajustes
- Modo claro, oscuro y seguir el sistema
- Persistencia de preferencia de tema
- Respaldo de datos en archivo `.presto`
- Restauración de datos desde archivo `.presto`
- Confirmación antes de restaurar

#### General
- Arquitectura por features (routes, clients, today, report, home)
- Base de datos SQLite local — funciona 100% offline
- Soporte de localización en español (Costa Rica)
- Ícono adaptativo para Android
- Splash screen personalizado
- Orientación bloqueada en vertical
- Modo oscuro en todos los widgets
- Formatters centralizados
- Dark mode helper para colores hardcodeados