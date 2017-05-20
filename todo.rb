require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret' # This is a session variable.
end

before do
  session[:lists] ||= [] # NB! session[:lists] is an Array of hashes
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
    session[:success] = "The list has been created."
    # :success is the new key (just added to the session hash!!!).
    redirect "/lists"
  end
end

# Render a single Todo list (just the title for now)
get "/lists/:id" do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id] # NB! session[:lists] is an array of hashes
  erb :list
end

# Edit a single existing todo list
get "/lists/:id/edit" do
  id = params[:id].to_i
  @list = session[:lists][id] # NB! session[:lists] is an array of hashes
  erb :edit_list
end

# Update an existing list's name
post "/lists/:id" do
  new_name = params[:list_name].strip # strip leading & trailing spaces
  id = params[:id].to_i
  @list = session[:lists][id] # NB! session[:lists] is an array of hashes

  error = error_for_list_name(new_name)
  if error
    session[:error] = error
    erb :edit_list
  else
    old_name = @list[:name]
    @list[:name] = new_name
    session[:success] = "The list name has been updated from '#{old_name}' to '#{new_name}'."
    redirect "/lists/#{id}"
  end
end

# Delete a Todo list
post "/lists/:id/destroy" do
  id = params[:id].to_i
  session[:lists].delete_at id
  session[:success] = "The list has been deleted."

  redirect "/lists"
end

# Return error message if the name is INVALID, else return nil.
def error_for_todo(name)
  if !(1..100).cover?(name.size)
    "The new todo item must be between 1 and 100 characters."
  end
end

# Add a new Todo item to a Todo list
post "/lists/:list_id/todos" do
  @list_id = params[:list_id].to_i

  # session[:lists] is an array (with hashes as elements).
  # session[:lists][list_id] is the hash at array index: list_id.
  # session[:lists][list_id][:todos] is an array (with hashes as elements).
  # session[:lists][0][:todos][0] is a hash (also array element at index: 0)
  # session[:lists][0][:todos][0] => { name: "item_1", completed: false }.
  # session[:lists][list_id][:todos] << {name: params[:todo], completed: false}

  @list = session[:lists][@list_id] # is the hash at array element: list_id.
  # list[:todos] is an array of hashes inside hash 'session[:lists][list_id]'.
  text = params[:todo].strip

  error = error_for_todo(text)
  if error
    session[:error] = error
    erb :list
  else
    @list[:todos] << { name: text, completed: false }
    session[:success] = "The todo was added."
    redirect "/lists/#{@list_id}"
  end
end

# Example of the session[:lists] array (of hashes):
# session[:lists][0][:todos] = { name: "item_1", completed: false },
# { name: "item_2", completed: false }
