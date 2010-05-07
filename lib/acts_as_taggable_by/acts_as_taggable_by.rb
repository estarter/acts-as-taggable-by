module ActsAsTaggableBy
  module Taggable
    def taggable?
      false
    end

    ##
    # This is an alias for calling <tt>acts_as_taggable_by :tags</tt>.
    #
    # Example:
    #   class Book < ActiveRecord::Base
    #     acts_as_taggable
    #   end
    def acts_as_taggable
      acts_as_taggable_by :tags
    end

    ##
    # Make a model taggable on specified contexts.
    #
    # @param [Array] tag_types An array of taggable contexts
    #
    # Example:
    #   class User < ActiveRecord::Base
    #     acts_as_taggable_by :languages, :skills
    #   end
    def acts_as_taggable_by(*tag_types)
      tag_types = tag_types.to_a.flatten.compact.map(&:to_sym)

      if taggable?
        write_inheritable_attribute(:tag_types, (self.tag_types + tag_types).uniq)
      else
        write_inheritable_attribute(:tag_types, tag_types)
        class_inheritable_reader(:tag_types)
        
        class_eval do
          has_many :taggings, :as => :taggable, :dependent => :destroy, :include => :tag, :class_name => "ActsAsTaggableBy::Tagging"
          has_many :base_tags, :through => :taggings, :source => :tag, :class_name => "ActsAsTaggableBy::Tag"

          def self.taggable?
            true
          end
        
          include ActsAsTaggableBy::Taggable::Core
          include ActsAsTaggableBy::Taggable::Collection
          include ActsAsTaggableBy::Taggable::Cache
          include ActsAsTaggableBy::Taggable::Ownership
          include ActsAsTaggableBy::Taggable::Related
        end
      end
    end
  end
end
