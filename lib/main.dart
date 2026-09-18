import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';
import 'video_module.dart';
import 'elevenlabs_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const GeneviewNativeApp());
}

class GeneviewNativeApp extends StatelessWidget {
  const GeneviewNativeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GENEVIEW Native',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF05070C),
        primaryColor: const Color(0xFF00FFFF),
      ),
      home: const GeneviewCoreScreen(),
    );
  }
}

class GeneviewCoreScreen extends StatefulWidget {
  const GeneviewCoreScreen({super.key});

  @override
  State<GeneviewCoreScreen> createState() => _GeneviewCoreScreenState();
}

class _GeneviewCoreScreenState extends State<GeneviewCoreScreen> {
  final TextEditingController _queryController = TextEditingController();
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  late AudioPlayer _audioPlayer;

  bool _speechReady = false;
  bool _isListening = false;
  String _responseMessage = "GENEVIEW mobil mag aktív. Helyszín: ${GeneviewConfig.systemLocation}";
  bool _isProcessing = false;
  bool _isSpeakingAnimation = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _audioPlayer = AudioPlayer();

    // Figyeljük az audió lejátszás állapotát a szinkron videó animációhoz
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isSpeakingAnimation = (state == PlayerState.playing);
      });
    });

    _initSpeech();
    _initTts();
  }

  Future<void> _initSpeech() async {
    _speechReady = await _speech.initialize(
      onStatus: (status) {},
      onError: (error) {},
    );
    setState(() {});
  }

  void _initTts() async {
    _flutterTts = FlutterTts();
    await _flutterTts.setLanguage("hu-HU");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      setState(() {
        _isSpeakingAnimation = true;
      });
    });

    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeakingAnimation = false;
      });
    });

    _flutterTts.setErrorHandler((msg) {
      setState(() {
        _isSpeakingAnimation = false;
      });
    });
  }

  // Szöveg felolvasása: ElevenLabs klónozott hang prioritással, fallback a beépített TTS-re
  Future<void> _speak(String text) async {
    if (text.isEmpty) return;

    // Megpróbáljuk letölteni a klónozott hangot az ElevenLabs-tól
    String? audioPath = await ElevenLabsService.synthesizeSpeech(text);

    if (audioPath != null) {
      // Ha sikerült, lejátsszuk a saját klónozott hangunkat
      await _audioPlayer.play(DeviceFileSource(audioPath));
    } else {
      // Biztonsági fallback: ha hiba van vagy nincs kulcs, marad a beépített TTS
      await _flutterTts.speak(text);
    }
  }

  // Valós idejű beszéd felismerés (Speech-to-Text)
  void _listen() async {
    if (!_speechReady) {
      setState(() {
        _responseMessage = "GENEVIEW: A mikrofon nem elérhető ezen az eszközön.";
      });
      return;
    }

    if (!_isListening) {
      setState(() => _isListening = true);
      setState(() => _responseMessage = "GENEVIEW: 🎙️ Hallgatlak... Beszélj most!");

      _speech.listen(
        onResult: (val) => setState(() {
          _queryController.text = val.recognizedWords;
          if (val.finalResult) {
            _isListening = false;
            _processQuery(val.recognizedWords);
          }
        }),
      );
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  /// Tiszta Dartban fut a telefonon, lekérdezi a DuckDuckGo "Instant Answer" API-t.
  Future<String> fetchDuckDuckGoAnswer(String query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse(
        'https://api.duckduckgo.com/?q=$encodedQuery&format=json&no_html=1&skip_disambig=1',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 8),
        onTimeout: () => http.Response('{}', 408),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        String answer = data['AbstractText'] ?? '';

        if (answer.isEmpty && data['RelatedTopics'] != null) {
          final topics = data['RelatedTopics'] as List;
          if (topics.isNotEmpty && topics[0]['Text'] != null) {
            answer = topics[0]['Text'];
          }
        }

        if (answer.isNotEmpty) {
          return answer;
        } else {
          return "Nem találtam pontos választ a(z) '$query' kérdésre.";
        }
      } else {
        return "Hálózati hiba történt a keresés közben.";
      }
    } catch (e) {
      return "Hiba történt a keresés közben: $e";
    }
  }

  Future<void> _processQuery(String query) async {
    if (_isProcessing) return;

    final qLower = query.toLowerCase().trim();
    if (qLower.isEmpty || qLower == "kérdezz a magtól...") return;

    setState(() {
      _isProcessing = true;
      _responseMessage = "GENEVIEW feldolgozás alatt...";
    });

    String answer = "";

    if (qLower.contains("pontos idő")) {
      final now = DateTime.now();
      answer = "A belső időgép szerint most ${now.hour} óra ${now.minute} perc van.";
    } else if (qLower.contains("helyszín")) {
      answer = "A valós idejű helymeghatározó mag szerint jelenleg itt vagyunk: ${GeneviewConfig.systemLocation}.";
    } else if (qLower.contains("milyen nap van ma")) {
      final now = DateTime.now();
      answer = "A belső naptár szerint ma van a ${now.year}. év ${now.month}. hó ${now.day}. napja.";
    } else if (qLower.contains("ki vagy te") || qLower.contains("geneview")) {
      answer = GeneviewConfig.identityProfile;
    } else {
      answer = await fetchDuckDuckGoAnswer(query);
    }

    setState(() {
      _isProcessing = false;
      _responseMessage = "GENEVIEW: $answer";
    });

    await _speak(answer);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _flutterTts.stop();
    _speech.stop();
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: Text(
                  "GENEVIEW // NATIVE MOBILE CORE",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Color(0xFF00FFFF),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              HologramVideoModule(isSpeaking: _isSpeakingAnimation),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  _responseMessage,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 3.4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: [
                  _buildBtn("1. Mennyi a pontos idő?", "pontos idő most"),
                  _buildBtn("2. Milyen nap van ma?", "milyen nap van ma"),
                  _buildBtn("3. Hol vagyunk?", "helyszín inglewood california"),
                  _buildBtn("4. Ki vagy te?", "ki vagy te geneview"),
                ],
              ),
              const Spacer(),

              Row(
                children: [
                  IconButton(
                    onPressed: _isProcessing ? null : _listen,
                    icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: _isListening ? Colors.amber : Colors.redAccent,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _queryController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: "Kérdezz a magtól...",
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onSubmitted: (val) => _processQuery(val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isProcessing ? null : () => _processQuery(_queryController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FFFF),
                      foregroundColor: const Color(0xFF05070C),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    child: const Text("Küldés", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBtn(String label, String q) {
    return ElevatedButton(
      onPressed: _isProcessing ? null : () => _processQuery(q),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: const Color(0xFF00FFFF),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}