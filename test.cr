require "./src/twenty_forty_eight_solver"
require "colorize"

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

hi_tile  = 0             # remember session highest tile
hi_score = 0             # remember session highscore
scores   = [] of Int32   # save final score of each game to show average score

depth    = 4             # how many moves to look ahead (6 already takes long)

# empty, mono, smooth, highest in corner, score diff
defaults = {8, 25, 3, 2, 1}
mods     = Tuple(Int32, Int32, Int32, Int32, Int32).from defaults.size.times.map { |i| ARGV[i]? && ARGV[i].to_i || defaults[i] }.to_a

loop do
  mcnt   = {:left => 0, :right => 0, :down => 0, :up => 0}
  mvs    = 0

  TwentyFortyEight.sample(TwentyFortyEight.options.size) do
    max_tile = board.flatten.max
    best     = TwentyFortyEightSolver.evaluate board, depth, *mods

    break scores << score unless move = best[0]

    puts "\033[#{(board.size * 3) + 1}A"
    move move
    sleep 0.15

    mcnt[move] += 1
    mvs        += 1

    hi_tile  = max_tile if max_tile > hi_tile
    hi_score = score if score > hi_score
    avg      = scores.any? ? (scores.sum + score) / (scores.size + 1) : score

    puts render board, row("metrics", "score", "tile", row("depth:", depth).colorize.cyan.to_s).colorize.green.bold.to_s,
                       row("current", score, max_tile, row("empty:", mods[0]).to_s.colorize.cyan.bold.to_s),
                       row("highest", hi_score, hi_tile, row("mono:", mods[1]).to_s.colorize.cyan.bold.to_s),
                       row("average", avg, "", row("smooth:", mods[2]).to_s.colorize.cyan.bold.to_s),
                       row("", "", "", row("corner:", mods[3]).to_s.colorize.cyan.bold.to_s),
                       row("", "", "", row("score:", mods[4]).to_s.colorize.cyan.bold.to_s),
                       row(""),
                       row("move", "perc", "", row("games:", scores.size + 1).colorize.red.bold.to_s).colorize.green.bold.to_s,
                       row("left", ((mcnt[:left] / mvs.to_f32) * 100).round(2)),
                       row("right", ((mcnt[:right] / mvs.to_f32) * 100).round(2)),
                       row("up", ((mcnt[:up] / mvs.to_f32) * 100).round(2)),
                       row("down", ((mcnt[:down] / mvs.to_f32) * 100).round(2))
  end
end

