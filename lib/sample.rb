require 'bundler'

Bundler.setup

require 'pathname'
require 'active_support/dependencies'
require 'roxml'

root = Pathname.new(File.expand_path('../..', __FILE__))

ActiveSupport::Dependencies.autoload_paths = [root.join('generated')]

document = Cda::ClinicalDocument.new
puts document.to_xml