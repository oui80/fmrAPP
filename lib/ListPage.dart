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
  String nomPartie = "";
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
      nomPartie = localData['Games'][0]['nomPartie'];

      String url = 'http://nausicaa.programind.fr:5000/api/get_chef/$idGame';
      try {
        http.get(Uri.parse(url)).then((response) {
          if (response.statusCode == 200) {
            final responseData = json.decode(response.body);
            if (responseData["id_chef"] == chefFromJson) {
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

  Future<void> _updateScore(int i, num incr) async {
    String nameJoueur = players[i].name;

    final url = 'http://nausicaa.programind.fr:5000/api/update_score/$idGame';

    // Corps de la requête en format JSON
    final body = json.encode({
      "name": nameJoueur,
      "score": incr,
    });

    try {
      // Envoi de la requête POST
      final response = await http.post(
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

  void _addPoint(int index, num incr) async {
    setState(() {
      var currentTime = DateTime.now().toIso8601String();
      for (var i = 0; i < players.length; i++) {
        if (i != index) {
          players[i].scores.add(Score(
              date: currentTime,
              scoreValue: players[i].scores.last.scoreValue));
        } else {
          players[i].scores.add(Score(
              date: currentTime,
              scoreValue: players[i].scores.last.scoreValue + incr));
        }
      }
    });
    _updateScore(index, incr);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Center(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 10),
              ),
              Text(
                nomPartie,
                style: const TextStyle(fontSize: 25, letterSpacing: 1.5),
              ),
              InkWell(
                onTap: () => _copyToClipboard(context),
                child: Padding(
                  padding: const EdgeInsets.only(
                      bottom: 10, left: 10, right: 10, top: 10),
                  child: Text(
                    'ID :   $idGame',
                    style: const TextStyle(fontSize: 15, letterSpacing: 1.5),
                  ),
                ),
              ),
            ],
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
                          margin: const EdgeInsets.only(
                              bottom: 8, left: 10, right: 10, top: 6),
                          child: ListTile(
                            contentPadding: const EdgeInsets.only(
                                bottom: 2, left: 15, right: 10, top: 2),
                            title: Column(
                              children: [
                                SizedBox(
                                  width: 1000,
                                  child: Row(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.deepPurple[50],
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              left: 5.0, right: 5),
                                          child: Text(
                                            '${player.scores.last.scoreValue}',
                                            style: const TextStyle(
                                                fontSize: 24,
                                                color: Colors.deepPurple),
                                          ),
                                        ),
                                      ),
                                      Expanded(child: Container()),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 1000,
                                  child: Text(
                                    player.name,
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                ),
                              ],
                            ),
                            trailing: isChef
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      SizedBox(
                                        width: 30,
                                        child: IconButton(
                                          icon:
                                              const Icon(Icons.remove_rounded),
                                          iconSize: 15,
                                          onPressed: () =>
                                              _addPoint(index, -0.5),
                                          tooltip: 'Diminuer un point',
                                          padding: EdgeInsets.all(0),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 40,
                                        child: IconButton(
                                          iconSize: 30,
                                          icon:
                                              const Icon(Icons.remove_rounded),
                                          onPressed: () => _addPoint(index, -1),
                                          tooltip: 'Diminuer un point',
                                          padding: EdgeInsets.all(0),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 40,
                                        child: IconButton(
                                          iconSize: 30,
                                          icon: const Icon(Icons.add_rounded),
                                          onPressed: () => _addPoint(index, 1),
                                          tooltip: 'Ajouter un point',
                                          padding: EdgeInsets.all(0),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 30,
                                        child: IconButton(
                                          icon: const Icon(Icons.add_rounded),
                                          iconSize: 15,
                                          onPressed: () =>
                                              _addPoint(index, 0.5),
                                          tooltip: 'Ajouter un demi point',
                                          padding: EdgeInsets.all(0),
                                        ),
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
              bottom: 30,
              left: 40,
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
                                  scores: [
                                    Score(
                                        date: DateTime.now().toIso8601String(),
                                        scoreValue: 0)
                                  ],
                                ));
                                _updateScore(players.length - 1, 0);
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
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(15),
                ),
                child: const SizedBox(
                  width: 90,
                  child: Icon(
                    Icons.add_rounded,
                    size: 30,
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 30,
            right: 40,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StatPage(players)),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(15),
              ),
              child: const SizedBox(
                width: 90,
                child: Icon(
                  Icons.bar_chart_rounded,
                  size: 30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
