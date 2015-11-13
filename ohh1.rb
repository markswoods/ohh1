$LOAD_PATH << '.'

# Global Definitions
$debug = false
$verbose = true
$RED = "\x1b[37;41mR"
$BLUE = "\x1b[37;44mB"
$EMPTY = "\x1b[0m-"
$NORMAL = "\x1b[0m"

def verbose(text)
  print(text) if $verbose 
end

def debug(text)
  print(text) if $debug 
end

def invert(char)
  char == "B" ? "R" : "B"
end

def showboard(board)
  text = ""
  board.each do |row|    
    text += row.join 
    if STDOUT.isatty
      text = text.gsub("R", $RED).gsub("B", $BLUE).gsub("-", $EMPTY) + "#{$NORMAL}\n"
    else
      text = text + "\n"
    end
  end
  return text
end

def fillRow(row, color)
  for i in 0..row.length - 1
    if row[i] == "-"
      row[i] = color
    end
  end
  row 
end

def workTheRow(row)
  changed = false
  debug("#{row.join.gsub("R", $RED).gsub("B", $BLUE).gsub("-", $EMPTY)}#{$NORMAL}")
  ops = ""
  # Looking for XX-
  for n in 0..row.length-3
    if row[n] != "-" && row[n] == row[n+1] && row[n+2] == "-"
      row[n+2] = invert(row[n])  # flip to opposite color
      changed = true
      ops << "XX- "
    end
  end
  # Looking for -XX
  for n in 2..row.length-1
    if row[n] != "-" && row[n] == row[n-1] && row[n-2] == "-"
      row[n-2] = invert(row[n])  # flip to opposite color
      changed = true
      ops << "-XX "
    end
  end
  # Looking for X-X
  for n in 0..row.length-3
    if row[n] != "-" && row[n] == row[n+2] && row[n+1] == "-"
      row[n+1] = invert(row[n])  # flip to opposite color
      changed = true
      ops << "X-X "
    end
  end
  # Looking for n/2 of same color in row
  if row.include?("-") 
    if row.count("B") == row.length/2 
      row = fillRow(row, "R")
      changed = true
      ops << "fillR "
    end
    if row.count("R") == row.length/2
      row = fillRow(row, "B")
      changed = true
      ops << "fillB "
    end
  end
  # Include Step #4 here
  # If four spaces open and three are in a row and must be same color, three adjacent cannot be same
  # so the separate space is the required color. 
  if row.count("-") == 4
    blue = row.count("B")
    red = row.count("R")
    if row.join.include?("---") && !row.join.include?("----")
      if row.length/2 - red == 3
        row[row.join.index(/(^-[RB]|[RB]-[RB]|[RB]-$)/)+1] = "R" # Set loner to Red 
        changed = true
        ops << "1/2R "       
      end
      if row.length/2 - blue == 3
        row[row.join.index(/(^-[RB]|[RB]-[RB]|[RB]-$)/)+1] = "B" # Set loner to Blue        
        changed = true
        ops << "1/2B "       
      end
    end
    # If three spaces open and two are in a row and must be same color, three adjacent cannot be same
    # so the separate space is the required color. 
  end
  if row.count("-") == 3
      blue = row.count("B")
      red = row.count("R")
      if row.length/2 - red == 2
        if row.join.index(/R--/) != nil  # One of these is going to be Red, the other cannot be
          if row.join.index(/^-[RB]/) != nil
            row[0] = "R"
            changed = true
            ops << "1/2R "       
          else
            if row.join.index(/[RB]-$/) != nil
              row[row.length-1] = "R"
              changed = true
              ops << "1/2R "       
            else
              if row.join.index(/[RB]-[RB]/) != nil
                row[row.join.index(/[RB]-[RB]/)+1] = "R"
                changed = true
                ops << "1/2R "       
              end
            end
          end
        end
      end
      if row.length/2 - blue == 2
        if row.join.index(/B--/) != nil  # One of these is going to be Blue, the other cannot be
          if row.join.index(/^-[RB]/) != nil
            row[0] = "B"
            changed = true
            ops << "1/2B "       
          else
            if row.join.index(/[RB]-$/) != nil
              row[row.length-1] = "B"
              changed = true
              ops << "1/2B "       
            else
              if row.join.index(/[RB]-[RB]/) != nil
                row[row.join.index(/[RB]-[RB]/)+1] = "B"
                changed = true
                ops << "1/2B "       
              end
            end
          end
        end
      end      
    end   
  
  text = row.join.gsub("R", $RED).gsub("B", $BLUE).gsub("-", $EMPTY)
  debug("\t#{text}#{$NORMAL}\t#{ops}\n")
  
  return changed 
end

