require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'sinatra/sequel'
require File.expand_path('../../config/init',  __FILE__)

require 'open-uri'


get '/' do
  erb :index
end

