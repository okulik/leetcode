require 'benchmark'

class PriorityQueue
  attr_reader :capacity, :size

  class PriorityQueueItem
    attr_accessor :key, :priority
  end

  def initialize(capacity)
    # Array for keeping items in heap order.
    @arr = Array.new(capacity)
    # Helper index for fast finding elements by key in @arr. The key is the
    # key of the item and the value is the index of the item in the @arr array.
    @index = {}
    # Contains the current number of elements in the queue.
    @size = 0
  end

  # The remove_at method removes and returns the element at the given index
  # from the priority queue. If the index is out of range (less than 0 or
  # greater than or equal to the length of the queue), it returns nil.
  # If the index is the last element in the queue, it simply removes it.
  # Otherwise, it swaps the element at the given index with the last element
  # in the queue, removes the last element, and then restores the heap property
  # by repeatedly swapping the element with its parent until it is in the
  # correct position.
  def remove_at(key)
    return if key.nil? || @size == 0
    return unless @index.key?(key)

    i = @index[key]
    if i != @size - 1
      @arr[i] = @arr[@size - 1]
      @index[@arr[i].key] = i
      @size -= 1
      @index.delete(key)
      heapify(i)
      return
    end

    @index.delete(key)
    @size -= 1
  end

  # The push method adds a new item to the priority queue with the given key
  # and prio values. If the priority queue is already full, it raises an
  # exception. The now parameter is optional and is used to calculate the
  # priority if the given prio value is less than 2^32. The method creates
  # a new PriorityQueueItem object with the given key and calculated priority
  # value and adds it to the end of the array. It then updates the index hash
  # with the new key and index value. Finally, it restores the heap property
  # by repeatedly swapping the new item with its parent until it is in the
  # correct position.
  def push(key, prio, now = nil)
    raise "no free slots in cache" if @size == @arr.size

    item = PriorityQueueItem.new
    item.key = key
    item.priority = (prio >> 32) > 0 ? prio : calc_priority(prio, now)

    @arr[@size] = item
    @index[key] = @size
    @size += 1

    i = @size - 1
    while i != 0 && @arr[parent(i)].priority > @arr[i].priority do
      # swap index elements for k at indices i and parent(i)
      @index[@arr[parent(i)].key], @index[@arr[i].key] = i, parent(i)
      # swap arr elements at indices i and parent(i)
      @arr[i], @arr[parent(i)] = @arr[parent(i)], @arr[i]
      i = parent(i)
    end
  end

  # The pop method removes and returns the item with the lowest priority
  # from the priority queue. If the queue is empty, it returns nil. The
  # method first retrieves the root item (which has the lowest priority)
  # from the array. It then removes the root item from the array by calling
  # the remove_at method with the root item's key. Finally, it returns the
  # root item.
  def pop
    return if @size == 0

    root = @arr[0]
    remove_at(root.key)
    root
  end

  # The peek method returns the item with the lowest priority from the
  # priority queue without removing it. If the queue is empty, it returns nil.
  def peek
    return if @size == 0

    @arr[0]
  end

  def dump(root = 0, space = 0, height = 8)
    puts "  arr: #{@arr.map.with_index { |item, i| i < @size ? item.key : nil }.compact.join(', ')}"
    puts "  index: #{@index.inspect}"
    puts "  tree:"
    dump_tree(root, space, height)
  end

  def dump_tree(root = 0, space = 0, height = 8)
    return if root > @size - 1

    space += height
    dump_tree(right(root), space)
    puts ""

    for i in (height...space) do
      print " "
    end
    print @arr[root].key
    puts ""
    dump_tree(left(root), space)
  end

  private

  def calc_priority(priority, now = nil)
    (priority << 32) + (now || Time.now).to_i
  end

  # The `heapify` method restores the heap property by recursively swapping
  # the current node with its child nodes until it is in the correct position.
  # It first compares the current node with its left and right child nodes to
  # find the minimum value. If the minimum value is not the current node, it
  # swaps the current node with the minimum value and continues recursivel
  #  with the new position of the current node.
  def heapify(i)
    l = left(i)
    r = right(i)
    if l < @size && @arr[l].priority <= @arr[i].priority
      mm = l
    else
      mm = i
    end
    mm = r if r < @size && @arr[r].priority <= @arr[mm].priority
    if mm != i
      @index[@arr[i].key], @index[@arr[mm].key] = mm, i
      @arr[i], @arr[mm] = @arr[mm], @arr[i]
      heapify(mm)
    end
  end

  def left(i)
    2 * i + 1
  end

  def right(i)
    2 * i + 2
  end

  def parent(i)
    (i - 1) / 2
  end
end

class Cache
  attr_reader :cache, :capacity
  attr_accessor :now

  def initialize(capacity, now = nil)
    @capacity = capacity
    @cache = {}
    @lru = PriorityQueue.new(capacity)
    @exp = PriorityQueue.new(capacity)
    @now = now
  end

  def get(key)
    if @cache.key?(key)
      ci = @cache[key]
      @lru.remove_at(key)
      @lru.push(key, ci.priority, @now)
      return ci.value
    end

    nil
  end

  def set(key, value, prio, expiry)
    # Update an existing item.
    if @cache.key?(key)
      @lru.remove_at(key)
      @lru.push(key, prio, @now)
      @exp.remove_at(key)
      @exp.push(key, expiry, @now)
      @cache[key] = CacheItem.new(value, prio, expiry)
      return
    end

    # Remove all expired items, if necessary.
    if @cache.size == @capacity
      while @exp.peek && @exp.peek.priority < @now || Time.now.to_i
        rem_key = @exp.pop.key
        @cache.delete(rem_key)
        @lru.remove_at(rem_key)
      end
    end

    # Remove the least recently used item, if necessary.
    if @cache.size == @capacity
      rem_key = @lru.pop.key
      @cache.delete(rem_key)
      @exp.remove_at(rem_key)
    end

    # Add the new item to the cache.
    @cache[key] = CacheItem.new(value, prio, expiry)
    @lru.push(key, prio, @now)
    @exp.push(key, expiry, @now)
  end

  def dump
    @cache.each do |k, v|
      puts "#{k} => #{v}"
    end
    puts "lru:"
    @lru.dump
    puts "exp:"
    @exp.dump
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

Benchmark.bm do |x|
  x.report("PriorityQueue           ") do
    timer_start = 5_000
    count = 10_000
    c = Cache.new(count, timer_start)
    count.times do |i|
      c.set(i.to_s(16), rand(1..100), rand(1..10), timer_start + i)
      c.now = timer_start + i + 1
    end
    count.times do |i|
      c.set(i.to_s(16), rand(1..100), rand(1..10), timer_start + i)
      c.now = timer_start + i + 1
    end
  end
end

# Cache contains key/value pairs. Each pair also has a priority and
# an expiry. If the cache is full, we try doing some cleanup first:
# - expired items are removed first
# - if still not enough place, the last recently used item
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
