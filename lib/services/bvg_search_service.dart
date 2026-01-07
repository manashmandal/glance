import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/station.dart';

class BvgSearchService {
  static const String baseUrl = 'https://v6.bvg.transport.rest';

  static Future<List<Station>> searchStations(String query) async {
    try {
      final url =
          '$baseUrl/locations?query=$query&results=5&stops=true&addresses=false&poi=false';
      print('Searching stations: $url');

      final response = await http
          .get(Uri.parse(url), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Found ${data.length} locations');

        return data
            .where((item) => item['type'] == 'stop')
            .map(
              (item) => Station(
                id: item['id'] as String,
                name: item['name'] as String,
              ),
            )
            .toList();
      }
      return [];
    } catch (e) {
      print('Error searching stations: $e');
      return [];
    }
  }
}
