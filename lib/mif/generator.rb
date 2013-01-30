require 'active_support/core_ext/string/inflections'
require 'fileutils'
require 'erb'

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

    def initialize(document)
      @output_dir = File.expand_path("../../../generated/#{document.namespace}", __FILE__)
      @root_module = document.root_module_name
      @document = document
      @template = ERB.new(File.read(File.expand_path('../../templates/class.rb.erb', __FILE__)))
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
      @cls = cls
      out.print @template.result(binding)
    end
  end
end