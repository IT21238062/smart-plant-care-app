import 'package:flutter/material.dart';
import 'premium_home_page.dart';

class FeatureDevelopmentScreen extends StatelessWidget {
  final String featureName;
  final IconData featureIcon;

  const FeatureDevelopmentScreen({
    Key? key,
    required this.featureName,
    required this.featureIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(featureName),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                featureIcon,
                size: 80,
                color: Colors.grey,
              ),
              const SizedBox(height: 24),
              Text(
                '$featureName',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'This feature is currently in development for free users.',
                style: TextStyle(
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              const Icon(
                Icons.lock,
                size: 40,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 16),
              const Text(
                'Upgrade to Premium to access this feature now!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  _showUpgradeDialog(context);
                },
                icon: const Icon(Icons.star, color: Colors.yellow),
                label: const Text(
                  'UPGRADE TO PREMIUM',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(250, 50),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Upgrade to Premium'),
          content: const Text(
              'Unlock all features with Premium:\n\n'
                  '• Real-time water control with sensors\n'
                  '• Environment monitoring and fan control\n'
                  '• Soil nutrition analysis and fertilizer recommendations\n'
                  '• Coming soon: Crop disease detection\n\n'
                  'Would you like to upgrade?'
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
                // Navigate to the premium home page
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const PremiumHomePage()),
                      (route) => false, // Remove all previous routes
                );
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