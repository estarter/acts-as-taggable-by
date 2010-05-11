module ActsAsTaggableBy::Taggable
  module Core
    def self.included(base)
      base.send :include, ActsAsTaggableBy::Taggable::Core::InstanceMethods
      base.extend ActsAsTaggableBy::Taggable::Core::ClassMethods

      base.class_eval do
        attr_writer :custom_contexts
        after_save :save_tags
      end
      
      base.initialize_acts_as_taggable_by_core
    end
    
    module ClassMethods
      def initialize_acts_as_taggable_by_core
        tag_types.map(&:to_s).each do |tags_type|
          tag_type         = tags_type.to_s.singularize
          context_taggings = "#{tag_type}_taggings".to_sym
          context_tags     = tags_type.to_sym

          class_eval do
            has_many context_taggings, :as => :taggable, :dependent => :destroy, :include => :tag, :class_name => "ActsAsTaggableBy::Tagging",
                     :conditions => ["#{ActsAsTaggableBy::Tag.table_name}.tagger_id IS NULL AND #{ActsAsTaggableBy::Tag.table_name}.context = ?", tags_type]
            has_many context_tags, :through => context_taggings, :source => :tag, :class_name => "ActsAsTaggableBy::Tag"
          end

          class_eval %(
            def #{tag_type}_list
              tag_list_on('#{tags_type}')
            end

            def #{tag_type}_list=(new_tags)
              set_tag_list_on('#{tags_type}', new_tags)
            end

            def all_#{tags_type}_list
              all_tags_list_on('#{tags_type}')
            end
          )
        end        
      end
      
      def acts_as_taggable_by(*args)
        super(*args)
        initialize_acts_as_taggable_by_core
      end
      
      # all column names are necessary for PostgreSQL group clause
      def grouped_column_names_for(object)
        object.column_names.map { |column| "#{object.table_name}.#{column}" }.join(", ")
      end

      ##
      # Return a scope of objects that are tagged with the specified tags.
      #
      # @param tags The tags that we want to query for
      # @param [Hash] options A hash of options to alter you query:
      #                       * <tt>:exclude</tt> - if set to true, return objects that are *NOT* tagged with the specified tags
      #                       * <tt>:any</tt> - if set to true, return objects that are tagged with *ANY* of the specified tags
      #                       * <tt>:match_all</tt> - if set to true, return objects that are *ONLY* tagged with the specified tags
      #
      # Example:
      #   User.tagged_with("awesome", "cool")                     # Users that are tagged with awesome and cool
      #   User.tagged_with("awesome", "cool", :exclude => true)   # Users that are not tagged with awesome or cool
      #   User.tagged_with("awesome", "cool", :any => true)       # Users that are tagged with awesome or cool
      #   User.tagged_with("awesome", "cool", :match_all => true) # Users that are tagged with just awesome and cool
      def tagged_with(tags, options = {})
        tag_list = ActsAsTaggableBy::TagList.from(tags)

        return {} if tag_list.empty?

        joins = []
        conditions = []

        context = options.delete(:on)

        if options.delete(:exclude)
          tags_conditions = tag_list.map { |t| sanitize_sql(["#{ActsAsTaggableBy::Tag.table_name}.name LIKE ?", t]) }.join(" OR ")
          conditions << "#{table_name}.#{primary_key} NOT IN (SELECT #{ActsAsTaggableBy::Tagging.table_name}.taggable_id FROM #{ActsAsTaggableBy::Tagging.table_name} JOIN #{ActsAsTaggableBy::Tag.table_name} ON #{ActsAsTaggableBy::Tagging.table_name}.tag_id = #{ActsAsTaggableBy::Tag.table_name}.id AND (#{tags_conditions}) WHERE #{ActsAsTaggableBy::Tagging.table_name}.taggable_type = #{quote_value(base_class.name)})"

        elsif options.delete(:any)
          tags_conditions = tag_list.map { |t| sanitize_sql(["#{ActsAsTaggableBy::Tag.table_name}.name LIKE ?", t]) }.join(" OR ")
          conditions << "#{table_name}.#{primary_key} IN (SELECT #{ActsAsTaggableBy::Tagging.table_name}.taggable_id FROM #{ActsAsTaggableBy::Tagging.table_name} JOIN #{ActsAsTaggableBy::Tag.table_name} ON #{ActsAsTaggableBy::Tagging.table_name}.tag_id = #{ActsAsTaggableBy::Tag.table_name}.id AND (#{tags_conditions}) WHERE #{ActsAsTaggableBy::Tagging.table_name}.taggable_type = #{quote_value(base_class.name)})"

        else
          tags = ActsAsTaggableBy::Tag.named_any(tag_list, context, nil)
          return scoped(:conditions => "1 = 0") unless tags.length == tag_list.length

          tags.each do |tag|
            safe_tag = tag.name.gsub(/[^a-zA-Z0-9]/, '')
            prefix   = "#{safe_tag}_#{rand(1024)}"

            taggings_alias = "#{table_name}_taggings_#{prefix}"

            tagging_join  = "JOIN #{ActsAsTaggableBy::Tagging.table_name} #{taggings_alias}" +
                            "  ON #{taggings_alias}.taggable_id = #{table_name}.#{primary_key}" +
                            " AND #{taggings_alias}.taggable_type = #{quote_value(base_class.name)}" +
                            " AND #{taggings_alias}.tag_id = #{tag.id}"

            joins << tagging_join
          end
        end

        taggings_alias, tags_alias = "#{table_name}_taggings_group", "#{table_name}_tags_group"

        if options.delete(:match_all)
          joins << "LEFT OUTER JOIN #{ActsAsTaggableBy::Tagging.table_name} #{taggings_alias}" +
                   "  ON #{taggings_alias}.taggable_id = #{table_name}.#{primary_key}" +
                   " AND #{taggings_alias}.taggable_type = #{quote_value(base_class.name)}"

          group = "#{grouped_column_names_for(self)} HAVING COUNT(#{taggings_alias}.taggable_id) = #{tags.size}"
        end


        scoped(:joins      => joins.join(" "),
               :group      => group,
               :conditions => conditions.join(" AND "),
               :readonly   => false)
      end

      def is_taggable?
        true
      end
    end    
    
    module InstanceMethods
      # all column names are necessary for PostgreSQL group clause
      def grouped_column_names_for(object)
        self.class.grouped_column_names_for(object)
      end

      def custom_contexts
        @custom_contexts ||= []
      end

      def is_taggable?
        self.class.is_taggable?
      end

      def add_custom_context(value)
        custom_contexts << value.to_s unless custom_contexts.include?(value.to_s) or self.class.tag_types.map(&:to_s).include?(value.to_s)
      end

      def cached_tag_list_on(context)
        self["cached_#{context.to_s.singularize}_list"]
      end

      def tag_list_cache_set_on(context)
        variable_name = "@#{context.to_s.singularize}_list"
        !instance_variable_get(variable_name).nil?
      end

      def tag_list_cache_on(context)
        variable_name = "@#{context.to_s.singularize}_list"
        instance_variable_get(variable_name) || instance_variable_set(variable_name, ActsAsTaggableBy::TagList.new(tags_on(context).map(&:name)))
      end

      def tag_list_on(context)
        add_custom_context(context)
        tag_list_cache_on(context)
      end

      def all_tags_list_on(context)
        variable_name = "@all_#{context.to_s.singularize}_list"
        return instance_variable_get(variable_name) if instance_variable_get(variable_name)

        instance_variable_set(variable_name, ActsAsTaggableBy::TagList.new(all_tags_on(context).map(&:name)).freeze)
      end

      ##
      # Returns all tags of a given context
      def all_tags_on(context)
        opts =  ["#{ActsAsTaggableBy::Tag.table_name}.context = ?", context.to_s]
        base_tags.where(opts).order("#{ActsAsTaggableBy::Tagging.table_name}.created_at").group("#{ActsAsTaggableBy::Tagging.table_name}.tag_id").all
      end

      ##
      # Returns all tags that are not owned of a given context
      def tags_on(context)
        base_tags.where(["#{ActsAsTaggableBy::Tag.table_name}.context = ? AND #{ActsAsTaggableBy::Tag.table_name}.tagger_id IS NULL", context.to_s]).all
      end

      def set_tag_list_on(context, new_list)
        add_custom_context(context)

        variable_name = "@#{context.to_s.singularize}_list"
        instance_variable_set(variable_name, ActsAsTaggableBy::TagList.from(new_list))
      end

      def tagging_contexts
        custom_contexts + self.class.tag_types.map(&:to_s)
      end

      def reload(*args)
        self.class.tag_types.each do |context|
          instance_variable_set("@#{context.to_s.singularize}_list", nil)
          instance_variable_set("@all_#{context.to_s.singularize}_list", nil)
        end
      
        super(*args)
      end

      def save_tags
        tagging_contexts.each do |context|
          next unless tag_list_cache_set_on(context)

          tag_list = tag_list_cache_on(context).uniq

          # Find existing tags or create non-existing tags:
          tag_list = ActsAsTaggableBy::Tag.find_or_create_all_with_like_by_name(tag_list, context, nil)

          current_tags = tags_on(context)
          old_tags     = current_tags - tag_list
          new_tags     = tag_list     - current_tags
          
          # Find taggings to remove:
          old_taggings = taggings.where("#{ActsAsTaggableBy::Tag.table_name}.tagger_id" => nil, "#{ActsAsTaggableBy::Tag.table_name}.tagger_type" => nil,
                                        "#{ActsAsTaggableBy::Tag.table_name}.context" => context.to_s, :tag_id => old_tags).all

          if old_taggings.present?
            # Destroy old taggings:
            ActsAsTaggableBy::Tagging.destroy_all :id => old_taggings.map(&:id)
          end

          # Create new taggings:
          new_tags.each do |tag|
            taggings.create!(:tag_id => tag.id, :taggable => self)
          end
        end

        true
      end
    end
  end
end