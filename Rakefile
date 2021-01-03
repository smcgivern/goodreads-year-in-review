require 'open-uri'
require './word_count'

file 'goodreads.xml' do
  goodreads_id = ENV.fetch('GOODREADS_ID', 4625510)
  goodreads_key = ENV.fetch('GOODREADS_KEY')

  api_response =
    URI
      .open("https://www.goodreads.com/review/list/#{goodreads_id}.xml?key=#{goodreads_key}&v=2&page=1&per_page=200&sort=date_read&order=d&shelf=read")

  IO.copy_stream(api_response, 'goodreads.xml')
end

file 'goodreads.csv' => ['goodreads.xml'] do
  goodreads_year = ENV.fetch('GOODREADS_YEAR', Time.now.year.pred)

  CSV.open('goodreads.csv', 'wb') do |csv|
    csv << ['Title', 'Author', 'Started', 'Finished', 'Word count']

    Oga
      .parse_xml(open('goodreads.xml'))
      .css('GoodreadsResponse reviews review')
      .map(&WordCount.method(:review_to_row))
      .select { |r| r.last&.start_with?('2020-') }
      .map(&WordCount.method(:append_word_count))
      .each { |r| csv << r }
  end
end