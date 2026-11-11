# wt_gateway_app

Aplicación **Flutter (Android)** para instaladores: se conecta por Bluetooth
al módulo ESP32, lo asigna a un vehículo y libera el corte de combustible.
Con firmware V3 el módulo se asigna en modo Protect (corte) o Sharing
(corte + puertas). El corte lo aplica el equipo de forma autónoma.

- **Versión:** 1.1.0 · ver [CHANGELOG.md](CHANGELOG.md)
- **Plataforma:** Android
- **Licencia:** [MIT](LICENSE)

---

## Estado del proyecto

El proyecto está **funcional** con el firmware V1 (corte) y V3 (corte + puertas,
`>= 3.4.0`): escanear, conectar, asignar y liberar el corte funcionan sobre un
equipo real.
Es un release estable y modular pensado para
que otros la clonen y agreguen módulos.

### Implementado y funcional

- Escaneo BLE con filtro y agrupación por cercanía.
- Chip de estado por equipo: `Sin asignar`, `Corte activo`, `Liberado`, `Estado sin leer`.
- Conexión guiada en 3 pasos (Conectar → Autenticar → Leer estado) con reintento por etapa.
- Autenticación reto-respuesta HMAC-SHA256.
- Wizard de asignación en 4 pasos (identificar y elegir modo → confirmar → provisionar → listo).
- Liberar corte del equipo, con la confirmación del GPS (firmware V3).
- Desasignar equipo (renombra la placa al genérico `WT-xxxx`).
- Modo de la placa al asignar: `Protect` (solo corte por ignición) o `Sharing`
  (el corte por ignición también cierra las puertas y liberarlo desde la app
  las abre). Firmware V3.
- Aviso de standby con botón Habilitar y aviso de corte activado (firmware V3).
- Log de depuración exportable, con la respuesta del GPS (OK/ERROR) a cada orden.

Los modos y avisos solo se muestran si el firmware los anuncia en
`<VERSION caps=...>`; con firmware V1 la app se comporta igual que en 1.0.0.

### Fuera del alcance

- Asignacion de Usuarios (Creacion de Cuenta o Similares).
- Compilación y validación en iOS.

---

## Requisitos

| Herramienta | Versión / nota |
|---|---|
| Flutter SDK | `>=3.6.0 <4.0.0` (Flutter 3.27+ / Dart 3.6+) |
| Android SDK | API 21+ |
| Dispositivo | Android físico con Bluetooth |

Dependencias clave: `flutter_blue_plus`, `crypto`, `convert`,
`permission_handler`, `shared_preferences`, `path_provider`, `share_plus`.

La master key **no está en el repositorio**. Pídela al responsable del proyecto
y guárdala fuera del repo en un JSON:

```json
{"WT_MASTER_SECRET": "<64 caracteres hex>"}
```

Se pasa al compilar con `--dart-define-from-file=<ruta al JSON>` (ver abajo).
Sin ella la app abre, pero no puede autenticar ni asignar equipos.

---

## Cómo correrlo

```bash
git clone https://github.com/IKroel/wt_gateway_app.git
cd wt_gateway_app
flutter pub get
flutter run --dart-define-from-file=<ruta>/wt_master_key.json
```

Si al clonar faltan las carpetas de plataforma (`android/`, `ios/`), genéralas
sin tocar `lib/` y vuelve a correr:

```bash
flutter create .
flutter pub get
flutter run --dart-define-from-file=<ruta>/wt_master_key.json
```

Compilar el APK de release:

```bash
flutter build apk --release --dart-define-from-file=<ruta>/wt_master_key.json
```

Verificar código:

```bash
dart format .
flutter analyze
```

Los permisos BLE ya están declarados en
`android/app/src/main/AndroidManifest.xml`
(`BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, `ACCESS_FINE_LOCATION`).

---

## Estructura

```
lib/
├── config.dart      Constantes: master key (inyectada), UUIDs NUS, filtro BLE.
├── main.dart        Entrada, init de stores, MaterialApp + tema.
├── models/          DeviceState (+ AccessoryChip), VehicleType, BoardMode.
├── services/        BLE, cripto (HMAC), stores (tema/equipos), log.
├── theme/           Sistema de diseño: WtColors mode-aware + ThemeData.
├── widgets/         Componentes reutilizables (botón, nav, switch,
│                    diálogo, toast, animaciones, chips, señal).
└── screens/         scanner, connection, device, provision (wizard),
                     settings, debug, edit_vehicle_dialog.
```

---

## Cómo extender

1. Crea la pantalla nueva en `lib/screens/`.
2. Navega con las rutas de `lib/widgets/motion.dart` (`slideUpRoute`,
   `slideOverRoute`) para mantener el movimiento consistente.
3. Reutiliza los componentes de `lib/widgets/` y los tokens de
   `lib/theme/wt_theme.dart` (`wt.*` para superficies y texto; `kTeal`,
   `kPetrol`, etc. para acentos de marca).
4. Agrega comandos BLE nuevos en `lib/services/ble_service.dart`, respetando el
   patrón de fases y errores tipados.

Guía completa en [CONTRIBUTING.md](CONTRIBUTING.md).

---

## Protocolo BLE

Transporte Nordic UART Service (`6E400001` / RX `…0002` / TX `…0003`). Comandos
ASCII con prefijo `>`, respuestas con `<`. Autenticación:

```
device_key = HMAC-SHA256(master, MAC_bytes[6])
token      = HMAC-SHA256(device_key, nonce)[0:16]
```

Comandos: `>STATUS`, `>CHALLENGE`, `>AUTH`, `>MAC`, `>NAME`, `>PROVISION`,
`>DISABLECUT`, `>UNPROVISION`, `>VERSION`.

Firmware V3 (car sharing) agrega, entre otros: `>SET_MODE protect|sharing`,
`>ENABLE 1|0`, `<RELEASE` (resultado de la liberación) y `<LOCK` (corte
aplicado). `<STATUS` suma `mode=` y `en=`. La app usa solo esos; el resto del
protocolo está en `docs/PROTOCOLO.md` del firmware V3.

---

## Versionado

Semver `MAJOR.MINOR.PATCH+BUILD` en `pubspec.yaml`. Cada cambio relevante queda
en [CHANGELOG.md](CHANGELOG.md). Trabaja siempre sobre la última versión
publicada ahí.
