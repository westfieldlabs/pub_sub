$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'pub_sub'

support_dir = File.expand_path('../../spec/support', __FILE__)
Dir["#{support_dir}/**/*.rb"].each { |f| require f }
