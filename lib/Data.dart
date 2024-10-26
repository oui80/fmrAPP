import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class Player {
  final String name;
  final List<Score> scores; // Renommer pour refléter qu'il peut y avoir plusieurs scores

  Player({required this.name, required this.scores});

  factory Player.fromJson(Map<String, dynamic> json) {
    var scoreDataList = json['Score'] as List; // Liste de scores
    List<Score> scores = scoreDataList.map((scoreData) => Score.fromJson(scoreData)).toList();

    return Player(
      name: json['name'] as String,
      scores: scores,
    );
  }
}



class Score {
  final String date;
  final int scoreValue; // Renommer pour éviter la confusion avec le champ imbriqué

  Score({required this.date, required this.scoreValue});

  factory Score.fromJson(Map<String, dynamic> json) {
    return Score(
      date: json['date'] as String,
      scoreValue: json['score']['score'] as int, // Accéder à la valeur de score
    );
  }
}

class Data {
  final List<Player> players;

  Data({required this.players});

  factory Data.fromJson(Map<String, dynamic> json) {
    var playerList = json['players'] as List;
    List<Player> players = playerList.map((playerData) => Player.fromJson(playerData)).toList();

    return Data(
      players: players,
    );
  }
}

// Gestion de la base de données locale

Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}

Future<File> get _localFile async {
  final path = await _localPath;
  return File('$path/DataBase.json');
}

Future<void> writeData(Map<String, dynamic> data) async {
  final file = await _localFile;
  await file.writeAsString(json.encode(data));
}

Future<Map<String, dynamic>> readData() async {
  try {
    final file = await _localFile;
    final contents = await file.readAsString();
    return json.decode(contents);
  } catch (e) {
    return {};
  }
}