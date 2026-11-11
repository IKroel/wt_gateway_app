// Constantes globales: master key, UUIDs NUS y filtro BLE.
//
// Master key: no se versiona. Se inyecta al compilar con
//   --dart-define-from-file=<archivo.json>   ({"WT_MASTER_SECRET": "<64 hex>"})
// Sin ella la app no puede autenticar ni asignar equipos.
const String kMasterSecret = String.fromEnvironment('WT_MASTER_SECRET');

// BLE — Nordic UART Service
const String kNusSvcUuid = '6E400001-B5A3-F393-E0A9-E50E24DCCA9E';
const String kNusRxUuid  = '6E400002-B5A3-F393-E0A9-E50E24DCCA9E'; // write
const String kNusTxUuid  = '6E400003-B5A3-F393-E0A9-E50E24DCCA9E'; // notify

// Filtro manufacturer data: FF FF 'W' 'T' 0x01
const int kWtMfgId = 0xFFFF;
const List<int> kWtMfgPrefix = [0x57, 0x54, 0x01];

const int kScanTimeoutSec = 10;
