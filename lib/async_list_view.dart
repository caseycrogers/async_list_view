library async_list_view;

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:stream_summary_builder/stream_summary_builder.dart';

/// A wrapper around [StreamSummaryBuilder] and [ListView] that displays a
/// scrollable list of items lazily fetched from an asynchronous data source.
///
/// AsyncListView is useful for loading a list of results from an asynchronous
/// database. Example use cases:
///  * display user chat history retrieved from Firestore.
///  * display search results for items on an online marketplace.
///
/// `T` is the event type of the provided source stream.
class AsyncListView<T> extends StatefulWidget {
  Key? key;

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
  final Widget? noResultsWidget;

  final Axis scrollDirection;
  final bool reverse;
  final ScrollController? controller;
  final bool? primary;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final EdgeInsetsGeometry? padding;
  final double? itemExtent;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;
  final double? cacheExtent;
  final DragStartBehavior dragStartBehavior;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final String? restorationId;
  final Clip clipBehavior;

  /// Creates an [AsyncListView] connected to the specified [stream].
  AsyncListView({
    required this.stream,
    required this.itemBuilder,
    this.initialData,
    this.loadingWidget,
    this.noResultsWidget,
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
  });

  @override
  _AsyncListViewState<T> createState() => _AsyncListViewState<T>();
}

class _AsyncListViewState<T> extends State<AsyncListView<T>> {
  StreamController<T> _streamController = StreamController();

  // instantiate with an empty dummy StreamSubscription
  StreamSubscription<T> _streamSubscription = Stream<T>.empty().listen((_) {});
  List<T> _listSoFar = [];

  _AsyncListViewState();

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
    super.dispose();
    _streamSubscription.cancel();
    _streamController.close();
  }

  @override
  Widget build(BuildContext context) {
    return StreamSummaryBuilder<T, List<T>>(
      initialData: _listSoFar,
      fold: (lst, newValue) {
        _listSoFar = lst..add(newValue);
        // Return a copy to the avoid race conditions.
        return List.from(_listSoFar);
      },
      stream: _streamController.stream,
      builder: _buildList,
    );
  }

  Widget _buildList(BuildContext context, AsyncSnapshot<List<T>> snapshot) {
    var length = snapshot.data?.length ?? 0;
    if (widget.noResultsWidget != null &&
        snapshot.connectionState == ConnectionState.done &&
        length == 0) return widget.noResultsWidget!;
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
        if (index < length - 1) _pauseStream();
        if (index >= length - 1) _resumeStream();
        if (index == _listSoFar.length) return widget.loadingWidget!;
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
    _listSoFar = List.from(widget.initialData ?? []);

    _streamController = StreamController();
    _streamSubscription = widget.stream.listen(
        (event) => _streamController.add(event),
        onDone: () => _streamController.close(),
        onError: (e) => _streamController.addError(e));
    _streamController = StreamController<T>();
  }

  void _pauseStream() {
    if (!_streamSubscription.isPaused) _streamSubscription.pause();
  }

  void _resumeStream() {
    if (_streamSubscription.isPaused) _streamSubscription.resume();
  }
}

/// A builder that builds a list item from a BuildContext, snapshot of items
/// seen so far, and item index.
typedef IndexedSnapshotWidgetBuilder<T> = Widget Function(
  BuildContext context,
  AsyncSnapshot<List<T>> snapshot,
  int index,
);
