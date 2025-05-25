import 'package:flutter/material.dart';

class SoilNutrientScreen extends StatelessWidget {
  const SoilNutrientScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soil Nutrient Guide'),
        backgroundColor: Colors.green[700],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.green[50],
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildNutrientCard(
              context,
              'Nitrogen (N)',
              'Plants show yellowing of older leaves starting at the tips and moving inward. Growth is stunted, and plants appear pale and weak.',
              'Add nitrogen-rich fertilizers like blood meal, fish emulsion, or composted manure. For a quick fix, use a balanced fertilizer with higher first number (e.g., 10-5-5).',
              Icons.eco,
              Colors.green[800]!,
            ),
            _buildNutrientCard(
              context,
              'Phosphorus (P)',
              'Plants develop dark green leaves with purple or reddish tints, especially on the undersides. Stunted growth, poor flowering, and weak root development.',
              'Apply bone meal, rock phosphate, or fish bone meal. Ensure soil pH is between 6.0-7.0 for optimal phosphorus availability.',
              Icons.spa,
              Colors.purple[800]!,
            ),
            _buildNutrientCard(
              context,
              'Potassium (K)',
              'Leaf edges turn yellow or brown and may appear scorched. Poor fruit development and increased susceptibility to disease.',
              'Add wood ash (carefully, as it raises pH), greensand, or kelp meal. Commercial fertilizers with high last number (e.g., 5-5-10) are also effective.',
              Icons.local_florist,
              Colors.orange[800]!,
            ),
            _buildNutrientCard(
              context,
              'Calcium (Ca)',
              'New leaves appear distorted or stunted. Blossom end rot in tomatoes and other fruiting plants. Weak stems and poor root growth.',
              'Add garden lime, gypsum, or crushed eggshells. Ensure consistent watering as calcium uptake is affected by water availability.',
              Icons.grass,
              Colors.amber[800]!,
            ),
            _buildNutrientCard(
              context,
              'Magnesium (Mg)',
              'Interveinal chlorosis (yellowing between leaf veins while veins remain green), starting with older leaves.',
              'Apply Epsom salts (1 tablespoon per gallon of water as a spray or soil drench) or dolomite lime (which contains both calcium and magnesium).',
              Icons.park,
              Colors.teal[800]!,
            ),
            _buildNutrientCard(
              context,
              'Sulfur (S)',
              'Yellowing of younger leaves throughout the plant. Stunted, thin stems and slow overall growth.',
              'Add gypsum, Epsom salts, or composted materials high in sulfur like onion and garlic scraps.',
              Icons.grass_outlined,
              Colors.amber[900]!,
            ),
            _buildNutrientCard(
              context,
              'Iron (Fe)',
              'Interveinal chlorosis on young leaves (similar to magnesium deficiency but affecting newer growth first). Leaves may eventually turn completely yellow or white.',
              'Apply iron sulfate or chelated iron products. Lower soil pH if it\'s above 7.0, as iron becomes less available in alkaline soils.',
              Icons.forest,
              Colors.brown[800]!,
            ),
            _buildNutrientCard(
              context,
              'Zinc (Zn)',
              'Leaves develop interveinal chlorosis with reduced size. Shortened internodes resulting in rosette-like appearance. Poor fruit development.',
              'Add zinc sulfate or chelated zinc products. Composted materials and manure often contain sufficient zinc to correct mild deficiencies.',
              Icons.eco_outlined,
              Colors.blueGrey[800]!,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: const Text(
                'Note: A soil test is the most reliable way to identify specific deficiencies before applying amendments. Over-application of certain nutrients can cause new problems and imbalances.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientCard(
      BuildContext context,
      String title,
      String problem,
      String solution,
      IconData icon,
      Color color,
      ) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Problem:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(problem),
              const SizedBox(height: 16),
              const Text(
                'Solution:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(solution),
              const SizedBox(height: 8),
            ],
          ),
        ],
      ),
    );
  }
}