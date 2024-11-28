class TetrisGame
  def initialize args
    @next_move = 30
    @args = args
    @score = 0
    @game_over = false
    @grid_w = 10
    @grid_h = 20
    @next_piece = nil

    @grid = []
    if @grid.empty?
      (0..(@grid_w - 1)).each do |x|
        @grid[x] = []
        (0..(@grid_h-1)).each do |y|
          @grid[x][y] = 0
        end
      end
    end

    @color_index = {
      # Deep space blue-black for background (softer than pure black)
      black: [16, 24, 32],
      
      # Warm raspberry red (less harsh than pure red)
      red: [232, 53, 98],
      
      # Mint green (pastel but visible)
      light_green: [162, 227, 159],
      
      # Teal (80s inspired)
      green: [32, 178, 170],
      
      # Deep cyan (complementary to the teal)
      dark_green: [0, 141, 151],
      
      # Banana yellow (warm but not harsh)
      yellow: [255, 218, 121],
      
      # Coral orange (80s inspired)
      orange: [255, 127, 80],
      
      # Lavender (soft purple that pops against dark background)
      purple: [230, 190, 255],
      
      # Sky blue (lighter and more playful)
      blue: [135, 206, 235],
      
      # Neutral gray (slightly warmer than pure gray)
      gray: [147, 138, 147]
    }
    select_next_piece
    select_next_piece
  end

  def color(num)
    keys = @color_index.reject { |k, _v| [:black, :gray].include?(k) }.keys
    color = @color_index[keys[num]]
    puts "#{num}: #{color}"
    color
  end

  def box_size
    30
  end

  def render_cube x, y, r, g, b, a=255
    centered_x = grid_x + (x * box_size)
    centered_y = 720 - grid_y - (y * box_size)
    dim_index = 1.05
    @args.outputs.solids << [centered_x, centered_y, box_size, box_size, r, g, b, a]
    @args.outputs.borders << [centered_x, centered_y, box_size, box_size,
                              r * dim_index, g * dim_index, b * dim_index, a * dim_index]
  end

  def render_grid
    for x in 0..(@grid_w-1) do
      for y in 0..(@grid_h-1) do
        if @grid[x][y].zero?
          render_cube x, y, *[197, 196, 195]
        else
          render_cube x, y, *color(@grid[x][y])
        end
      end
    end
  end

  def grid_x
    (1280 - (@grid_w * box_size)) / 2
  end

  def grid_y
    (720 - ((@grid_h - 2) * box_size)) / 2
  end

  def render_grid_border x, y, w, h
    (x..(x + w) -1).each do |i|
      render_cube i, y, *@color_index[:gray]
      render_cube i, y + h - 1, *@color_index[:gray]
    end
    (y..(y + h) -1).each do |i|
      render_cube x, i, *@color_index[:gray]
      render_cube (x + w) - 1, i, *@color_index[:gray]
    end
  end

  def render_background
    @args.outputs.background_color = [12, 23, 34]
    render_grid_border(-1, -1, @grid_w + 2, @grid_h + 2)
  end

  def render_piece piece, piece_x, piece_y
    return unless piece&.length&.positive?

    (0..piece.length - 1).each do |x|
      (0..piece[x].length - 1).each do |y|
        render_cube piece_x + x, piece_y + y, *color(piece[x][y]) if piece[x][y] != 0
      end
    end
  end

  def render_next_piece
    render_grid_border(13, 2, 8, 8)
    centerx = (8 - @next_piece.length) / 2
    centery = (8 - @next_piece[0].length) / 2
    render_piece @next_piece, 13 + centerx, 2 + centery
    @args.outputs.labels << [910, 640, 'Next Up', 10, 255, 255, 255, 255]
  end

  def render_current_piece
    render_piece @current_piece, @current_piece_x, @current_piece_y
  end

  def render
    render_background
    render_grid
    render_current_piece
    render_next_piece
    render_score
  end

  def piece_colliding?(piece, offset_x = 0, offset_y = 0)
    return false if piece.nil?
  
    (0..(piece.length - 1)).each do |x|
      (0..(piece[x].length - 1)).each do |y|
        next unless piece[x][y] != 0
  
        if @current_piece_y + y + offset_y >= @grid_h - 1
          return true
        elsif @grid[@current_piece_x + x + offset_x][@current_piece_y + y + 1 + offset_y] != 0
          return true
        end
      end
    end
    false
  end

  def select_next_piece
    @current_piece = @next_piece
    x = rand(7) + 1
    @next_piece = case x
                  when 1
                    [[x, x],
                     [x, x]]
                  when 2
                    [[x, x, x, x]]
                  when 3
                    [[x, x, x],
                     [0, 0, x]]
                  when 4
                    [[x, x, x],
                     [x, 0, 0]]
                  when 5
                    [[x, x, 0],
                     [0, x, x]]
                  when 6
                    [[0, x, x],
                     [x, x, 0]]
                  when 7
                    [[x, x, x],
                     [0, x, 0]]
                  end

    @current_piece_x = 5
    @current_piece_y = -1
    @game_over = false
  end

  def plant_current_piece
    (0..@current_piece.length - 1).each do |x|
      (0..@current_piece[x].length - 1).each do |y|
        next unless @current_piece[x][y] && @current_piece[x][y] != 0

        @grid[@current_piece_x + x][@current_piece_y + y] = @current_piece[x][y]
      end
    end

    (0..@grid_h - 1).each do |y|
      full = true
      (0..@grid_w - 1).each do |x|
        if @grid[x][y].zero?
          full = false
          break
        end
      end
      next unless full

      @score += 1
      y.downto(1).each do |i|
        (0..@grid_w - 1).each do |j|
          @grid[j][i] = @grid[j][i - 1]
        end
      end
      (0..@grid_w - 1).each do |i|
        @grid[i][0] = 0
      end
    end

    select_next_piece

    return unless piece_colliding?(@current_piece)

    @game_over = true
  end

  def render_score
    @args.outputs.labels << [75, 75, "Score: #{@score}", 10, 255, 255, 255, 255]
    @args.outputs.labels << [75, 200, 'GAME OVER', 30, 255, 255, 255, 255] if @game_over
  end

  def tick
    iterate
    render
  end

  def rotate_current_piece_left
    @current_piece = @current_piece.transpose.map(&:reverse)
    if (@current_piece_x + @current_piece.length) > @grid_w
      @current_piece_x = @grid_w - @current_piece.length
    end
  end

  def can_rotate?
    rotated = @current_piece.transpose.map(&:reverse)
    rotated_x = @current_piece_x + rotated.length
    return piece_colliding?(rotated) == false && rotated_x <= @grid_w
  end

  def iterate
    if @game_over
      $gtk.reset if @args.inputs.keyboard.key_down.space
      return
    end
    @current_piece_x -= 1 if can_go?(:left)
    @current_piece_x += 1 if can_go?(:right)

    @next_move -= 20 if can_go?(:down)
    rotate_current_piece_left if @args.inputs.keyboard.key_down.space && can_rotate?

    @next_move -= 1
    return unless @next_move <= 0

    plant_current_piece if piece_colliding?(@current_piece)
    @current_piece_y += 1
    @next_move = 30
  end

  def can_go?(direction, k = @args.inputs.keyboard)
    case direction
    when :left
      k.key_down.left && @current_piece_x.positive? && piece_colliding?(@current_piece, -1, 0) == false
    when :right
      k.key_down.right && @current_piece_x < @grid_w - @current_piece.length &&
        piece_colliding?(@current_piece, 1, 0) == false
    when :down
      k.key_down.down || k.key_held.down
    end
  end
end


def tick(args)
  args.state.game ||= TetrisGame.new args
  args.state.game.tick
end
