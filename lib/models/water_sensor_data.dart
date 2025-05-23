class WaterSensorData {
  final int motorStatus;
  final double soilEC;
  final double soilMoisture;
  final double soilTemp;

  WaterSensorData({
    required this.motorStatus,
    required this.soilEC,
    required this.soilMoisture,
    required this.soilTemp,
  });

  factory WaterSensorData.fromMap(Map<dynamic, dynamic> map) {
    return WaterSensorData(
      motorStatus: map['motorStatus'] ?? 0,
      soilEC: (map['soilEC'] ?? 0).toDouble(),
      soilMoisture: (map['soilMoisture'] ?? 0).toDouble(),
      soilTemp: (map['soilTemp'] ?? 0).toDouble(),
    );
  }
}