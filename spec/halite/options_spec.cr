require "../spec_helper"
require "tempfile"

private class SimpleLogger < Halite::Logger::Adapter
  def request(request)
    @writer.info "request"
  end

  def response(response)
    @writer.info "response"
  end
end

describe Halite::Options do
  describe "#initialize" do
    it "should initial with nothing" do
      options = Halite::Options.new
      options.should be_a(Halite::Options)
    end

    it "should initial with Hash arguments" do
      options = Halite::Options.new({
        "headers" => {
          "private_token" => "token",
        },
        "connect_timeout" => 3.2,
      })

      options.should be_a(Halite::Options)
      options.headers.should be_a(HTTP::Headers)
      options.headers["Private-Token"].should eq("token")
      options.timeout.connect.should eq(3.2)
    end

    it "should initial with NamedTuple arguments" do
      options = Halite::Options.new({
        headers: {
          private_token: "token",
        },
        connect_timeout: 1.minutes,
      })

      options.should be_a(Halite::Options)
      options.headers.should be_a(HTTP::Headers)
      options.headers["Private-Token"].should eq("token")
      options.timeout.connect.should eq(60)
    end

    it "should initial with tuples arguments" do
      options = Halite::Options.new(
        headers: {
          "private_token" => "token",
        },
        follow: 4,
        follow_strict: false
      )

      options.should be_a(Halite::Options)
      options.headers.should be_a(HTTP::Headers)
      options.headers["Private-Token"].should eq("token")
      options.follow.hops.should eq(4)
      options.follow.strict.should eq(false)
    end

    it "should overwrite default headers" do
      options = Halite::Options.new(
        headers: {
          user_agent: "spec",
        },
      )

      options.should be_a(Halite::Options)
      options.headers["User-Agent"].should eq("spec")
    end
  end

  describe "#with_headers" do
    it "should overwrite tupled headers" do
      options = Halite::Options.new(headers: {
        private_token: "token",
      })
      options = options.with_headers(private_token: "new", accept: "application/json")

      options.headers["Private-Token"].should eq("new")
      options.headers["Accept"].should eq("application/json")
    end

    it "should overwrite NamedTuped headers" do
      options = Halite::Options.new({
        headers: {
          private_token: "token",
        },
      })
      options = options.with_headers(private_token: "new", accept: "application/json")

      options.headers["Private-Token"].should eq("new")
      options.headers["Accept"].should eq("application/json")
    end

    it "should overwrite Hash headers" do
      options = Halite::Options.new({
        "headers" => {
          private_token: "token",
        },
      })
      options = options.with_headers(private_token: "new", accept: "application/json")

      options.headers["Private-Token"].should eq("new")
      options.headers["Accept"].should eq("application/json")
    end
  end

  describe "#with_cookies" do
    it "should overwrite tupled cookies" do
      options = Halite::Options.new(cookies: {
        "name" => "foo",
      })
      options = options.with_cookies(name: "bar")

      options.cookies["name"].value.should eq("bar")
    end

    it "should overwrite NamedTuple cookies" do
      options = Halite::Options.new(cookies: {
        "name" => "foo",
      })
      options = options.with_cookies({name: "bar"})

      options.cookies["name"].value.should eq("bar")
    end

    it "should overwrite Hash cookies" do
      options = Halite::Options.new(cookies: {
        "name" => "foo",
      })
      options = options.with_cookies({"name" => "bar"})

      options.cookies["name"].value.should eq("bar")
    end
  end

  describe "#with_timeout" do
    it "should overwrite timeout" do
      options = Halite::Options.new(connect_timeout: 1, read_timeout: 3)
      options = options.with_timeout(read: 4.minutes, connect: 1.2)

      options.timeout.connect.should eq(1.2)
      options.timeout.read.should eq(4.minutes.to_f)
    end
  end

  describe "#with_follow" do
    it "should overwrite follow" do
      options = Halite::Options.new(follow: 1, follow_strict: true)
      options = options.with_follow(follow: 5, strict: false)

      options.follow.hops.should eq(5)
      options.follow.strict.should eq(false)
    end
  end

  describe "#with_logger" do
    it "should overwrite logger with instance class" do
      options = Halite::Options.new.with_logger(logger: SimpleLogger.new)
      options.logger.should be_a SimpleLogger
    end

    it "should overwrite logger with adapter name" do
      Halite::Logger.register_adapter "simple", SimpleLogger.new

      options = Halite::Options.new.with_logger(adapter: "simple")
      options.logger.should be_a SimpleLogger
    end

    it "should became a file logger" do
      Halite::Logger.register_adapter "simple", SimpleLogger.new

      tempfile = Tempfile.new("halite_logger")

      options = Halite::Options.new.with_logger(adapter: "simple", filename: tempfile.path, mode: "w")
      options.logger.should be_a SimpleLogger
    end
  end

  describe "#clear!" do
    it "should clear setted options" do
      options = Halite::Options.new(
        headers: {
          "private_token" => "token",
        },
        cookies: {
          "name" => "foo",
        },
        params: {"name" => "foo"},
        form: {"name" => "foo"},
        json: {"name" => "foo"},
        connect_timeout: 1,
        read_timeout: 3,
        follow: 4,
        follow_strict: false
      )
      options.clear!

      options.headers.should eq(options.default_headers)
      options.cookies.empty?.should eq(true)
      options.params.empty?.should eq(true)
      options.form.empty?.should eq(true)
      options.json.empty?.should eq(true)

      options.timeout.connect.nil?.should eq(true)
      options.timeout.read.nil?.should eq(true)

      options.follow.hops.should eq(Halite::Options::Follow::DEFAULT_HOPS)
      options.follow.strict.should eq(Halite::Options::Follow::STRICT)
    end
  end

  describe "alias methods" do
    context "read_timeout alias to timeout.read" do
      it "getter" do
        options = Halite::Options.new(read_timeout: 34)
        options.read_timeout.should eq(34)
        options.timeout.read.should eq(34)
      end

      it "setter" do
        options = Halite::Options.new

        options.timeout.read = 12
        options.read_timeout.should eq(12)
        options.timeout.read.should eq(12)

        options.read_timeout = 21
        options.read_timeout.should eq(21)
        options.timeout.read.should eq(21)
      end
    end

    context "connect_timeout alias to timeout.connect" do
      it "getter" do
        options = Halite::Options.new(connect_timeout: 34)
        options.timeout.connect.should eq(34)
        options.connect_timeout.should eq(34)
      end

      it "setter" do
        options = Halite::Options.new

        options.timeout.connect = 12
        options.connect_timeout.should eq(12)
        options.timeout.connect.should eq(12)

        options.connect_timeout = 21
        options.connect_timeout.should eq(21)
        options.timeout.connect.should eq(21)
      end
    end

    context "only setter for follow alias to follow.hops" do
      it "setter" do
        options = Halite::Options.new

        options.follow = 2
        options.follow.hops.should eq(2)
      end

      it "getter" do
        options = Halite::Options.new(follow: 3)

        # Can not return integer with follow
        options.follow.hops.should eq(3)
      end
    end

    context "follow_strict alias to follow.strict" do
      it "setter" do
        options = Halite::Options.new

        options.follow_strict = false
        options.follow.strict.should eq(false)

        options.follow.strict = true
        options.follow.strict.should eq(true)
      end

      it "getter" do
        options = Halite::Options.new(follow_strict: false)

        options.follow_strict.should eq(false)
        options.follow.strict.should eq(false)
      end
    end
  end
end
