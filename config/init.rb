require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'sinatra/sequel'
require 'sqlite3'

db_path = File.expand_path(File.join(File.dirname(__FILE__), '../db', "#{ENV['OPSCODE_ENV']}frankenspice.db"))
set :database, "sqlite://#{db_path}"

migration "create the audit_log table" do
  database.create_table :audit_log do
    primary_key :id
    datetime    :created_at
    text        :apps
    text        :version
    text        :user
    text        :reason
  end
end
