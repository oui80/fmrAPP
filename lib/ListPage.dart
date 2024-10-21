import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import 'StatPage.dart';

class SecondPage extends StatefulWidget {
  @override
  _SecondPageState createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  List<Map<String, dynamic>> data = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getData('http://nausicaa.programind.fr:5000/api/get_all_score/134');
  }

  Future<void> getData(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      print(json.decode(response.body));
      if (response.statusCode == 200) {
        setState(() {
          data = List<Map<String, dynamic>>.from(json.decode(response.body));
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _addPoint(int index) {
    setState(() {
      var currentTime = DateTime.now();
      data[index]['points'].add({'time': currentTime, 'score': 1});
    });
  }

  void _minusPoint(int index) {
    setState(() {
      var currentTime = DateTime.now();
      data[index]['points'].add({'time': currentTime, 'score': -1});
    });
  }

  int _calculateTotalPoints(List<dynamic> points) {
    int total = 0;
    for (var point in points) {
      total += point['score'] as int;
    }
    return total;
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          if (isLoading)
            Center(child: CircularProgressIndicator())
          else
            Padding(
              padding: const EdgeInsets.only(left: 15.0, top: 30, right: 15, bottom: 15),
              child: ListView.builder(
                itemCount: data.length,
                itemBuilder: (context, index) {
                  var item = data[index];
                  return Card(
                    margin: EdgeInsets.all(10),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(10),
                      title: Text(
                        '${item['nom']}   ${_calculateTotalPoints(item['points'])}',
                        style: TextStyle(fontSize: 20),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          IconButton(
                            icon: Icon(Icons.remove),
                            onPressed: () => _minusPoint(index),
                            tooltip: 'Diminuer un point',
                          ),
                          IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () => _addPoint(index),
                            tooltip: 'Ajouter un point',
                          ),
                        ],
                      ),
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
                  MaterialPageRoute(builder: (context) => StatsPage(data: data)),
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