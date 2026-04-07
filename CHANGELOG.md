# Changelog — Presto

Todos los cambios importantes de cada versión están documentados aquí.
El formato está basado en [Keep a Changelog](https://keepachangelog.com/es/1.0.0/).

---

## [2.7.0] - 2026-04-06

### Agregado
- Múltiples pagos por cliente en el mismo día agrupados por método
- Swipe derecho en tiles pagados para agregar otro pago
- Badges de desglose en tile cuando hay pagos en efectivo y transferencia
- Totales por efectivo y transferencia en TodaySummaryCard
- Desglose por método de pago en el informe del día
- "Agregar pago" en menú contextual si el cliente ya pagó

### Mejorado
- TodayClient usa `List<PaymentModel>` en lugar de `PaymentModel?`
- `registerPayment` siempre inserta un nuevo registro — nunca reemplaza
- `undoPayment` elimina solo el último pago registrado
- Key del Dismissible incluye `payments.length` para forzar recreación del widget

### Corregido
- "No dio" bloqueado si el cliente ya tiene pagos registrados

---

## [2.7.0] - 2026-04-06

### Agregado
- Múltiples pagos por cliente en el mismo día agrupados por método
- Badges de desglose en tile cuando hay pagos en efectivo y transferencia
- Totales por efectivo y transferencia en TodaySummaryCard
- Desglose por método en el informe del día
- "Agregar pago" en menú contextual si el cliente ya pagó
- No se puede registrar "no dio" si el cliente ya tiene pagos

### Mejorado
- TodayClient usa `List<PaymentModel>` en lugar de `PaymentModel?`
- `registerPayment` siempre inserta — nunca reemplaza
- `undoPayment` elimina solo el último pago registrado

---

## [2.6.2] - 2026-03-25

### Corregido
- Restaurado sistema de colores DarkModeHelper para tiles
- Agregados colores para refinanciado y reagendado en DarkModeHelper
- Tiles usan Colors.green/red/amber de Material que combinan con la paleta anterior

---

## [2.6.1] - 2026-03-25

### Mejorado
- Tiles rediseñados — fondo neutro en todos los estados
- Color concentrado solo en el círculo de estado y el monto/etiqueta derecha
- Pendiente: círculo gris con número de orden
- Pagado: círculo verde oscuro con checkmark, monto en verde
- No dio: círculo rojo oscuro con X, etiqueta "No dio" en rojo
- Refinanciado: círculo ámbar oscuro con ícono, etiqueta en ámbar
- Reagendado: igual que pendiente + badge morado con fecha
- Badge SINPE en transferencias con fondo verde oscuro
- Modo claro inferido con mismos principios y paleta invertida

---

## [2.6.0] - 2026-03-25

### Mejorado
- Navegador de fecha rediseñado con contenedor y botones del mismo color
- Orden del header: navegador → summary card → filtros → búsqueda
- `TodaySummaryCard` integrada dentro de `TodayHeader`
- Filtros compactos con punto de color para "Pagaron" y "No dieron"
- Campo de búsqueda con fondo relleno sin borde
- `TodayScreen` simplificado — delega todo el header a `TodayHeader`

---

## [2.5.0] - 2026-03-23

### Agregado
- Refinanciamiento de clientes desde TodayScreen e historial
- Dos tipos: "Dar dinero" y "Dar tiempo"
- Dar dinero descuenta el monto de la base del día
- Dar tiempo actualiza los días de pago del cliente
- Soporte de imagen de comprobante para refinanciamientos por transferencia
- Menú contextual con long press en clientes pendientes
- Badge morado en tile de cliente refinanciado
- Sección "REFINANCIAMIENTOS" en el informe del día
- Migración de DB a versión 4 con tabla refinances

---

## [2.4.0] - 2026-03-23

### Agregado
- Navegación por fechas en TodayScreen con flechas anterior/siguiente
- Selector de fecha al tocar la fecha central
- Etiquetas especiales: "Hoy", "Ayer", "Mañana"
- Punto indicador bajo la fecha cuando es hoy
- Animación suave al cambiar de fecha
- Al cambiar fecha se resetean filtros y búsqueda automáticamente
- Estado vacío diferenciado para hoy vs otros días

---

## [2.3.0] - 2026-03-23

### Agregado
- Reagendar cobro al marcar cliente como "no dio"
- `ScheduledPaymentModel` y `ScheduledPaymentRepository`
- `RescheduleBottomSheet` con selector de fecha y nota
- Clientes reagendados aparecen en la lista del día con badge ámbar
- Dos opciones en SkippedBottomSheet: "Solo registrar" y "Agendar"
- Al pagar un cliente reagendado se elimina el reagendamiento automáticamente
- Migración de DB a versión 3 con tabla `scheduled_payments`

---

## [2.2.0] - 2026-03-23

### Agregado
- Botón en AppBar de TodayScreen para registrar abono fuera del calendario
- `ClientPickerBottomSheet` para seleccionar clientes no programados para hoy
- Búsqueda en tiempo real dentro del selector de clientes
- `getClientsNotInList()` en TodayProvider
- `todayClientIds` getter para identificar clientes ya en la lista

### Corregido
- Cliente registrado fuera del calendario ahora aparece en la lista
  del día y en el balance inmediatamente después de registrar el pago

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