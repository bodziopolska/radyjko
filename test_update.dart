import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const url = 'https://raw.githubusercontent.com/bodziopolska/radyjko/main/version.json';
  try {
    print('Fetching $url');
    final response = await http.get(Uri.parse(url));
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');
    final data = json.decode(response.body);
    print('Decoded: $data');
  } catch (e, stack) {
    print('Error: $e');
    print(stack);
  }
}
