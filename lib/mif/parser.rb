require 'mif/document'

module Mif
  class Parser
    def self.load(path, opts = {})
      schema = Nokogiri::XML(File.read(path))
      artifacts = opts[:artifacts] || {}
      name = schema.namespaces.find { |_, value| value == 'urn:hl7-org:v3/mif2' }[0]
      ns = "#{name.split(':').last}:"

      static_model_node = schema.xpath("//#{ns}staticModel")
      target_model_node = static_model_node.at_xpath("#{ns}derivedFrom/#{ns}targetStaticModel")
      parent_document = target_model_node && artifacts[target_model_node['artifact']]

      doc = Document.new
      doc.classes = []
      static_model_node.xpath("#{ns}containedClass/#{ns}class[count(#{ns}historyItem)=0 or #{ns}historyItem[1]/@id!=\"00000000-0000-0000-0000-000000000000\"]").each do |node|
        doc.classes << DeclaredClass.new.tap do |cls|
          cls.name = node['name']
          if (parent_node = node.at_xpath("#{ns}parentClass[count(#{ns}historyItem)=0 or #{ns}historyItem[1]/@id!=\"00000000-0000-0000-0000-000000000000\"]"))
            cls.parent_class = parent_node['name']
          elsif parent_document && (parent_node = node.at_xpath("#{ns}derivedFrom"))
            cls.parent_class = "#{parent_document.root_module_name}::#{parent_node['className']}"
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