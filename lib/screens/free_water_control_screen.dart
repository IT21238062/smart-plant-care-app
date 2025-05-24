import 'package:flutter/material.dart';
import '../services/weather_service.dart';

class FreeWaterControlScreen extends StatefulWidget {
  const FreeWaterControlScreen({Key? key}) : super(key: key);

  @override
  _FreeWaterControlScreenState createState() => _FreeWaterControlScreenState();
}

class _FreeWaterControlScreenState extends State<FreeWaterControlScreen> {
  final WeatherService _weatherService = WeatherService();
  List<DayForecast>? _forecast;
  bool _isLoading = true;
  String _errorMessage = '';
  String _city = 'Colombo'; // Default city

  final List<String> _popularCities = [
    'Colombo', 'Kandy', 'Galle', 'Jaffna', 'Anuradhapura',
    'Batticaloa', 'Negombo', 'Trincomalee', 'Vavuniya', 'Matara',
    'Kalmunai', 'Kurunegala', 'Ratnapura', 'Kotte', 'Dambulla',
    'Gampaha', 'Badulla', 'Matale', 'Kalutara', 'Polonnaruwa',
    'Nuwara Eliya', 'Moratuwa', 'Puttalam', 'Ampara', 'Hambantota'
  ];

  @override
  void initState() {
    super.initState();
    _loadForecast();
  }

  Future<void> _loadForecast() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final forecast = await _weatherService.getThreeDayForecast(_city);
      setState(() {
        _forecast = forecast;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load forecast: $e';
        _isLoading = false;
      });
    }
  }

  void _showCitySelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select City'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400, // Set a fixed height to make it scrollable
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _popularCities.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_popularCities[index]),
                  onTap: () {
                    setState(() {
                      _city = _popularCities[index];
                    });
                    Navigator.of(context).pop();
                    _loadForecast();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('CANCEL'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[400]!, Colors.blue[700]!],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '💧 Water Advisor',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Location Selection
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.blue),
                        const SizedBox(width: 12),
                        Text(
                          _city,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _showCitySelectionDialog,
                          icon: const Icon(Icons.edit_location_alt),
                          label: const Text('CHANGE'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Main Content
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20.0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: RefreshIndicator(
                    onRefresh: _loadForecast,
                    child: _buildMainContent(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading forecast...'),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[700]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadForecast,
              icon: const Icon(Icons.refresh),
              label: const Text('TRY AGAIN'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (_forecast == null || _forecast!.isEmpty) {
      return const Center(
        child: Text('No forecast data available'),
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.water_drop, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              'Watering Forecast',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Forecast Cards
        ..._forecast!.map((day) => _buildDayCard(day)).toList(),

        const SizedBox(height: 24),

        // Premium upgrade card
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.blue[50],
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.workspace_premium,
                      color: Colors.amber,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Want precise watering control?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Upgrade to Premium for automated watering based on real-time soil moisture sensing!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _showUpgradeDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'UPGRADE TO PREMIUM',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayCard(DayForecast day) {
    // Determine icon and color based on rain status
    IconData weatherIcon;
    Color cardColor;

    if (day.willRain) {
      weatherIcon = Icons.water_drop;
      cardColor = Colors.blue[50]!;
    } else {
      weatherIcon = Icons.wb_sunny;
      cardColor = Colors.orange[50]!;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                weatherIcon,
                size: 32,
                color: day.willRain ? Colors.blue : Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    day.displayDate,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    day.willRain
                        ? 'Rain expected'
                        : 'Temperature: ${day.temperature.toStringAsFixed(1)}°C',
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: day.willRain ? Colors.blue.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: day.willRain ? Colors.blue : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            day.wateringAdvice,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: day.willRain ? Colors.blue[800] : Colors.orange[800],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.workspace_premium, color: Colors.amber),
              const SizedBox(width: 8),
              const Text('Upgrade to Premium'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Unlock all features with Premium:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Feature(icon: Icons.water_drop, text: 'Real-time water control with sensors'),
              Feature(icon: Icons.thermostat, text: 'Environment monitoring and fan control'),
              Feature(icon: Icons.grass, text: 'Soil nutrition analysis and fertilizer recommendations'),
              Feature(icon: Icons.healing, text: 'Coming soon: Crop disease detection'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('MAYBE LATER'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Return to home page and then navigate to premium page
                Navigator.pop(context); // Return to home
                // Add navigation to premium home page here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
              ),
              child: const Text('UPGRADE NOW'),
            ),
          ],
        );
      },
    );
  }
}

// Helper widget for premium features list
class Feature extends StatelessWidget {
  final IconData icon;
  final String text;

  const Feature({
    Key? key,
    required this.icon,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.green),
          const SizedBox(width: 8),
          Flexible(child: Text(text)),
        ],
      ),
    );
  }
}