require_relative 'lib/repo_config'
require 'sinatra'
require 'sinatra/config_file'
require 'sinatra/respond_with'
require 'json'

config_file 'config.yml'
DELETED_STATUS = 204
CREATED_STATUS = 201

before do
  @repo_config = RepoConfig.new(settings.gitolite_root_dir)
end

get '/repos' do
  respond_to do |f|
    f.json { JSON.dump(@repo_config.repos) }
  end
end

post '/repos' do
  @repo_config.add_repo params[:repo_name]

  CREATED_STATUS
end

delete '/repos' do
  @repo_config.remove_repo params[:repo_name]

  DELETED_STATUS
end

get '/users' do
  respond_to do |f|
    f.json { JSON.dump(@repo_config.users) }
  end
end

post '/users' do
  @repo_config.add_user params[:username], params[:ssh_key]

  CREATED_STATUS
end

get '/groups' do
  respond_to do |f|
    f.json { JSON.dump(@repo_config.groups) }
  end
end

post '/groups' do
  if params[:username]
    @repo_config.add_group params[:group_name], params[:username]
  else
    @repo_config.add_group params[:group_name]
  end

  CREATED_STATUS
delete '/groups' do
  @repo_config.remove_group params[:group_name]

  DELETED_STATUS
end
end