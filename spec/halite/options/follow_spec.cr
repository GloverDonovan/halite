require "../../spec_helper"

describe Halite::Follow do
  describe "#initlize" do
    it "shoulds works" do
      follow = Halite::Follow.new(1, false)
      follow.hops.should eq(1)
      follow.strict.should be_false
    end

    it "shoulds sets one argument" do
      follow = Halite::Follow.new(1)
      follow.hops.should eq(1)
      follow.strict.should be_true

      follow = Halite::Follow.new(strict: false)
      follow.hops.should eq(0)
      follow.strict.should be_false
    end
  end

  describe "setter" do
    it "should works" do
      follow = Halite::Follow.new
      follow.hops = 3
      follow.hops.should eq(3)

      follow.strict = false
      follow.strict.should be_false
    end
  end
end
