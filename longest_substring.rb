require "set"

def length_of_longest_substring(s)
  dict = Hash.new
  sequences = []
  s.chars.each_with_index do |c, i|
    if dict.include?(c)
      sequences << dict.count
      ind = dict[c]
      dict.delete_if { |_, v| v <= ind }
    end
    dict[c] = i
  end
  sequences << dict.count
  sequences.max
end

puts length_of_longest_substring("abcabcbb") # 3, "abc"
puts length_of_longest_substring("bbbbb")    # 1, "b"
puts length_of_longest_substring("pwwkew")   # 3, "wke"
puts length_of_longest_substring("dvdf")     # 3, "vdf"