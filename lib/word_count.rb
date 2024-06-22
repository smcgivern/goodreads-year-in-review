require 'cgi'
require 'csv'
require 'date'
require 'json'
require 'oga'
require 'open-uri'
require 'selenium-webdriver'

module WordCount
  SEARCH_BASE = 'https://www.kobo.com/gb/en/search?fcmedia=Book&query='
  BOOK_BASE = 'https://kobostats.azurewebsites.net/bookstats/'

  class << self
    def driver
      @driver ||= Selenium::WebDriver.for(:firefox)
    end

    def review_to_row(review)
      ['book title_without_series', 'book authors author name', 'started_at', 'read_at'].map.with_index do |selector|
        val = review.css(selector).text

        val && val.length > 0 && selector.end_with?('_at') ? Date.parse(val).to_s : val
      end
    end

    def append_word_count(row)
      title, author, started, finished = row
      driver.get("#{SEARCH_BASE}#{CGI.escape(title)}+#{CGI.escape(author)}")
      parsed = Oga.parse_html(driver.page_source)
      search_result = parsed.css('a[data-testid="title"]').first
      search_title = search_result.text

      unless search_title.downcase.include?(title.downcase)
        p [search_title, title]
        return [title, author, started, finished]
      end

      driver.get(search_result.attribute('href'))

      parsed = Oga.parse_html(driver.page_source)
      word_count_text = parsed.css('.stat-desc strong').last&.text&.strip

      if word_count_text&.end_with?('k')
        [title, author, started, finished, word_count_text.to_i * 1000]
      else
        [title, author, started, finished, word_count_text]
      end
    end
  end
end
