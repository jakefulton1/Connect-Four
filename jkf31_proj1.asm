.data
welcome: .asciiz "Welcome to Connect-4, the MIPS version, Jake Fulton edition :D\nThis is a 2 player game, each player will take turns placing a token.\nThe objective is to create a line of 4 consecutive tokens.\n"
askChar: .asciiz ", what would you like your token to look like? Enter only one symbol.\nIf you're unsure, consider entering * or + \n"
one: .asciiz "*"
two: .asciiz "+"
indent: .asciiz "\n"
luck: .asciiz "\nGood luck!\n"
strTurn1: .asciiz "Player "
strTurn2: .asciiz ", it's your turn.\n"
askColumn: .asciiz "Select a column to play. Must be between 0 and 6\n"
badGuess: .asciiz "That play is _invalid. Try again\n"
full: .asciiz "That column is full. Try again\n"
gridTop: .asciiz " 0 1 2 3 4 5 6\n"
line: .asciiz "|"
lastLine: .asciiz "|\n"
empty: .asciiz "_"
win1: .asciiz "Congratulations player "
win2: .asciiz ". You won!"
tie: .asciiz "Game over, it's a tie!\nHow did neither of you manage to win?" 
replay: .asciiz "\nWould you like to play again?\nEnter 1 if yes, and 0 if not. "
replayAgain: .asciiz "Please only enter 1 or 0."


matrix: .word 0:42 #array of 42 elements, which is a 6x7 matrix because I say so
turn: .word 1 #keeps track of whose turn it is, is either 1 or 2
turnCounter: .word 0 #keeps track of number of turns to detect a tie and end the game if necessary
.globl main
.text
calc_elem_addr:
#This function finds the address of an element given a row number (a0) and a column number (a1)
	push ra
	la t0, matrix #address of matrix
	move t1, a0 #row index (i)
	move t2, a1 #column index (j)
	mul v0, t1, 28 #row address = [(row index) * (size of each row(4 bytes * 7 columns = 28 bytes))] + (matrix address)
	add v0, v0, t0
	mul t1, t2, 4 #element address = [column index * 4bytes] + row address
	add v0, v0, t1
	pop ra 
	jr ra

prompting: #System.out.println(askColumn); v0 = scanner.nextInt();
	push ra
	li v0 4
	la a0, askColumn
	syscall
	li v0, 5
	syscall
	move a1, v0
	j check_move	
	
check_move: #if (a1 <= 0) {_invalid();} if (a1 >= 6) {_invalid();} 
#this function checks if the inputted col is >0 & <6 (a1 holds the column number) 
	bltz a1, _invalid #first check that the move is valid
	bgt a1, 6, _invalid
	#now start from the bottom of the column and find an open space in check_column
	li a0 6 
	j check_column
		
	_invalid: #System.out.println(badGuess); prompting();
		li v0 4
		la a0, badGuess
		syscall
		j prompting
		
check_column: #for (int i = 5; i >= 0; i--) {if (matrix[a0][a1] == empty) {place_token();}} if(none were empty) {_full();}
	#a0 holds the number row being checked, a1 holds the column number
	sub a0, a0, 1
	bltz a0, _full
	jal calc_elem_addr #get the address being checked and store the value in t0
	lw s0, 0(v0)
	move s1, v0
	push s1
	beq s0, 0, place_token
	pop s1
	beq s0, 1, check_column
	beq s0, 2, check_column
	_full: #System.out.println("That column is full. Try again");
		li v0 4
		la a0, full
		syscall
		pop ra
		j prompting
		
place_token:  #this function does matrix[j][k] = turn; 	if (turn == 1) {turn = 2;} else {turn = 1;}
	pop s1 
	lw t1, turn
	sw t1, 0(s1) #place the token at the address in the matrix stored in s1
	lw t0, turnCounter
	add t0, t0, 1 #increment the turnCounter
	sw t0, turnCounter
	beq t1, 1, _change_to_p2 #these two functions switch the turn so the other player can play
	beq t1, 2, _change_to_p1
	_change_to_p2:
		add t1, t1, 1
		sw t1, turn
		pop ra
		jr ra
	_change_to_p1:
		sub t1, t1, 1
		sw t1, turn
		pop ra
		jr ra
