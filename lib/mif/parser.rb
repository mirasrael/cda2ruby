require 'mif/document'

module Mif
  class Parser
    def self.load(path, opts = {})
      schema = Nokogiri::XML(File.read(path))
      #schema.root.add_namespace

      ns = opts[:namespace] && !opts[:namespace].empty? ? "#{opts[:namespace]}:" : 'xmlns:'

      doc = Document.new
      doc.classes = []
      schema.xpath("//#{ns}staticModel/#{ns}containedClass/#{ns}class[count(#{ns}historyItem)=0 or #{ns}historyItem[1]/@id!=\"00000000-0000-0000-0000-000000000000\"]").each do |node|
        doc.classes << DeclaredClass.new.tap do |cls|
          cls.name = node['name']
          if (parent_node = node.at_xpath("#{ns}parentClass[count(#{ns}historyItem)=0 or #{ns}historyItem[1]/@id!=\"00000000-0000-0000-0000-000000000000\"]"))
            cls.parent_class = parent_node['name']
          end
          cls.attributes = node.xpath("#{ns}attribute[count(#{ns}historyItem)=0 or #{ns}historyItem[1]/@id!=\"00000000-0000-0000-0000-000000000000\"]").map do |attr_node|
            DeclaredAttribute.new.tap do |attr|
              attr.name = attr_node['name']
            end
          end
        end
      end
      doc
    end
  end
end