import 'package:async_list_view/async_list_view.dart';

import 'package:flutter/material.dart';

import 'mock_database.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 2,
        child: SafeArea(
          child: Scaffold(
            appBar: AppBar(
              title: const Text('AsyncListView demo!'),
              bottom: const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.menu_book)),
                  Tab(icon: Icon(Icons.add)),
                ],
              ),
            ),
            body: const TabBarView(
              children: [
                LazyFruitList(),
                Center(
                  child: SelectableText(
                    'To get a fruit added to the fruit list, please file a bug '
                    'report:\n\n'
                    'https://github.com/caseycrogers/async_list_view/issues/new?assignees=caseycrogers&labels=high-priority&template=fruit-request-template.md&title=%5BFruit%5D+Add+%3Cinsert-fruit-name-here%3E+to+the+Fruit+List',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black38,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LazyFruitList extends StatefulWidget {
  const LazyFruitList({Key? key}) : super(key: key);

  @override
  _LazyFruitListState createState() => _LazyFruitListState();
}

class _LazyFruitListState extends State<LazyFruitList> {
  // Number of fruits loaded so far
  int _loadedFruits = 0;

  // Total number of fruits meeting the search criteria
  int _totalFruits = countMatchingFruits('');

  String _searchString = '';
  late Stream<String> _fruitStream;

  void _initializeFruitStream() {
    _loadedFruits = 0;
    _totalFruits = countMatchingFruits(_searchString);
    _fruitStream = getFruits(_searchString).map((fruit) {
      // Increment here because we can't call `setState` from `itemBuilder`.
      // Use map instead of listen because listen would require a broadcast
      // stream and broadcast stream can't pause the stream's underlying source.
      // Pro tip: broadcast stream is not your friend. Avoid it at all costs.
      setState(() {
        _loadedFruits += 1;
      });
      return fruit;
    });
  }

  @override
  void initState() {
    _initializeFruitStream();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          onChanged: _onTextChanged,
          decoration: const InputDecoration(
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
              initialData: const [],
              // Display 'loading...' text if the user scrolls past the
              // currently loaded fruits to let them know they need to wait
              // for more results.
              loadingWidget: const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'loading...',
                  style: TextStyle(fontSize: 20, color: Colors.black54),
                ),
              ),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              noResultsWidgetBuilder: (context) {
                return SelectableText(
                  'No fruits found for search term \'$_searchString\'. '
                  'If you feel a fruit has excluded in error, please file '
                  'a bug report:'
                  '\n\nhttps://github.com/caseycrogers/async_list_view/issues/new?assignees=caseycrogers&labels=high-priority&template=fruit-request-template.md&title=%5BFruit%5D+Add+%3Cinsert-fruit-name-here%3E+to+the+Fruit+List',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black38,
                  ),
                  textAlign: TextAlign.center,
                );
              }),
        ),
        Container(
          color: Colors.blueAccent.shade100,
          child: Center(
            child: Text(
              '$_loadedFruits/$_totalFruits fruits loaded!',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
      ],
    );
  }

  // Take the snapshot of fruits loaded so far and the ListView index to build
  // for and build and return the desired widget corresponding to that index.
  Widget _buildFruitTile(
      BuildContext context, AsyncSnapshot<List<String>> snapshot, int index) {
    _loadedFruits = snapshot.data?.length ?? 0;
    return ListTile(
      title: Text(
        snapshot.data?[index] ?? 'Something went wrong!!!',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _onTextChanged(String newSearchString) {
    // Only update the stream if the search text has changed to avoid expensive
    // duplicate database queries.
    if (_searchString == newSearchString) {
      return;
    }
    setState(() {
      _searchString = newSearchString;
      _initializeFruitStream();
    });
  }
}
