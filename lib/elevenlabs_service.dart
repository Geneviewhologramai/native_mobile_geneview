import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ElevenLabsService {
  // Írd ide a saját ElevenLabs API kulcsodat és a klónozott hangod Voice ID-ját
  static const String apiKey = 'YOUR_ELEVENLABS_API_KEY';
  static const String voiceId = 'YOUR_CLONED_VOICE_ID';

  /// Elküldi a szöveget az ElevenLabs Text-to-Speech API-nak,
  /// letölti a generált hangot egy ideiglenes fájlba, és visszaadja az elérési útját.
  static Future<String?> synthesizeSpeech(String text) async {
    if (apiKey == 'YOUR_ELEVENLABS_API_KEY' || apiKey.isEmpty) {
      print('[ELEVENLABS] Hiba: Nincs beállítva API kulcs!');
      return null;
    }

    try {
      final url = Uri.parse('https://api.elevenlabs.io/v1/text-to-speech/$voiceId');
      
      final response = await http.post(
        url,
        headers: {
          'Accept': 'audio/mpeg',
          'Content-Type': 'application/json',
          'xi-api-key': apiKey,
        },
        body: jsonEncode({
          'text': text,
          'model_id': 'eleven_multilingual_v2', // Kiválóan támogatja a magyart is!
          'voice_settings': {
            'stability': 0.5,
            'similarity_boost': 0.75,
          }
        }),
      );

      if (response.statusCode == 200) {
        // Elmentjük a kapott hangot egy ideiglenes fájlba a telefonon
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/geneview_response.mp3';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        
        return filePath;
      } else {
        print('[ELEVENLABS] API Hiba (${response.statusCode}): ${response.body}');
        return null;
      }
    } catch (e) {
      print('[ELEVENLABS] Kivétel történt: $e');
      return null;
    }
  }
}