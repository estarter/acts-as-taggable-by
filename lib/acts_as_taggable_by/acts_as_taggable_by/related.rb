module ActsAsTaggableBy::Taggable
  module Related
    def self.included(base)
      base.send :include, ActsAsTaggableBy::Taggable::Related::InstanceMethods
      base.extend ActsAsTaggableBy::Taggable::Related::ClassMethods
      base.initialize_acts_as_taggable_by_related
    end
    
    module ClassMethods
      def initialize_acts_as_taggable_by_related
        tag_types.map(&:to_s).each do |tag_type|
          class_eval %(
            def find_related_#{tag_type}(options = {})
              related_tags_for('#{tag_type}', self.class, options)
            end
            alias_method :find_related_on_#{tag_type}, :find_related_#{tag_type}

            def find_related_#{tag_type}_for(klass, options = {})
              related_tags_for('#{tag_type}', klass, options)
            end

            def find_matching_contexts(search_context, result_context, options = {})
              matching_contexts_for(search_context.to_s, result_context.to_s, self.class, options)
            end

            def find_matching_contexts_for(klass, search_context, result_context, options = {})
              matching_contexts_for(search_context.to_s, result_context.to_s, klass, options)
            end
          )
        end        
      end
      
      def acts_as_taggable_by(*args)
        super(*args)
        initialize_acts_as_taggable_by_related
      end
    end
    
    module InstanceMethods
      def matching_contexts_for(search_context, result_context, klass, options = {})
        tags_to_find = tags_on(search_context).collect { |t| t.name }

        exclude_self = "#{klass.table_name}.id != #{id} AND" if self.class == klass
        
        klass.scoped({ :select     => "#{klass.table_name}.*, COUNT(#{ActsAsTaggableBy::Tag.table_name}.id) AS count",
                       :from       => "#{klass.table_name}, #{ActsAsTaggableBy::Tag.table_name}, #{ActsAsTaggableBy::Tagging.table_name}",
                       :conditions => ["#{exclude_self} #{klass.table_name}.id = #{ActsAsTaggableBy::Tagging.table_name}.taggable_id AND #{ActsAsTaggableBy::Tagging.table_name}.taggable_type = '#{klass.to_s}' AND #{ActsAsTaggableBy::Tagging.table_name}.tag_id = #{ActsAsTaggableBy::Tag.table_name}.id AND #{ActsAsTaggableBy::Tag.table_name}.name IN (?) AND #{ActsAsTaggableBy::Tag.table_name}.context = ?", tags_to_find, result_context],
                       :group      => grouped_column_names_for(klass),
                       :order      => "count DESC" }.update(options))
      end
      
      def related_tags_for(context, klass, options = {})
        tags_to_find = tags_on(context).collect { |t| t.name }

        exclude_self = "#{klass.table_name}.id != #{id} AND" if self.class == klass

        klass.scoped({ :select     => "#{klass.table_name}.*, COUNT(#{ActsAsTaggableBy::Tag.table_name}.id) AS count",
                       :from       => "#{klass.table_name}, #{ActsAsTaggableBy::Tag.table_name}, #{ActsAsTaggableBy::Tagging.table_name}",
                       :conditions => ["#{exclude_self} #{klass.table_name}.id = #{ActsAsTaggableBy::Tagging.table_name}.taggable_id AND #{ActsAsTaggableBy::Tagging.table_name}.taggable_type = '#{klass.to_s}' AND #{ActsAsTaggableBy::Tagging.table_name}.tag_id = #{ActsAsTaggableBy::Tag.table_name}.id AND #{ActsAsTaggableBy::Tag.table_name}.name IN (?)", tags_to_find],
                       :group      => grouped_column_names_for(klass),
                       :order      => "count DESC" }.update(options))
      end
    end
  end
end