def findBestRow(board)
  # Looking for the row with the least empty spaces
  counts = board.collect.with_index {|row, index| [index, row.count("-")]}
  counts = counts.select {|c| c[1] > 0}
  min = counts.min { |a, b| a[1] <=> b[1] } 
  return min[0]
end

def rowsValid(board, orientation)
  # 3 in a row?
  board.each do |row|
    if row.index(/(RRR|BBB)/) != nil
      verbose("Found 3 consecutive same color blocks in #{orientation} #{row}\n")
      return false
    end
  end
  
  # duplicate rows? Must be complete rows, not partial
  checkRows = board.select {|row| row.count("-") == 0}
  if checkRows.detect {|row| checkRows.count(row) > 1} != nil
    verbose("Found duplicate #{orientation}\n")
    return false
  end
  return true
end

def boardValid(board)
  verbose("Validating solution...\n")
  if !rowsValid(board, "row") 
    return false
  end
  
  tboard = board.transpose
  if !rowsValid(tboard, "column")
    return false
  end
    
  return true
end

def doMoves(board)
  # This is the loop controlling steps 1 - 4
  moreMoves = true
  pass = 1
  while moreMoves 
    changed = false
    debug("\nRow Pass: #{pass}\n")
    board.each do |row|
      changed = changed | workTheRow(row)
    end   # Row pass complete

    debug("\nColumn Pass: #{pass}\n")  
    tboard = board.transpose    # Transpose board to reuse workTheRow routine
    tboard.each do |row| 
      changed = changed | workTheRow(row)
    end # Column pass complete
    board = tboard.transpose    # Return orientation

    debug("\nPass #{pass}, Changed: #{changed}\n")
  
    if changed 
      #showboard(board) 
    else
      moreMoves = false
    end

    pass += 1
  end   # Board pass complete

  # When we get here, we've done all we can. It's time to make a guess, a hypothesis, and
  # proceed based on that...
  # Create copy of board, save first empty cell position, go recursive on this problem!
  hboard = board.collect {|row| row.clone} 
  while hboard.flatten.count("-") != 0  # Not Solved!
  
    # Select a row/column with least empty blocks, tie-breaker to any with n/2 - 1 of same color
    rindex = findBestRow(hboard)

    cboard = hboard.transpose
    cindex = findBestRow(cboard)

    if hboard[rindex].count("-") <= cboard[cindex].count("-")
      col = hboard[rindex].index("-") 
      row = rindex
    else
      row = cboard[cindex].index("-")
      col = cindex
    end
    hboard[row][col] = "R"  # Applying the hypothesis

    # Halt for user review before continuing on...
    debug("Best Row: #{rindex}, Best Column: #{cindex}\n")
    verbose("Hypothesis: #{row}, #{col} = R\n")
    verbose("Original\n" + showboard(board))
    verbose("Hypothesis\n" + showboard(hboard))

    hboard = doMoves(hboard)

    if hboard.flatten.count("-") == 0 
      if !boardValid(hboard)
        verbose("\nRevise hypothesis: #{row}, #{col} = B\n")
        # Reverse selected cell
        board[row][col] = "B"
        verbose("Revised hypothesis\n" + showboard(board))
        hboard = doMoves(board)
      end        
    end
  end  

  return hboard
end

# Outline:
# Read input file containing a board to start with
# Create an array of arrays to hold the board. Consider using binary values
# 0 = Red, 1 = Blue (Easier to flip)
# Work through board by rows and then columns repeatedly until there are no more moves to make
# 1. If two consecutive blocks are same, surround with an opposite color block
# 2. If two blocks of same color are separated by one space, fill space with opposite color
# 3. If n/2 blocks in a row/column are the same color, then remaining empty spaces must be opposite
# 4. If three spaces remain and two must be the same color but that would result in three in a row, then
#    the third space must be that color while the two adjacent are of each color.
# When there are no more moves to make AND the board is not yet complete, make a copy of the board, then
# pick a row or column with the least empty spaces.
# If there are n/2-1 blocks of the same color, then make first empty the same color, and store that
# cell's position and color.
# Now go back and repeat steps 1-5 - checking for duplicate rows and columns as you go.
# If a violation is found (three in a row, dup row or col), discard the copy, reverse the color of the 
# selected cell and continue (the hypothesis was invalidated so the opposite must be true).

fname = ARGV[0]
if fname == ""
  fname = "board.txt"
end

board = Array.new
file = File.open(fname).readlines.each do |line|
  line.chomp!  
  board.push(line.split(""))
end

verbose("Board Size: #{board.length} x #{board.length}\n")
verbose("initial board\n" + showboard(board))

board = doMoves(board)

verbose("Solved!\n")

print(showboard(board))