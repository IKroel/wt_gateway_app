# Changelog

Formato basado en [Keep a Changelog](https://keepachangelog.com/es/1.1.0/).
Versionado semántico: `MAJOR.MINOR.PATCH+BUILD`.

## [1.1.0] — 2026-11-11

Asignación en modo **Protect** o **Sharing** (firmware V3, `caps=mode`).
Compatible con firmware V1: lo nuevo solo aparece si la placa lo anuncia en `caps`.

### Agregado
- Modo de operación en el wizard de asignación (`Protect` / `Sharing`), enviado
  con `>SET_MODE` una vez autenticada la sesión. Si el firmware no admite modos,
  la placa queda en Protect y se avisa. Modelo `BoardMode`.
- Detalle del equipo: fila **Modo**; aviso **Equipo en standby** (`en=0`) con
  botón **Habilitar** (`>ENABLE 1`, fw >= 3.4.6).
- Aviso de activación del corte (`<LOCK`, fw >= 3.4.5): si la app está conectada
  cuando la placa aplica el corte, muestra "Corte activado · puertas cerradas"
  (o el error) y lo registra en el log (`AUDIT LOCK …`).
- `DeviceState`: `mode`, `caps`, `enabled`. `BleService`: `setMode`,
  `setEnabled` y petición genérica `_request()` (una a la vez, con timeout).
- Log de depuración: colores para `<TXGPS` / `<GPSACK` (respuesta OK/ERROR del
  GPS a cada orden) legibles en modo claro.

### Cambiado
- Liberar corte: en Sharing el aviso indica que también se abren las puertas.
  La app espera la confirmación del GPS (`<RELEASE … gps=ok|error|timeout`,
  fw >= 3.4.2), la registra en el log (`AUDIT RELEASE …`) y la muestra; con
  fw >= 3.4.4 `<ERR release_…` se trata como liberación fallida.

### Corregido
- Dos conexiones simultáneas al mismo equipo (reintento + pantalla) hacían
  fallar el AUTH; ahora se ignora la segunda.

## [1.0.0] — 2026-08-06

Primera versión productiva del repositorio. Línea base tras el rediseño UI/UX
sobre el prototipo funcional (heredado como `1.2.0` del proyecto anterior).

### Agregado
- Pantalla de conexión en 3 pasos (Conectar → Autenticar → Leer estado) como
  bottom sheet, con reintento por etapa y fase de error explícita (`errorPhase`).
- Wizard de asignación en 4 pasos con resultado tipado (`ProvisionResult`) y
  confirmación real por `<PROVISION_OK`.
- Chip de estado único por tarjeta en el escáner (`AccessoryChip`).
- Sistema de movimiento (`widgets/motion.dart`): slide-up del wizard,
  slide-over del detalle, cross-fade de Ajustes, punto "en vivo" pulsante.
- Componentes custom que reemplazan Material: `WtButton`, `WtNavBar`,
  `WtSwitch`, diálogo (`showWtConfirm`) y toast (`showWtToast`).
- Tokens de color mode-aware (`WtColors`): `surface2`, `neutral`, `divider`,
  `redSoft`, `greenSoft`, `panel`, `disabled` — modo oscuro consistente.

### Cambiado
- `disableCut()` confirma con `<CUT_DISABLED` y relanza `>STATUS`.
- Detalle: acción única "Liberar corte" con modal de confirmación.
- Al desprovisionar, la placa se renombra al genérico `WT-xxxx` (por detrás).
- `DeviceState.initial()` arranca con `provisioned: false`.

### Eliminado
- Modo test/producción (`app_mode.dart`) y banco de pruebas del flujo de instalador.
- Selector de tipo de accesorio, UI de master key y toggle de corte.
- Botón de edición (lápiz) del detalle y código muerto de comandos de testeo.
- Pantallas/servicios de legado: `login_screen`, `assign_vehicles_screen`,
  `user_store`, `app_user`, `profile_screen`.

## Prototipo previo

- `1.2.0` — prototipo funcional (repositorio anterior `wt_gateway_app`).