begin_print: #System.out.println(gridTop); print_grid();
	li v0 4 #print the top of the grid
	la a0, gridTop
	syscall
	li a0 0 #initialize the indexes of row (a0) and column (a1) to print
	li a1 -1
	push ra
	j print_grid

print_grid: #This function and its subfunctions do what's described in the following java code
#for (int i = 0; i <=5; i++) 
	#{for (int j = 0; j <=6; j++) {System.out.println(matrix[i][j]);}}
	add a1, a1, 1 #increment column
	bgt a1, 6, _new_row #if col > 6, branch to _new_row
	move t0, a0
	li v0 4
	la a0, line
	syscall
	move a0, t0
	jal calc_elem_addr
	lw t0, 0(v0)
	beq t0, 0, _print_empty
	beq t0, 1, _print_one
	beq t0, 2, _print_two
	
	_new_row: 
		add a0, a0, 1
		move t0, a0
		li v0 4 #print the last line of the row then 
		la a0, lastLine
		syscall
		move a0, t0
		bgt a0, 5, _end_print
		li a1 -1
		j print_grid
		
	_print_empty:
		move t0, a0
		li v0 4
		la a0, empty
		syscall
		move a0, t0
		j print_grid
	_print_one:
		move t0, a0
		li v0 4
		la a0, one
		syscall
		move a0, t0
		j print_grid
	_print_two:
		move t0, a0
		li v0 4
		la a0, two
		syscall
		move a0, t0
		j print_grid
			
	_end_print:
		pop ra
		jr ra

check_win: #This function calls 4 main subfunctions, _check_horizontal, _check_vertical, _check_diagonal1, and _check_diagonal2
#_check_horizontal(); _check_vertical(); _check_diagonal1(); _check_diagonal2();	
	push ra
#before _check_horizontal, initialize row and col values to be the bottom left of the matrix (a0 and a1), find the first 
#address (s0), reset the streak (s3), and I start by checking if player 1 won so I store 1 in s2
	li a0 5 
	li a1 0
	jal calc_elem_addr 
#I don't push or pop any of the s registers when I call calc_elem_addr in the check_win function because 
#I don't care if they're rewritten yet. I will push and pop them in check_win's subfunctions because there, I do care
	move s0, v0
	li s2 1
	li s3 0
	jal _check_horizontal #check for horizontal, vertical, and diagonal wins
	li a0 5 
	li a1 0
	jal calc_elem_addr
	move s0, v0
	li s2 1
	li s3 0
	jal _check_vertical
	li a0 3 
	li a1 0
	jal calc_elem_addr
	move s0, v0
	li s2 1
	li s3 0 
	jal _check_diagonal1 #_check_diagonal1 checks the diagonal wins with positive slopes
	li a0 5
	li a1 3
	jal calc_elem_addr
	move s0, v0
	li s2 1
	li s3 0
	jal _check_diagonal2 #_check_diagonal2 checks the diagonal wins with negative slopes
	lw t0, turnCounter 
	beq t0, 42, _tie_game #now check if the game has ended in a tie
	pop ra	
	jr ra #if the game's still going, return to main
	
	_check_horizontal: #s1 = matrix[s0] if (s1 == s2) {_next_hori_case();} else {s0 += 4; if (s3 == 4) {_game_won();} else _check_horizontal();}
