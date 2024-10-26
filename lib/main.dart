import 'package:flutter/material.dart';
import 'JoinPage.dart';
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

  @override
  void initState() {
    super.initState();
    loadPhoneId();
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

  Future<void> _createGame() async {
    final url = 'http://nausicaa.programind.fr:5000/api/creer_partie';

    // Corps de la requête en format JSON
    final body = json.encode({
      "id_chef": idPhone,
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

          Map<String, dynamic> localData = await readData();
          localData['Games'] ??= [];
          localData['Games']
              .insert(0,({'id': responseData["data"]['game_id'], 'nomJoueur': 'Moi'}));
          writeData(localData);
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
              width: 200, // Set the desired width
              height: 60, // Set the desired height
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => JoinPage()),
                  );
                },
                child: const Text('Join'),
                style: ElevatedButton.styleFrom(
                  textStyle: TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 200, // Set the desired width
              height: 60, // Set the desired height
              child: ElevatedButton(
                onPressed: () async {
                  await _createGame();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ListPage()),
                  );
                },
                child: const Text('Create'),
                style: ElevatedButton.styleFrom(
                  textStyle: TextStyle(fontSize: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
