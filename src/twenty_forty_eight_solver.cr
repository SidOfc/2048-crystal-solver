require "./twenty_forty_eight_solver/*"
require "twenty_forty_eight"
require "twenty_forty_eight/options"
require "colorize"

module TwentyFortyEightSolver
  extend self

  def evaluate(board)
    directions = available board

    return nil unless directions.any?

    Array({Symbol, Int32}).new(directions.size) do |idx|
      direction = directions[idx]
      {direction, weight merge_in direction, board}
    end.sort { |a, b| b[1] <=> a[1] }.first.first
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

  # a is a multiplier for empty cell bonus:
  #
  #   weight += a * 4096
  #
  # b is a multiplier for large values in the middle:
  #
  #   weight -= b * dist_to_nearest_border * cell_value
  #
  # c is a multiplier for not being smooth:
  #
  #   weight -= c * (cell - adjacent).abs
  def weight(board, a = 2, b = 10, c = 10)
    size    = board.size - 1
    weight  = 0
    largest = board.flatten.max

    # general heuristic
    size.times do |y|
      size.times do |x|
        cell = board[y][x]

        # give empty cells a large bonus and move to next cell
        if cell == 0
          weight += a * 4096
          next
        end

        # penalty for large values in the middle
        dist    = [[x, size - x].min, [y, size - y].min].min
        weight -= b * dist * cell

        # give large bonus when largest cell is in a corner
        weight += 4096 if cell == largest && (x == 0 || x == size) && (y == 0 || y == size)

        # penalty for not being smooth
        if x > 0 && y > 0 && size > x && size > y
          [board[y-1][x], board[y+1][x], board[y][x-1], board[y][x+1]].each do |other|
            weight -= c * (cell - other).abs
          end
        end
      end
    end

    weight
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

if mode == :man
  game = TwentyFortyEight::Game.new
  20.times { render(game.board) && game.move TwentyFortyEightSolver.available(game.board).sample }
  puts render game.board
  puts TwentyFortyEightSolver.evaluate game.board
  exit
end

loop do
  TwentyFortyEight.sample(TwentyFortyEight.options.size) do
    sleep 0.2
    puts render board
    puts "\033[#{(board.size * 3) + 1}A"
    break unless case mode
    when :smart then move TwentyFortyEightSolver.evaluate board
    when :naive then down || left || right || up
    end
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

