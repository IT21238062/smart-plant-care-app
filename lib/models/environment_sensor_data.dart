class EnvironmentSensorData {
  final int fanStatus;
  final double airflow;
  final double humidity;
  final double temperature;

  EnvironmentSensorData({
    required this.fanStatus,
    required this.airflow,
    required this.humidity,
    required this.temperature,
  });

  factory EnvironmentSensorData.fromMap(Map<dynamic, dynamic> map) {
    return EnvironmentSensorData(
      fanStatus: map['fanStatus'] ?? 0,
      airflow: (map['airflow'] ?? 0).toDouble(),
      humidity: (map['humidity'] ?? 0).toDouble(),
      temperature: (map['temperature'] ?? 0).toDouble(),
    );
  }
}