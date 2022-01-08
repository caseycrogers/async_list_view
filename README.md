![](https://github.com/caseycrogers/async_list_view/blob/main/async_list_view_banner.png)

Displays a scrollable list of items lazily fetched from an asynchronous data
source. Async list view is a thin wrapper on top of `ListView.builder` and
`StreamSummaryBuilder`.

Because items are only fetched when they're visible to the user, async list
view reduces potentially expensive database reads.

Example use cases:
 * display user chat history retrieved from Firestore.
 * display search results for items on an online marketplace.
 * display log lines read from a large file.

Any contributions, bug reports, or feature requests are  welcome.
