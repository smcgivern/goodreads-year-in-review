require 'csv'
require 'gruff'

class Stats
  attr_reader :rows

  def initialize(path = 'output/goodreads-filled.csv')
    @rows = CSV.read(path, headers: true)
  end

  def basic
    <<~BASIC
    Total words / books: #{thousands(total)} / #{thousands(rows.count)}
    Mean / median: #{thousands(mean.round)} / #{thousands(median.round)}

    Shortest: #{description(sorted.first)}
    Longest five:
    - #{sorted[-5..-1].reverse.map(&method(:description)).join("\n- ")}

    Non cis male words / books: #{thousands(filter('Cis male author', 'N').sum(&method(:word_count)))} / #{thousands(filter('Cis male author', 'N').count)}
    Translated words / books: #{thousands(filter('Translation', 'Y').sum(&method(:word_count)))} / #{thousands(filter('Translation', 'Y').count)}

    Fastest: #{description(speed.last, with_dates: true)}
    Slowest: #{description(speed.first, with_dates: true)}
    BASIC
  end

  def chart(output_file = 'output/chart.png')
    g = Gruff::Line.new
    g.theme_greyscale
    g.title = 'Words read per day'
    g.dataxy('', by_day.keys.map(&:yday), by_day.values)

    g.labels = by_day.keys.map.with_index do |day, i|
      next unless day.mday == 1

      [i, day.strftime('%b')]
    end.compact.to_h

    g.to_image.resize(1600, 1200).write(output_file)
  end

  private

  def by_day
    @by_day = extent.to_h { |d| [d, reading_days.fetch(d, 0)] }
  end

  def extent
    @extent ||=
      begin
        year = Date.parse(rows.first['Finished']).year

        Date.new(year).step(Date.new(year, -1, -1))
      end
  end

  def reading_days
    @reading_days ||=
      rows.each_with_object({}) do |row, accumulator|
        Date.parse(row['Started']).step(Date.parse(row['Finished'])).each do |day|
          accumulator[day] ||= 0
          accumulator[day] += words_per_day(row)
        end
      end
  end

  def filter(column, value)
    rows.select { |x| x[column] == value }
  end

  def total
    @total ||= rows.sum(&method(:word_count))
  end

  def mean
    total.to_f / rows.count
  end

  def sorted
    @sorted ||= rows.sort_by(&method(:word_count))
  end

  def speed
    @speed ||= rows.sort_by(&method(:words_per_day))
  end

  def median
    sorted_counts = sorted.map(&method(:word_count))
    mid = (sorted_counts.length - 1) / 2.0

    (sorted_counts[mid.floor] + sorted_counts[mid.ceil]) / 2.0
  end

  def word_count(row)
    row['Word count'].to_i
  end

  def words_per_day(row)
    @words_per_day ||= {}
    @words_per_day[row] ||=
      word_count(row).to_f / (Date.parse(row['Finished']) - Date.parse(row['Started']) + 1)
  end

  def thousands(n)
    n.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1,")
  end

  def description(row, with_dates: false)
    "#{thousands(word_count(row))} - #{row['Title']} (#{row['Author']})".tap do |s|
      next s unless with_dates

      s + " - #{row['started']} - #{row['finished']}"
    end
  end
end
