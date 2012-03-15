#require "staticizer/version"
require "mechanize"
require "open-uri"
require "fileutils"

module Staticizer

  def self.staticize(base_url, static_path)
    @base_url      = base_url
    @urls_to_crawl = [@base_url]
    @crawled_urls  = []
    @static_assets = []
    @static_path   = static_path

    while !@urls_to_crawl.empty? do
      crawl_url(@urls_to_crawl.pop)
    end
  end

  def self.crawl_url(url)
    return if @crawled_urls.include?(url)
    puts "Crawling #{url}"

    begin
      start = Time.now
      page  = agent.get(url)
    rescue Mechanize::ResponseCodeError => e
      puts "Bad Url: #{url}"
      return
    rescue Timeout::Error => e
      puts "Slow Url: timeout at #{Time.now - start} seconds"
      return
    end

    get_links(page)
    #get_iframes(page)
    get_static_assets(page)

  end

  def self.write_file(url, data)
    local_path = localized_path(url)
    FileUtils.mkdir_p(local_path.gsub(/\/[^\/]*$/, ''))
    File.open(local_path, 'w') { |f| f.puts data }
    puts "Wrote: #{local_path}"
  end

  def self.get_static_assets(page)
    page.image_urls.each do |image|
      next if @static_assets.include?(image)
      @static_assets << image
      write_file(image, open(image).read)
    end
  end

  def self.get_links(page)
    page.links.each do |link|
      if (link =~ /^#{Regexp.escape(@base_url)}/) || (link =~ /^\//)
        next if @urls_to_crawl.include?(link)
        @urls_to_crawl << link
      end
    end
  end

  def self.output_path(url)
    @static_path + localized_path(url)
  end

  def self.localized_path(url)
    url.gsub(/^#{Regexp.escape(@base_url)}/, '')
  end
  
  def self.agent
    @agent ||= Mechanize.new
  end

end

Staticizer.staticize('http://engineyard.com', 'engineyard')
