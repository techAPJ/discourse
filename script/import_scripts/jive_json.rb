# frozen_string_literal: true

require_relative 'base.rb'
require 'csv'

class ImportScripts::JiveJson < ImportScripts::Base
  DATA_FILE = '/home/ajalan/projects/freertos/data.csv'
  USER_FILE = '/home/ajalan/projects/freertos/user_data.json'

  def initialize
    super

    @system_user = Discourse.system_user
  end

  def execute
    puts '', 'Importing from SourceForge...'

    # load_json

    import_users
    import_topics
  end

  def csv_filename(table_name, use_fixed: true)
    @path = '/home/ajalan/projects/freertos'
    if use_fixed
      filename = File.join(@path, "#{table_name}.csv")
      return filename if File.exists?(filename)
    end

    File.join(@path, "#{table_name}.csv")
  end

  def csv_parse(table_name)
    CSV.foreach(csv_filename(table_name),
                headers: true,
                header_converters: :symbol,
                skip_blanks: true,
                encoding: 'bom|utf-8') { |row| yield row }
  end

  def load_json
    @json = MultiJson.load(File.read(JSON_FILE), symbolize_keys: true)
  end

  def repair_json(arg)
    arg.gsub!(/^\(/, "")     # content of file is surround by ( )
    arg.gsub!(/\)$/, "")

    arg.gsub!(/\]\]$/, "]")  # there can be an extra ] at the end

    arg.gsub!(/\}\{/, "},{") # missing commas sometimes!

    arg.gsub!("}]{", "},{")  # surprise square brackets
    arg.gsub!("}[{", "},{")  # :troll:

    arg
  end

  def import_users
    puts '', 'importing users'

    users = JSON.parse(repair_json(File.read(USER_FILE)))
    # {"userid"=>265482, "username"=>"zeni241", "name"=>"Zeni", "namevisible"=>"1", "email"=>"abc357@example.com",
    # "usercreationdate"=>"2013-06-14 03:46:47", "usermodificationDate"=>"2016-06-15 11:44:39"}

    create_users(users) do |user|
      {
        id: "jive-userid-#{user["userid"]}",
        email: user["email"],
        username: user["username"],
        name: user["name"],
        active: false,
        created_at: parse_datetime(user["usercreationdate"])
      }
    end
  end

  def import_topics
    puts '', 'importing posts'

    # posts = JSON.parse(repair_json(File.read(JSON_FILE)))

    posts = []
    csv_parse("data") do |row|
      posts << row.to_h
    end

    imported_post_count = 0
    total_post_count = posts.count

    create_posts(posts, total: total_post_count, offset: imported_post_count) do |post|
      post_id = "jive-postid-#{post[:messageid]}"
      first_post_id = "jive-postid-#{post[:rootmessageid]}"

      mapped = {
        id: post_id,
        user_id: user_id_from_imported_user_id("jive-userid-#{post[:userid]}"),
        created_at: parse_datetime(post[:messagecreationdate]),
        raw: normalize_raw!(post[:body])
      }

      if post_id == first_post_id
        # mapped[:category] = 2
        mapped[:title] = post[:subject][0...255]
      else
        imported_topic = @lookup.topic_lookup_from_imported_post_id(first_post_id)

        if imported_topic.nil?
          # skip
          puts "Topic not found with ID #{first_post_id}"
          next
        end

        mapped[:topic_id] = imported_topic[:topic_id]
      end

      # puts mapped.inspect
      # exit

      imported_post_count += 1
      mapped
    end

  end

  def normalize_raw!(raw)
    return "<missing>" if raw.blank?
    raw = raw.dup

    # new line
    raw.gsub!(/\\n/, "\n")

    # raw = CGI.unescapeHTML(raw)
    # raw = ReverseMarkdown.convert(raw)
    raw
  end

  def parse_datetime(text)
    return nil if text.blank? || text == "null"
    DateTime.parse(text)
  end
end

ImportScripts::JiveJson.new.perform

# bundle exec ruby script/import_scripts/jive_json.rb

# rootmessageid: topic id
# messageid: post id
# parentmessageid: reply_to_post id

# threadid: category_id

# jq '. |= sort_by(.messageid)' export.json > data.json

# jq 'map(del(.threadid, .rootmessageid, .messageid, .parentmessageid, .subject, .body, .helpfulanswer, .correctanswer, .threadcreationdate, .threadmodificationDate, .messagecreationdate, .messagemodificationDate))' user_raw.json > users.json
# jq 'unique_by(.userid)' users.json > user_data.json


# CSV mans
# ruby csv_sort.rb

# https://forums.aws.amazon.com/forum.jspa?forumID=276&start=0
# https://api.discourse.org/admin/hosted_sites/8711
