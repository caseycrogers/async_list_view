# async_list_view

A wrapper around `StreamSummaryBuilder` and `ListView` that displays a
scrollable list of items lazily fetched from an asynchronous data source.
AsyncListView is useful for loading a list of results from an asynchronous
database. Example use cases:
 * display user chat history retrieved from Firestore.
 * display search results for items on an online marketplace.
 
`T` is the event type of the provided source stream.

**Disclaimer:** This package isn't unit tested (yet). Use at your own risk.
Any contributions, bug reports or feature requests are  welcome.
