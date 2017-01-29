desc "Change topic/post ownership of all the topics/posts by a specific user (without creating new revision)"
task "users:change_post_ownership", [:old_username, :new_username, :archetype] => [:environment] do |_,args|
  old_username = args[:old_username]
  new_username = args[:new_username]
  archetype = args[:archetype]
  archetype = archetype.downcase if archetype
  if !old_username || !new_username
    puts "ERROR: Expecting rake posts:change_post_ownership[old_username,new_username,archetype]"
    exit 1
  end
  old_user = User.find_by(username_lower: old_username.downcase)
  if !old_user
    puts "ERROR: User with username #{old_username} does not exist"
    exit 1
  end
  new_user = User.find_by(username_lower: new_username.downcase)
  if !new_user
    puts "ERROR: User with username #{new_username} does not exist"
    exit 1
  end

  if archetype == "private"
    posts = Post.private_posts.where(user_id: old_user.id)
  elsif archetype == "public" || !archetype
    posts = Post.public_posts.where(user_id: old_user.id)
  else
    puts "ERROR: Expecting rake posts:change_post_ownership[old_username,new_username,archetype] where archetype is public or private"
    exit 1
  end

  puts "Changing post ownership"
  i = 0
  posts.each do |p|
    PostOwnerChanger.new(post_ids: [p.id], topic_id: p.topic.id, new_owner: User.find_by(username_lower: new_user.username_lower), acting_user: User.find_by(username_lower: "system"), skip_revision: true).change_owner!
    putc "."
    i += 1
  end
  puts "", "#{i} posts ownership changed!", ""
end

# bundle exec rake users:batch_remap_email['mysite.co','yoursite.co']
# https://meta.discourse.org/t/tried-to-change-domain-caused-my-user-email-to-change-too-what-to-do/56519/9?u=techapj
desc 'Batch remap user email address'
task 'users:batch_remap_email', [:find, :replace] => [:environment] do |_,args|
  require 'highline/import'

  find = args[:find]
  replace = args[:replace]
  if !find || !replace
    puts "ERROR: Expecting rake users:batch_remap_email['find','replace']"
    exit 1
  else
    confirm_replace = ask("Are you sure you want to remap all email addresses matching '#{find}' with '#{replace}'? (Y/n)  ")
    exit 1 unless (confirm_replace == "" || confirm_replace.downcase == 'y')
  end

  puts "Remapping email addresses"
  i = 0
  User.where("email LIKE ?", "%#{find}%").each do |u|
    new_email = u.email.dup
    new_email = new_email.gsub!(/#{Regexp.escape(find)}/, replace) || new_email

    if new_email != u.email
      u.email = new_email
      u.email_tokens.create(email: u.email)
      u.activate
      u.save
      putc "."
      i += 1
    end
  end
  i

  puts "", "#{i} email addresses remapped!", ""
end
