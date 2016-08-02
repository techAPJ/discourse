require "mysql2"
require File.expand_path(File.dirname(__FILE__) + "/base.rb")

class ImportScripts::Drupal < ImportScripts::Base

  DRUPAL_DB = ENV['DRUPAL_DB'] || "wealthforums"
  VID = ENV['DRUPAL_VID'] || 26
  BATCH_SIZE = 2000

  def initialize
    super

    @client = Mysql2::Client.new(
      host: "localhost",
      username: "root",
      #password: "password",
      database: DRUPAL_DB
    )
  end

  def categories_query
    @client.query("SELECT tid, name, description FROM term_data WHERE vid = #{VID}")
  end

  def execute
    import_users

    # You'll need to edit the following query for your Drupal install:
    #
    #   * Drupal allows duplicate category names, so you may need to exclude some categories or rename them here.
    #   * Table name may be term_data.
    #   * May need to select a vid other than 1.
    create_categories(categories_query) do |c|
      {id: c['tid'], name: c['name'], description: c['description']}
    end

    # "Nodes" in Drupal are divided into types. Here we import two types,
    # and will later import all the comments/replies for each node.
    # You will need to figure out what the type names are on your install and edit the queries to match.
    if ENV['DRUPAL_IMPORT_BLOG']
      # create_blog_topics
    end

    create_forum_topics

    create_replies
  end

  def import_users

    # create_users(@client.query("SELECT uid id, name, mail email, created FROM users;")) do |row|
    #   {id: row['id'], username: row['name'], email: row['email'], created_at: Time.zone.at(row['created'])}
    # end

    puts '', "creating users"

    total_count = @client.query("SELECT count(*) count FROM users;").first['count']

    batches(BATCH_SIZE) do |offset|
      results = @client.query(
        "SELECT uid id, name, mail email, created
         FROM users
         LIMIT #{BATCH_SIZE}
         OFFSET #{offset};", cache_rows: false)

      break if results.size < 1

      next if all_records_exist? :users, results.map {|u| u["id"].to_i}

      create_users(results, total: total_count, offset: offset) do |user|
        { id: user['id'],
          email: user['email'],
          username: user['name'],
          created_at: Time.zone.at(user['created']) }
      end
    end

  end

  def create_blog_topics
    puts '', "creating blog topics"

    create_category({
      name: 'Blog',
      user_id: -1,
      description: "Articles from the blog"
    }, nil) unless Category.find_by_name('Blog')

    results = @client.query("
      SELECT n.nid nid, n.title title, n.uid uid, n.created created, n.sticky sticky,
             f.body_value body
        FROM node n,
             field_data_body f
       WHERE n.type = 'blog'
         AND n.nid = f.entity_id
         AND n.status = 1
    ", cache_rows: false)

    create_posts(results) do |row|
      {
        id: "nid:#{row['nid']}",
        user_id: user_id_from_imported_user_id(row['uid']) || -1,
        category: 'Blog',
        raw: row['body'],
        created_at: Time.zone.at(row['created']),
        pinned_at: row['sticky'].to_i == 1 ? Time.zone.at(row['created']) : nil,
        title: row['title'].try(:strip),
        custom_fields: {import_id: "nid:#{row['nid']}"}
      }
    end
  end

  def create_forum_topics
    puts '', "creating forum topics"

    total_count = @client.query("
        SELECT COUNT(*) count
          FROM node n
         WHERE n.type = 'forum'
           AND n.status = 1;").first['count']

    batch_size = 1000

    batches(batch_size) do |offset|
      results = @client.query("
        SELECT n.nid nid,
               n.title title,
               n.uid uid,
               n.created created,
               n.sticky sticky,
               nr.body body,
               f.tid tid
          FROM node n,
               node_revisions nr,
               forum f
         WHERE n.type = 'forum'
           AND n.nid = nr.nid
           AND n.vid = nr.vid
           AND n.nid = f.nid
           AND n.vid = f.vid
           AND n.status = 1
         LIMIT #{batch_size}
        OFFSET #{offset};
      ", cache_rows: false)

      break if results.size < 1

      next if all_records_exist? :posts, results.map {|p| "nid:#{p['nid']}"}

      create_posts(results, total: total_count, offset: offset) do |row|
        {
          id: "nid:#{row['nid']}",
          user_id: user_id_from_imported_user_id(row['uid']) || -1,
          category: category_id_from_imported_category_id(row['tid']),
          raw: row['body'],
          created_at: Time.zone.at(row['created']),
          pinned_at: row['sticky'].to_i == 1 ? Time.zone.at(row['created']) : nil,
          title: row['title'].try(:strip)
        }
      end
    end
  end

  def create_replies
    puts '', "creating replies in topics"

    total_count = @client.query("
        SELECT COUNT(*) count
          FROM comments c,
               node n
         WHERE n.nid = c.nid
           AND c.status = 0
           AND n.type = 'forum'
           AND n.status = 1;").first['count']

    batch_size = 1000

    batches(batch_size) do |offset|
      results = @client.query("
        SELECT c.cid, c.pid, c.nid, c.uid,
               c.timestamp created, c.comment body
          FROM comments c,
               node n
         WHERE n.nid = c.nid
           AND c.status = 0
           AND n.type = 'forum'
           AND n.status = 1
         LIMIT #{batch_size}
        OFFSET #{offset};
      ", cache_rows: false)

      break if results.size < 1

      next if all_records_exist? :posts, results.map {|p| "cid:#{p['cid']}"}

      create_posts(results, total: total_count, offset: offset) do |row|
        topic_mapping = topic_lookup_from_imported_post_id("nid:#{row['nid']}")
        if topic_mapping && topic_id = topic_mapping[:topic_id]
          h = {
            id: "cid:#{row['cid']}",
            topic_id: topic_id,
            user_id: user_id_from_imported_user_id(row['uid']) || -1,
            raw: row['body'],
            created_at: Time.zone.at(row['created']),
          }
          if row['pid']
            parent = topic_lookup_from_imported_post_id("cid:#{row['pid']}")
            h[:reply_to_post_number] = parent[:post_number] if parent and parent[:post_number] > 1
          end
          h
        else
          puts "No topic found for comment #{row['cid']}"
          nil
        end
      end
    end
  end

end

if __FILE__==$0
  ImportScripts::Drupal.new.perform
end


# AND n.type IN ('blog', 'forum')
