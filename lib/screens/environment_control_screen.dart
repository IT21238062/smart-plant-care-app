import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import '../models/environment_sensor_data.dart';

class EnvironmentControlScreen extends StatefulWidget {
  const EnvironmentControlScreen({Key? key}) : super(key: key);

  @override
  _EnvironmentControlScreenState createState() => _EnvironmentControlScreenState();
}

class _EnvironmentControlScreenState extends State<EnvironmentControlScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  late DatabaseReference _sensorRef;

  EnvironmentSensorData? _currentData;
  String _connectionStatus = 'Connecting...';
  String _predictionText = '';
  int _lastPredictionLevel = 0;
  bool _isLoading = false;
  bool _fanRunning = false;
  Timer? _fanTimer;

  // Your exact sensor ranges
  static const double MAX_AIRFLOW = 20000000;
  static const double MAX_HUMIDITY = 100;
  static const double MIN_TEMP = 20;
  static const double MAX_TEMP = 40;

  // Prediction level to text mapping
  static const Map<int, String> predictionTexts = {
    1: "Perfect Condition",
    2: "Average Condition need little airflow",
    3: "Little Bad condition need airflow",
    4: "Bad condition need little airflow",
    5: "Bad condition need full airflow"
  };

  // Fan duration mapping (seconds)
  static const Map<int, int> fanDurations = {
    1: 0, 2: 2, 3: 4, 4: 6, 5: 8
  };

  @override
  void initState() {
    super.initState();
    _sensorRef = _database.child('Sensor_Environmental');
    _startListening();
  }

  void _startListening() {
    _sensorRef.onValue.listen((DatabaseEvent event) {
      if (event.snapshot.exists) {
        setState(() {
          _currentData = EnvironmentSensorData.fromMap(
              event.snapshot.value as Map<dynamic, dynamic>
          );
          _connectionStatus = 'Connected';
          _fanRunning = _currentData!.fanStatus == 1;
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
        Uri.parse('https://environment-control-api-production.up.railway.app/predict'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'airflow': _currentData!.airflow,
          'humidity': _currentData!.humidity,
          'temperature': _currentData!.temperature,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('API Response: $data'); // Debug print

        // Handle response format
        int predictionLevel;
        if (data['fan_level'] != null) {
          predictionLevel = (data['fan_level'] is String)
              ? int.parse(data['fan_level'].toString())
              : data['fan_level'] as int;
        } else {
          throw Exception('No prediction found in response');
        }

        setState(() {
          _lastPredictionLevel = predictionLevel;
          _predictionText = predictionTexts[predictionLevel] ?? 'Unknown prediction';
          _isLoading = false;
        });

        // Store prediction result in Firebase
        await _database.child('predictions/environment').push().set({
          'prediction_level': predictionLevel,
          'prediction_text': _predictionText,
          'sensor_data': {
            'airflow': _currentData!.airflow,
            'humidity': _currentData!.humidity,
            'temperature': _currentData!.temperature,
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

  Future<void> _controlFan() async {
    if (_lastPredictionLevel == 0 || _lastPredictionLevel == 1) return;

    final duration = fanDurations[_lastPredictionLevel] ?? 0;
    if (duration == 0) return;

    try {
      // Turn fan ON
      await _sensorRef.update({'fanStatus': 1});

      setState(() {
        _fanRunning = true;
      });

      // Set timer to turn fan OFF after duration
      _fanTimer?.cancel();
      _fanTimer = Timer(Duration(seconds: duration), () async {
        try {
          await _sensorRef.update({'fanStatus': 0});
          setState(() {
            _fanRunning = false;
          });
        } catch (e) {
          print('Error turning fan off: $e');
        }
      });

    } catch (e) {
      setState(() {
        _fanRunning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fan control error: $e')),
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
    _fanTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🌡️ Environment Control'),
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

                      // Airflow
                      _buildSensorRow(
                        '💨 Airflow',
                        '${_currentData!.airflow.toStringAsFixed(0)}',
                        _currentData!.airflow,
                        MAX_AIRFLOW,
                      ),

                      SizedBox(height: 8),

                      // Humidity
                      _buildSensorRow(
                        '💦 Humidity',
                        '${_currentData!.humidity.toStringAsFixed(1)}%',
                        _currentData!.humidity,
                        MAX_HUMIDITY,
                      ),

                      SizedBox(height: 8),

                      // Temperature
                      _buildSensorRow(
                        '🌡️ Temperature',
                        '${_currentData!.temperature.toStringAsFixed(1)}°C',
                        _currentData!.temperature,
                        MAX_TEMP,
                        isTemp: true,
                      ),

                      SizedBox(height: 8),

                      // Fan Status
                      Row(
                        children: [
                          Text('🌬️ Fan: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          Icon(
                            _fanRunning ? Icons.play_circle : Icons.stop_circle,
                            color: _fanRunning ? Colors.blue : Colors.grey,
                          ),
                          SizedBox(width: 4),
                          Text(
                            _fanRunning ? 'RUNNING' : 'OFF',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _fanRunning ? Colors.blue : Colors.grey,
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

              // Fan Control Section
              if (_lastPredictionLevel >= 2 && _lastPredictionLevel <= 5) ...[
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '🌬️ Fan Control',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),

                        ElevatedButton.icon(
                          onPressed: _fanRunning ? null : _controlFan,
                          icon: Icon(_fanRunning ? Icons.hourglass_top : Icons.air),
                          label: Text(
                              _fanRunning
                                  ? 'FAN RUNNING...'
                                  : 'START FAN (${fanDurations[_lastPredictionLevel]}s)'
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _fanRunning ? Colors.grey : Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),

                        if (_lastPredictionLevel > 0) ...[
                          SizedBox(height: 8),
                          Text(
                            'Action: Level $_lastPredictionLevel → ${fanDurations[_lastPredictionLevel]} seconds ventilation',
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