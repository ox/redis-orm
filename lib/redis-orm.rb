module RedisOrm
  class Model
    def self.string(name)
      collection[name] = {type: :string, value: ""}
    end

    def self.collection
      @collection ||= {}
    end
  end
end
