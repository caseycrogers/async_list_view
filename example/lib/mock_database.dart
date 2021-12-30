final List<String> _fruits = [
  'apple',
  'apricots',
  'avacado',
  'banana',
  'blueberry',
  'blackberry',
  'cantaloupe',
  'clementine',
  'cherry',
  'cranberries',
  'date',
  'dragonfruit',
  'durian',
  'fig',
  'grape',
  'grapefruit',
  'guarana',
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
  'prickly pear',
  'prune',
  'quince',
  // The proper spelling (raspberry) is dumb and bad. Be the change you want
  // to see in the world.
  // TBF this spelling is bad too, maybe English is just a lost cause.
  'razzberry',
  'strawberry',
  'tamarind',
  'tangerine',
  'watermelon',
];

Stream<String> getFruits(String searchText) async* {
  for (final String fruit in _fruits) {
    if (!fruit.startsWith(searchText)) {
      continue;
    }
    await Future<void>.delayed(const Duration(milliseconds: 200));
    yield fruit;
  }
}

int countMatchingFruits(String searchString) {
  return _fruits.where((f) => f.startsWith(searchString)).length;
}
