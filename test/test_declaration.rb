require 'redis-orm'

class TestModel < RedisOrm::Model
  string :foo
end

