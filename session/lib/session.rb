puts 'Content-Type: application/json; charset=UTF-8'
puts 'Status: 200'

puts

require 'json'
require 'ulid'

FLAVORS = %i[chicken fish meat veg]
TIMEOUT = 30_000

def random_flavor
  FLAVORS.at(Random.rand(0..3))
end

menu = []

offset = 0
while offset < TIMEOUT
  menu.push({ demand: random_flavor, offset: offset })
  offset += Random.rand(1000..3000)
end

puts JSON.generate({ id: ULID.generate, menu: menu })
