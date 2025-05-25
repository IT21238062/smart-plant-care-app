import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import '../models/water_sensor_data.dart';
import 'prediction_history_screen.dart'; // Import the history screen we'll create next

class WaterControlScreen extends StatefulWidget {
  const WaterControlScreen({Key? key}) : super(key: key);

  @override
  _WaterControlScreenState createState() => _WaterControlScreenState();
}

class _WaterControlScreenState extends State<WaterControlScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  late DatabaseReference _sensorRef;

  WaterSensorData? _currentData;
  String _connectionStatus = 'Connecting...';
  String _predictionText = '';
  int _lastPredictionLevel = 0;
  bool _isLoading = false;
  bool _motorRunning = false;
  Timer? _motorTimer;

  // Your exact sensor ranges
  static const double MAX_EC = 500;
  static const double MAX_MOISTURE = 6000;
  static const double MIN_TEMP = 20;
  static const double MAX_TEMP = 40;

  // Prediction level to text mapping
  static const Map<int, String> predictionTexts = {
    1: "Dry soil need full irrigation",
    2: "Semi dry soil needs watering",
    3: "Little bit dry soil need some watering",
    4: "Little bit wet soil but need small amount of water",
    5: "Wet soil no need to water"
  };

  // Motor duration mapping (seconds)
  static const Map<int, int> motorDurations = {
    1: 5, 2: 4, 3: 3, 4: 2, 5: 0
  };

  @override
  void initState() {
    super.initState();
    _sensorRef = _database.child('Sensor_IrrigationCTRL');
    _startListening();
  }

  void _startListening() {
    _sensorRef.onValue.listen((DatabaseEvent event) {
      if (event.snapshot.exists) {
        setState(() {
          _currentData = WaterSensorData.fromMap(
              event.snapshot.value as Map<dynamic, dynamic>
          );
          _connectionStatus = 'Connected';
          _motorRunning = _currentData!.motorStatus == 1;
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
        Uri.parse('https://water-backend-production-fda9.up.railway.app/predict'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'soil_ec': _currentData!.soilEC,
          'soil_moisture': _currentData!.soilMoisture,
          'soil_temperature': _currentData!.soilTemp,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('API Response: $data'); // Debug print

        // Handle different possible response formats
        int predictionLevel;
        if (data['prediction'] != null) {
          predictionLevel = (data['prediction'] is String)
              ? int.parse(data['prediction'].toString())
              : data['prediction'] as int;
        } else if (data['water_level'] != null) {
          predictionLevel = (data['water_level'] is String)
              ? int.parse(data['water_level'].toString())
              : data['water_level'] as int;
        } else {
          throw Exception('No prediction found in response');
        }

        setState(() {
          _lastPredictionLevel = predictionLevel;
          _predictionText = predictionTexts[predictionLevel] ?? 'Unknown prediction';
          _isLoading = false;
        });

        // Store prediction result in Firebase
        await _database.child('predictions').push().set({
          'prediction_level': predictionLevel,
          'prediction_text': _predictionText,
          'sensor_data': {
            'soil_ec': _currentData!.soilEC,
            'soil_moisture': _currentData!.soilMoisture,
            'soil_temp': _currentData!.soilTemp,
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

  Future<void> _controlMotor() async {
    if (_lastPredictionLevel == 0 || _lastPredictionLevel == 5) return;

    final duration = motorDurations[_lastPredictionLevel] ?? 0;
    if (duration == 0) return;

    try {
      // Turn motor ON
      await _sensorRef.update({'motorStatus': 1});

      setState(() {
        _motorRunning = true;
      });

      // Set timer to turn motor OFF after duration
      _motorTimer?.cancel();
      _motorTimer = Timer(Duration(seconds: duration), () async {
        try {
          await _sensorRef.update({'motorStatus': 0});
          setState(() {
            _motorRunning = false;
          });
        } catch (e) {
          print('Error turning motor off: $e');
        }
      });

    } catch (e) {
      setState(() {
        _motorRunning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Motor control error: $e')),
      );
    }
  }

  Color _getStatusColor(String status) {
    if (status == 'Connected') return Colors.green;
    if (status.contains('not connected')) return Colors.red;
    return Colors.orange;
  }

  Color _getValueColor(double value, double max, {bool isTemp = false}) {
    if (isTemp) {
      if (value < 22) return Colors.blue;
      if (value > 35) return Colors.red;
      return Colors.green;
    }

    final percentage = value / max;
    if (percentage < 0.3) return Colors.red;
    if (percentage < 0.7) return Colors.orange;
    return Colors.green;
  }

  @override
  void dispose() {
    _motorTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🌱 Water Control'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          // History button
          IconButton(
            icon: Icon(Icons.history),
            tooltip: 'Prediction History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PredictionHistoryScreen(),
                ),
              );
            },
          ),
        ],
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

                      // Soil EC
                      _buildSensorRow(
                        '⚡ EC',
                        '${_currentData!.soilEC.toStringAsFixed(1)} μS/cm',
                        _currentData!.soilEC,
                        MAX_EC,
                      ),

                      SizedBox(height: 8),

                      // Soil Moisture
                      _buildSensorRow(
                        '💧 Moisture',
                        '${_currentData!.soilMoisture.toStringAsFixed(0)}',
                        _currentData!.soilMoisture,
                        MAX_MOISTURE,
                      ),

                      SizedBox(height: 8),

                      // Temperature
                      _buildSensorRow(
                        '🌡️ Temperature',
                        '${_currentData!.soilTemp.toStringAsFixed(1)}°C',
                        _currentData!.soilTemp,
                        MAX_TEMP,
                        isTemp: true,
                      ),

                      SizedBox(height: 8),

                      // Motor Status
                      Row(
                        children: [
                          Text('🔧 Motor: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          Icon(
                            _motorRunning ? Icons.play_circle : Icons.stop_circle,
                            color: _motorRunning ? Colors.blue : Colors.grey,
                          ),
                          SizedBox(width: 4),
                          Text(
                            _motorRunning ? 'RUNNING' : 'OFF',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _motorRunning ? Colors.blue : Colors.grey,
                            ),
                          ),
                        ],
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

              SizedBox(height: 16),

              // Motor Control Section
              if (_lastPredictionLevel > 0 && _lastPredictionLevel < 5) ...[
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '🚿 Motor Control',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),

                        ElevatedButton.icon(
                          onPressed: _motorRunning ? null : _controlMotor,
                          icon: Icon(_motorRunning ? Icons.hourglass_top : Icons.water_drop),
                          label: Text(
                              _motorRunning
                                  ? 'MOTOR RUNNING...'
                                  : 'START WATERING (${motorDurations[_lastPredictionLevel]}s)'
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _motorRunning ? Colors.grey : Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),

                        if (_lastPredictionLevel > 0) ...[
                          SizedBox(height: 8),
                          Text(
                            'Action: Level $_lastPredictionLevel → ${motorDurations[_lastPredictionLevel]} seconds watering',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
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

  Widget _buildSensorRow(String label, String value, double currentValue, double maxValue, {bool isTemp = false}) {
    final color = _getValueColor(currentValue, maxValue, isTemp: isTemp);
    final percentage = isTemp
        ? (currentValue - MIN_TEMP) / (MAX_TEMP - MIN_TEMP)
        : currentValue / maxValue;

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