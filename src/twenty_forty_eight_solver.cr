require "./twenty_forty_eight_solver/*"
require "twenty_forty_eight"

module TwentyFortyEightSolver
  extend self

  def entropy(board)
    smoothness   = 0
    monotonicity = 0
    total        = 0
    max_tile     = -Float32::INFINITY
    max_loc      = { :x => 0, :y => 0 }
    board        = board.reverse
    size         = board.size
                   # top left  bottom left    top right      bottom right
    edges        = { { 0, 0 }, { 0, size-1 }, { size-1, 0 }, { size-1, size-1 } }

    # for each cell
    size.times do |y|
      size.times do |x|
        # store value in cell variable
        cell = board[y][x]

        # don't bother unless cell has a value (e.g. ignore empty tiles)
        next unless cell > 0

        # add cell^2 (cell * cell) to total
        total += cell ** 2

        # keep track of max_tile position
        # so we can freak out when it isn't in a corner
        if cell > max_tile
          max_tile    = cell
          max_loc[:x] = x
          max_loc[:y] = y
        end

        # calculate weights based on seemingly working math
        # I have yet to figure out how exactly it works
        # left        right       up          down
        { { x-1, y }, { x+1, y }, { x, y-1 }, { x, y+1 } }.each do |pos|
          # skip out of bounds elements
          next if pos[0] < 0 || pos[1] < 0 || pos[0] == board.size || pos[1] == board.size

          # score weight
          weight        = (board[pos[1]][pos[0]] - cell) ** 2

          # seems we always want to calculate how "smooth" any given neighbor is
          # compared to the current tile (cell variable)
          smoothness   += weight

          # however, only if a weight is present, we want to calculate
          # monotonicity
          monotonicity += weight if weight > 0
        end
      end
    end

    # this is the "going crazy" part, where we push the entropy to basically the
    # worst possible state when the board is not aligned.
    return Float32::INFINITY unless edges.find &.==({ max_loc[:x], max_loc[:y] })

    tmp = [smoothness, monotonicity, (size ** 2), (max_tile ** 4), total].map &.to_f
    sum = tmp[0] + tmp[1] + tmp[2] - tmp[3] - tmp[4]

    sum / tmp.max
  end
end

board = [[0, 0, 0, 0],
         [8, 4, 4, 2],
         [1024, 64, 512, 128],
         [2048, 1024, 512, 256]]

board2 = [[32, 8, 16, 64],
          [128, 512, 32, 16],
          [32, 8, 16, 512],
          [2048, 512, 8, 16]]

# board = board.transpose

board.each do |row|
  puts row.join '|'
end

puts "entropy: #{TwentyFortyEightSolver.entropy board}"

board2.each do |row|
  puts row.join '|'
end

puts "entropy: #{TwentyFortyEightSolver.entropy board2}"


# puts "*" * 60

# board2.each do |row|
#   puts row.join '|'
# end

# puts "emptiness: #{TwentyFortyEightSolver.emptiness board2}"
# puts "emptiness: #{TwentyFortyEightSolver.monotonicity board2}"
