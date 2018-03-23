;-------  spawn2.pro = A version of spawn that uses a file to capture results.
;	R. Sterner, 1995 Dec 11

	pro spawn2, cmd, results, count=count, _extra=extra, help=hlp

	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' A version of spawn that uses a file to capture results.'
	  print,' spawn2, cmd, [results]'
	  print,'   cmd=txt      Command to spawn.                    in'
	  print,'   results=res  Returned array of resulting lines.   out'
	  print,' Notes: sometimes the results of a command are visible'
	  print,'   on the screen but cannot be captured by spawn and returned.'
	  print,' This routine directs the results to a file and then reads'
	  print,' them back to be returned.  The operation is close but not'
	  print,' identical to spawn.'
	  return
	endif

#######################################################
#	Need to find an unused file name (instead of spawn2.tmp)
#	Modify getfile to allow optional delete after read.
#######################################################

	spawn, cmd+'>spawn2.tmp', _extra=extra
	results = getfile('spawn2.tmp')
	count = n_elements(results)

	return
	end
