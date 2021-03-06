require "abstract_unit"
require "env_helpers"
require "rails/command"
require "rails/commands/server/server_command"

class Rails::ServerTest < ActiveSupport::TestCase
  include EnvHelpers

  def test_environment_with_server_option
    args = ["thin", "-e", "production"]
    options = parse_arguments(args)
    assert_equal "production", options[:environment]
    assert_equal "thin", options[:server]
  end

  def test_environment_without_server_option
    args = ["-e", "production"]
    options = parse_arguments(args)
    assert_equal "production", options[:environment]
    assert_nil options[:server]
  end

  def test_server_option_without_environment
    args = ["thin"]
    with_rack_env nil do
      with_rails_env nil do
        options = parse_arguments(args)
        assert_equal "development",  options[:environment]
        assert_equal "thin", options[:server]
      end
    end
  end

  def test_environment_with_rails_env
    with_rack_env nil do
      with_rails_env "production" do
        options = parse_arguments
        assert_equal "production", options[:environment]
      end
    end
  end

  def test_environment_with_rack_env
    with_rails_env nil do
      with_rack_env "production" do
        options = parse_arguments
        assert_equal "production", options[:environment]
      end
    end
  end

  def test_environment_with_port
    switch_env "PORT", "1234" do
      options = parse_arguments
      assert_equal 1234, options[:Port]
    end
  end

  def test_environment_with_host
    switch_env "HOST", "1.2.3.4" do
      options = parse_arguments
      assert_equal "1.2.3.4", options[:Host]
    end
  end

  def test_caching_without_option
    args = []
    options = parse_arguments(args)
    assert_nil options[:caching]
  end

  def test_caching_with_option
    args = ["--dev-caching"]
    options = parse_arguments(args)
    assert_equal true, options[:caching]

    args = ["--no-dev-caching"]
    options = parse_arguments(args)
    assert_equal false, options[:caching]
  end

  def test_log_stdout
    with_rack_env nil do
      with_rails_env nil do
        args    = []
        options = parse_arguments(args)
        assert_equal true, options[:log_stdout]

        args    = ["-e", "development"]
        options = parse_arguments(args)
        assert_equal true, options[:log_stdout]

        args    = ["-e", "production"]
        options = parse_arguments(args)
        assert_equal false, options[:log_stdout]

        with_rack_env "development" do
          args    = []
          options = parse_arguments(args)
          assert_equal true, options[:log_stdout]
        end

        with_rack_env "production" do
          args    = []
          options = parse_arguments(args)
          assert_equal false, options[:log_stdout]
        end

        with_rails_env "development" do
          args    = []
          options = parse_arguments(args)
          assert_equal true, options[:log_stdout]
        end

        with_rails_env "production" do
          args    = []
          options = parse_arguments(args)
          assert_equal false, options[:log_stdout]
        end
      end
    end
  end

  def test_host
    with_rails_env "development" do
      options = parse_arguments([])
      assert_equal "localhost", options[:Host]
    end

    with_rails_env "production" do
      options = parse_arguments([])
      assert_equal "0.0.0.0", options[:Host]
    end

    with_rails_env "development" do
      args = ["-b", "127.0.0.1"]
      options = parse_arguments(args)
      assert_equal "127.0.0.1", options[:Host]
    end
  end

  def test_argument_precedence_over_environment_variable
    switch_env "PORT", "1234" do
      args = ["-p", "5678"]
      options = parse_arguments(args)
      assert_equal 5678, options[:Port]
    end

    switch_env "PORT", "1234" do
      args = ["-p", "3000"]
      options = parse_arguments(args)
      assert_equal 3000, options[:Port]
    end

    switch_env "HOST", "1.2.3.4" do
      args = ["-b", "127.0.0.1"]
      options = parse_arguments(args)
      assert_equal "127.0.0.1", options[:Host]
    end
  end

  def test_records_user_supplied_options
    server_options = parse_arguments(["-p", 3001])
    assert_equal [:Port], server_options[:user_supplied_options]

    server_options = parse_arguments(["--port", 3001])
    assert_equal [:Port], server_options[:user_supplied_options]
  end

  def test_default_options
    server = Rails::Server.new
    old_default_options = server.default_options

    Dir.chdir("..") do
      assert_equal old_default_options, server.default_options
    end
  end

  def test_restart_command_contains_customized_options
    original_args = ARGV.dup
    args = %w(-p 4567 -b 127.0.0.1 -c dummy_config.ru -d -e test -P tmp/server.pid -C)
    ARGV.replace args

    options = parse_arguments(args)
    expected = "bin/rails server  -p 4567 -b 127.0.0.1 -c dummy_config.ru -d -e test -P tmp/server.pid -C"

    assert_equal expected, options[:restart_cmd]
  ensure
    ARGV.replace original_args
  end

  private
    def parse_arguments(args = [])
      Rails::Command::ServerCommand.new([], args).server_options
    end
end
