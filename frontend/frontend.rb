require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'yaml'

require File.expand_path('../../config/init',  __FILE__)

require 'open-uri'


get '/' do
  erb :index
end

get '/classes' do
  @classes = YAML.load(open('classes.yml').read)
  erb :classes
end

