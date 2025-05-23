import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/soil_nutrition_data.dart';

class SoilNutritionScreen extends StatefulWidget {
  const SoilNutritionScreen({Key? key}) : super(key: key);

  @override
  _SoilNutritionScreenState createState() => _SoilNutritionScreenState();
}

class _SoilNutritionScreenState extends State<SoilNutritionScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  late DatabaseReference _sensorRef;

  SoilNutritionData? _currentData;
  String _connectionStatus = 'Connecting...';
  String _predictionText = '';
  String _fertilizeAdvice = '';
  int _lastPredictionLevel = 0;
  bool _isLoading = false;

  // Your exact sensor ranges
  static const double MAX_NITROGEN = 100;
  static const double MAX_PHOSPHORUS = 120;
  static const double MAX_POTASSIUM = 110;
  static const double MAX_PH = 14;

  // Prediction level to text mapping
  static const Map<int, String> predictionTexts = {
    1: "Soil is extremely poor in nitrogen, phosphorus, and potassium",
    2: "Adequate P and K, but nitrogen-deficient",
    3: "Poor phosphorus with sufficient N and K",
    4: "Potassium lacking despite good N and P",
    5: "Soil lacks N and P, but K is adequate",
    6: "Deficiency in P and K with sufficient nitrogen",
    7: "Phosphorus is sufficient; N and K are low",
    8: "All nutrients are within optimal range"
  };

  // Fertilizer advice mapping
  static const Map<int, String> fertilizerAdvice = {
    1: "Need Fertilizer Advice: (Quantity for 100 sq ft)\n-Urea: 230g\n-SSP: 345g\n-MOP: 115g",
    2: "Need Fertilizer Advice: (Quantity for 100 sq ft)\n-Urea: 183g",
    3: "Need Fertilizer Advice: (Quantity for 100 sq ft)\n-SSP: 287g\nor DAP: 138g",
    4: "Need Fertilizer Advice: (Quantity for 100 sq ft)\n-MOP: 92g\nor SOP: 80g",
    5: "Need Fertilizer Advice: (Quantity for 100 sq ft)\n-Urea: 183g\n-SSP: 287g\nor DAP: 138g",
    6: "Need Fertilizer Advice: (Quantity for 100 sq ft)\n-SSP: 287g + MOP: 92g\nor DAP: 138g + MOP: 92g",
    7: "Need Fertilizer Advice: (Quantity for 100 sq ft)\n-Urea: 183g + MOP: 92g\nor AS: 345g + SOP: 80g",
    8: "Need Fertilizer Advice: (Quantity for 100 sq ft)\n-No need to add Fertilizer\n-Maintain using Compost"
  };

  @override
  void initState() {
    super.initState();
    _sensorRef = _database.child('Soil_Nutrition');
    _startListening();
  }

  void _startListening() {
    _sensorRef.onValue.listen((DatabaseEvent event) {
      if (event.snapshot.exists) {
        setState(() {
          _currentData = SoilNutritionData.fromMap(
              event.snapshot.value as Map<dynamic, dynamic>
          );
          _connectionStatus = 'Connected';
        });
      } else {
        setState(() {
          _connectionStatus = 'Sensor not connected please check sensor connection';
        });
      }
    }).onError((error) {
      setState(() {
        _connectionStatus = 'Connection error: $error';
      });
    });
  }

  Future<void> _getPrediction() async {
    if (_currentData == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://believable-connection-production-14a7.up.railway.app/predict'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'n': _currentData!.nitrogen,
          'p': _currentData!.phosphorus,
          'k': _currentData!.potassium,
          'ph': _currentData!.phValue,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('API Response: $data'); // Debug print

        // Handle response format
        int predictionLevel;
        if (data['prediction'] != null) {
          predictionLevel = (data['prediction'] is String)
              ? int.parse(data['prediction'].toString())
              : data['prediction'] as int;
        } else {
          throw Exception('No prediction found in response');
        }

        setState(() {
          _lastPredictionLevel = predictionLevel;
          _predictionText = predictionTexts[predictionLevel] ?? 'Unknown prediction';
          _fertilizeAdvice = fertilizerAdvice[predictionLevel] ?? '';
          _isLoading = false;
        });

        // Store prediction result in Firebase
        await _database.child('predictions/nutrition').push().set({
          'prediction_level': predictionLevel,
          'prediction_text': _predictionText,
          'fertilizer_advice': _fertilizeAdvice,
          'sensor_data': {
            'nitrogen': _currentData!.nitrogen,
            'phosphorus': _currentData!.phosphorus,
            'potassium': _currentData!.potassium,
            'ph_value': _currentData!.phValue,
          },
          'timestamp': ServerValue.timestamp,
        });

      } else {
        throw Exception('Prediction failed: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _predictionText = 'Error getting prediction: $e';
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    if (status == 'Connected') return Colors.green;
    if (status.contains('not connected')) return Colors.red;
    return Colors.orange;
  }

  Color _getValueColor(double value, double max, {bool isPH = false}) {
    if (isPH) {
      // For pH, the ideal range is around 6-7
      if (value < 5.5 || value > 7.5) return Colors.red;
      if (value < 6.0 || value > 7.0) return Colors.orange;
      return Colors.green;
    }

    final percentage = value / max;
    if (percentage < 0.3) return Colors.red;
    if (percentage < 0.7) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🌱 Soil Nutrition'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connection Status
            Card(
              color: _getStatusColor(_connectionStatus).withOpacity(0.1),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _connectionStatus == 'Connected'
                          ? Icons.wifi
                          : Icons.wifi_off,
                      color: _getStatusColor(_connectionStatus),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _connectionStatus,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(_connectionStatus),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Live Sensor Data
            if (_currentData != null) ...[
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📊 Live Sensor Data',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),

                      // Nitrogen
                      _buildSensorRow(
                        '🟢 Nitrogen (N)',
                        '${_currentData!.nitrogen.toStringAsFixed(1)}',
                        _currentData!.nitrogen,
                        MAX_NITROGEN,
                      ),

                      SizedBox(height: 8),

                      // Phosphorus
                      _buildSensorRow(
                        '🟠 Phosphorus (P)',
                        '${_currentData!.phosphorus.toStringAsFixed(1)}',
                        _currentData!.phosphorus,
                        MAX_PHOSPHORUS,
                      ),

                      SizedBox(height: 8),

                      // Potassium
                      _buildSensorRow(
                        '🟣 Potassium (K)',
                        '${_currentData!.potassium.toStringAsFixed(1)}',
                        _currentData!.potassium,
                        MAX_POTASSIUM,
                      ),

                      SizedBox(height: 8),

                      // pH
                      _buildSensorRow(
                        '🔵 pH Value',
                        '${_currentData!.phValue.toStringAsFixed(1)}',
                        _currentData!.phValue,
                        MAX_PH,
                        isPH: true,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Prediction Section
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '🔮 AI Prediction',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),

                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _getPrediction,
                        icon: _isLoading
                            ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : Icon(Icons.psychology),
                        label: Text(_isLoading ? 'Getting Prediction...' : 'GET PREDICTION'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),

                      if (_predictionText.isNotEmpty) ...[
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: Text(
                            _predictionText,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Fertilizer Advice Section
              if (_fertilizeAdvice.isNotEmpty) ...[
                SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🧪 Fertilizer Recommendation',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          _fertilizeAdvice,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                        if (_lastPredictionLevel > 0) ...[
                          SizedBox(height: 8),
                          Text(
                            '📝 Note: SSP = Single Super Phosphate, MOP = Muriate of Potash, SOP = Sulfate of Potash',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ] else ...[
              // Loading state
              Card(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading sensor data...'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSensorRow(String label, String value, double currentValue, double maxValue, {bool isPH = false}) {
    final color = _getValueColor(currentValue, maxValue, isPH: isPH);
    double percentage;

    if (isPH) {
      // For pH scale (0-14), show position on scale
      percentage = currentValue / maxValue;
    } else {
      percentage = currentValue / maxValue;
    }

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.circle,
                    size: 12,
                    color: color,
                  ),
                ],
              ),
              SizedBox(height: 4),
              LinearProgressIndicator(
                value: percentage.clamp(0.0, 1.0),
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ],
          ),
        ),
      ],
    );
  }
}