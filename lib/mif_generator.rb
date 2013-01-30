require 'bundler'

Bundler.setup

$:.unshift(File.expand_path('..', __FILE__))

require 'nokogiri'
require 'fileutils'
require 'active_support/core_ext/string/inflections'
require 'mif/parser'
require 'mif/generator'

rim_schema_path = File.expand_path('../../mif/rim-archive.mif', __FILE__)
rim_document = Mif::Parser.load(rim_schema_path)
rim_document.namespace = 'rim'
Mif::Generator.new(rim_document).generate

cda_schema_path = File.expand_path('../../mif/POCD_RM000040.mif', __FILE__)
cda_document = Mif::Parser.load(cda_schema_path, artifacts: {'RIM' => rim_document})
cda_document.namespace = 'cda'
Mif::Generator.new(cda_document).generate