// KONZOL DIAGNOSZTIKAI TESZT - nem igényel telefont/emulátort!
//
// Futtatás: helyezd ezt a fájlt a projekted GYÖKERÉBE (a pubspec.yaml mellé,
// NEM a lib/ vagy test/ mappába), majd a terminálban (a projekt mappájában):
//
//   dart run test_console.dart
//
// Ez leellenőrzi:
//   1. A belső logikát (pontos idő / milyen nap / helyszín / ki vagy te)
//   2. A DuckDuckGo hidat (valódi hálózati hívás, valódi válasszal)

import 'dart:convert';
import 'package:http/http.dart' as http;

// --- Ugyanaz a DuckDuckGo híd logika, mint a main.dart-ban ---
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
      return "Hálózati hiba (Státusz: ${response.statusCode})";
    }
  } catch (e) {
    return "Hiba történt a keresés közben: $e";
  }
}

// --- Ugyanaz a belső intent-felismerő logika, mint a main.dart-ban ---
String? resolveLocalAnswer(String query) {
  final qLower = query.toLowerCase().trim();

  if (qLower.contains("pontos idő")) {
    final now = DateTime.now();
    return "A belső időgép szerint most ${now.hour} óra ${now.minute} perc van.";
  } else if (qLower.contains("helyszín")) {
    return "A valós idejű helymeghatározó mag szerint jelenleg itt vagyunk: Inglewood, California, United States.";
  } else if (qLower.contains("milyen nap van ma")) {
    final now = DateTime.now();
    return "A belső naptár szerint ma van a ${now.year}. év ${now.month}. hó ${now.day}. napja.";
  } else if (qLower.contains("ki vagy te") || qLower.contains("geneview")) {
    return "A nevem GENEVIEW. Egy szuverén, önálló Edge-AI holografikus egység vagyok.";
  }
  return null; // nincs helyi találat -> DuckDuckGo-hoz kell fordulni
}

void main() async {
  print("=" * 60);
  print("1. TESZT: Belső logika (helyi válaszok)");
  print("=" * 60);

  final localTestQueries = [
    "mennyi a pontos idő",
    "milyen nap van ma",
    "hol vagyunk, helyszín",
    "ki vagy te geneview",
  ];

  for (final q in localTestQueries) {
    final answer = resolveLocalAnswer(q);
    if (answer != null) {
      print("[OK] '$q' -> $answer");
    } else {
      print("[HIBA] '$q' -> nem talált helyi választ! (pedig kellett volna)");
    }
  }

  print("");
  print("=" * 60);
  print("2. TESZT: DuckDuckGo híd (valódi hálózati hívás)");
  print("=" * 60);

  final networkTestQueries = [
    "Albert Einstein",          // jól ismert téma -> várhatóan lesz válasz
    "Python programming language", // jól ismert téma -> várhatóan lesz válasz
    "milyen idő lesz ma Budapesten", // hétköznapi kérdés -> várhatóan ÜRES lesz
  ];

  for (final q in networkTestQueries) {
    print("\n--- Kérdés: '$q' ---");
    final answer = await fetchDuckDuckGoAnswer(q);
    print("Válasz: $answer");
  }

  print("");
  print("=" * 60);
  print("ÖSSZEGZÉS");
  print("=" * 60);
  print("Ha az 1. teszt minden sora [OK] -> a belső logika jól működik.");
  print("Ha a 2. tesztben az 'Albert Einstein' és 'Python programming");
  print("language' kérdésekre kaptál értelmes választ, a DuckDuckGo híd");
  print("működik. A 'milyen idő lesz Budapesten' kérdésre valószínűleg");
  print("üres/nem-talált választ kapsz - ez VÁRHATÓ, ez a korábban");
  print("említett korlátja az Instant Answer API-nak, nem hiba.");
}