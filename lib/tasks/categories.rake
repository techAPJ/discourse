task "categories:move_topics", [:from_category, :to_category] => [:environment] do |_, args|
  from_category_id = args[:from_category]
  to_category_id = args[:to_category]

  if !from_category_id || !to_category_id
    puts "ERROR: Expecting categories:move_topics[from_category_id,to_category_id]"
    exit 1
  end

  from_category = Category.find(from_category_id)
  to_category = Category.find(to_category_id)

  if from_category.present? && to_category.present?
    puts "Moving topics from #{from_category.slug} to #{to_category.slug}..."
    Topic.where(category_id: from_category.id).update_all(category_id: to_category.id)
    from_category.update_attribute(:topic_count, 0)

    puts "Updating category stats..."
    Category.update_stats
  end

  puts "", "Done!", ""
end

task "categories:recategorize" => [:environment] do
  # bundle exec rake categories:recategorize

  uncategorized = Category.find_by_slug('uncategorized')
  archive = Category.find_by_slug('archive')
  users = Category.find_by_slug('users')
  dev = Category.find_by_slug('dev')

  unless archive.present?
    puts "archive?"
    exit
  end


  puts users.topics.where('last_posted_at > ?', DateTime.parse('2017-01-01 00:00')).count
  puts dev.topics.where('last_posted_at > ?', DateTime.parse('2017-01-01 00:00')).count
  puts users.topics.where('last_posted_at < ?', DateTime.parse('2017-01-01 00:00')).count
  puts dev.topics.where('last_posted_at < ?', DateTime.parse('2017-01-01 00:00')).count

  puts "Moving topics to Uncategorized..."
  Topic.where(category_id: users.id).where('last_posted_at > ?', DateTime.parse('2017-01-01 00:00')).update_all(category_id: uncategorized.id)
  Topic.where(category_id: dev.id).where('last_posted_at > ?', DateTime.parse('2017-01-01 00:00')).update_all(category_id: uncategorized.id)

  puts "Moving topics to Archive..."
  Topic.where(category_id: users.id).update_all(category_id: archive.id)
  Topic.where(category_id: dev.id).update_all(category_id: archive.id)

  users.update_attribute(:topic_count, 0)
  dev.update_attribute(:topic_count, 0)

  puts "Updating category stats..."
  Category.update_stats

  puts uncategorized.topics.count
  puts archive.topics.count

  puts "", "Done!", ""
end

# 772
# 1421

# 3646
# 8113

# 4418
# 9534

# ####

# 776
# 1498

# 3642
# 8036

# 2275
# 11679
