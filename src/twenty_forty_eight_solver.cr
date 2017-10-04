require "./twenty_forty_eight_solver/*"
require "twenty_forty_eight"
require "twenty_forty_eight/options"

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
      new_board, score_diff = merge_in direction, board, true
      score                 = weight new_board, score_diff, *modifiers

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

  def weight(board, diff, b = 15,  e = 3, m = 8, s = 2, c = 2, d = 4)
    flattened         = board.flatten
    size              = board.size
    largest           = flattened.max
    nonempty          = flattened.select(&.>(0))
    empty_score       = flattened.sum / size.to_f
    maxpos            = {:x => 0, :y => 0}
    emt, mon, smt, hc = 0, 0, 0, 0
    bias              = 0

    # get largest cell coords and give a bonus to largest in corner
    size.times { |y| size.times { |x| (maxpos[:x] = x) && (maxpos[:y] = y) if board[y][x] == largest } }
    hc = largest * largest if {0, size - 1}.includes?(maxpos[:x]) && {0, size - 1}.includes?(maxpos[:y])

    size.times do |y|
      size.times do |x|
        cell  = board[y][x]

        (emt += empty_score) && next if cell == 0 # give empty cells a large bonus and move to next cell

        bias += cell * (x+1) * (y+1)

        mon  -= 0.4 * {x, size - x}.min * cell    # penalty for large values not near horizontal border
        mon  -= 0.4 * {y, size - y}.min * cell    # penalty for large values not near vertical border
        mon  -= 0.1 * (x - maxpos[:x]).abs * cell # penalty for large values not near largest value in x axis
        mon  -= 0.1 * (y - maxpos[:y]).abs * cell # penalty for large values not near largest value in x axis

        smt  -= 0.25 * (cell - (y > 0            ? board[y-1][x] : cell)).abs # top of current
        smt  -= 0.25 * (cell - (y < size - 1     ? board[y+1][x] : cell)).abs # down of current
        smt  -= 0.25 * (cell - (l = x > 0        ? board[y][x-1] : cell)).abs # left of current
        smt  -= 0.25 * (cell - (r = x < size - 1 ? board[y][x+1] : cell)).abs # right of current
      end
    end

    {b * bias, e * emt, c * hc, d ** diff.abs, m * mon, s * smt}.sum.abs
  end

  def merge_in(direction, board, insert = false)
    initial = board.flatten.sum
    board   = case direction
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

    {board, board.flatten.sum - initial}
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

