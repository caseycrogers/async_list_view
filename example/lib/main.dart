import 'package:async_list_view/async_list_view.dart';
import 'package:example/mock_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _loadedFruits = 0;
  int _totalFruits = MockDatabase.countMatchingFruits('');
  String _searchString = '';
  Stream<String> _fruitStream = MockDatabase.getFruits('');

  @override
  void initState() {
    super.initState();

    _updateWithNewSearchString(_searchString);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stream Summary Builder Demo',
      home: SafeArea(
        child: Scaffold(
          body: Column(
            children: [
              TextField(
                onChanged: _onTextChanged,
                decoration: InputDecoration(
                  hintText: 'Search Fruits...',
                ),
              ),
              Expanded(
                child: AsyncListView<String>(
                  stream: _fruitStream,
                  itemBuilder: _buildFruitTile,
                  loadingWidget: Text('  loading...',
                      style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black38)),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            label: Text('Fruits Loaded: $_loadedFruits/$_totalFruits'),
            onPressed: () {},
          ),
        ),
      ),
    );
  }

  Widget _buildFruitTile(
      BuildContext context, AsyncSnapshot<List<String>> snapshot, int index) {
    Future.delayed(Duration(seconds: 0)).then((value) => setState(() {
          _loadedFruits = snapshot.data?.length ?? 0;
        }));
    return ListTile(
      title: Text(
        snapshot.data?[index] ?? 'Something went wrong!!!',
        style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _onTextChanged(String newSearchString) {
    // Only update the stream if the search text has changed to avoid
    // duplicate database queries.
    if (_searchString == newSearchString) return;
    _updateWithNewSearchString(newSearchString);
  }

  void _updateWithNewSearchString(String newSearchString) {
    setState(() {
      _searchString = newSearchString;
      _fruitStream = MockDatabase.getFruits(_searchString);
      _totalFruits = MockDatabase.countMatchingFruits(_searchString);
    });
  }
}
