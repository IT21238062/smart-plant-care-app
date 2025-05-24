import 'package:flutter/material.dart';
import 'feature_development_screen.dart';
import 'free_water_control_screen.dart';
import 'premium_home_page.dart';

class FreeHomePage extends StatelessWidget {
  const FreeHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Add a gradient background
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.green[50]!],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // App Logo/Icon
                    Icon(
                      Icons.eco,
                      size: 70,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 16),
                    // App Title
                    const Text(
                      'Plant Care System',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Tagline
                    Text(
                      'Smart Plant Care Made Simple',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Feature Section Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Available Features',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Feature Cards Section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: ListView(
                    children: [
                      // Water Advisor Card (Available)
                      _buildFeatureCard(
                        context,
                        icon: Icons.water_drop,
                        title: 'Water Advisor',
                        description: 'Get watering recommendations based on weather forecasts',
                        isAvailable: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FreeWaterControlScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Environment Control Card (Coming Soon)
                      _buildFeatureCard(
                        context,
                        icon: Icons.thermostat,
                        title: 'Environment Monitor',
                        description: 'Track temperature and humidity (Premium Only)',
                        isAvailable: false,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FeatureDevelopmentScreen(
                                featureName: 'Environment Monitor',
                                featureIcon: Icons.thermostat,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Soil Nutrition Card (Coming Soon)
                      _buildFeatureCard(
                        context,
                        icon: Icons.grass,
                        title: 'Soil Nutrition',
                        description: 'Analyze soil quality (Premium Only)',
                        isAvailable: false,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FeatureDevelopmentScreen(
                                featureName: 'Soil Nutrition',
                                featureIcon: Icons.grass,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Crop Disease Detection Card (Coming Soon)
                      _buildFeatureCard(
                        context,
                        icon: Icons.healing,
                        title: 'Crop Disease Detection',
                        description: 'Identify plant diseases (Premium Only)',
                        isAvailable: false,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FeatureDevelopmentScreen(
                                featureName: 'Crop Disease Detection',
                                featureIcon: Icons.healing,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Premium Upgrade Banner
              Container(
                margin: const EdgeInsets.all(20.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.deepPurple[300]!, Colors.deepPurple[500]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Upgrade to Premium',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Unlock all features with real-time sensor monitoring',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PremiumHomePage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'UPGRADE NOW',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build feature cards
  Widget _buildFeatureCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String description,
        required bool isAvailable,
        required VoidCallback onTap,
      }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isAvailable ? Colors.green.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isAvailable ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isAvailable ? Colors.green : Colors.grey,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isAvailable ? Colors.black87 : Colors.grey[600],
                          ),
                        ),
                        if (isAvailable)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Available',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isAvailable ? Colors.green : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}