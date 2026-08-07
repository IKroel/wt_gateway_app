// Constantes globales: master key, UUIDs NUS y filtro BLE.
//
// SEGURIDAD: la master key NO se versiona. Inyéctala al compilar:
//   flutter run   --dart-define=WT_MASTER_SECRET=<64 hex>
//   flutter build --dart-define=WT_MASTER_SECRET=<64 hex>
// El valor por defecto es un placeholder NO funcional (solo demo/UI).
// Limitación conocida: aún embebida en el binario resultante. En producción
// debe entregarla el servidor por sesión (JWT → vault) o firmar el nonce
// del lado servidor para que la app nunca vea el master.
const String kMasterSecret = String.fromEnvironment(
  'WT_MASTER_SECRET',
  defaultValue:
      '0000000000000000000000000000000000000000000000000000000000000000',
);

// BLE — Nordic UART Service
const String kNusSvcUuid = '6E400001-B5A3-F393-E0A9-E50E24DCCA9E';
const String kNusRxUuid  = '6E400002-B5A3-F393-E0A9-E50E24DCCA9E'; // write
const String kNusTxUuid  = '6E400003-B5A3-F393-E0A9-E50E24DCCA9E'; // notify

// Filtro manufacturer data: FF FF 'W' 'T' 0x01
const int kWtMfgId = 0xFFFF;
const List<int> kWtMfgPrefix = [0x57, 0x54, 0x01];

const int kScanTimeoutSec = 10;
