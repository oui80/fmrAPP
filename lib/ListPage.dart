import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import 'Data.dart';
import 'StatPage.dart';

class ListPage extends StatefulWidget {
  @override
  _ListPageState createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  List<Player> players = [];
  bool isLoading = true;
  String idGame = '';
  late String chefFromJson;
  bool isChef = false;

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: idGame));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Text copied to clipboard')),
    );
  }

  @override
  void initState() {
    super.initState();
    loadChefFromJson();
  }

  Future<void> loadChefFromJson() async {
    Map<String, dynamic> localData = await readData();
    setState(() {
      // on récupère la première partie de la base de données
      idGame = localData['Games'][0]['id'];
      chefFromJson = localData['idPhone'];

      String url = 'http://nausicaa.programind.fr:5000/api/get_chef/$idGame';
      try {
        http.get(Uri.parse(url)).then((response) {
          if (response.statusCode == 200) {
            final responseData = json.decode(response.body);
            if (responseData == chefFromJson) {
              isChef = true;
            }
          } else {
            throw Exception('Failed to load data');
          }
        }).then((_) {
          getData(
              'http://nausicaa.programind.fr:5000/api/get_all_score/$idGame');
        });
      } catch (e) {
        print('Error: $e');
      }
    });
  }

  Future<void> getData(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          Data data = Data.fromJson(responseData);
          players = data.players; // Assurez-vous que `players` est une liste de type `Player`
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error: $e');
    }
  }


  Future<void> _updateScore(int i) async {
    Map<String, dynamic> localData = await readData();
    String nameJoueur = localData['Games'][0]['nomJoueur'];

    final url = 'http://nausicaa.programind.fr:5000/api/update_score';

    // Corps de la requête en format JSON
    final body = json.encode({
      "name": nameJoueur,
      "score": {
        "date": DateTime.now().toIso8601String(),
        "score": players[i].scores.last.scoreValue,
      },
    });

    try {
      // Envoi de la requête POST
      final response = await http
          .post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      )
          .then((response) async {
        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          print(responseData);
        } else {
          throw Exception('Failed to create game');
        }
      });
    } catch (e) {
      print('Error: $e');
    }
  }

  void _addPoint(int index) {
    setState(() {
      var currentTime = DateTime.now().toIso8601String();
      players[index].scores.add(
          Score(date: currentTime, scoreValue: players[index].scores.last.scoreValue + 1));
    });
    _updateScore(index);
  }

  void _minusPoint(int index) {
    setState(() {
      var currentTime = DateTime.now().toIso8601String();
      players[index].scores.add(
          Score(date: currentTime, scoreValue: players[index].scores.last.scoreValue - 1));
    });
    _updateScore(index);
  }

  String _formatDate(String date) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.parse(date));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Center(
              child: InkWell(
                  onTap: () => _copyToClipboard(context),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text('ID :   $idGame',
                        style:
                            const TextStyle(fontSize: 25, letterSpacing: 1.5)),
                  )))),
      body: Stack(
        children: <Widget>[
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, top: 30, right: 15, bottom: 15),
              child: ListView.builder(
                itemCount: players.length,
                itemBuilder: (context, index) {
                  var player = players[index];
                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(10),
                      title: Text(
                        '${player.name}   ${player.scores.last.scoreValue}',
                        style: const TextStyle(fontSize: 20),
                      ),
                      trailing: isChef
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () => _minusPoint(index),
                                  tooltip: 'Diminuer un point',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () => _addPoint(index),
                                  tooltip: 'Ajouter un point',
                                ),
                              ],
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          Positioned(
            bottom: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StatPage(players)),
                );
              },
              child: Icon(Icons.check),
              style: ElevatedButton.styleFrom(
                shape: CircleBorder(),
                padding: EdgeInsets.all(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
