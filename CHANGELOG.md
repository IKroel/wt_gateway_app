# Changelog

Formato basado en [Keep a Changelog](https://keepachangelog.com/es/1.1.0/).
Versionado semántico: `MAJOR.MINOR.PATCH+BUILD`.

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

### Seguridad
- La master key ya no se versiona: se inyecta con `--dart-define=WT_MASTER_SECRET`;
  el repo trae solo un placeholder no funcional.

### Eliminado
- Modo test/producción (`app_mode.dart`) y banco de pruebas del flujo de instalador.
- Selector de tipo de accesorio, UI de master key y toggle de corte.
- Botón de edición (lápiz) del detalle y código muerto de comandos de testeo.
- Pantallas/servicios de legado: `login_screen`, `assign_vehicles_screen`,
  `user_store`, `app_user`, `profile_screen`.

## Prototipo previo

- `1.2.0` — prototipo funcional (repositorio anterior `wt_gateway_app`).
