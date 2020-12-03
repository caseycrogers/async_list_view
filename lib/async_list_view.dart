library async_list_view;

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stream_summary_builder/stream_summary_builder.dart';

class AsyncListView<T> extends StatefulWidget {
  final Stream<T> stream;
  final IndexedSnapshotWidgetBuilder<T> itemBuilder;
  final List<T>? initialData;
  final ScrollController? controller;
  final Widget? loadingWidget;
  final Widget? noResultsWidget;

  AsyncListView({
    required this.stream,
    required this.itemBuilder,
    this.initialData,
    this.controller,
    this.loadingWidget,
    this.noResultsWidget,
  });

  @override
  _AsyncListViewState<T> createState() => _AsyncListViewState<T>();
}

class _AsyncListViewState<T> extends State<AsyncListView<T>> {
  StreamController<T> _streamController = StreamController();
  // instantiate with an empty dummy StreamSubscription
  StreamSubscription<T> _streamSubscription = Stream<T>.empty().listen((_) { });
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
    if (widget.noResultsWidget != null && snapshot.connectionState == ConnectionState.done && length == 0)
      return widget.noResultsWidget!;
    return ListView.builder(
      itemBuilder: (context, index) {
        if (index < length - 1) _pauseStream();
        if (index >= length - 1) _resumeStream();
        if (index == _listSoFar.length) return widget.loadingWidget!;
        return widget.itemBuilder(context, snapshot, index);
      },
      // Allow for an extra item past the list for the loading widget.
      itemCount: snapshot.connectionState == ConnectionState.done || widget.loadingWidget == null
          ? length
          : length + 1,
      controller: widget.controller,
    );
  }

  void _initializeWithNewStream() {
    _streamController.close();
    _streamSubscription.cancel();
    _listSoFar = List.from(widget.initialData ?? []);

    _streamController = StreamController();
    _streamSubscription = widget.stream
        .listen((event) => _streamController.add(event),
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

typedef IndexedSnapshotWidgetBuilder<T> = Widget Function(BuildContext context, AsyncSnapshot<List<T>> snapshot, int index, );
