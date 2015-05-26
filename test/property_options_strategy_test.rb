require 'test_helper'

class PropertyOptionsStrategyTest < BaseTest
  let (:format) { :hash }
  let (:song) { Struct.new(:title, :author_name, :song_volume).new("Revolution", "Some author", 20) }
  let (:prepared) { representer.prepare song }

  describe "module" do
    representer! do
      defaults do
        property do |name, given_options|
          { as: property_name.to_s.camelize }
        end
      end

      property :title
      property :author_name

      with_no_defaults

      property :song_volume
    end

    it { render(prepared).must_equal_document({"Title" => "Revolution", "AuthorName" => "Some author", "song_volume" => 20}) }
  end

  describe "decorator" do
    representer!(:decorator => true) do
      strategic_property_options do |property_name, property_options={}|
        { as: property_name.to_s.camelize(:lower) }
      end

      property :title
      property :author_name
    end

    it { render(prepared).must_equal_document({"title" => "Revolution", "authorName" => "Some author"}) }
  end
end
