
module RedisORM
  class Connection
    attr_accessor :options

    def initialize(options)
      @options = options
    end

    def self.reset!
      threaded = nil
    end

    def self.start(options)
      self.options = options
      self.reset!
    end

    def redis
      threaded ||= Redic.connect(options)
    end
  end

  # add code here

  def self.connect(options={})
    @conn = Redis.new(options)
  end

  def self.conn
    @conn
  end

  module Document
    attr_accessor :id

    def field(name, options={})
      defaults = {type: String}
      attr_accessor name
      collection << {name: name}.merge(defaults).merge(options)

      if options[:index]
        RedisORM.conn.hset("#{self}:indexes", options[:name], 1)
      end
    end

    def collection
      @collection ||= []
    end

    def where(options={})
      keepers = []

      collection.find_all { |f| options.keys.include?(f[:name]) and f[:index] }.each do |attr|
        id = RedisORM.conn.hget("#{self}:index_#{attr[:name]}", options[attr[:name]])
        keepers << RedisORM.conn.hgetall("#{self}:#{id}")
        options.delete(attr[:name])
      end

      keepers.uniq!

      if not options.empty?
        objects = RedisORM.conn.smembers("#{self}_list").map do |object_id|
          RedisORM.conn.hgetall("#{self}:#{object_id}")
        end

        keepers = objects.find_all do |object|
          add = true
          options.each_pair do |key, value|
            add = false if object[key.to_s] != value
          end

          object if add
        end
      end

      keepers = keepers.map do |obj|
        create(obj)
      end

      return (keepers.size == 1) ? keepers.first : keepers
    end

    def create(options={})
      return nil if options.empty?

      tmp = self.new
      options.each_pair do |key, value|
        tmp.send("#{key.to_s}=", value) if tmp.respond_to? key
      end

      return tmp
    end

    module InstanceMethods
      attr_accessor :id

      def fields
        self.class.collection
      end

      def save(options={})
        if @id.nil?
          @id = (rand(100)*rand(100)).hash
          fields << {name: :id, type: String}
          RedisORM.conn.sadd("#{self.class}_list", @id) unless options[:test]

          fields.find_all { |field| field[:index] }.each do |attr|
            RedisORM.conn.hset("#{self.class}:index_#{attr[:name]}", self.send(attr[:name]), @id)
          end
        end

        fields.each do |field|
          case field[:type].to_s
          when String.to_s, Fixnum.to_s
            RedisORM.conn.hset("#{self.class}:#{@id}", field[:name], self.send(field[:name])) unless options[:test]
          end
        end
      end
    end

    def Document.included(mod)
      mod.class_eval {
        extend Document
        include Document::InstanceMethods
      }
    end
  end
end

class Foo
  include RedisORM::Document

  field :title
  field :bar
end
