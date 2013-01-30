require 'active_support/core_ext/string/inflections'
require 'mif/declared_class'

module Mif
  class Document
    attr_accessor :namespace
    attr_accessor :classes

    def root_module_name
      namespace.camelize
    end
  end
end