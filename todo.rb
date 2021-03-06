require "sinatra"
require "sinatra/reloader" # if development?
require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret' # This is a session variable.
  set :erb, :escape_html => true
end

helpers do
  def todos_count(list)
    list[:todos].count
  end

  def todos_remaining(list)
    list[:todos].select { |todo| !todo[:completed] }.count
  end

  def list_complete?(list)
    todos_count(list) > 0 && todos_remaining(list) == 0
    # list[:todos].count > 0 && list[:todos].all? { |todo| todo[:completed] }
  end

  def list_class(list)
    "complete" if list_complete?(list)
  end

  def sort_lists(lists, &block)
    complete_lists, incomplete_lists = lists.partition { |list| list_complete?(list) }

    incomplete_lists.each { |list| yield list, lists.index(list) }
    complete_lists.each { |list| yield list, lists.index(list) }
  end

  def sort_todos(todos, &block)
    # todos.each_with_index do |todo, index|
    #   if todo[:completed]
    #     complete_todos[todo] = index
    #   else
    #     incomplete_todos[todo] = index
    #   end
    # end
    complete_todos, incomplete_todos = todos.partition { |todo| todo[:completed] }

    # incomplete_todos.each(&block)
    # complete_todos.each(&block)
    incomplete_todos.each { |todo| yield todo, todos.index(todo) }
    complete_todos.each { |todo| yield todo, todos.index(todo) }
  end

  def validate_id(index)
    return index if index.to_i.to_s == index

    session[:error] = "The specified list index is invalid!"
    redirect "/lists"
  end

  def load_list(index)
    list = session[:lists][index]
    return list if list

    session[:error] = "The specified list was not found!"
    redirect "/lists"
  end
end

before do
  session[:lists] ||= [] # NB! session[:lists] is an Array of hashes
end

get "/" do
  redirect "/lists"
end

get "/lists/" do
  session[:error] = "The specified list index is invalid!"
  redirect "/lists"
end

# View all the lists (list of lists)
get "/lists" do
  @lists = session[:lists]
  erb :lists
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

# Edit a single existing todo list
get "/lists/:list_id/edit" do
  @list_id = validate_id(params[:list_id]).to_i
  @list = load_list(@list_id)

  erb :edit_list
end

# Render a single Todo list
get "/lists/:list_id" do
  @list_id = validate_id(params[:list_id]).to_i
  @list = load_list(@list_id)

  erb :list
end

# Update an existing list's name
post "/lists/:list_id" do
  new_name = params[:list_name].strip # strip leading & trailing spaces
  @list_id = validate_id(params[:list_id]).to_i
  @list = load_list(@list_id)

  error = error_for_list_name(new_name)
  if error
    session[:error] = error
    erb :edit_list
  else
    old_name = @list[:name]
    @list[:name] = new_name
    session[:success] = "The list name has been updated from '#{old_name}' to '#{new_name}'."
    redirect "/lists/#{@list_id}"
  end
end

# Delete a Todo list
post "/lists/:list_id/destroy" do
  @list_id = validate_id(params[:list_id]).to_i
  @list = load_list(@list_id)

  session[:lists].delete_at(@list_id)
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
  @list_id = validate_id(params[:list_id]).to_i
  @list = load_list(@list_id)
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

# Delete a specific Todo item from a specific Todo list
post "/lists/:list_id/todos/:todo_id/destroy" do
  @list_id = validate_id(params[:list_id]).to_i
  @list = load_list(@list_id)

  todo_id = params[:todo_id].to_i
  item_name = @list[:todos][todo_id][:name]
  @list[:todos].delete_at(todo_id)
  session[:success] = "The todo item '#{item_name}', has been deleted."
  redirect "/lists/#{@list_id}"
end

# Update todo item status (true or false)
post "/lists/:list_id/todos/:todo_id" do
  @list_id = validate_id(params[:list_id]).to_i
  @list = load_list(@list_id)

  todo_id = params[:todo_id].to_i
  item_name = @list[:todos][todo_id][:name]
  is_completed = params[:completed] == "true"

  @list[:todos][todo_id][:completed] = is_completed
  session[:success] = "The todo item '#{item_name}', has been updated."

  redirect "/lists/#{@list_id}"
end

# Mark all todos as complete for a specific list
post "/lists/:list_id/complete_all" do
  @list_id = validate_id(params[:list_id]).to_i
  @list = load_list(@list_id)

  @list[:todos].each { |todo| todo[:completed] = true }
  session[:success] = "All todo items have been completed."

  redirect "/lists/#{@list_id}"
end
