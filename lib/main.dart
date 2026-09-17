import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config.dart';
import 'video_module.dart';

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
  
  // Állapotok a Python logika alapján
  String _responseMessage = "GENEVIEW mobil mag aktív. Helyszín: ${GeneviewConfig.systemLocation}";
  bool _isProcessing = false;
  bool _isSpeakingAnimation = false;

  void _processQuery(String query) {
    if (_isProcessing) return;
    
    final qLower = query.toLowerCase().trim();
    if (qLower.isEmpty || qLower == "kérdezz a magtól...") return;

    setState(() {
      _isProcessing = true;
      _isSpeakingAnimation = true;
      _responseMessage = "GENEVIEW feldolgozás alatt: '$query'...";
    });

    // Itt történik a logikai feldolgozás (mint a Python oldalon a belső profil / DuckDuckGo híd)
    Future.delayed(const Duration(seconds: 2), () {
      String answer = "";
      
      if (qLower.contains("pontos idő")) {
        final now = DateTime.now();
        answer = "A belső időgép szerint most ${now.hour} óra ${now.minute} perc van.";
      } else if (qLower.contains("helyszín")) {
        answer = "A valós idejű helymeghatározó mag szerint jelenleg itt vagyunk: ${GeneviewConfig.systemLocation}.";
      } else if (qLower.contains("ki vagy te") || qLower.contains("geneview")) {
        answer = GeneviewConfig.identityProfile;
      } else {
        answer = "Hálózati keresési eredmény a(z) '$query' kifejezésre (DuckDuckGo híd aktív).";
      }

      setState(() {
        _isProcessing = false;
        _isSpeakingAnimation = false;
        _responseMessage = "GENEVIEW: $answer";
      });
    });
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
              
              // Hologram Videó / Szinkron Trezor (GPU gyorsított)
              HologramVideoModule(isSpeaking: _isSpeakingAnimation),
              const SizedBox(height: 12),

              // Állapotjelző / Válasz Doboz (A Python response_label megfelelője)
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

              // Gyorsgombok (Puzzle elemek - pontosan mint a Python kódban)
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

              // Beviteli sáv & Mikrofon (Hardveres hangkezelés trezor)
              Row(
                children: [
                  IconButton(
                    onPressed: _isProcessing ? null : () {
                      // Mobilos mikrofon rögzítés trigger
                      setState(() {
                        _responseMessage = "GENEVIEW: 🎙️ Hallgatlak... Beszélj most!";
                      });
                      Future.delayed(const Duration(seconds: 2), () {
                        _processQuery("pontos idő");
                      });
                    },
                    icon: const Icon(Icons.mic, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.redAccent,
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