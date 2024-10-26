import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'Data.dart';
import 'ListPage.dart';

class JoinPage extends StatefulWidget {
  @override
  _JoinPageState createState() => _JoinPageState();
}

class _JoinPageState extends State<JoinPage> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _controller2 = TextEditingController();
  String _errorMessage = '';

  Future<void> _addGameLocal(String idGame) async {
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
        // on remonte la partie en haut de la liste
        localData['Games'].removeWhere((element) => element['id'] == idGame);
      }
    }
    localData['Games']
        .insert(0, {'id': idGame, 'nomJoueur': _controller2.text});
    writeData(localData);
  }

  Future<void> _joinGame(String idGame) async {
    String url = 'http://nausicaa.programind.fr:5000/api/update_score/$idGame';
    final body = json.encode({
      "name": _controller2.text,
      "score": {
        "date": DateTime.now().toIso8601String(),
        "score": 0,
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
          await _addGameLocal(idGame);
        } else {
          throw Exception('Failed to join game');
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Cette partie n\'existe pas';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: 'Id partie',
                      border: OutlineInputBorder(),
                      errorText: _errorMessage.isEmpty ? null : _errorMessage,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _errorMessage = '';
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _controller2,
                    decoration: InputDecoration(
                      labelText: 'Pseudo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () async {
                await _joinGame(_controller.text);

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ListPage()),
                );
              },
              child: Icon(Icons.check),
              style: ElevatedButton.styleFrom(
                  shape: CircleBorder(), padding: EdgeInsets.all(20)),
            ),
          ),
        ],
      ),
    );
  }
}
