require 'capistrano'
require 'capistrano/version'

is_cap3 = Capistrano.constants.include? :VERSION
if is_cap3
  load File.expand_path('../capistrano/capistrano3.rb', __FILE__)
else
  require_relative 'capistrano/capistrano2'
end
