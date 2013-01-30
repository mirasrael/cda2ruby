require 'bundler'

Bundler.setup

$:.unshift(File.expand_path('..', __FILE__))

require 'nokogiri'
require 'fileutils'
require 'active_support/core_ext/string/inflections'
require 'mif/parser'
require 'mif/generator'

rim_schema_path = File.expand_path('../../mif/rim-archive.mif', __FILE__)
#Mif::Generator.new(Mif::Parser.load(rim_schema_path, namespace: 'mif'), namespace: 'mif').generate

cda_schema_path = File.expand_path('../../mif/POCD_RM000040.mif', __FILE__)
Mif::Generator.new(Mif::Parser.load(cda_schema_path), namespace: 'cda').generate