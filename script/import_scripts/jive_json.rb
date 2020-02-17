# frozen_string_literal: true

require_relative 'base.rb'
require 'csv'

class ImportScripts::JiveJson < ImportScripts::Base
  JSON_FILE = '/home/ajalan/projects/freertos/data.json'
  USER_FILE = '/home/ajalan/projects/freertos/user_data.json'

  def initialize
    super

    puts "loading post mappings..."
    @post_number_map = {}
    Post.pluck(:id, :post_number).each do |post_id, post_number|
      @post_number_map[post_id] = post_number
    end
  end

  def created_post(post)
    @post_number_map[post.id] = post.post_number
    super
  end

  def execute
    puts '', 'Importing from SourceForge...'

    import_topics
    mark_topics_as_solved
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

  def import_topics
    puts '', 'importing posts'

    posts = JSON.parse(repair_json(File.read(JSON_FILE)))
    imported_post_count = 0
    total_post_count = posts.count

    discobot_user_id = ::DiscourseNarrativeBot::Base.new.discobot_user.id

    create_posts(posts, total: total_post_count, offset: imported_post_count) do |post|
      # puts post.inspect
      # exit
      post_id = "jive-postid-#{post['messageid']}"
      first_post_id = "jive-postid-#{post['rootmessageid']}"

      mapped = {
        id: post_id,
        user_id: Discourse::SYSTEM_USER_ID,
        created_at: parse_datetime(post['messagecreationdate']),
        raw: normalize_raw!(post)
      }

      if post_id == first_post_id
        mapped[:category] = 35
        mapped[:title] = post['subject'][0...255]
      else
        imported_topic = @lookup.topic_lookup_from_imported_post_id(first_post_id)

        if imported_topic.nil?
          # skip
          puts "Topic not found with ID #{first_post_id}"
          next
        end

        mapped[:topic_id] = imported_topic[:topic_id]
        mapped[:custom_fields] = { is_accepted_answer: true, is_accepted_answer_from_import: true } if post['correctanswer'] == 1

        reply_to_post_id = post_id_from_imported_post_id(post[:parentmessageid])
        if reply_to_post_id
          reply_to_post_number = @post_number_map[reply_to_post_id]
          if reply_to_post_number && reply_to_post_number > 1
            mapped[:reply_to_post_number] = reply_to_post_number
          end
        end

        mapped[:post_create_action] = proc do |p|
          if post['helpfulanswer'] == 1
            user = User.new
            user.id = discobot_user_id
            PostActionCreator.like(user, p)
          end
        end
      end

      # puts mapped.inspect
      # exit

      imported_post_count += 1
      mapped
    end

  end

  def normalize_raw!(post)
    # puts post.inspect
    raw = post["body"]
    return "<missing>" if raw.blank?
    raw = raw.dup

    # new line
    raw.gsub!(/\\n/, "\n")

    # code block
    raw.gsub!(/\{code\}/, "\n```\n")

    # fix quotes
    raw.gsub!(/(^>.+\n)(?!^>)/, "#{$1}\n")
    raw.gsub!(/> {quote:title=(.+?) wrote:},{quote}/i) { "> **#{$1}** wrote:" }

    username = post['username']
    user_link = "[#{username}](https://forums.aws.amazon.com/profile.jspa?userID=#{post['userid']})"
    post_date = Time.zone.parse(post['messagecreationdate']).strftime('%B %d, %Y')

    raw = "**#{user_link}** wrote on #{post_date}:\n\n#{raw}"

    # puts raw
    # exit
    # raw = CGI.unescapeHTML(raw)
    # raw = ReverseMarkdown.convert(raw)
    raw
  end

  def parse_datetime(text)
    return nil if text.blank? || text == "null"
    DateTime.parse(text)
  end

  def mark_topics_as_solved
    puts "", "Marking topics as solved..."

    DB.exec <<~SQL
      INSERT INTO topic_custom_fields (name, value, topic_id, created_at, updated_at)
      SELECT 'accepted_answer_post_id', pcf.post_id, p.topic_id, p.created_at, p.created_at
        FROM post_custom_fields pcf
        JOIN posts p ON p.id = pcf.post_id
       WHERE pcf.name = 'is_accepted_answer_from_import'
    SQL
  end
end

ImportScripts::JiveJson.new.perform

# bundle exec ruby script/import_scripts/jive_json.rb

# rootmessageid: topic id
# messageid: post id
# parentmessageid: reply_to_post id

# threadid: category_id

# jq '. |= sort_by(.messageid)' export.json > data.json

# jq 'map(del(.threadid, .rootmessageid, .messageid, .parentmessageid, .subject, .body, .helpfulanswer, .correctanswer, .threadcreationdate, .threadmodificationDate, .messagecreationdate, .messagemodificationDate))' data.json > users.json
# jq 'unique_by(.username)' users.json > user_data.json


# CSV mans
# ruby csv_sort.rb

# https://forums.aws.amazon.com/forum.jspa?forumID=276&start=0
# https://api.discourse.org/admin/hosted_sites/8711
