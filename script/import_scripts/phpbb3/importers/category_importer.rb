module ImportScripts::PhpBB3
  class CategoryImporter
    # @param lookup [ImportScripts::LookupContainer]
    # @param text_processor [ImportScripts::PhpBB3::TextProcessor]
    # @param permalink_importer [ImportScripts::PhpBB3::PermalinkImporter]
    def initialize(lookup, text_processor, permalink_importer)
      @lookup = lookup
      @text_processor = text_processor
      @permalink_importer = permalink_importer
    end

    def map_category(row)
      {
        id: row[:forum_id],
        name: get_category_name(row[:forum_name]),
        parent_category_id: @lookup.category_id_from_imported_category_id(row[:parent_id]),
        post_create_action: proc do |category|
          update_category_description(category, row)
          @permalink_importer.create_for_category(category, row[:forum_id])
        end
      }
    end

    protected

    def get_category_name(forum_name)
      if forum_name == "Objective-C Programming: The Big Nerd Ranch Guide (2nd Edition)"
        category_name = "Objective-C Programming (2nd Edition)"
      else
        category_name = forum_name
      end

      return CGI.unescapeHTML(category_name)
    end

    # @param category [Category]
    def update_category_description(category, row)
      return if row[:forum_desc].blank? && row[:first_post_time].blank?

      topic = category.topic
      post = topic.first_post

      if row[:first_post_time].present?
        created_at = Time.zone.at(row[:first_post_time])

        topic.created_at = created_at
        topic.save

        post.created_at = created_at
        post.save
      end

      if row[:forum_desc].present?
        changes = {raw: @text_processor.process_raw_text(row[:forum_desc])}
        opts = {revised_at: post.created_at, bypass_bump: true}
        post.revise(Discourse.system_user, changes, opts)
      end
    end
  end
end
