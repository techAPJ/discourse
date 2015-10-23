require "mysql2"
require File.expand_path(File.dirname(__FILE__) + "/base.rb")

class ImportScripts::Roblox < ImportScripts::Base

  KUNENA_DB    = "roblox"
  BATCH_SIZE = 1000

  def initialize
    super

    @path = "/Users/techapj/Downloads"

    @users = {}

    @client = Mysql2::Client.new(
      host: "localhost",
      username: "root",
      password: "jalan",
      database: KUNENA_DB
    )
  end

  def execute

    import_users

    update_users

    puts "creating categories"

    create_categories(@client.query("SELECT id, parent_id, name, description, ordering FROM rbxdev_kunena_categories ORDER BY parent_id, id;")) do |c|
      h = {id: c['id'], name: c['name'], description: c['description'], position: c['ordering'].to_i}
      if c['parent_id'].to_i > 0
        h[:parent_category_id] = category_id_from_imported_category_id(c['parent_id'])
      end
      h
    end

    import_posts

    begin
      create_admin(email: 'arpit.jalan@discourse.org', username: UserNameSuggester.suggest('arpit_jalan'))
    rescue => e
      puts '', "Failed to create admin user"
      puts e.message
    end
  end

  def csv_parse(name)
    filename = "#{@path}/#{name}.csv"
    rows = []

    CSV.foreach(filename, "r:ISO-8859-1") do |row|
      rows.push(row)
    end

    rows
  end

  def update_users
    puts "", "updating users"

    csv_parse("ROBLOX-Discourse-User").each  do |user|
      if user_record = User.find_by_id(user_id_from_imported_user_id(user[2]))
        if user_record.email.downcase != user[4].downcase
          if existing_user = User.find_by_email(user[4].downcase)
            # user already exist with that email, delete that user first
            # puts "#{user_record.email} => #{user[4]} => #{existing_user.posts.count} \n"
            existing_user.destroy
            user_record.update_column(:email, user[4].downcase)
          else
            user_record.update_column(:email, user[4].downcase)
          end
        end
	    end
    end

  end

  def import_users
    puts '', "creating users"

    total_count = @client.query("SELECT count(*) count FROM rbxdev_users;").first['count']

    batches(BATCH_SIZE) do |offset|
      results = @client.query(
        "SELECT id, username, name, email, registerDate created_at, lastvisitDate last_visit_time
         FROM rbxdev_users
         LIMIT #{BATCH_SIZE}
         OFFSET #{offset};")

      break if results.size < 1

      # next if all_records_exist? :users, users.map {|u| u["id"].to_i}

      create_users(results, total: total_count, offset: offset) do |user|
        { id: user['id'],
          email: user['email'],
          username: user['username'],
          name: user['name'],
          created_at: user['created_at'] == nil ? 0 : Time.zone.at(user['created_at']),
          last_seen_at: user['last_visit_time'] == nil ? 0 : Time.zone.at(user['last_visit_time']) }
      end
    end
  end

  def import_posts
    puts '', "creating topics and posts"

    total_count = @client.query("SELECT COUNT(*) count FROM rbxdev_kunena_messages m;").first['count']

    batch_size = 1000

    batches(batch_size) do |offset|
      results = @client.query("
        SELECT m.id id,
               m.thread thread,
               m.parent parent,
               m.catid catid,
               m.userid userid,
               m.subject subject,
               m.time time,
               t.message message
        FROM rbxdev_kunena_messages m,
             rbxdev_kunena_messages_text t
        WHERE m.id = t.mesid
        ORDER BY m.id
        LIMIT #{batch_size}
        OFFSET #{offset};
      ", cache_rows: false)

      break if results.size < 1

      # next if all_records_exist? :posts, results.map {|p| p['id'].to_i}

      create_posts(results, total: total_count, offset: offset) do |m|
        skip = false
        mapped = {}

        mapped[:id] = m['id']
        mapped[:user_id] = user_id_from_imported_user_id(m['userid']) || -1
        mapped[:raw] = process_post(m['message'])
        mapped[:created_at] = Time.zone.at(m['time'])

        if m['parent'] == 0
          mapped[:category] = category_id_from_imported_category_id(m['catid'])
          mapped[:title] = m['subject']
        else
          parent = topic_lookup_from_imported_post_id(m['parent'])
          if parent
            mapped[:topic_id] = parent[:topic_id]
            mapped[:reply_to_post_number] = parent[:post_number] if parent[:post_number] > 1
          else
            puts "Parent post #{m['parent']} doesn't exist. Skipping #{m["id"]}: #{m["subject"][0..40]}"
            skip = true
          end
        end

        skip ? nil : mapped
      end
    end
  end


  def process_post(raw)
    s = raw.dup

    # :) is encoded as <!-- s:) --><img src="{SMILIES_PATH}/icon_e_smile.gif" alt=":)" title="Smile" /><!-- s:) -->
    s.gsub!(/<!-- s(\S+) -->(?:.*)<!-- s(?:\S+) -->/, '\1')

    # Some links look like this: <!-- m --><a class="postlink" href="http://www.onegameamonth.com">http://www.onegameamonth.com</a><!-- m -->
    s.gsub!(/<!-- \w --><a(?:.+)href="(\S+)"(?:.*)>(.+)<\/a><!-- \w -->/, '[\2](\1)')

    # Many phpbb bbcode tags have a hash attached to them. Examples:
    #   [url=https&#58;//google&#46;com:1qh1i7ky]click here[/url:1qh1i7ky]
    #   [quote=&quot;cybereality&quot;:b0wtlzex]Some text.[/quote:b0wtlzex]
    s.gsub!(/:(?:\w{8})\]/, ']')

    # Remove mybb video tags.
    s.gsub!(/(^\[video=.*?\])|(\[\/video\]$)/, '')

    s = CGI.unescapeHTML(s)

    # phpBB shortens link text like this, which breaks our markdown processing:
    #   [http://answers.yahoo.com/question/index ... 223AAkkPli](http://answers.yahoo.com/question/index?qid=20070920134223AAkkPli)
    #
    # Work around it for now:
    s.gsub!(/\[http(s)?:\/\/(www\.)?/, '[')

    # [IMG size]...[/IMG]
    s.gsub!(/\[img (.*?)\](.+?)\[\/img\]/im) { "\n <img src='#{$2}'> \n" }

    # [QUOTE username]...[/QUOTE]
    s.gsub!(/\[quote (.*?)\](.+?)\[\/quote\]/im) { "[quote] #{$2} [/quote]" }

    # [quote="Andy" post=183]...[/QUOTE]
    s.gsub!(/\[quote="?(.+?)"? post=?(.+?)?\](.+?)\[\/quote\]/im) { "[quote] #{$3} [/quote]" }
    # [quote=Andy post=183]...[/QUOTE]
    s.gsub!(/\[quote=?(.+?)? post=?(.+?)?\](.+?)\[\/quote\]/im) { "[quote] #{$3} [/quote]" }

    # remove attachments
    s.gsub!(/\[attachment[^\]]*\]\d+\[\/attachment\]/im, "")# [ame="youtube_link"]title[/ame]
    s.gsub!(/\[attachment="?(.+?)"?\](.+)\[\/attachment\]/im, "")

    # [URL=...]...[/URL]
    s.gsub!(/\[url="?(.+?)"?\](.+?)\[\/url\]/im) { "[#{$2}](#{$1})" }

    # [spoiler=...]...[/spoiler]
    s.gsub!(/\[spoiler="?(.+?)"?\](.+?)\[\/attachment\]/im, "")
    s.gsub!(/\[spoiler ="?(.+?)"?\](.+?)\[\/spoiler\]/im) { "#{$2}" }

    # [IMG]...[/IMG]
    s.gsub!(/\[img\](.+?)\[\/img\]/im) { "\n <img src='#{$1.strip}'> \n" }

    # convert list tags to ul and list=1 tags to ol
    # (basically, we're only missing list=a here...)
    s.gsub!(/\[list\](.*?)\[\/list:u\]/m, '[ul]\1[/ul]')
    s.gsub!(/\[list=1\](.*?)\[\/list:o\]/m, '[ol]\1[/ol]')
    # convert *-tags to li-tags so bbcode-to-md can do its magic on phpBB's lists:
    s.gsub!(/\[\*\](.*?)\[\/\*:m\]/, '[li]\1[/li]')

    # [YOUTUBE]<id>[/YOUTUBE]
    s.gsub!(/\[youtube\](.+?)\[\/youtube\]/im) { "\nhttps://www.youtube.com/watch?v=#{$1}\n" }

    # [confidential]<id>[/confidential]
    s.gsub!(/\[confidential\](.+?)\[\/confidential\]/im, "")

    # [youtube=425,350]id[/youtube]
    s.gsub!(/\[youtube="?(.+?)"?\](.+)\[\/youtube\]/im) { "\nhttps://www.youtube.com/watch?v=#{$2}\n" }

    # [MEDIA=youtube]id[/MEDIA]
    s.gsub!(/\[MEDIA=youtube\](.+?)\[\/MEDIA\]/im) { "\nhttps://www.youtube.com/watch?v=#{$1}\n" }

    # [ame="youtube_link"]title[/ame]
    s.gsub!(/\[ame="?(.+?)"?\](.+)\[\/ame\]/im) { "\n#{$1}\n" }

    # [VIDEO=youtube;<id>]...[/VIDEO]
    s.gsub!(/\[video=youtube;([^\]]+)\].*?\[\/video\]/im) { "\nhttps://www.youtube.com/watch?v=#{$1}\n" }

    # [video width=425 height=344 type=youtube]qZIOAoEiIzw[/video]
    s.gsub!(/\[video (.*?) type=youtube\](.+?)\[\/video\]/im) { "\nhttps://www.youtube.com/watch?v=#{$2}\n" }

    # [USER=706]@username[/USER]
    s.gsub!(/\[user="?(.+?)"?\](.+)\[\/user\]/im) { $2 }

    # Remove the color tag
    s.gsub!(/\[color=[#a-z0-9]+\]/i, "")
    s.gsub!(/\[\/color\]/i, "")

    s.gsub!(/\[hr\]/i, "<hr>")

    s
  end

end

ImportScripts::Roblox.new.perform


# https://github.com/discourse/discourse/pull/3289/files

# john@roblox.com => john@shedletsky.com => 0
# minecraftedmods@gmail.com => rfugate99@gmail.com => 0
# mrsixsevens@gmail.com => master112233445@gmail.com => 0
# mail.asleum@gmail.com => samuel_bouhadana@yahoo.fr => 0

# SELECT * FROM `rbxdev_kunena_categories` WHERE parent_id=0
# UPDATE rbxdev_kunena_categories SET parent_id=0 WHERE parent_id=1

# UPDATE rbxdev_kunena_categories SET parent_id=11 WHERE id=14
# UPDATE rbxdev_kunena_categories SET parent_id=0 WHERE id=15
# UPDATE rbxdev_kunena_categories SET parent_id=0 WHERE id=16
# UPDATE rbxdev_kunena_categories SET parent_id=0 WHERE id=18

# UPDATE rbxdev_kunena_messages SET catid=4 WHERE catid=18

# UPDATE rbxdev_kunena_categories SET parent_id=0 WHERE id=19

# UPDATE rbxdev_kunena_messages SET catid=13 WHERE catid=28

# UPDATE rbxdev_kunena_messages SET catid=12 WHERE catid=29

# UPDATE rbxdev_kunena_categories SET parent_id=34 WHERE id=30
# UPDATE rbxdev_kunena_categories SET parent_id=11 WHERE id=31



# ISSUES
#

# OFF TOPIC != LOUNGE

# http://roblox.techapj.com/t/ignore-halloween-event-page-box-ad-position-missaligned/19199?u=arpit_jalan
