def neutral_cards
  res = []
  res += (1..100).to_a
  res += (15..50).to_a
  res
end

def class_cards
  (5..19).map { |x| x * 5 } + [35,40,45,50,55,60,65]
end

def all_cards
  neutral_cards + (class_cards*2)
end

class Array
  def rand_el
    self[rand(size)]
  end
  def average
    sum.to_f / size.to_f
  end
  def sum
    inject { |s,i| s + i }
  end
end

def used_cards
  $used_cards ||= all_cards
end

def choose_one
  (1..3).map { |x| used_cards.rand_el }.max
end

def average_choice
  (1..500000).map do
    choose_one
  end.average.round(2)
end

# 2.times do
#   puts average_choice
# end