# wt_gateway_app

Aplicación **Flutter (Android)** para instaladores. Descubre por Bluetooth (BLE)
los accesorios de corte (placas ESP32), los asigna a un vehículo y permite
liberar el corte de combustible. El corte es autónomo en el equipo —decide por
ignición y geocerca—; la app autentica y solo puede deshabilitarlo.

- **Versión:** 1.0.0 · ver [CHANGELOG.md](CHANGELOG.md)
- **Plataforma:** Android (probado en dispositivo físico)
- **Licencia:** [MIT](LICENSE)

---

## Estado del proyecto

El proyecto está **funcional de extremo a extremo** contra el firmware V1:
escanear, conectar, asignar y liberar el corte funcionan sobre un equipo real.
`flutter analyze` corre sin issues. Es una base estable y modular pensada para
que otros la clonen y agreguen módulos encima.

### Implementado y funcional

- Escaneo BLE con filtro por *manufacturer data* y agrupación por cercanía.
- Chip de estado por equipo: `Sin asignar`, `Corte activo`, `Liberado`, `Estado sin leer`.
- Conexión guiada en 3 pasos (Conectar → Autenticar → Leer estado) con reintento por etapa.
- Autenticación reto-respuesta HMAC-SHA256.
- Wizard de asignación en 4 pasos (identificar → confirmar → provisionar → listo).
- Liberar corte con confirmación real del equipo.
- Desasignar equipo (renombra la placa al genérico `WT-xxxx`).
- Tema claro/oscuro persistido y sistema de diseño propio (componentes custom).
- Log de depuración exportable.

### Fuera de alcance (para extender)

- Backend de flota y sincronización remota.
- Compilación y validación en iOS (el árbol es multiplataforma, pero solo se validó Android).
- Reasignación y auditoría centralizada.
- Pruebas automatizadas más allá del smoke test incluido.

---

## Requisitos

| Herramienta | Versión / nota |
|---|---|
| Flutter SDK | `>=3.6.0 <4.0.0` (Flutter 3.27+ / Dart 3.6+) |
| Android SDK | API 21+ |
| Dispositivo | Android físico con BLE (el emulador no tiene Bluetooth) |

Dependencias clave: `flutter_blue_plus`, `crypto`, `convert`,
`permission_handler`, `shared_preferences`, `path_provider`, `share_plus`.

La master key de pruebas ya viene definida en `lib/config.dart`; no requiere
configuración adicional para trabajar contra los equipos de prueba.

---

## Cómo correrlo

```bash
git clone https://github.com/IKroel/wt_gateway_app.git
cd wt_gateway_app
flutter pub get
flutter run
```

Si al clonar faltan las carpetas de plataforma (`android/`, `ios/`), genéralas
sin tocar `lib/` y vuelve a correr:

```bash
flutter create .
flutter pub get
flutter run
```

Compilar el APK de release:

```bash
flutter build apk --release
```

Verificar calidad del código:

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
├── config.dart      Constantes: master key, UUIDs NUS, filtro BLE.
├── main.dart        Entrada, init de stores, MaterialApp + tema.
├── models/          DeviceState (+ AccessoryChip), VehicleType.
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

---

## Versionado

Semver `MAJOR.MINOR.PATCH+BUILD` en `pubspec.yaml`. Cada cambio relevante queda
en [CHANGELOG.md](CHANGELOG.md). Trabaja siempre sobre la última versión
publicada ahí.
