require "./twenty_forty_eight_solver/*"
require "twenty_forty_eight"
require "twenty_forty_eight/options"
require "colorize"

module TwentyFortyEightSolver
  extend self

  # lower entropy is better
  def evaluate(board)
    directions = available board

    return nil unless directions.any?

    Array({Symbol, Float32}).new(directions.size) do |idx|
      direction = directions[idx]
      {direction, weight merge_in direction, board}
    end.sort { |a, b| a[1] <=> b[1] }.first.first
  end

  def merge_in(direction, board)
    case direction
    when :right then right board
    when :down  then down board
    when :left  then left board
    when :up    then up board
    else board
    end
  end

  def weight(board)
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

    tmp = [smoothness, monotonicity, (size ** 2), (max_tile ** 4), total].map &.to_f32
    sum = tmp[0] + tmp[1] + tmp[2] - tmp[3] - tmp[4]

    sum / tmp.max
  end

  def up(board)
    left(board.transpose).transpose
  end

  def down(board)
    right(board.transpose).transpose
  end

  def left(board)
    board.map { |row| merge row }
  end

  def right(board)
    board.map { |row| merge(row.reverse).reverse }
  end

  def merge(row)
    tmp, res = row - [0], Array(Int32).new

    while cur = tmp.shift?
      cmp = tmp.shift?

      if cur == cmp
        mrg     = cur << 1
        res    << mrg
      else
        res << cur
        break unless cmp
        tmp.unshift cmp
      end
    end

    res.concat Array(Int32).new(row.size - res.size) { 0 }
  end

  def available(board)
    out = [] of Symbol
    out << :up if up? board
    out << :down if down? board
    out << :right if right? board
    out << :left if left? board
    out
  end

  def up?(board)
    board != up board
  end

  def down?(board)
    board != down board
  end

  def left?(board)
    board != left board
  end

  def right?(board)
    board != right board
  end
end

# tilevalue => [:fore, :back]
COLOR_MAP = {
  0    => [:white, :white],
  2    => [:white, :light_green],
  4    => [:white, :green],
  8    => [:white, :light_yellow],
  16   => [:white, :light_red],
  32   => [:white, :red],
  64   => [:white, :light_magenta],
  128  => [:white, :magenta],
  256  => [:white, :light_cyan],
  512  => [:white, :cyan],
  1024 => [:white, :light_blue],
  2048 => [:white, :blue]
}

def render(board, padding = 9)
  board.map do |row|
    row.map do |value|
      fg, bg = COLOR_MAP[value]
      strval = value == 0 ? "" : value.to_s
      rem    = (padding - strval.size) / 2.0
      filler = (" " * padding).colorize.back(bg).to_s
      fmttd  = ((" " * rem.floor.to_i) +
                strval.colorize.fore(fg).bold.to_s +
                (" " * rem.ceil.to_i).colorize.back(bg).to_s).colorize.back(bg).to_s

      [filler, fmttd, filler]
    end.transpose.map(&.join).join "\n"
  end.join "\n"
end

mode = :smart

loop do
  TwentyFortyEight.sample(TwentyFortyEight.options.size) do
    sleep 0.2
    puts render board
    case mode
    when :smart then move TwentyFortyEightSolver.evaluate board
    when :naive then down || left || right || up
    end
    move = TwentyFortyEightSolver.evaluate board

    move ||= down || left || right || up

    puts "\033[#{(board.size * 3) + 1}A"
    move
  end
end

# TwentyFortyEight.sample do
#   sleep 0.5
#   puts render board
#   best = TwentyFortyEightSolver.evaluate(board)
#   break unless best[0]? && best[0][0]?
#   puts "\033[#{(board.size * 3) + 1}A"
#   move best[0][0]
# end

