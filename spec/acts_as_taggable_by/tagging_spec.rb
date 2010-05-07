require File.expand_path('../../spec_helper', __FILE__)

describe ActsAsTaggableBy::Tagging do
  before(:each) do
    clean_database!
    @tagging = ActsAsTaggableBy::Tagging.new
  end

  it "should not be valid with a invalid tag" do
    @tagging.taggable = TaggableModel.create(:name => "Bob Jones")
    @tagging.tag = ActsAsTaggableBy::Tag.new(:name => "", :context => "tags")

    @tagging.should_not be_valid
    
    if ActiveRecord::VERSION::MAJOR >= 3
      @tagging.errors[:tag_id].should == ["can't be blank"]
    else
      @tagging.errors[:tag_id].should == "can't be blank"
    end
  end

  it "should not create duplicate taggings" do
    @taggable = TaggableModel.create(:name => "Bob Jones")
    @tag = ActsAsTaggableBy::Tag.create(:name => "awesome", :context => 'tags')

    lambda {
      2.times { ActsAsTaggableBy::Tagging.create(:taggable => @taggable, :tag => @tag) }
    }.should change(ActsAsTaggableBy::Tagging, :count).by(1)
  end
end
