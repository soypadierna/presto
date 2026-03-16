# Changelog — Presto

Todos los cambios importantes de cada versión están documentados aquí.
El formato está basado en [Keep a Changelog](https://keepachangelog.com/es/1.0.0/).

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