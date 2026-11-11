# Guía de contribución

Gracias por sumar. El objetivo del repo es que cualquiera pueda clonar, correr
y **extender** la app con nuevos módulos a partir de una base local.

## Antes de empezar

- Flutter `>=3.6.0`. Corre `flutter doctor` y resuelve lo que marque.
- `flutter pub get`.
- Corre la app con `flutter run --dart-define-from-file=<ruta>/wt_master_key.json`
  (la master key no se versiona; ver README).

## Estilo y calidad

- `dart format .` — formato estándar de Dart.
- `flutter analyze` — debe salir **sin issues** antes de abrir un PR.
- Reutiliza `lib/widgets/` y los tokens de
  `lib/theme/wt_theme.dart` (`wt.*` para superficies/texto mode-aware; las
  constantes `kTeal`, `kPetrol`, etc. para acentos de marca).

## Cómo agregar un módulo / pantalla

1. Crea la pantalla en `lib/screens/`.
2. Navega con las rutas de `lib/widgets/motion.dart`
   (`slideUpRoute`, `slideOverRoute`) para mantener el movimiento consistente.
3. Si necesitas comandos BLE nuevos, agrégalos en
   `lib/services/ble_service.dart` (respeta el patrón de fases/errores tipados).
4. Persistencia local → `lib/services/vehicle_store.dart` u otro store.
