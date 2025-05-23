class SoilNutritionData {
  final double nitrogen;
  final double phosphorus;
  final double potassium;
  final double phValue;

  SoilNutritionData({
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    required this.phValue,
  });

  factory SoilNutritionData.fromMap(Map<dynamic, dynamic> map) {
    return SoilNutritionData(
      nitrogen: (map['nitrogen'] ?? 0).toDouble(),
      phosphorus: (map['phosphorus'] ?? 0).toDouble(),
      potassium: (map['potassium'] ?? 0).toDouble(),
      phValue: (map['pH_Value'] ?? 0).toDouble(),
    );
  }
}