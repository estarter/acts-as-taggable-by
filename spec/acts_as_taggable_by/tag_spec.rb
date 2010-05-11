require File.expand_path('../../spec_helper', __FILE__)

describe ActsAsTaggableBy::Tag do
  before(:each) do
    clean_database!
    @tag = ActsAsTaggableBy::Tag.new
    @user = TaggableModel.create(:name => "Pablo")
  end

  describe "named like any" do
    before(:each) do
      ActsAsTaggableBy::Tag.create(:name => "awesome", :context => "sample_context")
      ActsAsTaggableBy::Tag.create(:name => "epic", :context => "sample_context")
    end

    it "should find both tags" do
      ActsAsTaggableBy::Tag.named_like_any(["awesome", "epic"]).should have(2).items
    end
  end

  describe "find or create by name" do
    before(:each) do
      @tag.name = "awesome"
      @tag.context = "sample_context"
      @tag.save
    end

    it "should find by name" do
      ActsAsTaggableBy::Tag.find_or_create_with_like_by_name(["awesome"], @tag.context, nil).should == @tag
    end

    it "should find by name case insensitive" do
      ActsAsTaggableBy::Tag.find_or_create_with_like_by_name(["AWESOME"], @tag.context, nil).should == @tag
    end

    it "should create by name" do
      lambda {
        ActsAsTaggableBy::Tag.find_or_create_with_like_by_name(["epic"], @tag.context, nil)
      }.should change(ActsAsTaggableBy::Tag, :count).by(1)
    end
  end

  describe "find or create all by any name" do
    before(:each) do
      @tag.name = "awesome"
      @tag.context = "sample_context"
      @tag.save
    end

    it "should find by name" do
      ActsAsTaggableBy::Tag.find_or_create_all_with_like_by_name(["awesome"], @tag.context, nil).should == [@tag]
    end

    it "should find by name case insensitive" do
      ActsAsTaggableBy::Tag.find_or_create_all_with_like_by_name(["AWESOME"], @tag.context, nil).should == [@tag]
    end

    it "should create by name and context" do
      lambda {
        ActsAsTaggableBy::Tag.find_or_create_all_with_like_by_name(["epic"], "sample_context", nil)
      }.should change(ActsAsTaggableBy::Tag, :count).by(1)
    end

    it "should create by exist name with different context" do
      lambda {
        ActsAsTaggableBy::Tag.find_or_create_all_with_like_by_name([@tag.name], @tag.context + "_other", nil)
      }.should change(ActsAsTaggableBy::Tag, :count).by(1)
    end

    it "should find or create by name and context" do
      lambda {
        ActsAsTaggableBy::Tag.find_or_create_all_with_like_by_name(["awesome", "epic"], @tag.context, nil).map(&:name).should == ["awesome", "epic"]
        ActsAsTaggableBy::Tag.find_or_create_all_with_like_by_name(["awesome", "epic"], @tag.context, nil).map(&:context).should == [@tag.context, @tag.context]
      }.should change(ActsAsTaggableBy::Tag, :count).by(1)
    end

    it "should return an empty array if no tags are specified" do
      ActsAsTaggableBy::Tag.find_or_create_all_with_like_by_name([], nil, nil).should == []
    end
  end

  it "should require a name" do
    @tag.valid?
    
    if ActiveRecord::VERSION::MAJOR >= 3
      @tag.errors[:name].should == ["can't be blank"]
    else
      @tag.errors[:name].should == "can't be blank"
    end

    @tag.name = "something"
    @tag.valid?
    
    if ActiveRecord::VERSION::MAJOR >= 3      
      @tag.errors[:name].should == []
    else
      @tag.errors[:name].should be_nil
    end
  end

  it "should equal a tag with the same name" do
    pending
    @tag.name = "awesome"
    new_tag = ActsAsTaggableBy::Tag.new(:name => "awesome")
    new_tag.should == @tag
  end

  it "should return its name when to_s is called" do
    @tag.name = "cool"
    @tag.to_s.should == "cool"
  end

  it "have named_scope named(something)" do
    @tag.name = "cool"
    @tag.context = "context"
    @tag.save!
    ActsAsTaggableBy::Tag.named('cool').should include(@tag)
  end

  it "have named_scope named_like(something)" do
    @tag.name = "cool"
    @tag.context = "sample_context"
    @tag.save!
    @another_tag = ActsAsTaggableBy::Tag.create!(:name => "coolip", :context => @tag.context)
    ActsAsTaggableBy::Tag.named_like(['cool'], @tag.context, nil).should include(@tag, @another_tag)
  end
end
