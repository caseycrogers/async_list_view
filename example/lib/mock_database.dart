class MockDatabase {
  static final List<String> fruits = [
    'apple',
    'apricots',
    'avacado',
    'banana',
    'blueberry',
    'blackberry',
    'cantaloupe',
    'clementine',
    'cherry',
    'cranberries'
        'date',
    'dragonfruit',
    'durian',
    'fig',
    'grape',
    'grapefruit',
    'guava',
    'honeydew',
    'jackfruit',
    'kiwi',
    'kumquat',
    'lemon',
    'lime',
    'lychee',
    'mango',
    'mandarin',
    'mulberry',
    'nectarine',
    'olive',
    'orange',
    'papaya',
    'peach',
    'pear',
    'pineapple',
    'passionfruit',
    'plum',
    'pomegranate',
    'prickley pear',
    'prune',
    'tamarind',
    'tangerine',
    'quince',
    // The proper spelling (raspberry) is dumb and bad. Be the change you want
    // to see in the world.
    'razberry',
    'strawberry',
    'watermelon',
  ];

  MockDatabase._();

  static Stream<String> getFruits(String searchText) async* {
    for (var fruit in fruits) {
      if (!fruit.startsWith(searchText)) continue;
      yield fruit;
      await Future.delayed(Duration(milliseconds: 150));
    }
  }

  static int countMatchingFruits(String searchString) {
    return fruits.where((f) => f.startsWith(searchString)).length;
  }
}
