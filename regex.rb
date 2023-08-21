def is_match(s, p)
  rows = s.length
  columns = p.length

  # base conditions
  return true if rows == 0 && columns == 0
  return false if columns == 0

  # The dp array is used for dynamic programming to store the results of
  # matching subproblems. It contains a 2D array of booleans. The rows represent
  # the characters in the s string and the columns represent the characters in the
  # p string. The dp array is initialized with all false values. As we loop over
  # all characters of both strings and find a match, we set a corresponding
  # value in the dp array to true.
  dp = Array.new(rows + 1) { [false] }

  # empty string and empty pattern are a match
  dp[0][0] = true

  # deals with patterns with *
  (1..columns).each do |i|
    if p[i - 1] == '*'
      dp[0][i] = dp[0][i - 2]
    else
      dp[0][i] = false
    end
  end

  # for remaining characters
  (1..rows).each do |i|
    (1..columns).each do |j|
      if p[j - 1] == '*'
        if p[j - 2] == s[i - 1] || p[j - 2] == '.'
          dp[i][j] = dp[i][j - 2] || dp[i - 1][j]
        else
          dp[i][j] = dp[i][j - 2]
        end
      elsif p[j - 1] == s[i - 1] || p[j - 1] == '.'
        dp[i][j] = dp[i - 1][j - 1]
      else
        dp[i][j] = false
      end
    end
  end

  dp[rows][columns]
end

# Example usage
puts is_match("Hello, World!", "Hello, World!")          # true
puts is_match("ab", ".*")                                # true
puts is_match("aa", "a")                                 # false
puts is_match("aa", "a*")                                # true
puts is_match("aabccd", "a*..*d")                        # true
puts is_match("ab", ".*c")                               # false
puts is_match("aabcbcbcaccbcaabc", ".*a*aa*.*b*.c*.*a*") # true