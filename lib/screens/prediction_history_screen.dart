import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart'; // Make sure to add intl package to your pubspec.yaml

class PredictionHistoryScreen extends StatefulWidget {
  const PredictionHistoryScreen({Key? key}) : super(key: key);

  @override
  _PredictionHistoryScreenState createState() => _PredictionHistoryScreenState();
}

class _PredictionHistoryScreenState extends State<PredictionHistoryScreen> {
  List<Map<String, dynamic>> _predictions = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadPredictionHistory();
  }

  Future<void> _loadPredictionHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Explicitly target the 'predictions' node
      print('Loading predictions from Firebase...');

      // Make sure we're targeting the correct path
      final DatabaseReference predictionsRef = FirebaseDatabase.instance.ref().child('predictions');
      print('Query path: ${predictionsRef.path}');

      final event = await predictionsRef.once();

      print('Firebase response received');
      print('Data exists: ${event.snapshot.exists}');
      print('Snapshot value type: ${event.snapshot.value?.runtimeType}');

      if (event.snapshot.exists) {
        final dynamic snapshotValue = event.snapshot.value;

        if (snapshotValue is Map) {
          final Map<dynamic, dynamic> data = snapshotValue;
          print('Found ${data.length} predictions');

          final List<Map<String, dynamic>> predictions = [];

          data.forEach((key, value) {
            print('Processing prediction key: $key');

            if (value is Map) {
              final prediction = Map<String, dynamic>.from(value);
              prediction['id'] = key;
              predictions.add(prediction);
            }
          });

          // Sort by timestamp (newest first)
          predictions.sort((a, b) {
            final aTimestamp = a['timestamp'] as int?;
            final bTimestamp = b['timestamp'] as int?;

            if (aTimestamp == null || bTimestamp == null) {
              return 0;
            }

            return bTimestamp.compareTo(aTimestamp);
          });

          setState(() {
            _predictions = predictions;
            _isLoading = false;
          });
        } else {
          print('Unexpected data structure: $snapshotValue');
          setState(() {
            _errorMessage = 'Unexpected data structure in Firebase';
            _isLoading = false;
          });
        }
      } else {
        print('No predictions found in Firebase.');
        setState(() {
          _predictions = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading prediction history: $e');
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  // Format timestamp to readable date/time
  String _formatTimestamp(int timestamp) {
    final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final DateTime now = DateTime.now();
    final DateTime yesterday = DateTime.now().subtract(Duration(days: 1));

    if (dateTime.year == now.year && dateTime.month == now.month && dateTime.day == now.day) {
      return 'Today, ${DateFormat.jm().format(dateTime)}';
    } else if (dateTime.year == yesterday.year && dateTime.month == yesterday.month && dateTime.day == yesterday.day) {
      return 'Yesterday, ${DateFormat.jm().format(dateTime)}';
    } else {
      return DateFormat('MMM d, h:mm a').format(dateTime);
    }
  }

  // Get color based on prediction level
  Color _getPredictionColor(int level) {
    switch (level) {
      case 1:
        return Colors.red; // Dry soil - needs full irrigation
      case 2:
        return Colors.orange; // Semi-dry soil
      case 3:
        return Colors.amber; // Little bit dry soil
      case 4:
        return Colors.lightGreen; // Little bit wet soil
      case 5:
        return Colors.green; // Wet soil - no need to water
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Prediction History'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          // Refresh button
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh History',
            onPressed: _loadPredictionHistory,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              'Error loading history',
              style: TextStyle(
                fontSize: 18,
                color: Colors.red[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage,
              style: TextStyle(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPredictionHistory,
              child: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
            ),
          ],
        ),
      )
          : _predictions.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_toggle_off,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No prediction history yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Make a prediction to see it here',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _predictions.length,
        itemBuilder: (context, index) {
          final prediction = _predictions[index];
          final timestamp = prediction['timestamp'] as int? ?? 0;
          final level = prediction['prediction_level'] as int? ?? 0;
          final text = prediction['prediction_text'] as String? ?? 'Unknown prediction';

          // Sensor data
          Map<dynamic, dynamic>? sensorData;
          if (prediction.containsKey('sensor_data') && prediction['sensor_data'] is Map) {
            sensorData = prediction['sensor_data'] as Map<dynamic, dynamic>;
          }

          final soilEC = sensorData?['soil_ec']?.toDouble() ?? 0.0;
          final soilMoisture = sensorData?['soil_moisture']?.toDouble() ?? 0.0;
          final soilTemp = sensorData?['soil_temp']?.toDouble() ?? 0.0;

          return Card(
            margin: EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: _getPredictionColor(level).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timestamp and level indicator
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 6),
                      Text(
                        timestamp > 0 ? _formatTimestamp(timestamp) : 'Unknown time',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Spacer(),
                      if (level > 0)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getPredictionColor(level),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Level $level',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: 12),

                  // Prediction text
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getPredictionColor(level).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  SizedBox(height: 12),

                  // Sensor data
                  Row(
                    children: [
                      _buildDataChip('EC', '${soilEC.toStringAsFixed(1)} μS/cm', Icons.electric_bolt),
                      SizedBox(width: 8),
                      _buildDataChip('Moisture', '${soilMoisture.toStringAsFixed(0)}', Icons.water_drop),
                      SizedBox(width: 8),
                      _buildDataChip('Temp', '${soilTemp.toStringAsFixed(1)}°C', Icons.thermostat),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDataChip(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: Colors.grey[700],
            ),
            SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}