#s0 holds the address being checked, s1 holds the contents of s0, a1 holds the starting column of the case being checked, 
#s2 holds the number player being checked, and s3 holds the current streak of tokens in a row 
		push ra
		lw s1, 0(s0)
		bne s1, s2, _next_hori_case
		add s0, s0, 4 #for row j and col k, look at [j][k+1] (one column to the right)
		add s3, s3, 1
		beq s3, 4, _game_won
		pop ra
		j _check_horizontal
		_next_hori_case: #a1++; s0 = calc_elem_addr(a0, a1); if (a0 > 3) _next_row(); else {s3 = 0; _check_horizontal();}
			add a1, a1, 1
			push s0
			push s1
			push s2
			push s3
			jal calc_elem_addr
			pop s3
			pop s2
			pop s1
			pop s0
			move s0, v0
			li s3 0
			bgt a1, 3, _next_row
			pop ra
			j _check_horizontal
		_next_row: #a0--; if (a0<=0) _end_check_horizontal(); else {a1 = 0; s0 = calc_elem_addr(a0, a1) _check_horizontal();}
			sub a0, a0, 1
			bltz a0, _end_check_horizontal
			li a1 0
			push s0
			push s1
			push s2
			push s3
			jal calc_elem_addr
			pop s3
			pop s2
			pop s1
			pop s0
			move s0, v0
			pop ra
			j _check_horizontal
		_end_check_horizontal: #if(s2 == 1) {_reset_check_horizontal();} else {go to return address back in check_win}
			beq s2 1 _reset_check_horizontal
			pop ra
			jr ra
		_reset_check_horizontal:
			#Once it has checked if player one won, reset _check_horizontal so it can check if player two won
			add s2, s2, 1
			li a0 5
			li a1 0
			push s0
			push s1
			push s2
			push s3
			jal calc_elem_addr
			pop s3
			pop s2
			pop s1
			pop s0
			move s0, v0
			li s3 0
			pop ra
			j _check_horizontal
	_check_vertical: #s1 = matrix[s0] if (s1 == s2) {_next_verti_case();} else {s0 -= 28; if (s3 == 4) {_game_won();} else _check_vertical();}
