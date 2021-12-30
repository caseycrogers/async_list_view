library async_list_view;

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:stream_summary_builder/stream_summary_builder.dart';

/// A wrapper around [StreamSummaryBuilder] and [ListView] that displays a
/// scrollable list of lazily loaded stream elements.
///
/// AsyncListView is useful for loading a list of results from an asynchronous
/// database. Example use cases:
///  * display user chat history retrieved from Firestore.
///  * display search results for items on an online marketplace.
///
/// `T` is the event type of the provided source stream.
class AsyncListView<T> extends StatefulWidget {
  /// Creates an [AsyncListView] connected to the specified [stream].
  const AsyncListView({
    Key? key,
    required this.stream,
    required this.itemBuilder,
    this.initialData,
    this.loadingWidget,
    this.noResultsWidgetBuilder,
    // Generic ListView parameters.
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    this.itemExtent,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.cacheExtent,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
  }) : super(key: key);

  /// The Stream providing events for this ListView. AsyncListView will reuse
  /// an existing StreamSubscription if passed the same Stream twice so a
  /// non-broadcast stream can be safely used here.
  final Stream<T> stream;

  /// See [IndexedSnapshotWidgetBuilder].
  final IndexedSnapshotWidgetBuilder<T> itemBuilder;

  /// Synchronously fetched data to seed the displayed [ListView] with. Stream
  /// events will be appended to [initialData].
  ///
  /// This is especially useful if you need to rebuild your [AsyncListView]
  /// elsewhere in the widget tree and don't want to re-fetch list elements.
  final List<T>? initialData;

  /// A [Widget] to display at the end of the contained [ListView] if the
  /// user scrolls to the bottom of the [ListView] before the source [stream]
  /// is done.
  final Widget? loadingWidget;

  /// A [Widget] to display instead of the [ListView] if the source [stream]
  /// finishes without producing any events.
  final WidgetBuilder? noResultsWidgetBuilder;

  /// The following attributes are all passed directly through to [ListView] as
  /// constructor arguments.

  /// See [ScrollView.scrollDirection].
  final Axis scrollDirection;

  /// See [ScrollView.reverse].
  final bool reverse;

  /// See [ScrollView.controller].
  final ScrollController? controller;

  /// See [ScrollView.primary].
  final bool? primary;

  /// See [ScrollView.physics].
  final ScrollPhysics? physics;

  /// See [ScrollView.shrinkWrap].
  final bool shrinkWrap;

  /// See [ListView.padding].
  final EdgeInsetsGeometry? padding;

  /// See [ListView.itemExtent].
  final double? itemExtent;

  /// See [SliverChildListDelegate.addAutomaticKeepAlives].
  final bool addAutomaticKeepAlives;

  /// See [SliverChildListDelegate.addRepaintBoundaries].
  final bool addRepaintBoundaries;

  /// See [SliverChildListDelegate.addSemanticIndexes].
  final bool addSemanticIndexes;

  /// See [ScrollView.cacheExtent].
  final double? cacheExtent;

  /// See [ScrollView.dragStartBehavior].
  final DragStartBehavior dragStartBehavior;

  /// See [ScrollView.keyboardDismissBehavior].
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  /// See [ScrollView.restorationId].
  final String? restorationId;

  /// See [ScrollView.clipBehavior].
  final Clip clipBehavior;

  @override
  _AsyncListViewState<T> createState() => _AsyncListViewState<T>();
}

class _AsyncListViewState<T> extends State<AsyncListView<T>> {
  StreamController<T> _streamController = StreamController();

  // instantiate with an empty dummy StreamSubscription
  StreamSubscription<T> _streamSubscription = Stream<T>.empty().listen((_) {});
  List<T> _listSoFar = [];

  @override
  void initState() {
    super.initState();
    _initializeWithNewStream();
  }

  @override
  void didUpdateWidget(AsyncListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stream != widget.stream) {
      _initializeWithNewStream();
    }
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    _streamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamSummaryBuilder<T, List<T>>(
      initialData: _listSoFar,
      fold: (lst, newValue) {
        _listSoFar = List.from(lst)..add(newValue);
        // Return a copy to the avoid race conditions.
        return List.from(_listSoFar);
      },
      stream: _streamController.stream,
      builder: _buildList,
    );
  }

  Widget _buildList(BuildContext context, AsyncSnapshot<List<T>> snapshot) {
    final int length = snapshot.data?.length ?? 0;
    if (widget.noResultsWidgetBuilder != null &&
        snapshot.connectionState == ConnectionState.done &&
        length == 0) {
      return widget.noResultsWidgetBuilder!(context);
    }
    return ListView.builder(
      key: widget.key,
      scrollDirection: widget.scrollDirection,
      reverse: widget.reverse,
      controller: widget.controller,
      primary: widget.primary,
      physics: widget.physics,
      shrinkWrap: widget.shrinkWrap,
      padding: widget.padding,
      itemExtent: widget.itemExtent,
      itemBuilder: (context, index) {
        if (index < length - 1) {
          _pauseStream();
        } else if (index >= length - 1) {
          _resumeStream();
        }
        if (index == _listSoFar.length) {
          return widget.loadingWidget!;
        }
        return widget.itemBuilder(context, snapshot, index);
      },
      // Allow for an extra item past the list for the loading widget.
      itemCount: snapshot.connectionState == ConnectionState.done ||
              widget.loadingWidget == null
          ? length
          : length + 1,
      addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
      addRepaintBoundaries: widget.addRepaintBoundaries,
      addSemanticIndexes: widget.addSemanticIndexes,
      cacheExtent: widget.cacheExtent,
      dragStartBehavior: widget.dragStartBehavior,
      keyboardDismissBehavior: widget.keyboardDismissBehavior,
      restorationId: widget.restorationId,
      clipBehavior: widget.clipBehavior,
    );
  }

  void _initializeWithNewStream() {
    _streamController.close();
    _streamSubscription.cancel();
    _listSoFar = List.from(widget.initialData ?? <T>[]);

    _streamController = StreamController();
    _streamSubscription = widget.stream.listen(
        (event) => _streamController.add(event),
        onDone: () => _streamController.close(),
        onError: (Object e) => _streamController.addError(e));
    _streamController = StreamController<T>();
  }

  void _pauseStream() {
    if (!_streamSubscription.isPaused) {
      _streamSubscription.pause();
    }
  }

  void _resumeStream() {
    if (_streamSubscription.isPaused) {
      _streamSubscription.resume();
    }
  }
}

/// A builder that builds a list item from a BuildContext, snapshot of items
/// seen so far, and item index.
typedef IndexedSnapshotWidgetBuilder<T> = Widget Function(
  BuildContext context,
  AsyncSnapshot<List<T>> snapshot,
  int index,
);
