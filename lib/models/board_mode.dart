// Modos de operación de la placa (fw V3, `caps=mode`). Se guardan en la placa
// (NVS): se eligen al asignar o desde el GPS (`8|modo`).

class BoardMode {
  static const protect = 'protect';
  static const sharing = 'sharing';

  /// (valor enviado en >SET_MODE, etiqueta, descripción).
  static const options = [
    (protect, 'Protect', 'Solo corte por ignición.'),
    (sharing, 'Sharing',
        'Protect + puertas: el corte por ignición cierra las puertas y liberarlo desde la app las abre.'),
  ];

  static String label(String m) =>
      options.firstWhere((o) => o.$1 == m, orElse: () => options.first).$2;
}
