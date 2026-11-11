// Estado del dispositivo ESP32 (V2).
// El corte es autónomo (ignición + geocerca). La app solo deshabilita.

enum RelayState { cutActive, free, unknown }

/// Chip único de estado para la tarjeta del escáner.
enum AccessoryChip { unassigned, cutActive, released, unread }

class DeviceState {
  final String name;
  final RelayState relay;
  final bool connected;
  final bool provisioned;
  final bool? ignOn;
  final bool? inGeo;
  final bool? cutDisabled;
  /// Modo de la placa (`mode=` en <STATUS / <VERSION): 'protect' | 'sharing'.
  /// null = sin dato (firmware sin modos).
  final String? mode;
  /// Capacidades anunciadas en <VERSION caps=...>. Vacío = firmware antiguo.
  final Set<String> caps;
  /// Placa habilitada (`en=` en <STATUS). false = standby: no corta ni acciona puertas.
  final bool? enabled;
  final String? lastError;

  const DeviceState({
    required this.name,
    required this.relay,
    required this.connected,
    required this.provisioned,
    this.ignOn,
    this.inGeo,
    this.cutDisabled,
    this.mode,
    this.caps = const {},
    this.enabled,
    this.lastError,
  });

  factory DeviceState.initial() => const DeviceState(
        name: 'Desconocido',
        relay: RelayState.unknown,
        connected: false,
        provisioned: false,
      );

  DeviceState copyWith({
    String? name,
    RelayState? relay,
    bool? connected,
    bool? provisioned,
    bool? ignOn,
    bool? inGeo,
    bool? cutDisabled,
    String? mode,
    Set<String>? caps,
    bool? enabled,
    String? lastError,
    bool clearError = false,
  }) =>
      DeviceState(
        name: name ?? this.name,
        relay: relay ?? this.relay,
        connected: connected ?? this.connected,
        provisioned: provisioned ?? this.provisioned,
        ignOn: ignOn ?? this.ignOn,
        inGeo: inGeo ?? this.inGeo,
        cutDisabled: cutDisabled ?? this.cutDisabled,
        mode: mode ?? this.mode,
        caps: caps ?? this.caps,
        enabled: enabled ?? this.enabled,
        lastError: clearError ? null : (lastError ?? this.lastError),
      );

  /// Sharing: el corte (protect) sigue activo y además acciona las puertas.
  /// Se compara por prefijo para cubrir variantes de sharing fijadas desde el GPS.
  bool get isSharing => mode?.startsWith('sharing') ?? false;
  String get modeLabel => switch (mode) {
        null => '—',
        'protect' => 'Protect',
        'sharing' => 'Sharing',
        _ => mode!,
      };
  /// La placa acepta >SET_MODE (fw V3).
  bool get supportsModes => caps.contains('mode');
  /// La placa acepta >ENABLE 1|0 (fw >= 3.4.6).
  bool get supportsEnable => caps.contains('enable');

  /// Chip derivado del estado para la lista de equipos.
  AccessoryChip get chip {
    if (!provisioned) return AccessoryChip.unassigned;
    if (cutDisabled == true) return AccessoryChip.released;
    if (relay == RelayState.cutActive) return AccessoryChip.cutActive;
    if (relay == RelayState.unknown || cutDisabled == null) {
      return AccessoryChip.unread;
    }
    return AccessoryChip.released;
  }

  String get relayLabel => switch (relay) {
        RelayState.cutActive => 'Corte activo',
        RelayState.free => 'Liberado',
        RelayState.unknown => '—',
      };
}
