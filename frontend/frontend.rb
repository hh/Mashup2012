require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'sinatra/sequel'
require File.expand_path('../../config/init',  __FILE__)

require '../site-cookbooks/fleet_windows/libraries/fleet_build'
require '../site-cookbooks/route_windows/libraries/route_build'
require '../site-cookbooks/route_windows/libraries/route_sql'
require 'spice'
require 'open-uri'


case ENV['OPSCODE_ENV']
when 'qa'
  Spice.server_url = 'http://chefserver.chc.tlocal:4000'
  Spice.chef_version = '10.8'
  Spice.client_name = 'devops'
  Spice.key_file = File.expand_path('../../../.chef/devops.pem',  __FILE__)
else
  Spice.server_url = 'http://chefserver.telogis.local:4000'
  Spice.chef_version = '10.8'
  Spice.client_name = 'production-admin'
  Spice.key_file = File.expand_path('../../../.chef/production.pem',  __FILE__)
end
#Spice.autoconfigure! # not implemented yet?

Spice.connect!

helpers do

  def protected!
    unless authorized?
      response['WWW-Authenticate'] = %(Basic realm="Use your TeamCity credentials")
      throw(:halt, [401, "Not authorized\n"])
    end
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    if @auth.provided? && @auth.basic? && @auth.credentials
      @username = @auth.credentials[0]
      # use our teamcity credentials
      authenticated = begin
                        open("http://fleet-teamcity/httpAuth/app/rest",
          :http_basic_authentication=>@auth.credentials).read
                        true
                      rescue OpenURI::HTTPError => e
                        case e.message
                        when /401 Unauthorized/
                          false
                        else
                          raise
                        end
                      end
      # even if the user authenticates,
      # they must be in the users array for this environment
      # to be authorized to make changes
      case ENV['OPSCODE_ENV']
      when 'qa'
        authorized = [
          'karen',
          'stephen',
          'jared.oelderinkwale',
          'astrid',
          'thomas.evans',
          'hannah.sim',
          'jessica.gough',
          'jeff.thompson',
          'chris',
	  'james.thompson',
	  'cain.cresswell-miley',
          'jaredk',
          'jezza',
          'kathy.kok@telogis.com',
          'lukas.pohl',
          'mark.dunlop',
          'michael.russell',
          'ray.hidayat@telogis.com',
          'simon.frost',
          'tino.kochinski@telogis.com',
          'wim.looman'
        ].include? @username || false
      else
        authorized = [
          'jessica.gough',
          'jeff.thompson',
          'chris',
          'stephen.a', # no login created yet...
          'daniel.bason',
          'james.thompson',
          'karen'
        ].include? @username || false
      end
      (authenticated && authorized) || false
    else
      false
    end
  end
end


get '/' do
  @fleet_deploys = Spice::DataBag.show_item(:name=>'fleet_deployments',:id=>'versions')
  @route_deploys = Spice::DataBag.show_item(:name=>'route_deployments',:id=>'versions')
  @route_status = {}
  @route_deploys.each do |name, ver|
    next if name == 'id'

    begin
      rdb = RouteDB.new name
    rescue
      @route_status[name] = "Route-#{name} sql db doesn't exist!"
      next
    end

    begin
      if rdb.idle?
        @route_status[name] = "Idle"
      else
        @route_status[name] = "#{rdb.current_runners.count} job(s) running"
      end
    end
  end
  erb :index
end

get '/fleet' do
  @versions = FleetBuild.versions
  @deploys = Spice::DataBag.show_item(:name=>'fleet_deployments',:id=>'versions')
  erb :selectfleet
end

get '/audit' do
  erb :audit
end

post '/fleet' do
  protected!
  @versions = FleetBuild.versions
  @deploys = Spice::DataBag.show_item(
    :name=>'fleet_deployments',:id=>'versions')

  
  @desired_version = params[params["vername"]]
  @reason = params['reason']

  @upgrades = []

  @deploys.each do |name,version|
    if params[name]
      @upgrades << name
      @deploys[name]=@desired_version
    end
  end
  
  Spice::DataBag.update_item(
    {:name=>'fleet_deployments',:id=>'versions'}.merge @deploys)

  data = {
    'created_at' => DateTime.now,
    'apps' => @upgrades.join(','),
    'version' => @desired_version,
    'user' => @username,
    'reason' => @reason
  }
  database[:audit_log].insert(data)

  erb :upgrade
end

get '/route' do
  @versions = RouteBuild.versions
  @deploys = Spice::DataBag.show_item(:name=>'route_deployments',:id=>'versions')
  erb :selectroute
end


get '/route/:buildname' do
  @buildname = params[:buildname]
  @rdb = RouteDB.new @buildname
  @all_versions = RouteBuild.versions[@buildname]
  @desired_version = Spice::DataBag.show_item(:name=>'route_deployments',:id=>'versions')[@buildname]
  erb :showroute
end

post '/route' do
  protected!
  @versions = RouteBuild.versions
  @deploys = Spice::DataBag.show_item(
    :name=>'route_deployments',:id=>'versions')

  
  @desired_version = params[params["vername"]]
  @desired_deployment=@desired_version.split('.')[0] #versions must end in .buildnumber

  @upgrades=[@desired_deployment]
  @deploys[@desired_deployment]=@desired_version
    
  Spice::DataBag.update_item(
    {:name=>'route_deployments',:id=>'versions'}.merge @deploys)

  data = {
    'created_at' => DateTime.now,
    'apps' => @desired_deployment,
    'version' => @desired_version,
    'user' => @username,
    'reason' => @reason
  }
  database[:audit_log].insert(data)

  erb :upgrade
end
