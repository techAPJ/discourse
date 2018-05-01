task "tags:bulk_tag_category", [:tags, :category] => [:environment] do |_, args|
  tags = args[:tags].split("|")
  category_id = args[:category]

  if !tags || !category_id
    puts "ERROR: Expecting tags:bulk_tag_category[tags,category_id]"
    exit 1
  end

  guardian = Guardian.new(Discourse.system_user)
  category = Category.find(category_id)

  tagged = 0
  total = category.topics.count

  category.topics.find_each do |topic|
    # puts topic.slug
    DiscourseTagging.tag_topic_by_names(topic, guardian, tags)
    print_status(tagged += 1, total)
  end
  # DiscourseTagging.tag_topic_by_names(post.topic, staff_guardian, tag_names)

  puts "", "Done!", ""
end


task "tags:move_category", [:from_category, :to_category] => [:environment] do |_, args|
  from_category_id = args[:from_category]
  to_category_id = args[:to_category]

  if !from_category_id || !to_category_id
    puts "ERROR: Expecting tags:move_category[from_category_id,to_category_id]"
    exit 1
  end

  from_category = Category.find(from_category_id)
  to_category = Category.find(to_category_id)

  if from_category && to_category
    Topic.where(category_id: from_category_id).update_all(category_id: to_category_id)
    from_category.destroy!
  end

  puts "", "Done!", ""
end


task "tags:create_category_definition" => :environment do
  # https://meta.discourse.org/search?q=edit%20category%20description

  puts "Creating category definitions"
  puts

  tagged = 0
  done = 0
  total = category.topics.count
  user = Discourse.system_user

  Category.find_each do |cat|
    if cat.topic_id.blank?
      t = Topic.new(title: I18n.t("category.topic_prefix", category: cat.name), user: user, pinned_at: Time.now, category_id: cat.id)
      t.skip_callbacks = true
      t.ignore_category_auto_close = true
      t.delete_topic_timer(TopicTimer.types[:close])
      t.save!(validate: false)
      cat.update_column(:topic_id, t.id)
      t.posts.create(raw: description || post_template, user: user)

      done += 1
    end
    print_status(tagged += 1, total)
  end

  puts "", "Done!", ""
end


def print_status(current, max)
  print "\r%9d / %d (%5.1f%%)" % [current, max, ((current.to_f / max.to_f) * 100).round(1)]
end

# bundle exec rake tags:bulk_tag_category[tag,tips-tricks-how-tos]