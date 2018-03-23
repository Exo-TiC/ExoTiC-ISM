;###########################################################################
;  Was to be used to build a byte array with a given set of variables
;  But a simple array with the bytes of each variable concatenated is not
;  enough for more than scalars since array dimensions would need to be
;  handled in some way.  Skip this for now.
;###########################################################################
;  bytstack.pro = Write and read a set of variables to and from a byte buffer.
;  R. Sterner, 2007 Dec 13

	pro bytstack, init=init,pop=pop,push=push, $
	  outstack=buffout,outtype=typout, $
	  instack=buffin,intype=typin, $
	  v1,v2,v3,v4,v5,v6,v7,v8,v9, help=hlp

	common bytstack_com, buff, typ, flag, tmp1, tmp2, tmp3

	if keyword_set(hlp) then begin
	  print,' Write and read a set of variables to and from a byte buffer.'
	  print,' bytstack, v1, v2, ..., v9'
	  print,'   v1, ... = Input or output variables.   in,out'
	  print,' Keywords:'
	  print,'   /INIT Initialize buffer (clear any old, start new).'
	  print,'   /PUSH push given variables onto buffer.'
	  print,'   /POP  pop previously pushed variables off buffer.'
	  print,'     May push or pop one or more variables at a time.'
	  print,'     Variables are popped in reverse order from push:'
	  print,'       bytstack,/push,aa,bb,cc'
	  print,'       bytstack,/pop,cc,bb,aa'
	  print,'   OUTSTACK=buff  Return current byte buffer.'
	  print,'   OUTTYPE=typ    Return current data type list.'
	  print,'     Used after pushing variables to get the built byte array.'
	  print,'   INSTACK=buff   Set current byte buffer.'
	  print,'   INTYPE=typ     Set current data type list.'
	  print,'     Used to set byte array to extract (pop) variables.'
	  print,' Notes: Intended puropse is to build a byte array containing'
	  print,'   a set of variables, and then be able to extract them.'
	  return
	endif

	if n_elements(buff) eq 0 then buff=[0B]
	if keyword_set(init) eq 0 then buff=[0B]
	if n_elements(buffin) ne 0 then buff=buffin
	if n_elements(typin) ne 0 then typ=typin

	if keyword_set(push) then begin
	  

	endif
