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
  TextEditingController _controller = TextEditingController();

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
          players = responseData['players']
              .map<Player>((player) => Player.fromJson(player))
              .toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _updateScore(int i,int incr) async {
    String nameJoueur = players[i].name;

    final url = 'http://nausicaa.programind.fr:5000/api/update_score/$idGame';

    // Corps de la requête en format JSON
    final body = json.encode({
      "name": nameJoueur,
      "score": incr,
    });

    try {
      // Envoi de la requête POST
      final response = await http
          .post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-HTTP-Version': 'HTTP/1.1 ',
        },
        body: body,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update score');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void _addPoint(int index) async {
    setState(() {
      var currentTime = DateTime.now().toIso8601String();
      players[index].scores.add(Score(
          date: currentTime,
          scoreValue: players[index].scores.last.scoreValue + 1));
    });
    _updateScore(index,1);

  }

  void _minusPoint(int index) {
    setState(() {
      var currentTime = DateTime.now().toIso8601String();
      players[index].scores.add(Score(
          date: currentTime,
          scoreValue: players[index].scores.last.scoreValue - 1));
      _updateScore(index,-1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: InkWell(
            onTap: () => _copyToClipboard(context),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                'ID :   $idGame',
                style: const TextStyle(fontSize: 25, letterSpacing: 1.5),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 15.0, top: 30, right: 15, bottom: 15),
                    child: ListView.builder(
                      itemCount: players.length,
                      itemBuilder: (context, index) {
                        var player = players[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 6, left: 10, right: 10, top: 6),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(6),
                            title: Text(
                              '  ${player.name}   ${player.scores.last.scoreValue}',
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
                ),
                const SizedBox(
                  width: 100, // Set the desired width
                  height: 80,
                ),
              ],
            ),
          if (isChef)
            Positioned(
              bottom: 20,
              left: 20,
              child: ElevatedButton(
                onPressed: () {
                  // on ouvre un dialogue pour ajouter un joueur
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Ajouter un joueur'),
                        content: TextField(
                          controller: _controller,
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                players.add(Player(
                                  name: _controller.text,
                                  scores: [Score(date: DateTime.now().toIso8601String(), scoreValue: 0)],
                                ));
                                _updateScore(players.length - 1,0);
                                _controller.clear();
                              });
                              Navigator.of(context).pop();
                            },
                            child: const Text('Ajouter'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const Icon(Icons.add),
                style: ElevatedButton.styleFrom(
                  shape: CircleBorder(),
                  padding: EdgeInsets.all(20),
                ),
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
