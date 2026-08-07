// Constantes globales: master key, UUIDs NUS y filtro BLE.
//
// Master key de pruebas: única y compartida por todos los equipos de prueba.
const String kMasterSecret =
    'cfc03b94812eee0b3d3b385b1378bb034c8303cdc94975ce34958056d0a5f76c';

// BLE — Nordic UART Service
const String kNusSvcUuid = '6E400001-B5A3-F393-E0A9-E50E24DCCA9E';
const String kNusRxUuid  = '6E400002-B5A3-F393-E0A9-E50E24DCCA9E'; // write
const String kNusTxUuid  = '6E400003-B5A3-F393-E0A9-E50E24DCCA9E'; // notify

// Filtro manufacturer data: FF FF 'W' 'T' 0x01
const int kWtMfgId = 0xFFFF;
const List<int> kWtMfgPrefix = [0x57, 0x54, 0x01];

const int kScanTimeoutSec = 10;
