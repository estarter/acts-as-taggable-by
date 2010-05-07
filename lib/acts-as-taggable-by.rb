require "active_record"
require "action_view"

$LOAD_PATH.unshift(File.dirname(__FILE__))

require "acts_as_taggable_by/compatibility/active_record_backports" if ActiveRecord::VERSION::MAJOR < 3

require "acts_as_taggable_by/acts_as_taggable_by"
require "acts_as_taggable_by/acts_as_taggable_by/core"
require "acts_as_taggable_by/acts_as_taggable_by/collection"
require "acts_as_taggable_by/acts_as_taggable_by/cache"
require "acts_as_taggable_by/acts_as_taggable_by/ownership"
require "acts_as_taggable_by/acts_as_taggable_by/related"

require "acts_as_taggable_by/acts_as_tagger"
require "acts_as_taggable_by/tag"
require "acts_as_taggable_by/tag_list"
require "acts_as_taggable_by/tags_helper"
require "acts_as_taggable_by/tagging"

$LOAD_PATH.shift

if defined?(ActiveRecord::Base)
  ActiveRecord::Base.extend ActsAsTaggableBy::Taggable
  ActiveRecord::Base.send :include, ActsAsTaggableBy::Tagger
end

if defined?(ActionView::Base)
  ActionView::Base.send :include, ActsAsTaggableBy::TagsHelper
end