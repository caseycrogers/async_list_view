import 'package:async_list_view/async_list_view.dart';
import 'package:example/mock_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Number of fruits loaded so far
  int _loadedFruits = 0;
  // Total number of fruits meeting the search criteria
  int _totalFruits = MockDatabase.countMatchingFruits('');
  String _searchString = '';
  Stream<String> _fruitStream = MockDatabase.getFruits('');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SafeArea(
        child: Scaffold(
          appBar: AppBar(title: Text('AsyncListView demo!')),
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
                  // If the same stream is passed repeatedly into AsyncListView
                  // AsyncListView will maintain its state and not erroneously
                  // listen to the same stream twice.
                  stream: _fruitStream,
                  itemBuilder: _buildFruitTile,
                  // Display 'loading...' text if the user scrolls past the
                  // currently loaded fruits to let them know they need to wait
                  // for more results.
                  loadingWidget: Text('  loading...',
                      style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black38)),
                ),
              ),
            ],
          ),
          // Illustrate that AsyncListView is lazily loading fruits.
          floatingActionButton: FloatingActionButton.extended(
            label: Text('Fruits Loaded: $_loadedFruits/$_totalFruits'),
            onPressed: () {},
          ),
        ),
      ),
    );
  }

  // Take the snapshot of fruits loaded so far and the ListView index to build
  // for and build and return the desired widget corresponding to that index.
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
    // Only update the stream if the search text has changed to avoid expensive
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
