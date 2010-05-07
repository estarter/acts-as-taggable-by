class TaggableModel < ActiveRecord::Base
  acts_as_taggable
  acts_as_taggable_by :languages
  acts_as_taggable_by :skills
  acts_as_taggable_by :needs, :offerings
  has_many :untaggable_models
end

class CachedModel < ActiveRecord::Base
  acts_as_taggable
end

class OtherTaggableModel < ActiveRecord::Base
  acts_as_taggable_by :tags, :languages
  acts_as_taggable_by :needs, :offerings
end

class InheritingTaggableModel < TaggableModel
end

class AlteredInheritingTaggableModel < TaggableModel
  acts_as_taggable_by :parts
end

class TaggableUser < ActiveRecord::Base
  acts_as_tagger
end

class UntaggableModel < ActiveRecord::Base
  belongs_to :taggable_model
end