import 'package:async_list_view/async_list_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget _boilerPlate({
    int itemCount = 1000,
    VoidCallback? onLoaded,
  }) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: AsyncListView<int>(
          stream: _streamFrom(List.generate(itemCount, (i) => i)).map((i) {
            onLoaded?.call();
            return i;
          }),
          loadingWidget: const Text('loading'),
          itemBuilder: (context, snap, index) {
            return SizedBox(
              height: 10,
              child: Text('item${snap.data![index]}'),
            );
          },
        ),
      ),
    );
  }

  testWidgets('AsyncListView displays loading and results',
      (WidgetTester tester) async {
    int loaded = 0;
    await tester.pumpWidget(_boilerPlate(onLoaded: () => loaded++));
    expect(loaded, 0);
    expect(find.text('item1'), findsNothing);
    expect(find.text('loading'), findsOneWidget);

    // Wait for 5 items to load.
    await tester.pump(const Duration(milliseconds: 5));
    expect(loaded, 5);
    expect(find.text('item1'), findsOneWidget);
    expect(find.text('item6'), findsNothing);
    expect(find.text('loading'), findsOneWidget);

    // Only as many items as are visible should load.
    await _iterativePump(tester, 100);
    expect(loaded, 86);
    expect(find.text('item1'), findsOneWidget);
    expect(find.text('item50'), findsOneWidget);
    expect(find.text('item70'), findsNothing);
    expect(find.text('loading'), findsNothing);

    await tester.drag(find.text('item1'), const Offset(0, -100));
    await _iterativePump(tester, 100);
    expect(loaded, 96);
    expect(find.text('item1'), findsNothing);
    expect(find.text('item60'), findsOneWidget);
    expect(find.text('item70'), findsNothing);
    expect(find.text('loading'), findsNothing);

    await tester.drag(find.text('item60'), const Offset(0, 100));
    await tester.pump();
    expect(loaded, 96);
    expect(find.text('item1'), findsOneWidget);
    expect(find.text('item50'), findsOneWidget);
    expect(find.text('item60'), findsNothing);
    expect(find.text('loading'), findsNothing);

    // Replace the async list view so that it disposes itself.
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });
}

/// Call pump repeatedly at 1 ms intervals.
///
/// This is necessary because async list view relies on its build function to
/// pause and resume it's input stream so we need to pump frames as elements
/// come in.
Future<void> _iterativePump(WidgetTester tester, int ms) async {
  int i = 0;
  while (i < ms) {
    await tester.pump(const Duration(milliseconds: 1));
    i++;
  }
}

Stream<T> _streamFrom<T>(List<T> values) async* {
  for (final T value in values) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
    yield value;
  }
}
