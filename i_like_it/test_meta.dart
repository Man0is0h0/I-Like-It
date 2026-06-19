import 'package:http/http.dart' as http;
import 'package:html/parser.dart';

void main() async {
  String url = 'https://youtu.be/dQw4w9WgXcQ';
  try {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
      },
    );
    print('Status: ${response.statusCode}');
    final document = parse(response.body);
    String imageUrl =
        document
            .querySelector('meta[property="og:image"]')
            ?.attributes['content'] ??
        '';
    if (imageUrl.isEmpty) {
      imageUrl =
          document
              .querySelector('meta[name="twitter:image"]')
              ?.attributes['content'] ??
          '';
    }
    if (imageUrl.isEmpty) {
      imageUrl =
          document
              .querySelector('link[rel="apple-touch-icon"]')
              ?.attributes['href'] ??
          '';
    }
    if (imageUrl.isEmpty) {
      imageUrl =
          document.querySelector('link[rel="icon"]')?.attributes['href'] ?? '';
    }
    print('Image URL: $imageUrl');
  } catch (e) {
    print('Error: $e');
  }
}
