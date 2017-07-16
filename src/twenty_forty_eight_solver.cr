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
  #
  # d is a multiplier for keeping the highest tile in the corner:
  #
  #   weight += d * 4096
  #
  def weight(board, a = 2, b = 10, c = b, d = a)
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
        weight += d * 4096 if cell == largest && (x == 0 || x == size) && (y == 0 || y == size)

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
  2048 => [:white, :blue],
  4096 => [:white, :light_gray],
  8192 => [:white, :dark_gray]
}

CELL_PADDING = 9

def render(board, *info)
  # transform board into printable lines
  lines = board.map_with_index do |row|
    row.map do |value|
      fg, bg = COLOR_MAP[value]
      strval = value == 0 ? "" : value.to_s
      rem    = (CELL_PADDING - strval.size) / 2.0
      filler = (" " * CELL_PADDING).colorize.back(bg).to_s
      fmttd  = ((" " * rem.floor.to_i) +
                strval.colorize.fore(fg).bold.to_s +
                (" " * rem.ceil.to_i).colorize.back(bg).to_s).colorize.back(bg).to_s

      [filler, fmttd, filler]
    end.transpose.map &.join
  end.flatten

  # append any additional info to the top right side of the board
  info.each_with_index { |text, idx| lines[idx] += "   #{text}" }

  lines.join "\n"
end

mode = :smart

# game = TwentyFortyEight::Game.new
# 20.times { render(game.board) && game.move TwentyFortyEightSolver.available(game.board).sample }
# puts render game.board
# puts TwentyFortyEightSolver.evaluate game.board
# exit

hi_tile  = 0
hi_score = 0

loop do
  mcnt = {:left => 0, :right => 0, :down => 0, :up => 0}
  mvs  = 0

  TwentyFortyEight.sample(TwentyFortyEight.options.size) do
    break unless moved = case mode
    when :smart then move TwentyFortyEightSolver.evaluate board
    when :naive then down || left || right || up
    end

    sleep 0.2

    mvs += 1
    mcnt[moved] += 1
    max_tile = board.flatten.max
    hi_tile  = max_tile if max_tile > hi_tile
    hi_score = score if score > hi_score

    percentage_strs = [
      "left:    #{((mcnt[:left] / mvs.to_f32) * 100).round(3)}%         ",
      "right:   #{((mcnt[:right] / mvs.to_f32) * 100).round(3)}%        ",
      "up:      #{((mcnt[:up] / mvs.to_f32) * 100).round(3)}%           ",
      "down:    #{((mcnt[:down] / mvs.to_f32) * 100).round(3)}%         "
    ]

    percentage_strs[0] = percentage_strs[0].colorize.fore(:green).to_s if moved == :left
    percentage_strs[1] = percentage_strs[1].colorize.fore(:green).to_s if moved == :right
    percentage_strs[2] = percentage_strs[2].colorize.fore(:green).to_s if moved == :up
    percentage_strs[3] = percentage_strs[3].colorize.fore(:green).to_s if moved == :down

    puts render board, "score:   #{score}           ",
                       "hi:      #{hi_score}        ",
                       "                            ",
                       "largest: #{max_tile}        ",
                       "hi:      #{hi_tile}         ",
                       "                            ",
                       "moves:   #{mvs}             ",
                       percentage_strs[0],
                       percentage_strs[1],
                       percentage_strs[2],
                       percentage_strs[3]
    puts "\033[#{(board.size * 3) + 1}A"
  end
end
