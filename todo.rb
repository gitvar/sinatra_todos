require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret' # This is a session variable.
end

before do
  session[:lists] ||= [] # session[] is an Array of hashes.
end

get "/" do
  redirect "/lists"
end

# See 7. URL Discussion.md

# View all the lists (list of lists)
get "/lists" do
  @lists = session[:lists]
  erb :lists, layout: :layout
  # erb(:lists, { layout: :layout })
end

# Render a new list form
get "/lists/new" do
  erb :new_list
end

# Return error message if the name is INVALID, else return nil.
def error_for_list_name(name)
  if !(1..100).cover?(name.size)
    "The new list name must be between 1 and 100 characters."
  elsif session[:lists].any? { |list| list[:name] == name }
    "The new list name must be unique."
  end
end

# Create a new list
post "/lists" do
  list_name = params[:list_name].strip # strip leading & trailing spaces

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:sukses] = "The list has been created."
    # :sukses is the new key (just added to the session hash!!!).
    redirect "/lists"
  end
end

# Render a single Todo list (just the title for now)
get "/lists/:id" do
  id = params[:id].to_i
  @list = session[:lists][id] # Remember session[] is an array of hashes!
  erb :list
end
