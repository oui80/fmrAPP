import 'package:flutter/material.dart';
import 'ListPage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'Data.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String idPhone = '';
  TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadPhoneId();
  }

  final TextEditingController _controllerJoin = TextEditingController();
  String _errorMessage = '';

  Future<void> _addGameLocal(String idGame, String nomPartie) async {
    Map<String, dynamic> localData = await readData();
    if (localData['Games'] == null) {
      localData['Games'] = [];
    } else {
      // on vérifie si la partie est déjà dans la liste
      bool found = false;
      for (var i = 0; i < localData['Games'].length; i++) {
        if (localData['Games'][i]['id'] == idGame) {
          found = true;
          break;
        }
      }
      if (found) {
        // on l'enlève afin de remonter la partie en haut de la liste
        localData['Games'].removeWhere((element) => element['id'] == idGame);
      }
    }
    localData['Games'].insert(0, {'id': idGame, 'nomPartie': nomPartie});
    writeData(localData);
  }

  Future<bool> _joinGame(String idGame) async {
    String url = 'http://nausicaa.programind.fr:5000/api/get_chef/$idGame';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        Map<String,dynamic> responseData = json.decode(response.body);
        await _addGameLocal(idGame,responseData['nom_game']);
        return true;
      } else {
        throw Exception('Failed to join game');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Cette partie n\'existe pas';
      });
      return false;
    }
  }

  Widget JoinDialog(BuildContext context) {
    return AlertDialog(
      title: const Text('Rejoindre une partie'),
      content: TextField(
          controller: _controllerJoin,
          decoration: InputDecoration(
            labelText: 'Id partie',
            border: OutlineInputBorder(),
            errorText: _errorMessage.isEmpty ? null : _errorMessage,
          )),

      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () async {
            bool move = await _joinGame(_controllerJoin.text);

            if (move) {
              _controllerJoin.clear();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ListPage()),
              );
            }
          },
          child: const Text('Rejoindre'),
        ),
      ],
    );
  }

  Future<void> setIdPhone(Map<String, dynamic> localData) async {
    final url = 'http://nausicaa.programind.fr:5000/api/new_id';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        idPhone = responseData.values.first;
        localData['idPhone'] = idPhone;
        await writeData(localData);
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> loadPhoneId() async {
    Map<String, dynamic> localData = await readData();
    setState(() {
      String? temp = localData['idPhone'];
      if (temp != null) {
        idPhone = temp;
      } else {
        setIdPhone(localData).then((_) async {
          await writeData(localData);
        });
      }
    });
  }

  Future<void> _createGame(String nom) async {
    final url = 'http://nausicaa.programind.fr:5000/api/creer_partie';

    final body = json.encode({
      "id_chef": idPhone,
      "nom_game": nom,
    });

    try {
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

          Map<String, dynamic> localData = await readData();
          localData['Games'] ??= [];
          localData['Games'].insert(
              0, ({'id': responseData["data"]['game_id'], 'nomPartie': nom}));
          await writeData(localData);
        } else {
          throw Exception('Failed to create game');
        }
      });
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 200,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return JoinDialog(context);
                      });
                },
                style: ElevatedButton.styleFrom(
                  textStyle: TextStyle(fontSize: 20),
                ),
                child: const Text('Join'),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 200,
              height: 60,
              child: ElevatedButton(
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Créer une partie'),
                        content: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            hintText: 'Nom partie',
                          ),
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () async {
                              await _createGame(_controller.text);
                              _controller.clear();
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (context) => ListPage()),
                              );
                            },
                            child: const Text('Créer'),
                          ),
                        ],
                      );
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 20),
                ),
                child: const Text('Create'),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 200,
              height: 60,
              child: ElevatedButton(
                onPressed: () async {
                  Map<String, dynamic> localData = await readData();
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Historique'),
                        content: SingleChildScrollView(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.8,
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: (localData['Games'] == null)
                                ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: Text('Aucune partie récente'),
                                ))
                                : ListView.builder(
                              itemCount: localData['Games'].length,
                              itemBuilder: (BuildContext context, int index) {
                                var partie = localData['Games'][index];
                                return ListTile(
                                  title: Row(
                                    children: [
                                      SizedBox(
                                        width: 150,
                                        height: 30,
                                        child: Text(
                                          '${partie['nomPartie']}',
                                          style: const TextStyle(fontSize: 25),
                                        ),
                                      ),
                                      Expanded(child: Container()),
                                      Text(
                                        'id : ${partie['id']}',
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                    ],
                                  ),
                                  onTap: () async {
                                    await _joinGame(partie['id']);
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) => ListPage()),
                                    );

                                  },
                                );
                              },
                            ),
                          ),
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Fermer'),
                          ),
                        ],
                      );
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 20),
                ),
                child: const Text('Récent'),
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
