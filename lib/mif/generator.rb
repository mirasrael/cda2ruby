require 'active_support/core_ext/string/inflections'
require 'fileutils'

class PaddedOutput
  def initialize(output)
    @output = output
    @padding = ''
    @new_line = true
  end

  def with_padding
    @padding << '  '
    yield
  ensure
    @padding = @padding[0..-3]
  end

  def print(msg)
    if @new_line
      @output.print @padding
      @new_line = false
    end
    @output.print msg
  end

  def puts(msg = '')
    @output.print @padding if @new_line
    @output.puts msg
    @new_line = true
  end

  def close
    @output.close
  end
end

module Mif
  class Generator
    attr_reader :document

    def initialize(document, opts = {})
      namespace = opts[:namespace] || '.'
      @output_dir = File.expand_path("../../../generated/#{namespace}", __FILE__)
      @root_module = namespace.camelcase if namespace
      @document = document
    end

    def generate
      document.classes.each do |cls|
        output_path = "#{File.join(@output_dir, cls.name.underscore)}.rb"
        FileUtils.mkpath(File.dirname(output_path))
        out = PaddedOutput.new(File.open(output_path, 'wt+'))
        if @root_module
          out.puts("module #@root_module")
          out.with_padding {
            generate_class(out, cls)
          }
          out.puts("end")
        else
          generate_class(out, cls)
        end
        out.close
      end
    end

    def generate_class(out, cls)
      out.print "class #{cls.name}"
      out.print " < #{cls.parent_class}" if cls.parent_class
      out.puts
      out.with_padding do
        cls.attributes.each do |attr|
          out.puts "attr_accessor :#{attr.name}"
        end
      end
      out.puts "end"
    end
  end
end