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
    localData['Games'].insert(0, {'id': idGame});
    writeData(localData);
  }

  Future<bool> _joinGame(String idGame) async {
    String url = 'http://nausicaa.programind.fr:5000/api/get_chef/$idGame';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        await _addGameLocal(idGame);
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
                  )
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () async {
                bool move = await _joinGame(_controller.text);

                if (move) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ListPage()),
                  );
                }
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