#initial values: a0=5 a1=0 s0=calc_elem_addr(5,0) s2=1 s3=0 
#_check_vertical starts in the bottom left corner
		push ra
		lw s1, 0(s0)
		bne s1, s2, _next_verti_case
		sub s0, s0, 28 #for row j and col k, look at [j-1][k] (one row higher)
		add s3, s3, 1
		beq s3, 4, _game_won
		pop ra
		j _check_vertical
		_next_verti_case: #a0--; s0 = calc_elem_addr(a0, a1); if (a0 < 3) _next_column(); else {s3 = 0; _check_vertical();}
			sub a0, a0, 1
			push s0
			push s1
			push s2
			push s3
			jal calc_elem_addr
			pop s3
			pop s2
			pop s1
			pop s0
			move s0, v0
			li s3 0 #use an s register for s2 and s3 and push before calling calc_elem_addr then pop after calc_elem_addr
			blt a0, 3, _next_column
			pop ra
			j _check_vertical
		_next_column: #a1++; if (a1>6) _end_check_vertical(); else {a1 = 0; s0 = calc_elem_addr(a0, a1) _check_vertical();}
			add a1, a1, 1
			bgt a1, 6, _end_check_vertical 
			li a0 5
			push s0
			push s1
			push s2
			push s3
			jal calc_elem_addr
			pop s3
			pop s2
			pop s1
			pop s0
			move s0, v0
			pop ra
			j _check_vertical
		_end_check_vertical: #if(s2 == 1) {_reset_check_horizontal();} else {go to return address back in check_win}
			beq s2 1 _reset_check_vertical
			pop ra
			jr ra
		_reset_check_vertical: #reset values so _check_vertical can run again and check if player 2 won
			add s2, s2, 1
			li a0 5 
			li a1 0
			push s0
			push s1
			push s2
			push s3
			jal calc_elem_addr
			pop s3
			pop s2
			pop s1
			pop s0
			move s0, v0
			li s3 0
			pop ra
			j _check_vertical
			
	_check_diagonal1: #s1 = matrix[s0] if (s1 == s2) {_next_diag1_case();} else {s0 -= 24; if (s3 == 4) {_game_won();} else _check_diagonal1();}
	#initial values: a0=3 a1=0 s0=calc_elem_addr(3,0) s2=1 s3=0
		push ra
		lw s1, 0(s0)
		bne s1, s2, _next_diag1_case
		sub s0, s0, 24 #for row j and col k, look at [j-1][k+1] (one row up and one column to the right)
		add s3, s3, 1
		beq s3, 4, _game_won
		pop ra
		j _check_diagonal1
		_next_diag1_case: #s0 -= 24; s3 = 0; if(s0 is out of bounds) {_next_line_down();} else {_check_diagonal1();}
			sub s0, s0, 24
			li s3 0
			blt s0, 268501628, _next_line_down #if s0 is out of bounds s0 will be < 0x1001027c and 0x1001027c = 268501628
			pop ra
			j _check_diagonal1
		_next_line_down: #a0++; if (a0 > 5) {_next_line_right1();} else {a1 = 0 s0 = calc_elem_addr(a0, a1) _check_diagonal1();}
			add a0, a0, 1
			bgt a0, 5, _next_line_right1 
			li a1 0
			push s0
			push s1
			push s2
			push s3
			jal calc_elem_addr
			pop s3
			pop s2
			pop s1
			pop s0
			move s0, v0
			pop ra
			j _check_diagonal1
		_next_line_right1: #a1++; if (a1 > 3) {_end_check_diagonal1();} else {a0 = 5; s0 = calc_elem_addr(a0, a1); _check_diagonal1();}
			add a1, a1, 1
			bgt a1, 3, _end_check_diagonal1
			li a0 5
			push s0
			push s1
			push s2
			push s3
			jal calc_elem_addr
			pop s3
			pop s2
			pop s1
			pop s0
			move s0, v0
			pop ra
			j _check_diagonal1
		_end_check_diagonal1: #if (s2 == 1) {_reset_check_diagonal1();} else {go to rerturn address back in check_win} 
			beq s2 1 _reset_check_diagonal1
			pop ra
			jr ra
		_reset_check_diagonal1: #reset all the values so _check_diagonal1 can be run again to see if player 2 won
			add s2, s2, 1
			li a0 3 
			li a1 0
			push s0
			push s1
			push s2
			push s3
			jal calc_elem_addr
			pop s3
			pop s2
			pop s1
			pop s0
			move s0, v0
			li s3 0
			pop ra
			j _check_diagonal1
			
	_check_diagonal2: #s1 = matrix[s0] if (s1 == s2) {_next_diag2_case();} else {s0 -= 32; if (s3 == 4) {_game_won();} else _check_diagonal2();}
	#initial values: a0=5 a1=3 s0=calc_elem_addr(5,0) s2=1 s3=0
		push ra
		lw s1, 0(s0)
		bne s1, s2, _next_diag2_case
		sub s0, s0, 32 #for row j and col k, look at [j-1][k-1] (one row up and one column to the left)
		add s3, s3, 1
		beq s3, 4, _game_won
		pop ra
		j _check_diagonal2
		_next_diag2_case: #s0 -= 32; s3 = 0; if(s0 is out of bounds) {_next_line_right2();} else {_check_diagonal2();}
			sub s0, s0, 32
			li s3 0
			blt s0, 268501628, _next_line_right2 #if s0 is out of bounds s0 will be < 0x1001027c and 0x1001027c = 268501628
			pop ra
			j _check_diagonal2
		_next_line_right2: #a1++; if (a1 > 6) {_next_line_up();} else {a1 = 5 s0 = calc_elem_addr(a0, a1) _check_diagonal2();}
			add a1, a1, 1
			bgt a1, 6, _next_line_up
			li a0 5
			push s0
			push s1
			push s2
			push s3
			jal calc_elem_addr
			pop s3
			pop s2
			pop s1
			pop s0
			move s0, v0
			pop ra
			j _check_diagonal2
		_next_line_up: #a0++; if (a0 > 3) {_end_check_diagonal2();} else {a1 = 6; s0 = calc_elem_addr(a0, a1); _check_diagonal2();}
			sub a0, a0, 1
			blt a0, 3, _end_check_diagonal2
			li a1 6
			push s0
			push s1
			push s2
			push s3
			jal calc_elem_addr
			pop s3
			pop s2
			pop s1
			pop s0
			move s0, v0
			pop ra
			j _check_diagonal2
		_end_check_diagonal2: #if (s2 == 1) {_reset_check_diagonal2();} else {go to the return address back in check_win()}
			beq s2 1 _reset_check_diagonal2
			pop ra
			jr ra
		_reset_check_diagonal2: #Reset all the values so that _check_diagonal2 can be run again and check if player 2 won 
			add s2, s2, 1
			li a0 5
			li a1 3
			push s0
			push s1
			push s2
			push s3
			jal calc_elem_addr
			pop s3
			pop s2
			pop s1
			pop s0
			move s0, v0
			li s3 0
			pop ra
			j _check_diagonal2
		
	_tie_game: #System.out.println(tie + replay); if (scanner.nextInt() == 0) {clear_board();} else {break;} 
		pop ra
		li v0 4
		la a0, tie
		syscall
		j ask_if_replay
		
	_game_won: #System.out.println(win + replay); if (scanner.nextInt() == 0) {clear_board();} else {break;} 
		pop ra
		li v0 4
		la a0, win1
		syscall
		li v0 1
		move a0, s2
		syscall
		li v0 4
		la a0, win2
		syscall 
		j ask_if_replay

