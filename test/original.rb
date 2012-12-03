require 'redis-orm'

# Declaration
class Page < RedisOrm::Model
  string :title
  string :date
  string :body
end

# querying
# page = Page.where(title: "foo")
# puts page.title # => "foo"

# modification and update
# page.title = "bar"
# page.save!

# creation
# Page.create!(title: "baz", body: "hello world")

