require 'cgi'
require 'csv'
require 'date'
require 'json'
require 'oga'
require 'open-uri'

module WordCount
  SEARCH_BASE = 'https://www.kobo.com/gb/en/search?fcmedia=Book&query='
  BOOK_BASE = 'https://kobostats.azurewebsites.net/bookstats/'

  class << self
    def review_to_row(review)
      ['book title_without_series', 'book authors author name', 'started_at', 'read_at'].map.with_index do |selector|
        val = review.css(selector).text

        val && val.length > 0 && selector.end_with?('_at') ? Date.parse(val).to_s : val
      end
    end

    def append_word_count(row)
      title, author, started, finished = row
      search_result =
        Oga
          .parse_html(URI.open("#{SEARCH_BASE}#{CGI.escape(title)}+#{CGI.escape(author)}"))
          .css('.item-detail')
          .first

      search_title = search_result.css('.title.product-field a').text

      unless search_title.downcase.include?(title.downcase)
        p [search_title, title]
        return [title, author, started, finished]
      end

      isbn = JSON.parse(search_result.css('script').text).dig('data', 'isbn')
      word_count = JSON.parse(URI.open("#{BOOK_BASE}#{isbn}").read)['WordCount'].to_i

      [title, author, started, finished, word_count]
    rescue => e
      binding.irb
    end
  end
end
