desc 'Update each post with latest markdown'
task 'posts:rebake' => :environment do
  ENV['RAILS_DB'] ? rebake_posts : rebake_posts_all_sites
end

desc 'Update each post with latest markdown and refresh oneboxes'
task 'posts:refresh_oneboxes' => :environment do
  ENV['RAILS_DB'] ? rebake_posts(invalidate_oneboxes: true) : rebake_posts_all_sites(invalidate_oneboxes: true)
end

desc 'Rebake all posts with a quote using a letter_avatar'
task 'posts:fix_letter_avatars' => :environment do
  return unless SiteSetting.external_system_avatars_enabled

  search = Post.where("user_id <> -1")
               .where("raw LIKE '%/letter\_avatar/%' OR cooked LIKE '%/letter\_avatar/%'")

  rebaked = 0
  total = search.count

  search.order(updated_at: :asc).find_each do |post|
    rebake_post(post)
    print_status(rebaked += 1, total)
  end

  puts "", "#{rebaked} posts done!", ""
end

desc 'Remap all posts'
task 'posts:remap' => :environment do
  require 'import/image_me'

  puts "Remapping"
  i = 0
  Post.where("raw LIKE '%/wp-content/%'").each do |p|
    new_raw_post = Import::ImageMe.get_raw_post(p.raw)

    if new_raw_post != p.raw
      p.revise(Discourse.system_user, { raw: new_raw_post }, { bypass_bump: true })
      putc "."
      i += 1
    end
  end
  puts
  puts "#{i} posts normalized!"
end

desc 'Get Attachments from all posts'
task 'posts:attachments' => :environment do
  require 'import/image_me'

  puts "Remapping"
  i = 0
  post_ids = []

  Post.where("raw LIKE '%/wp-content/%'").each do |p|
    new_raw_post = Import::ImageMe.has_attachment(p.raw)
    if new_raw_post
      post_ids << p.id
      putc "."
      i += 1
    end
  end

  CSV.open(File.expand_path("../posts.csv", __FILE__), "w") do |csv|
    csv << post_ids
  end

  puts
  puts "#{i} posts normalized!"
end

desc 'Revert all posts'
task 'posts:revert' => :environment do

  puts "Reverting"
  i = 0

  CSV.foreach(File.expand_path("../posts.csv", __FILE__), { :col_sep => ',' }) do |post_id|
    # puts post_id

    post_revision = PostRevision.find_by(post_id: post_id, number: 2)

    if post_revision
      post = Post.where(id: post_id).first

      post_revision.post = post

      topic = Topic.with_deleted.find(post.topic_id)

      changes = {}
      changes[:raw] = post_revision.modifications["raw"][0] if post_revision.modifications["raw"].present? && post_revision.modifications["raw"][0] != post.raw

      if changes.length > 0
        changes[:edit_reason] = "reverted to version ##{post_revision.number.to_i - 1}"

        revisor = PostRevisor.new(post, topic)
        # revisor.revise!(Discourse.system_user, changes, { bypass_bump: true })
        revisor.revise!(Discourse.system_user, changes)
        putc "."
        i += 1
      else
        puts "error in reverting post #{post_id}"
      end
    end
  end

  puts
  puts "#{i} posts normalized!"
end

def rebake_posts_all_sites(opts = {})
  RailsMultisite::ConnectionManagement.each_connection do |db|
    rebake_posts(opts)
  end
end

def rebake_posts(opts = {})
  puts "Rebaking post markdown for '#{RailsMultisite::ConnectionManagement.current_db}'"

  disable_edit_notifications = SiteSetting.disable_edit_notifications
  SiteSetting.disable_edit_notifications = true

  total = Post.count
  rebaked = 0

  Post.order(updated_at: :asc).find_each do |post|
    rebake_post(post, opts)
    print_status(rebaked += 1, total)
  end

  SiteSetting.disable_edit_notifications = disable_edit_notifications

  puts "", "#{rebaked} posts done!", "-" * 50
end

def rebake_post(post, opts = {})
  post.rebake!(opts)
rescue => e
  puts "", "Failed to rebake (topic_id: #{post.topic_id}, post_id: #{post.id})", e, e.backtrace.join("\n")
end

def print_status(current, max)
  print "\r%9d / %d (%5.1f%%)" % [current, max, ((current.to_f / max.to_f) * 100).round(1)]
end

desc 'normalize all markdown so <pre><code> is not used and instead backticks'
task 'posts:normalize_code' => :environment do
  lang = ENV['CODE_LANG'] || ''
  require 'import/normalize'

  puts "Normalizing"
  i = 0
  Post.where("raw like '%<pre>%<code>%'").each do |p|
    normalized = Import::Normalize.normalize_code_blocks(p.raw, lang)
    if normalized != p.raw
      p.revise(Discourse.system_user, { raw: normalized })
      putc "."
      i += 1
    end
  end

  puts
  puts "#{i} posts normalized!"
end
