def find_median_sorted_arrays(nums1, nums2)
  nsa = merge(nums1, nums2).to_a
  mid = nsa.length / 2
  nsa.length % 2 == 0 ? (nsa[mid - 1] + nsa[mid])/2.0 : Float(nsa[mid])
end

def merge(array_1, array_2)
  return enum_for(__method__, array_1, array_2) unless block_given?
  a = array_1.each
  b = array_2.each
  loop { yield a.peek < b.peek ? a.next : b.next }
  loop { yield a.next }
  loop { yield b.next }
end

puts find_median_sorted_arrays([1, 2], [1,3])
