require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'yaml'
require 'json'

require File.expand_path('../../config/init',  __FILE__)

require 'open-uri'


get '/' do
  erb :index
end

get '/classes' do
  @classes = YAML.load(open('classes.yml').read)
  erb :classes
end

get '/classes/:shortname' do
  @shortname = params[:shortname]
  @classes = YAML.load(open('classes.yml').read)
  @klass = @classes[@shortname]
  erb :showclass
end


get '/airdata' do
  @airdata = JSON.load(open('airdata.json').read)
  erb :airdata
end

get '/airdata/:placename' do
  @air = JSON.load(open('airdata.json').read).find{|x| x['title'] =~ /#{params[:placename]}/ }
  erb :showairdata
end

