def max_score(nums, counter = 1, seen = 0, cache = {})
  return cache[seen] if cache.key?(seen)

  max = 0
  (0...nums.length - 1).each do |i|
    next if seen[i] == 1
    (i + 1...nums.length).each do |j|
      next if seen[j] == 1
      score = counter * nums[i].gcd(nums[j]) + max_score(nums, counter + 1, seen | 2 ** i | 2 ** j, cache)
      max = score if score > max
    end
  end

  cache[seen] = max
end

require "benchmark"

Benchmark.bm do |x|
  x.report("[1,2]                                                                 ") do
    max_score([1,2])                                                                    # 1
  end
  x.report("[1,2,3,4]                                                             ") do
    max_score([1,2,3,4])                                                                # 11
  end
  x.report("[1,2,3,4,5,6]                                                         ") do
    max_score([1,2,3,4,5,6])
  end                                                                                   # 14
  x.report("[1,2,3,4,5,6,7,8]                                                     ") do
    max_score([1,2,3,4,5,6,7,8])                                                        # 28
  end
  x.report("[153577,37043,753754,168011,467318,738833,530904,711119,447391,571162]") do
    max_score([153577,37043,753754,168011,467318,738833,530904,711119,447391,571162])   # 102
  end
end

# puts max_score([1,2])                                                                    # 1
# puts max_score([1,2,3,4])                                                                # 11
# puts max_score([1,2,3,4,5,6])
# puts max_score([1,2,3,4,5,6,7,8])                                                        # 28
# puts max_score([153577,37043,753754,168011,467318,738833,530904,711119,447391,571162])   # 102
