MAX_INT = 2147483647
MIN_INT = -2147483648

def divide(dividend, divisor)
  rest = dividend.abs
  count = 0
  if divisor.abs == 1
    count = rest
  elsif divisor.abs == 1 && dividend.abs != 1
    count = 0
  elsif divisor.abs == 1 && dividend.abs == 1
    count = 1
  else
    while rest > 0 do
      rest -= divisor.abs
      count += 1 if rest >= 0
    end
  end
  count *= -1 if dividend < 0 && divisor > 0 || dividend > 0 && divisor < 0
  if count > MAX_INT
    count = MAX_INT
  elsif count < MIN_INT
    count = MIN_INT
  end
  count
end

puts divide(10, 3) # 3
puts divide(7, -3) # -2
puts divide(1, 1) # 1
puts divide(-1, 1) # -1
puts divide(-2147483648, -1) # 2147483647
