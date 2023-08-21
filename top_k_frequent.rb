def top_k_frequent(nums, k)
  d = nums.each_with_object(Hash.new(0)) { |n, h| h[n] += 1 }
  d.sort_by { |k, v| -v }.first(k).map { |k, v| k }
end

puts top_k_frequent([1, 1, 1, 2, 2, 3], 2).inspect # [1, 2]
puts top_k_frequent([1], 1).inspect                # [1]
puts top_k_frequent([1, 2], 2).inspect             # [1, 2]
puts top_k_frequent([3,0,1,0], 1).inspect          # [0]