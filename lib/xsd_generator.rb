require 'bundler'

Bundler.setup

require 'nokogiri'
require 'fileutils'
require 'active_support/core_ext/string/inflections'

class ClassBuilder
  def sanitize_constant_name(name)
    (name[0] == name[0].upcase ? name : "X_#{name}")
  end

  def sanitize_attribute_name(name)
    name
  end

  def make_const(name, parent = Object)
    parts = name.gsub('.', '::').split('::').map { |part| sanitize_constant_name(part) }
    scope = parts[0..-2].inject(Object) { |scope, part| !scope.const_defined?(part) ? scope.const_set(part, Module.new) : scope.const_get(part) }
    @defined_types[name] = scope.const_set(parts[-1], Class.new(parent))
  end

  def ensure_type(type)
    @defined_types[type['name']] || make_class(type['name'], type).tap { |cls| @classes.push(cls) }
  end

  def make_class(name, type, parent = Object)
    klass = make_const(name, parent)
    type.element_children.each do |node|
      case node.node_name
        when 'attribute'
          klass.send(:attr_accessor, sanitize_attribute_name(node['name']))
        when 'sequence'
          node.element_children.each do |ref|
            next unless ref['name']

            if @types.key?(ref['type'])
              cls = ensure_type(@types[ref['type']])
              klass.send(:attr_accessor, "ref_#{cls.name.underscore.gsub('/', '_')}_#{ref['name']}")
            else
              klass.send(:attr_accessor, ref['name'])
            end
          end
        else
          puts "WARNING: Ignore #{node.node_name}"
      end
    end
    klass
  end

  def make_classes(xsd_path)
    @types = {}
    @defined_types = {}
    @elements = []
    collect_types(xsd_path)
    @classes = []
    @elements.sort_by { |element| element['name'] }.each do |element|
      parent = ensure_type(@types[element['type']])
      @classes.push(make_const(element['name'], parent))
    end
    @classes
  end

  def collect_types(xsd_path, visited_paths = [])
    puts "collect #{xsd_path} elements..."
    visited_paths.push(xsd_path)

    schema = Nokogiri::XML(File.read(xsd_path))
    schema.root.element_children.each do |node|
      case node.node_name
        when 'include'
          included_xsd_path = File.expand_path(node['schemaLocation'], File.dirname(xsd_path))
          unless visited_paths.include?(included_xsd_path)
            visited_paths.push(included_xsd_path)
            collect_types(included_xsd_path, visited_paths)
          end
        when 'element'
          @elements.push(node)
        when 'complexType'
          @types[node['name']] = node
        when 'annotation'
        else
          puts "WARNING: Ignore '#{node.node_name}'"
      end
    end
  end
end

schema_path = File.expand_path('../../xsd/infrastructure/cda/CDA_SDTC.xsd', __FILE__)
builder = ClassBuilder.new
classes = builder.make_classes(schema_path)

puts "=======Classes======="
generated_classes_path = File.expand_path('../../generated', __FILE__)
Dir.mkdir(generated_classes_path) unless Dir.exist?(generated_classes_path)
classes.each do |cl|
  class_path = File.join(generated_classes_path, "#{cl.name.underscore}.rb")
  FileUtils.mkdir_p(File.dirname(class_path))
  out = File.open(class_path, 'wt+')
  out.print "class #{cl.name}"
  out.print " < #{cl.superclass.name}" unless cl.superclass == Object
  out.puts
  cl.instance_methods(false).reject { |m| m.to_s.end_with?('=') }.each do |m|
    out.puts "\tattr_accessor #{m.inspect}"
  end
  out.puts "end"
  out.close
end

#puts "=======Tags======="
#puts schema.tags.collect { |n,cb| n + ": " + cb.to_s + ": " + (cb.nil? ? "ncb" : cb.klass_name.to_s + "-" + cb.klass.to_s) }.sort.join("\n")

#puts "=======Objects======="
#data = RXSD::Parser.parse_xml :uri => xml_uri
#objs = data.to :ruby_objects, :schema => schema
#objs.each {  |obj|
#  puts "#{obj}"
#}