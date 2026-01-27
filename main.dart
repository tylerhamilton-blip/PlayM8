import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Replace these with your Twitch/IGDB app credentials.
/// NOTE: Do NOT ship your client secret in a real mobile app.
/// For production, call IGDB from your backend instead.
const String twitchClientId = '6iba49x20oxe95b3kli0idvgshk9oo';
const String twitchClientSecret = 'rwov0npeobipq3hr1ms4eraj89vovh';

Future<String> getTwitchAppAccessToken() async {
  final uri = Uri.parse(
    'https://id.twitch.tv/oauth2/token'
    '?client_id=$twitchClientId'
    '&client_secret=$twitchClientSecret'
    '&grant_type=client_credentials',
  );

  final res = await http.post(uri);

  if (res.statusCode != 200) {
    throw Exception('Failed to get Twitch token (${res.statusCode}): ${res.body}');
  }

  final data = jsonDecode(res.body) as Map<String, dynamic>;
  final token = data['access_token'] as String?;
  if (token == null || token.isEmpty) {
    throw Exception('No access_token found in response: ${res.body}');
  }
  return token;
}

Future<Map<String, dynamic>?> fetchGameById({
  required int gameId,
  required String accessToken,
}) async {
  final uri = Uri.parse('https://api.igdb.com/v4/games');

  // Updated query: ask for image_id (so we can build the desired image size URL ourselves)
  final igdbQuery = '''
fields
  id,
  name,
  summary,
  first_release_date,
  rating,
  genres.name,
  platforms.name,
  cover.image_id;
where id = $gameId;
limit 1;
''';

  final res = await http.post(
    uri,
    headers: {
      'Client-ID': twitchClientId,
      'Authorization': 'Bearer $accessToken',
      'Accept': 'application/json',
    },
    body: igdbQuery,
  );

  if (res.statusCode != 200) {
    throw Exception('IGDB request failed (${res.statusCode}): ${res.body}');
  }

  final decoded = jsonDecode(res.body);
  if (decoded is List && decoded.isNotEmpty && decoded.first is Map<String, dynamic>) {
    return decoded.first as Map<String, dynamic>;
  }
  return null;
}

String? buildIgdbImageUrl(String? imageId, {String size = 'cover_big'}) {
  if (imageId == null || imageId.isEmpty) return null;
  return 'https://images.igdb.com/igdb/image/upload/t_$size/$imageId.jpg';
}

String? unixSecondsToDateString(dynamic seconds) {
  if (seconds is! int) return null;
  final dt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true).toLocal();
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

void main() async {
  stdout.writeln('Enter an IGDB game ID (example: 2899):');
  final input = stdin.readLineSync();

  final gameId = int.tryParse((input ?? '').trim());
  if (gameId == null) {
    stderr.writeln('That was not a valid integer game ID.');
    exit(1);
  }

  try {
    stdout.writeln('Getting Twitch app access token...');
    final token = await getTwitchAppAccessToken();

    stdout.writeln('Fetching game $gameId from IGDB...');
    final game = await fetchGameById(gameId: gameId, accessToken: token);

    if (game == null) {
      stdout.writeln('No game found for id=$gameId');
      return;
    }

    final name = game['name'];
    final summary = game['summary'];
    final release = unixSecondsToDateString(game['first_release_date']);
    final rating = game['rating'];

    final genres = (game['genres'] as List?)
            ?.map((g) => (g as Map?)?['name'])
            .whereType<String>()
            .toList() ??
        [];

    final platforms = (game['platforms'] as List?)
            ?.map((p) => (p as Map?)?['name'])
            .whereType<String>()
            .toList() ??
        [];

    final coverImageId = (game['cover'] as Map?)?['image_id'] as String?;
    final coverUrl = buildIgdbImageUrl(coverImageId, size: 'cover_big');

    stdout.writeln('\n--- IGDB Result ---');
    stdout.writeln('ID: $gameId');
    stdout.writeln('Name: $name');
    if (release != null) stdout.writeln('Release: $release');
    if (rating != null) stdout.writeln('Rating: ${rating.toString()}');
    if (genres.isNotEmpty) stdout.writeln('Genres: ${genres.join(", ")}');
    if (platforms.isNotEmpty) stdout.writeln('Platforms: ${platforms.join(", ")}');
    if (coverUrl != null) stdout.writeln('Cover (big): $coverUrl');
    if (summary != null) stdout.writeln('\nSummary:\n$summary');
  } catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }
}
