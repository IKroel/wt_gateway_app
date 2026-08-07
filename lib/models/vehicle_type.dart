import 'package:flutter/material.dart';

enum VehicleType { auto, camioneta, camion, maquinaria }

extension VehicleTypeX on VehicleType {
  String get label => switch (this) {
        VehicleType.auto => 'Auto',
        VehicleType.camioneta => 'Camioneta',
        VehicleType.camion => 'Camión',
        VehicleType.maquinaria => 'Maquinaria',
      };

  IconData get icon => switch (this) {
        VehicleType.auto => Icons.directions_car,
        VehicleType.camioneta => Icons.airport_shuttle,
        VehicleType.camion => Icons.local_shipping,
        VehicleType.maquinaria => Icons.agriculture,
      };
}
