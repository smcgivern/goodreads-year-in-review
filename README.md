## Goodreads year in review

A command-line tool to produce a plot of a year's reading on Goodreads.

### Usage

#### Generating the initial CSV

The Makefile does the initial work to generate a CSV file of the user's
reading. It takes two variables:

1. `GOODREADS_ID` - Goodreads user ID. Defaults to mine (4625510).
2. `GOODREADS_KEY` - Goodreads API key. No sensible default possible.

```shell
make goodreads.csv GOODREADS_KEY=$GOODREADS_KEY
```

Will generate a `goodreads.csv` file.

### Goodreads exports

Goodreads are [removing their API support][api], and recommend using their
[export] feature instead. I'd love to use the export instead, but I can't, as
it's missing some crucial information - when the book was started:

```shell
$ cat goodreads_library_export.csv | xsv search --select 'Date Read' '2020/\d{2}/\d{2}' | xsv select 'Title,Author,Date Added,Date Read' | tail -n 1
The Kite Runner,Khaled Hosseini,2017/10/28,2020/01/03
```

This says that I added [The Kite Runner][tkr] in 2017, which is true. But I
didn't start reading it until December 2019. The [reviews.list API][rl] does
handle this, which we can demonstrate with [xq]:

```shell
$ curl -s "https://www.goodreads.com/review/list/4625510.xml?key=$GOODREADS_KEY&v=2&page=1&per_page=200&sort=date_read&order=d&shelf=read" | xq '.GoodreadsResponse.reviews.review[] | select(.book.title == "The Kite Runner") | [.date_added, .started_at, .read_at]'
[
  "Sat Oct 28 01:52:25 -0700 2017",
  "Mon Dec 30 11:20:49 -0800 2019",
  "Fri Jan 03 22:34:43 -0800 2020"
]
```

[api]: https://help.goodreads.com/s/article/Does-Goodreads-support-the-use-of-APIs
[export]: https://help.goodreads.com/s/article/How-do-I-import-or-export-my-books-1553870934590
[tkr]: https://www.goodreads.com/book/show/77203.The_Kite_Runner
[rl]: https://www.goodreads.com/api/index#reviews.list
[xq]: https://kislyuk.github.io/yq/#xml-support
