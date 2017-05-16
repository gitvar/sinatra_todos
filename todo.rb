require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret' # This is a session variable.
end

before do
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

# The Routes built so far are:
# GET  /lists      -> view all lists
# GET  /lists/new  -> new list form
# POST /lists/new  -> create a new list

# The above names are 'resource based' names.
# Meaning that the name of the things being modified is named in the URL.
# Everything so far is modifying a "lists" object so there is a 'lists' element
# at the very beginning of the URL. The name indicates what a URL IS rahter
# than what the URL will DO.

# Lets extrapolate out to what we know what this app is to ba able to do:
# a. We need to VIEW a list and also view all of its todo items. This will be
# a get as we are fetching data from a server. So, get a single list:

# GET  /lists/1   -> view a single list (the 1 is an id which uniquely
#                    identifes the list we want to see).

# What about users?

# GET  /users     -> view all the users
# GET  /users/1   -> view one specific user with unique id == 1

# See the pattern? fetch the "resourse type" (list or user in this case)
# and if need be supply an unique identifier to fetch a single resource...

# View all the lists (list of lists)
get "/lists" do
  @lists = session[:lists]
  erb :lists, layout: :layout
  # The above line is the same as:
  # erb("You have no lists.", { layout: :layout })
end

# Render a new list form
get "/lists/new" do
  erb :new_list
end

# Create a new list
post "/lists" do
  session[:lists] << { name: params[:list_name], todos: [] }
  redirect "/lists"
end
