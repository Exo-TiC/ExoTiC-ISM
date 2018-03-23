	function cholesky1, b

	if n_elements(b) eq 1 then return,sqrt(b)
	alpha = b[0,0]
	v = b[1:*,0]
	b1 = b[1:*,1:*]
	b11 = b1 - v#transpose(v)/alpha
	cholesky, b11, g1
	return, g1
	end

	pro cholesky, b, g
	g1 = cholesky1(b)
	if n_elements(b) eq 1 then begin
	  g = g1
	  return
	endif
	alpha = b[0,0]
	v = b[1:*,0]
	g = b*0
	t = sqrt(alpha)
	g[0,0] = t
	g[1:*,0] = v/t
	g[1,1] = g1

	end
