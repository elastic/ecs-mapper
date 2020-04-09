require 'optparse'
require 'pathname'

## Configuration

def parse_options!(argv)
  # defaults
  options = {
    :action => :main,
    :rename => 'rename',
  }

  parser = OptionParser.new do |opts|
    opts.banner = [
      SYNOPSIS,
      "",
    ].join("\n")
    opts.separator "Options:"

    # More examples at http://apidock.com/ruby/OptionParser

    opts.on('-f', '--file FILE', "Input CSV file.") do |value|
      options[:file] = value
    end

    opts.on('-o', '--output DIR', "Output directory. Defaults to parent dir of --file.") do |value|
      options[:output] = value
    end

    opts.on('--rename-action RENAME_ACTION', "Default action for field renames. Acceptable values are: copy, rename. Default is rename.") do |value|
      options[:rename] = value
    end


    # opts.on("--log-level LEVEL", "Log level. Default is info. Supports all of Ruby's Logger levels.") do |value|
    #   level_name = value.upcase
    #   if Logger.const_defined?(level_name) && Logger.const_get(level_name).is_a?(Integer)
    #     options[:log_level] = Logger.const_get(level_name)
    #   end
    # end

    opts.on_tail("--debug", "Shorthand for --log-level=debug") do |value|
      $debug = true
      require 'pry'
      # options[:log_level] = Logger::DEBUG
    end

    opts.on_tail('-h', '--help', "Display help") do
      options[:action] = :help
    end

    opts.on_tail('-v', '--version', "Display version and exit") do
      options[:action] = :version
    end

  end

  parser.parse!(argv)

  if :version == options[:action]
    puts VERSION_STRING
    exit
  end

  if :help == options[:action]
    puts VERSION_STRING, ''
    puts parser.to_s
    exit
  end

  if options[:file].nil?
    abort "Use flag '--file FILE' to specify the mapping file to convert."
  end

  options = smart_output_default(options)

  options
end

def smart_output_default(raw_options)
  options = raw_options.dup
  if options[:output]
    output = Pathname.new(options[:output])
  else
    if options[:file]
      output = Pathname.new(options[:file]).parent
    else
      output = Pathname.new('.')
    end
  end
  options[:output] = output.expand_path
  options
end
