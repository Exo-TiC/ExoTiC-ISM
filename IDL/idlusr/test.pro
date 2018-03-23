	pro test

	;---  Variable list  ---
	list = ['x1','y1','z1']
	n = n_elements(list)

	;---  Grab these variables from 1 level up  ---
	for i=0,n-1 do begin
	  cmd = list[i] + ' = scope_varfetch(list[i],level=-1,/enter)'
	  err = execute(cmd)
	endfor

	;---  Use these variables in an expression  ---
	help, x1, y1, z1

	end
