import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FreeEnvironmentMonitorScreen extends StatefulWidget {
  const FreeEnvironmentMonitorScreen({Key? key}) : super(key: key);

  @override
  State<FreeEnvironmentMonitorScreen> createState() => _FreeEnvironmentMonitorScreenState();
}

class _FreeEnvironmentMonitorScreenState extends State<FreeEnvironmentMonitorScreen> {
  // Controllers for text fields
  final TextEditingController _temperatureController = TextEditingController();
  final TextEditingController _humidityController = TextEditingController();
  final TextEditingController _windSpeedController = TextEditingController();

  // Results variables
  bool _showResults = false;
  String _overallStatus = '';
  Color _statusColor = Colors.grey;
  String _temperatureMessage = '';
  String _humidityMessage = '';
  String _windSpeedMessage = '';
  String _recommendationMessage = '';
  IconData _statusIcon = Icons.help_outline;

  @override
  void dispose() {
    _temperatureController.dispose();
    _humidityController.dispose();
    _windSpeedController.dispose();
    super.dispose();
  }

  void _analyzeEnvironment() {
    // Parse input values (with error handling)
    double? temperature = double.tryParse(_temperatureController.text);
    double? humidity = double.tryParse(_humidityController.text);
    double? windSpeed = double.tryParse(_windSpeedController.text);

    // Check if any input is invalid
    if (temperature == null || humidity == null || windSpeed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid numbers for all fields')),
      );
      return;
    }

    // Evaluate each parameter
    int goodCount = 0;
    bool anyCritical = false;

    // Temperature evaluation
    if (temperature >= 20 && temperature <= 35) {
      _temperatureMessage = 'Temperature is in the ideal range for tropical plants.';
      goodCount++;
    } else if (temperature >= 15 && temperature < 20 || temperature > 35 && temperature <= 40) {
      _temperatureMessage = 'Temperature is slightly outside the ideal range (20-35°C).';
    } else {
      _temperatureMessage = 'Temperature is far from ideal. Most plants may struggle in these conditions.';
      anyCritical = true;
    }

    // Humidity evaluation
    if (humidity >= 50 && humidity <= 80) {
      _humidityMessage = 'Humidity is in the ideal range for most tropical plants.';
      goodCount++;
    } else if (humidity >= 30 && humidity < 50 || humidity > 80 && humidity <= 90) {
      _humidityMessage = 'Humidity is slightly outside the ideal range (50-80%).';
    } else {
      _humidityMessage = 'Humidity is far from ideal. Plants may show stress in these conditions.';
      anyCritical = true;
    }

    // Wind speed evaluation
    if (windSpeed >= 5 && windSpeed <= 20) {
      _windSpeedMessage = 'Wind speed is good for air circulation without stressing plants.';
      goodCount++;
    } else if (windSpeed >= 0 && windSpeed < 5) {
      _windSpeedMessage = 'Wind speed is low. Air circulation may be insufficient for optimal growth.';
    } else if (windSpeed > 20 && windSpeed <= 30) {
      _windSpeedMessage = 'Wind speed is slightly high. Some delicate plants may experience stress.';
    } else {
      _windSpeedMessage = 'Wind speed is very high. Plants may suffer physical damage.';
      anyCritical = true;
    }

    // Overall evaluation
    if (anyCritical) {
      _overallStatus = 'Critical';
      _statusColor = Colors.red[700]!;
      _statusIcon = Icons.warning_amber_rounded;
      _recommendationMessage = 'Consider moving sensitive plants to a more protected location or adjusting conditions if possible.';
    } else if (goodCount == 3) {
      _overallStatus = 'Perfect';
      _statusColor = Colors.green;
      _statusIcon = Icons.check_circle;
      _recommendationMessage = 'Your environment is ideal for most tropical plants. Maintain these conditions for optimal growth.';
    } else if (goodCount == 2) {
      _overallStatus = 'Good';
      _statusColor = Colors.lightGreen;
      _statusIcon = Icons.thumb_up;
      _recommendationMessage = 'Your environment is generally favorable for plant growth with minor adjustments recommended.';
    } else if (goodCount == 1) {
      _overallStatus = 'Fair';
      _statusColor = Colors.orange;
      _statusIcon = Icons.sentiment_neutral;
      _recommendationMessage = 'Your environment has some challenges. Consider addressing the issues mentioned above.';
    } else {
      _overallStatus = 'Poor';
      _statusColor = Colors.deepOrange;
      _statusIcon = Icons.thumb_down;
      _recommendationMessage = 'Your environment needs significant improvements for optimal plant growth.';
    }

    setState(() {
      _showResults = true;
    });
  }

  void _resetForm() {
    setState(() {
      _temperatureController.clear();
      _humidityController.clear();
      _windSpeedController.clear();
      _showResults = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Environment Monitor'),
        backgroundColor: Colors.green[700],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.green[50]!],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Information Card
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            const Text(
                              'Environmental Data',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Enter current environmental conditions to assess plant growing conditions. '
                              'You can find these values on weather apps like The Weather Channel (weather.com) '
                              'or your local weather service.',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Input Fields
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Temperature Input
                        const Text(
                          'Temperature (°C)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _temperatureController,
                          decoration: const InputDecoration(
                            hintText: 'Enter temperature (e.g., 28)',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            suffixText: '°C',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Humidity Input
                        const Text(
                          'Humidity (%)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _humidityController,
                          decoration: const InputDecoration(
                            hintText: 'Enter humidity (e.g., 75)',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            suffixText: '%',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Wind Speed Input
                        const Text(
                          'Wind Speed (km/h)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _windSpeedController,
                          decoration: const InputDecoration(
                            hintText: 'Enter wind speed (e.g., 10)',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            suffixText: 'km/h',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _analyzeEnvironment,
                        icon: const Icon(Icons.search),
                        label: const Text('ANALYZE'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _resetForm,
                      icon: const Icon(Icons.refresh),
                      label: const Text('RESET'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green[700],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.green[700]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Results Section (shown only after analysis)
                if (_showResults) ...[
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _statusColor.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Result Header
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _statusColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_statusIcon, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  'Environment Status: $_overallStatus',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Detailed Results
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildResultItem(Icons.thermostat, 'Temperature', _temperatureMessage),
                              const Divider(),
                              _buildResultItem(Icons.water_drop, 'Humidity', _humidityMessage),
                              const Divider(),
                              _buildResultItem(Icons.air, 'Wind Speed', _windSpeedMessage),
                              const Divider(),
                              // Recommendations
                              _buildResultItem(Icons.lightbulb_outline, 'Recommendation', _recommendationMessage),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultItem(IconData icon, String title, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[700], size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}