ask_if_replay: #System.out.println("~Do you wanna play again?"); v0 = scanner.nextInt() if (v0 == 1) clear_board(); if (v0 == 0) _end_game();
	la a0, replay
	syscall
	li v0 5
	syscall
	beq v0, 1, clear_board
	beq v0, 0, _end_game
	j _ask_replay_again
	_ask_replay_again:
		li v0 4
		la a0, replayAgain
		syscall
		j ask_if_replay
	_end_game: #break;
		li v0 10
		syscall
clear_board: #t0 = address of matrix; _clearing();
	li a0 0
	li a1 0
	jal calc_elem_addr
	move s0, v0
	j _clearing
	_clearing: #while(s0 < 268501836) {matrix[t0] = 0; t0 += 4;} 
		li t0 0
		sw t0, 0(s0)
		add s0, s0, 4
		bgt s0, 268501836, _end_clear #if t0 > 0x10010320, it's out of bounds and 0x10010320 = 268501792
		j _clearing
	_end_clear:
		j main
		
	
main: #System.out.println(welcome + askChar);
li v0 4
la a0, welcome
syscall
la a0, strTurn1
syscall
li v0 1 
lw a0, turn
syscall
li v0 4
la a0, askChar
syscall 
li v0 12 #one = scanner.nextLine();
syscall
sb v0, one
li v0 4
la a0, indent
syscall
la a0, strTurn1
syscall
li v0 1 
li a0 2
syscall
li v0 4
la a0, askChar
syscall 
li v0 12 #two = scanner.nextLine();
syscall
sb v0, two
li v0 4
la a0, luck
syscall
jal begin_print 	#begin_print prints the top label then jumpts to print_grid, which prints the rest of the grid
_main_loop: #while(true) {prompting(); begin_print(); check_win();}
	li v0 4 #print whose turn it is
	la a0, strTurn1
	syscall
	li v0 1
	lw a0, turn
	syscall
	li v0 4
	la a0, strTurn2
	syscall
	jal prompting
	jal begin_print
	jal check_win #the program doesn't end in the main, it either ends in the subfunctions _game_won or _tie_game
	j _main_loop  #both of those subfunctions are inside check_win
	