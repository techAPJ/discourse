# bespoke importer for a customer, feel free to borrow ideas

require 'csv'
require File.expand_path(File.dirname(__FILE__) + "/base.rb")

# Call it like this:
#   RAILS_ENV=production bundle exec ruby script/import_scripts/bespoke_1.rb
class ImportScripts::Custom < ImportScripts::Base

  BATCH_SIZE = 1000

  def initialize
    @path = "/Users/techapj/Downloads/Forum_Data"
    super()
    @bbcode_to_md = true

    puts "loading post mappings..."
    @post_number_map = {}
    Post.pluck(:id, :post_number).each do |post_id, post_number|
      @post_number_map[post_id] = post_number
    end
  end

  def execute
    import_users
    import_categories
    import_posts

  end

  def csv_parse(name)
    filename = "#{@path}/#{name}.csv"
    rows = []

    CSV.foreach(filename, "r:ISO-8859-1") do |row|
      rows.push(row)
    end

    rows
  end

  def total_rows(table)
    File.foreach("#{@path}/#{table}.csv").inject(0) {|c, line| c+1} - 1
  end

  def import_users
    puts "", "creating users"
    total_count = total_rows("users")

    create_users(csv_parse("users"), total: total_count) do |user|
      { id: user[0],
        email: user[2],
        username: user[1].split("@")[0],
        name: "#{user[3]} #{user[5]}" }
    end

  end

  def import_categories
    puts "", "creating categories"

    create_categories(csv_parse("Forum_Data_Category")) do |category|
      {
        id: category[0],
        name: category[2],
        description: category[3],
      }
    end
  end

  def normalize_raw!(raw)
    raw = raw.dup

    # hoist code
    hoisted = {}
    raw.gsub!(/(<pre>\s*)?<code>(.*?)<\/code>(\s*<\/pre>)?/mi) do
      code = $2
      hoist = SecureRandom.hex
      # tidy code, wow, this is impressively crazy
      code.gsub!(/  (\s*)/,"\n\\1")
      code.gsub!(/^\s*\n$/, "\n")
      code.gsub!(/\n+/m, "\n")
      code.strip!
      hoisted[hoist] = code
      hoist
    end

    # impressive seems to be using tripple space as a <p> unless hoisted
    # in this case double space works best ... so odd
    raw.gsub!("   ", "\n\n")

    hoisted.each do |hoist, code|
      raw.gsub!(hoist, "\n```\n" << code << "\n```\n")
    end

    raw
  end

  def import_post_batch!(posts, topics, total)
    create_posts(posts, total: total) do |post|

      mapped = {}

      mapped[:id] = post[:id]
      mapped[:user_id] = user_id_from_imported_user_id(post[:user_id]) || -1
      mapped[:raw] = post[:body]
      mapped[:created_at] = post[:created_at]

      topic = topics[post[:topic_id]]

      unless topic
        p "MISSING TOPIC #{post[:topic_id]}"
        next
      end


      unless topic[:post_id]
        mapped[:title] = topic[:title] || "Topic title missing"
        topic[:post_id] = post[:id]
        mapped[:category] = category_id_from_imported_category_id(topic[:category_id])
      else
        parent = topic_lookup_from_imported_post_id(topic[:post_id])
        next unless parent

        mapped[:topic_id] = parent[:topic_id]
      end

      next if topic[:deleted] or post[:deleted]

      mapped
    end

    posts.clear
  end

  def import_posts
    puts "", "creating topics and posts"
    topic_map = {}

    csv_parse("topics").each do |topic|

      # unless topic[3]
      #   puts "NO USER FOR THREAD"
      #   next
      # end

      topic_map[topic[0]] = {
        id: topic[0],
        category_id: topic[2],
        title: topic[5],
        deleted: topic[7] == "N",
        user_id: topic[3] || -1
      }
    end

    total = total_rows("posts")
    posts = []

    csv_parse("posts").each do |row|

      # unless row[2]
      #   puts "NO USER FOR THREAD"
      #   next
      # end

      row = {
        id: row[0],
        topic_id: row[1],
        user_id: row[2] || -1,
        body: normalize_raw!(row[4]),
        deleted: row[5] == "N",
        created_at: DateTime.parse(row[11])
      }
      posts << row
    end

    import_post_batch!(posts, topic_map, total) if posts.length > 0
  end


end

ImportScripts::Custom.new.perform
