#!/usr/bin/env crystal

require "crt"
require "./src/twenty_forty_eight_solver"

size     = TwentyFortyEight.options.size
plays    = TwentyFortyEight.options.count
interval = (0.004 * plays).seconds
channel  = Channel(Tuple(Int32, Int32, Int32, Int32)).new

plays.times do |id|
  spawn do
    game = TwentyFortyEight.sample TwentyFortyEight.options.size do
      dir, _ = TwentyFortyEightSolver.evaluate board, 4, 15, 6, 7, 2, 2, 1

      break channel.send({id, score, board.flatten.max, -1}) unless move dir
      channel.send({id, score, board.flatten.max, empty.size})

      sleep interval
    end
  end
end


fren      = true
lended    = 0
lscores   = plays.times.map { 0 }.to_a
lmaxes    = plays.times.map { 0 }.to_a
scores    = [] of Int32
maxes     = [] of Int32
ended     = 0
offset_y  = 8
offset_yb = 12
offset_x  = 24
meta_pad  = 29
win       = Crt::Window.new offset_y + plays + offset_yb, 100

Crt.init
Crt.start_color

BG_YELLOW   = Crt::ColorPair.new Crt::Color::Black, Crt::Color::Yellow
BG_GREEN    = Crt::ColorPair.new Crt::Color::Black, Crt::Color::Green
BG_RED      = Crt::ColorPair.new Crt::Color::White, Crt::Color::Red
BG_BLACK    = Crt::ColorPair.new Crt::Color::White, Crt::Color::Black
COLOR_RESET = Crt::ColorPair.new Crt::Color::Default, Crt::Color::Default

win.clear
win.print offset_y - 2, offset_x, "  id   |  score  |  max"
win.print offset_y - 1, offset_x, "+++++++++++++++++++++++++++"

def select_color(empty_tile_count)
  return BG_BLACK if empty_tile_count < 0
  return BG_RED if empty_tile_count <= 2
  return BG_YELLOW if empty_tile_count <= 5
  BG_GREEN
end

size_str  = "   size: #{size}x#{size}"
delay_str = "  delay: #{interval.milliseconds}ms"
games_str = "  games: #{plays}"

while (info = channel.receive)
  id, score, max, empty  = info
  lscores[id]            = score
  lmaxes[id]             = max
  lended                 = ended
  ended                 += 1 if empty < 0

  win.attribute_on COLOR_RESET
  win.print offset_y,     offset_x + meta_pad, size_str
  win.print offset_y + 1, offset_x + meta_pad, delay_str
  win.print offset_y + 2, offset_x + meta_pad, games_str
  win.print offset_y + 6, offset_x + meta_pad, "average: #{lscores.sum / plays}"

  if fren || lended < ended
    win.print offset_y + 4, offset_x + meta_pad, "   dead: #{ended.to_s.ljust(7)} #{((ended / plays.to_f * 100).ceil).round(2)}%  "
    win.print offset_y + 5, offset_x + meta_pad, "  alive: #{(plays - ended).to_s.ljust(7)} #{(((plays - ended).to_f / plays * 100).floor).round(2)}%  "

    {256, 512, 1024, 2048}.each.with_index do |m, i|
      clcount = lmaxes.count(&.>=(m)).to_s.ljust 4
      win.print offset_y + 8 + i, offset_x + meta_pad, "#{m.to_s.rjust(7)}: #{clcount.to_s.ljust(7)} #{(clcount.to_f / plays * 100).round(2)}%  "
    end
  end

  win.attribute_on select_color empty
  win.print offset_y + id, offset_x, "  #{"##{id + 1}".ljust(5)}|  #{score.to_s.ljust(5)}  |  #{max.to_s.ljust(5)}  "
  win.refresh

  fren = false
  break if ended == plays
end

win.refresh
channel.close

loop { sleep 1.second }

Crt.done
