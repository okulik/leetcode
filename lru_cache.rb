# Cache contains key/value entries. Each entry also has a priority and
# an expiry. If the cache is full, we try doing some cleanup first:
# - expired items are removed first
# - if still not enough place, the least recently used item
#   with the lowest priority is removed
#
# c = Cache.new(5, PriorityQueue, 5000)
# c.set('A', 1, 3, 4000) # 4000 is expiry, a timestamp
# c.now = 5001
# c.set('B', 2, 3, 6000)
# c.now = 5002
# c.set('C', 3, 5, 6010)
# c.now = 5003
# c.set('D', 4, 5, 6020)
# c.now = 5004
# c.set('E', 5, 5, 6030)
# c.dump
# puts ""

# c.now = 5005
# c.set('F', 6, 6, 6040)
# c.dump
# puts ""

# c.now = 5006
# c.get('C')
# c.now = 5007
# c.set('G', 7, 6, 6050)
# c.dump
# puts ""

# c.now = 5008
# c.set('H', 8, 6, 6060)
# c.dump
# puts ""

require "pry"
require "pry-byebug"

class Cache
  def initialize(capacity)
    @capacity = capacity
    @data = {}
    @lru = PriorityQueue.new(capacity)
    @exp = PriorityQueue.new(capacity)
  end

  def get(key)
    return nil unless @data.key?(key)

    ci = @data[key]
    @lru.remove_at(key)
    @lru.push(key, ci.priority, Time.now.to_i)
    ci.value
  end

  def set(key, value, priority, expiry)
    if @data.key?(key)
      @lru.remove_at(key)
      @lru.push(key, priority, Time.now.to_i)
      @exp.remove_at(key)
      @exp.push(key, expiry)
      @data[key] = CacheItem.new(value, priority, expiry)
      return
    end

    # cleanup strategy remove all expired items
    if @data.size == @capacity
      while @exp.peek && @exp.peek.priority < Time.now.to_i
        rem_key = @exp.pop.key
        @data.delete(rem_key)
        @lru.remove_at(rem_key)
      end
    end

    # cleanup strategy remove lowest priority item
    if @data.size == @capacity
      rem_key = @lru.pop.key
      @exp.remove_at(rem_key)
      @data.delete(rem_key)
    end

    @data[key] = CacheItem.new(value, priority, expiry)
    @lru.push(key, priority, Time.now.to_i)
    @exp.push(key, expiry)
  end

  def dump
    puts @data.keys.join(",")
  end
end

class CacheItem
  attr_accessor :value, :priority, :expiry

  def initialize(value, priority, expiry)
    @value = value
    @priority = priority
    @expiry = expiry
  end

  def to_s
    "value: #{value}, priority: #{priority}, expiry: #{expiry}"
  end
end

class PriorityQueue
  class PriorityQueueItem
    attr_reader :key, :priority, :ts, :lru

    def initialize(key, priority, ts)
      @key = key
      @priority = priority
      @ts = ts
      @lru = (priority << 32) | ts
    end
  end

  def initialize(capacity)
    @data = []
    @capacity = capacity
    @index = {}
  end

  def push(key, priority, ts = 0)
    raise "no free slots in the queue" if @data.size == @capacity

    @data << PriorityQueueItem.new(key, priority, ts)
    @index[key] = @data.size - 1
    heapify_up(@data.size - 1)
  end

  def pop
    return if @data.size == 0

    if @data.size > 1
      @data[0], @data[@data.size - 1] = @data[@data.size - 1], @data[0]
    end

    root = @data.pop
    @index.delete(key)
    heapify_down(0)
    root
  end

  def peek
    return if @data.size == 0

    @data[0]
  end

  def remove_at(key)
    return if key.nil? || @data.size == 0
    raise "missing index for key #{key}" unless @index.key?(key)

    i = @index[key]
    if i != @data.size - 1
      @data[i] = @data[@data.size - 1]
      @index[@data[i].key] = i
      @data.pop
      @index.delete(key)
      heapify_down(i)
      return
    end

    @index.delete(key)
    @data.pop
  end

  private

  def heapify_down(i)
    return if @data.size <= 1

    l = left(i)
    r = right(i)

    if l < @data.size && @data[l].lru <= @data[i].lru
      mm = l
    else
      mm = i
    end

    if r < @data.size && @data[r].lru <= @data[mm].lru
      mm = r
    end

    if mm != i
      @index[@data[i].key], @index[@data[mm].key] = mm, i
      @data[i], @data[mm] = @data[mm], @data[i]
      heapify_down(mm)
    end
  end

  def heapify_up(i)
    return if @data.size <= 1 || i == 0

    p = parent(i)
    return if p < @data.size && @data[p].lru <= @data[i].lru

    @index[@data[i].key], @index[@data[p].key] = p, i
    @data[i], @data[p] = @data[p], @data[i]

    heapify_up(p)
  end

  def left(i)
    i * 2 + 1
  end

  def right(i)
    i * 2 + 2
  end

  def parent(i)
    (i - 1) / 2
  end

  def dump
    puts @data.map { |el| el.key}.join(",")
  end
end


c = Cache.new(3)
c.set('A', 1, 3, 4000)
c.set('B', 2, 4, 4000)
c.set('C', 3, 3, 4000)
c.get('A')
c.set('D', 4, 5, 6030)
puts c.dump