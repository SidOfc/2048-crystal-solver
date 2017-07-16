require "./twenty_forty_eight_solver/*"
require "twenty_forty_eight"
require "twenty_forty_eight/options"
require "colorize"

module TwentyFortyEightSolver
  extend self

  def evaluate(board)
    directions = available board

    return unless directions.any?

    Array({Symbol, Int32}).new(directions.size) do |idx|
      direction = directions[idx]
      {direction, weight merge_in direction, board}
    end.sort { |a, b| b[1] <=> a[1] }
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
    vals    = board.flatten
    size    = board.size - 1
    avg     = vals.sum / board.size
    invempt = 1 + (board.size - board.select(&.==(0)).size) / 2
    weight  = -vals.reduce(0) { |initial, cell| cell >= avg ? (initial + invempt * 4096) : initial }
    largest = vals.max

    # general heuristic
    size.times do |y|
      size.times do |x|
        cell = board[y][x]

        # give empty cells a large bonus and move to next cell
        if cell == 0
          weight += invempt * 4096
          next
        end

        # penalty for large values in the middle
        dist    = [[x, size - x].min, [y, size - y].min]
        weight -= (5 * [x, size - 1].min * cell) + (5 * [y, size - 1].min * cell)

        # give large bonus when largest cell is in a corner
        weight += 4096 if cell == largest && (x == 0 || x == size) && (y == 0 || y == size)

        # penalty for not being smooth
        if x > 0 && y > 0 && size > x && size > y
          [board[y-1][x], board[y+1][x], board[y][x-1], board[y][x+1]].each do |other|
            weight -= (3 * invempt) * (cell - other).abs
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
  0     => [:white, :white],
  2     => [:white, :green],
  4     => [:white, :light_green],
  8     => [:white, :yellow],
  16    => [:white, :light_yellow],
  32    => [:white, :red],
  64    => [:white, :light_red],
  128   => [:white, :magenta],
  256   => [:white, :light_magenta],
  512   => [:white, :cyan],
  1024  => [:white, :light_cyan],
  2048  => [:white, :blue],
  4096  => [:white, :light_blue],
  8192  => [:white, :dark_gray],
  16384 => [:white, :black]
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

def row(*data, **opts)
  padding = opts[:padding]? || 8
  gutter  = " " * (opts[:gutter]? || 3)
  data.map(&.to_s.ljust(padding)).join gutter
end

hi_tile  = 0
hi_score = 0

loop do
  mcnt = {:left => 0, :right => 0, :down => 0, :up => 0}
  mvs  = 0

  TwentyFortyEight.sample(TwentyFortyEight.options.size) do
    break unless weights = TwentyFortyEightSolver.evaluate board

    move weights[0][0]
    sleep 0.15

    mvs += 1
    mcnt[weights[0][0]] += 1
    max_tile = board.flatten.max
    hi_tile  = max_tile if max_tile > hi_tile
    hi_score = score if score > hi_score

    lw, rw, uw, dw = [:left, :right, :up, :down].map do |direction|
      weight = weights.find(&.first.==(direction))
      weight && weight.last || ""
    end

    puts render board, row("metrics", "score", "tile").colorize.green.bold.to_s,
                       row("current", score, max_tile),
                       row("highest", hi_score, hi_tile),
                       row(""),
                       row("move", "perc", "weight").colorize.green.bold.to_s,
                       row("left", ((mcnt[:left] / mvs.to_f32) * 100).round(3), lw),
                       row("right", ((mcnt[:right] / mvs.to_f32) * 100).round(3), rw),
                       row("up", ((mcnt[:up] / mvs.to_f32) * 100).round(3), uw),
                       row("down", ((mcnt[:down] / mvs.to_f32) * 100).round(3), dw)
    puts "\033[#{(board.size * 3) + 1}A"
  end
end
