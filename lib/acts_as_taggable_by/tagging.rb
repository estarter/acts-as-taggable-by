module ActsAsTaggableBy
  class Tagging < ::ActiveRecord::Base #:nodoc:
    include ActsAsTaggableBy::ActiveRecord::Backports if ::ActiveRecord::VERSION::MAJOR < 3

    attr_accessible :tag,
                    :tag_id,
                    :taggable,
                    :taggable_type,
                    :taggable_id

    belongs_to :tag, :class_name => 'ActsAsTaggableBy::Tag'
    belongs_to :taggable, :polymorphic => true

    validates_presence_of :tag_id

    validates_uniqueness_of :tag_id, :scope => [ :taggable_type, :taggable_id ]
  end
end