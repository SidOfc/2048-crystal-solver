require "./twenty_forty_eight_solver/*"
require "twenty_forty_eight"
require "twenty_forty_eight/options"
require "colorize"

module TwentyFortyEightSolver
  extend self

  def evaluate(board, depth, *modifiers)
    get_move board, depth, depth, *modifiers
  end

  def get_move(board, depth, max_depth = depth, *modifiers)
    best_score = 0
    best_move  = nil
    directions = available board

    directions.each do |direction|
      new_board = merge_in direction, board, true
      score     = weight new_board, *modifiers

      if depth != 0
        tmp_move, tmp_score  = get_move new_board, depth - 1, max_depth, *modifiers
        score               += tmp_score * (0.9 ** (max_depth - depth + 1))
      end

      if score > best_score
        best_move  = direction
        best_score = score
      end
    end

    return {best_move, best_score}
  end

  def weight(board, e = 3, m = 8, s = 2)
    flattened         = board.flatten
    size              = board.size
    largest           = flattened.max
    nonempty          = flattened.select(&.>(0))
    average           = e * nonempty.size * (nonempty.sum / flattened.size)
    maxpos            = {:x => 0, :y => 0}
    emt, mon, smt, hc = 0, 0, 0, 0

    size.times { |y| size.times { |x| (maxpos[:x] = x) && (maxpos[:y] = y) if board[y][x] == largest } }

    size.times do |y|
      size.times do |x|
        cell  = board[y][x]

        (emt += average) && next if cell == 0 # give empty cells a large bonus and move to next cell

        hc   += cell * cell if cell == largest && {0, size - 1}.includes?(y) &&
                               {0, size - 1}.includes?(x)

        mon  -= 0.3 * m * {x, size - x}.min * cell    # penalty for large values not near horizontal border
        mon  -= 0.3 * m * {y, size - y}.min * cell    # penalty for large values not near vertical border
        mon  -= 0.2 * m * (x - maxpos[:x]).abs * cell # penalty for large values not near largest value in x axis
        mon  -= 0.2 * m * (y - maxpos[:y]).abs * cell # penalty for large values not near largest value in x axis

        smt  -= 0.2 * s * (cell - (y > 0            ? cell - board[y-1][x] : 0)).abs # top of current
        smt  -= 0.2 * s * (cell - (y < size - 1     ? cell - board[y+1][x] : 0)).abs # down of current
        smt  -= 0.2 * s * (cell - (l = x > 0        ? cell - board[y][x-1] : 0)).abs # left of current
        smt  -= 0.2 * s * (cell - (r = x < size - 1 ? cell - board[y][x+1] : 0)).abs # right of current
      end
    end

    {emt, hc, mon, smt}.sum.abs
  end

  def merge_in(direction, board, insert = false)
    board = case direction
    when :down  then down board
    when :right then right board
    when :left  then left board
    when :up    then up board
    else board
    end

    if insert
      x, y = random_empty board
      board[y][x] = rand(1..10) == 10 ? 4 : 2
    end

    board
  end

  def random_empty(board)
    board.size.times.flat_map do |x|
      board.size.times.compact_map { |y| {x, y} if board[x][y] == 0 }
    end.to_a.sample
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

# color palette used in #render
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

# default cell padding value
CELL_PADDING = 9

# method for rendering board and any additional info
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

# method for outputting padded data consistently
def row(*data, **opts)
  padding = opts[:padding]? || 8
  gutter  = " " * (opts[:gutter]? || 3)
  data.map(&.to_s.ljust(padding)).join gutter
end

# trap Ctrl+C and clear the output
Signal::INT.trap do
  puts "\033[#{(TwentyFortyEight.options.size * 3) + 1}A"
  exit
end

hi_tile  = 0         # remember session highest tile
hi_score = 0         # remember session highscore

depth    = 5         # how many moves to look ahead (6 already takes long)
mods     = {4, 9, 3} # modifiers for empty, monotonocity and smoothness respectively

loop do
  mcnt   = {:left => 0, :right => 0, :down => 0, :up => 0}
  mvs    = 0

  TwentyFortyEight.sample(TwentyFortyEight.options.size) do
    max_tile = board.flatten.max
    best     = TwentyFortyEightSolver.evaluate board, depth, *mods

    break unless move = best[0]

    puts "\033[#{(board.size * 3) + 1}A"
    move move
    sleep 0.15

    mcnt[move] += 1
    mvs        += 1

    hi_tile  = max_tile if max_tile > hi_tile
    hi_score = score if score > hi_score

    puts render board, row("metrics", "score", "tile", row("depth:", depth).colorize.cyan.to_s).colorize.green.bold.to_s,
                       row("current", score, max_tile, row("empty:", mods[0]).to_s.colorize.cyan.bold.to_s),
                       row("highest", hi_score, hi_tile, row("mono:", mods[1]).to_s.colorize.cyan.bold.to_s),
                       row("", "", "", row("smooth:", mods[2]).to_s.colorize.cyan.bold.to_s),
                       row("move", "perc").colorize.green.bold.to_s,
                       row("left", ((mcnt[:left] / mvs.to_f32) * 100).round(2)),
                       row("right", ((mcnt[:right] / mvs.to_f32) * 100).round(2)),
                       row("up", ((mcnt[:up] / mvs.to_f32) * 100).round(2)),
                       row("down", ((mcnt[:down] / mvs.to_f32) * 100).round(2))
  end
end
