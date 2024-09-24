Name: Jake Fulton
Pitt username: jkf31
I am pleased to report that as far as I'm aware, everything functions properly.

For extra credit, I added 2 extra functions to the program. 
	The program asks the user(s) what they want their token to look like, and it asks if they would like to replay they game, and if so, it clears the board and lets 	them play again. Otherwise, it ends the loop properly.

Explaining my program:
The order of the functions and their subfunctions is like this:
main leads to _main_loop -> jal prompting -> j check_move -> ((j check_column) or (branches to _invalid -> j prompting))
check_column -> (j place_token or _full -> prompting) place_token returns to _main_loop

then _main_loop -> jal begin_print -> j print_grid -> jr ra back to _main_loop
then _main_loop -> jal check_win -> jal _check_horizontal -> jr ra to check_win -> jal _check_vertical -> jr ra to check_win
-> jal _check_diagonal1 -> jr ra to check_win -> _check_diagonal2 -> jr ra to check_win -> (branch to _tie_game or jr ra to _main_loop)
after _check_win, _main_loop -> j _main_loop and it continues until someone wins or ties.

Here I'll try to describe the order of the subfunctions in all the subfunctions that check for wins.
_check_horizontal, _check_vertical, _check_diagonal1, and _check_diagonal2 all have the same subfunction structure, although the diagonals
are slightly different.
The main subfunction (for example _check_horizontal) loops and checks if a position is occupied, and increments the streak (s2) if so.
If the position is not occupied or is owned by another player, it calls the next subfunction (for example _next_hori_case)
The next case subfunctions increment to the next possible place someone could get 4 in a row, and if all the possible places are checked, it calls the next subfunction.
In _check_horizontal the next subfunction is _next_row, although it's different for each. This part changes the row so that more cases can be checked.
In the diagonal checks, two subfunctions are used to get to all of the lines, instead of using one like in _check_horizontal and _check_vertical
After these subfunctions, _end_check_(whatever direction) is called. In this subfunction, if it just checked player one, it jumps to 
_reset_check_(this direction), which sets the initial values and jumps to _check_**** again. If it checked player two, it returns back to _check_win.

The following is the full order each subfunction eventually follows as they iterate:

	_check_horizontal->_next_hori_case->_next_row->_end_check_horizontal->_reset_check_horizontal->_check_horizontal

	_check_vertical->_next_verti_case->_next_column->_end_check_vertical->_reset_check_vertical->_check_vertical

	_check_diagonal1->_next_diag1_case->_next_line_down->_next_line_right1->_end_check_diagonal1->reset_check_diagonal1->_check_diagonal1

	_check_diagonal1->_next_diag1_case->_next_line_right2->_next_line_up->_end_check_diagonal1->reset_check_diagonal1->_check_diagonal1
