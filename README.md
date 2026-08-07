# wt_gateway_app

App **Flutter (Android)** para instaladores: descubre por BLE los accesorios
de corte (placas ESP32), los **asigna/provisiona** y permite **liberar el corte
de combustible**. El corte es **autónomo en el equipo** (decide por ignición +
geocerca); la app solo autentica y puede *deshabilitarlo*.

- Versión actual: **1.0.0** · ver [CHANGELOG.md](CHANGELOG.md)
- Estado: **funcional de extremo a extremo** sobre firmware V1 (ver más abajo)
- Licencia: [MIT](LICENSE)

---

## Estado del proyecto

### Listo y funcional
- Escaneo BLE con filtro por *manufacturer data* y agrupación por cercanía.
- Chip de estado único por equipo (Sin asignar / Corte activo / Liberado / Estado sin leer).
- Conexión en 3 pasos (Conectar → Autenticar → Leer estado) como *bottom sheet*, con reintento por etapa.
- Autenticación reto-respuesta HMAC-SHA256.
- Wizard de asignación (identificar → confirmar → provisionar → listo) con resultado tipado.
- Liberar corte con confirmación real (`<CUT_DISABLED`).
- Desasignar equipo (renombra la placa al genérico `WT-xxxx` por detrás).
- Tema claro/oscuro persistido, sistema de diseño propio y componentes custom.
- Log de depuración exportable.
- `flutter analyze`: **0 issues**.

### No incluido / pensado para extender
- Entrega de la master key desde servidor (hoy se inyecta por `--dart-define`; ver [Seguridad](#seguridad)).
- iOS (el proyecto compila multiplataforma pero solo se validó en Android).
- Backend de flota / sincronización remota.
- Reasignación remota y auditoría centralizada.
- Pruebas automatizadas más allá del smoke test.

---

## Requisitos

| Herramienta | Versión |
|---|---|
| Flutter SDK | `>=3.6.0 <4.0.0` (Flutter 3.27+ / Dart 3.6+) |
| Android SDK | API 21+ (compileSdk según Flutter) |
| Dispositivo | Android físico con BLE (el emulador no tiene Bluetooth) |

Dependencias principales (`pubspec.yaml`): `flutter_blue_plus`, `crypto`,
`convert`, `permission_handler`, `shared_preferences`, `path_provider`,
`share_plus`.

---

## Puesta en marcha (entorno propio)

```bash
# 1. Clonar
git clone https://github.com/<usuario>/wt_gateway_app.git
cd wt_gateway_app

# 2. (Solo si faltan carpetas de plataforma android/ o ios/)
flutter create .

# 3. Dependencias
flutter pub get

# 4. Ejecutar en un dispositivo Android conectado, inyectando la master key
flutter run --dart-define=WT_MASTER_SECRET=<64_caracteres_hex>
```

Compilar el APK de release:

```bash
flutter build apk --release --dart-define=WT_MASTER_SECRET=<64_caracteres_hex>
```

Generar una master key de ejemplo:

```bash
python3 -c "import secrets; print(secrets.token_hex(32))"
```

Los permisos BLE ya están declarados en
`android/app/src/main/AndroidManifest.xml`
(`BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, `ACCESS_FINE_LOCATION`).

---

## Estructura

```
lib/
├── config.dart            constantes (master key vía --dart-define, UUIDs NUS, filtro BLE)
├── main.dart              entrada, init de stores, MaterialApp + tema
├── models/                DeviceState (+ AccessoryChip), VehicleType
├── services/              BLE, cripto (HMAC), stores (tema/equipos/master), log
├── theme/                 sistema de diseño (WtColors mode-aware, ThemeData)
├── widgets/               componentes reutilizables:
│                          wt_button, wt_nav_bar, wt_switch, wt_dialog, wt_toast,
│                          motion (rutas/animaciones), status_chip, signal_bars,
│                          circle_button, icon_chip
└── screens/               scanner, connection (sheet), device, provision (wizard),
                           settings, debug, edit_vehicle_dialog
```

Para **agregar un módulo**: crea la pantalla en `screens/`, reutiliza los
`widgets/` y los tokens de `theme/wt_theme.dart` (`wt.*` + constantes de marca),
y expón la lógica BLE nueva en `services/ble_service.dart`.

---

## Protocolo BLE

Transporte **Nordic UART Service** (`6E400001` / RX `…0002` / TX `…0003`).
Comandos ASCII con prefijo `>`, respuestas con `<`. Autenticación:

```
device_key = HMAC-SHA256(master, MAC_bytes[6])
token      = HMAC-SHA256(device_key, nonce)[0:16]
```

Comandos usados: `>STATUS`, `>CHALLENGE`, `>AUTH`, `>MAC`, `>NAME`,
`>PROVISION`, `>DISABLECUT`, `>UNPROVISION`, `>VERSION`.

---

## Seguridad

> La master key **no se versiona**. El repositorio trae un placeholder no
> funcional (`0000…`). Inyecta la real con `--dart-define=WT_MASTER_SECRET=...`.
>
> Limitación conocida: la key inyectada queda embebida en el binario, por lo que
> quien decompile el APK puede derivar la `device_key` de cualquier equipo. Para
> producción, la key debe entregarla el servidor por sesión (login → JWT → vault)
> o moverse la firma del nonce al lado servidor. No publiques APKs de release con
> la master real.

---

## Versionado

Semver `MAJOR.MINOR.PATCH+BUILD` en `pubspec.yaml`. Todo cambio relevante se
registra en [CHANGELOG.md](CHANGELOG.md). Trabaja siempre sobre la última
versión publicada ahí.

## Contribuir

Ver [CONTRIBUTING.md](CONTRIBUTING.md). Regla mínima: `flutter analyze` sin
issues y `dart format .` antes de abrir un PR.
