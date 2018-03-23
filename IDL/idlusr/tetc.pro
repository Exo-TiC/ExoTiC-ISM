;--------  tetc.pro = Test etc  ----------
;	R. Sterner, 1995 Feb 9

	pro tetc

	t = etc(0)
	for f = 0., 1, .05 do begin
	  t = etc(f,/status,delta=5)
	  wait,1
	endfor

	return
	end
