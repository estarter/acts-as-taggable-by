module ActsAsTaggableBy
  class Tag < ::ActiveRecord::Base
    include ActsAsTaggableBy::ActiveRecord::Backports if ::ActiveRecord::VERSION::MAJOR < 3
  
    attr_accessible :name,
                    :context,
                    :tagger,
                    :tagger_type,
                    :tagger_id

    ### ASSOCIATIONS:

    belongs_to :tagger,   :polymorphic => true
    has_many :taggings, :dependent => :destroy, :class_name => 'ActsAsTaggableBy::Tagging'

    ### VALIDATIONS:

    validates_presence_of :name
    validates_uniqueness_of :name, :scope => [:tagger_id, :tagger_type, :context]
    validates_presence_of :context

    ### SCOPES:

    def self.named(name)
      where(["name LIKE ?", name])
    end
  
    def self.named_any(list)
      where(list.map { |tag| sanitize_sql(["name LIKE ?", tag.to_s]) }.join(" OR "))
    end
  
    def self.named_like(name)
      where(["name LIKE ?", "%#{name}%"])
    end

    def self.named_like_any(list)
      where(list.map { |tag| sanitize_sql(["name LIKE ?", "%#{tag.to_s}%"]) }.join(" OR "))
    end

    ### CLASS METHODS:

    def self.find_or_create_with_like_by_name(name)
      named_like(name).first || create(:name => name)
    end

    def self.find_or_create_all_with_like_by_name(*list)
      list = [list].flatten

      return [] if list.empty?

      existing_tags = Tag.named_any(list).all
      new_tag_names = list.reject { |name| existing_tags.any? { |tag| tag.name.mb_chars.downcase == name.mb_chars.downcase } }
      created_tags  = new_tag_names.map { |name| Tag.create(:name => name) }

      existing_tags + created_tags
    end

    ### INSTANCE METHODS:

    def ==(object)
      super || (object.is_a?(Tag) && name == object.name)
    end

    def to_s
      name
    end

    def count
      read_attribute(:count).to_i
    end

  end
end