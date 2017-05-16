require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

get "/" do
  redirect "/lists"
end

get "/lists" do
  @lists = [
    { name: "Lunch Groceries", todos: ["Bread", "Butter", "Cheese"] },
    { name: "Dinner Groceries", todos: ["Steak", "Potatoes"] }
  ]
  erb :lists, layout: :layout

  # erb("You have no lists.", { layout: :layout })
end
