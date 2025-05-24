import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherService {
  // Your OpenWeatherMap API key
  final String apiKey = '1a8f792911735d49af4548710b0edc57';
  final String baseUrl = 'https://api.openweathermap.org/data/2.5';

  Future<List<DayForecast>> getThreeDayForecast(String city) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/forecast?q=$city&appid=$apiKey&units=metric'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> forecastList = data['list'];

        // Group by day (simple approach)
        Map<String, bool> dailyRainStatus = {};
        Map<String, double> dailyTemps = {};
        Map<String, int> dailyCounts = {};

        for (var forecast in forecastList) {
          // Get date without time
          String dateText = forecast['dt_txt'].toString().split(' ')[0];

          // Check for rain
          bool hasRain = forecast['weather'][0]['main'].toString().toLowerCase().contains('rain');

          // Get temperature
          double temp = forecast['main']['temp'];

          // If any period in the day has rain, the day has rain
          if (dailyRainStatus.containsKey(dateText)) {
            dailyRainStatus[dateText] = dailyRainStatus[dateText]! || hasRain;
            dailyTemps[dateText] = dailyTemps[dateText]! + temp;
            dailyCounts[dateText] = dailyCounts[dateText]! + 1;
          } else {
            dailyRainStatus[dateText] = hasRain;
            dailyTemps[dateText] = temp;
            dailyCounts[dateText] = 1;
          }
        }

        // Convert to list of day forecasts (limited to 3 days)
        List<DayForecast> result = [];

        // Get dates and sort them
        List<String> dates = dailyRainStatus.keys.toList();
        dates.sort(); // Sort by date

        // Get only first 3 days
        for (int i = 0; i < dates.length && i < 3; i++) {
          String date = dates[i];

          // Calculate average temperature
          double avgTemp = dailyTemps[date]! / dailyCounts[date]!;

          // Format date to display
          DateTime dateTime = DateTime.parse(date);
          String dayName = _getDayName(dateTime);

          result.add(DayForecast(
            date: date,
            displayDate: "$dayName (${dateTime.day}/${dateTime.month})",
            willRain: dailyRainStatus[date]!,
            temperature: avgTemp,
          ));
        }

        return result;
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        return _getDummyForecast();
      }
    } catch (e) {
      print('Exception in weather service: $e');
      return _getDummyForecast();
    }
  }

  String _getDayName(DateTime date) {
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return dayNames[date.weekday - 1];
  }

  List<DayForecast> _getDummyForecast() {
    // Return dummy data if API fails
    final now = DateTime.now();

    return [
      DayForecast(
        date: now.toString().split(' ')[0],
        displayDate: "Today",
        willRain: false,
        temperature: 28,
      ),
      DayForecast(
        date: now.add(Duration(days: 1)).toString().split(' ')[0],
        displayDate: "Tomorrow",
        willRain: true,
        temperature: 22,
      ),
      DayForecast(
        date: now.add(Duration(days: 2)).toString().split(' ')[0],
        displayDate: "Day After",
        willRain: false,
        temperature: 30,
      ),
    ];
  }
}

class DayForecast {
  final String date;
  final String displayDate;
  final bool willRain;
  final double temperature;

  DayForecast({
    required this.date,
    required this.displayDate,
    required this.willRain,
    required this.temperature,
  });

  String get wateringAdvice {
    if (willRain) {
      return "Rain expected - no need to water";
    } else if (temperature > 28) {
      return "Hot day - water plants thoroughly";
    } else {
      return "No rain expected - water your plants";
    }
  }

  String get weatherIconText {
    return willRain ? "🌧️" : "☀️";
  }
}