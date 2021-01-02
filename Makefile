GOODREADS_ID := "4625510"
GOODREADS_KEY := "foo"

goodreads.xml:
	curl -s "https://www.goodreads.com/review/list/${GOODREADS_ID}.xml?key=${GOODREADS_KEY}&v=2&page=1&per_page=200&sort=date_read&order=d&shelf=read" > goodreads.xml

goodreads.csv: goodreads.xml
	echo 'Title,Author,Started,Finished' > goodreads.csv
	xq -r '.GoodreadsResponse.reviews.review[] | select(.read_at // "" | endswith("2020")) | [.book.title_without_series, .book.authors.author.name, .started_at, .read_at] | @csv' goodreads.xml >> goodreads.csv
