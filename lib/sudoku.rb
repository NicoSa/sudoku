class Sudoku
  
  COLUMN_SIZE = 9
  SIZE = COLUMN_SIZE * COLUMN_SIZE
  BOX_SIZE = Math.sqrt(COLUMN_SIZE)

  attr_reader :cells
  private :cells

  def initialize(args)
    raise "Wrong number of values given, #{SIZE} expected" unless args.length == SIZE
    initialize_cells(args)
  end

  def to_s
    @cells.map(&:value).join
  end

  def to_board
    # this is arguably stupid
    rows = @cells.each_slice(COLUMN_SIZE).inject([]) do |strings, row|
      strings << row.each_slice(BOX_SIZE).map{|a| a.map(&:to_s).join(" ")}.join(" | ")
    end
    row_length = rows.first.length    
    separator = "\n#{'-' * row_length}\n"
    rows.each_slice(BOX_SIZE).map{|s| s.join("\n")}.join(separator)
  end

  def solved?
    @cells.all? {|cell| cell.solved? }
  end

  def solve!        
    outstanding_before, looping = SIZE, false
    while !solved? && !looping
      try_to_solve!
      outstanding         = @cells.count {|c| c.solved? }
      looping             = outstanding_before == outstanding
      outstanding_before  = outstanding
    end
    try_harder unless solved?
  end

private

  def replicate!
    self.class.new(self.to_s)
  end

  def steal_solution(source)
    initialize_cells(source.to_s)        
  end

  def try_harder
    blank_cell = @cells.reject(&:solved?).first
    blank_cell.candidates.each do |candidate|
      blank_cell.assume(candidate)
      board = replicate!
      board.solve!
      steal_solution(board) and return if board.solved?
    end
  end

  def try_to_solve!
    @cells.each do |cell|        
      cell.solve! unless cell.solved?                
    end      
  end

  def rows(cells)
    (0..COLUMN_SIZE-1).inject([]) do |rows, index|
      rows << cells.slice(index * COLUMN_SIZE, COLUMN_SIZE)
    end
  end

  def columns(cells, rows)
    (0..COLUMN_SIZE-1).inject([]) do |cols, index|
      cols << rows.map{|row| row[index]}
    end
  end

  def boxes(rows)    
    (0..BOX_SIZE-1).inject([]) do |boxes, i|
      relevant_rows = rows.slice(BOX_SIZE * i, BOX_SIZE)
      boxes + relevant_rows.transpose.each_slice(BOX_SIZE).map(&:flatten)       
    end        
  end
  
  def initialize_cells(digits)
    cells       = digits.split('').map {|v| Cell.new(v) }    
    rows        = rows(cells)
    columns     = columns(cells, rows)
    boxes       = boxes(rows)
    [columns, rows, boxes].each do |slices|
      slices.each {|group| group.each{|cell| cell.add_slice(group)}}
    end
    @cells = cells
  end

end