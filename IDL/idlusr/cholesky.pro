	;----------------------------------------------------------------------
	;  cholesky.pro = Compute square-root of a positive definte
	;    hermitian matrix
	;  A. Najmi, R. Sterner, 2005 Oct 25
        ;  R. Sterner, 2010 Apr 30 --- Converted arrays from () to [].
	;----------------------------------------------------------------------


	;--------------------------------------------------------------
	;  Internal function to Compute b11 and return its Square-root.
	;--------------------------------------------------------------
	function cholesky1, b

	if n_elements(b) eq 1 then return,sqrt(b)  ; 1x1 matrix.

	alpha = b[0,0]		; Grab parts from b and compute b11.
	v = b[1:*,0]
	b1 = b[1:*,1:*]
	b11 = b1 - v#transpose(v)/alpha

	cholesky, b11, t	; Square-root of b11.

	return, t

	end

	;--------------------------------------------------------------
	;  Compute square-root of a Positive Definite Hermitian matrix
	;
	;--------------------------------------------------------------
	pro cholesky, b, g, check=check, error=err, quiet=quiet, help=hlp

	if keyword_set(hlp) then begin
	  print,' Compute square-root of a Positive Definite Hermitian matrix.'
	  print,' cholesky, b, g'
	  print,'   b = Incoming matrix.   in'
	  print,'   g = Square root of b.  out'
	  print,'       b = g#transpose(g)'
	  print,' Keywords:'
	  print,'   /CHECK check that incoming matrix is:'
	  print,'     A matrix, Positive Definite, and Hermitian.'
	  print,'   ERROR=err Error flag: 0=ok, 1=not a matrix,'
	  print,'      2=not PD, 3=not Hermitian.'
	  print,'   /QUIET do not display error messages.'
	  return
	endif

	;----------------------------------------------------
	;  Check incoming matrix to make sure it is:
	; 
	;    1. A matrix.
	;
	;    2. Positive Definite
	; 
	;       The definition of positive definiteness is equivalent to
	;       the requirement that the determinants associated with all
	;       upper-left submatrices are positive.
	;       http://mathworld.wolfram.com/PositiveDefiniteMatrix.html
	; 
	;    3. Hermitian
	; 
	;       Matrix equals its conjugate transpose.
	;----------------------------------------------------
	if keyword_set(check) then begin
	  ;------  A matrix?  ------
	  if dimsz(b,1) eq 0 then begin
	    if not keyword_set(quiet) then begin
	      print,' Error in cholesky: Given value is not a matrix.'
	    endif
	    err = 1
	    return
	  endif
	  ;------  Positive Definite?  ------
	  n = dimsz(b,1)
	  for i=1,n-1 do begin
	    if determ(b[0:i,0:i]) le 0 then begin
	      if not keyword_set(quiet) then begin
	        print,' Error in cholesky: Given matrix not Positive Definite.'
	      endif
	      err = 2
	      return
	    endif
	  endfor
	  ;------  Hermitian?  --------
	  if min(b eq transpose(conj(b))) lt 1 then begin
	      if not keyword_set(quiet) then begin
	        print,' Error in cholesky: Given matrix is not Hermitian.'
	      endif
	      err = 3
	      return
	  endif
	endif
	err = 0

	;----------------------------------------------------
	;  Find square-root of b11
	;----------------------------------------------------
	g1 = cholesky1(b)

	;----------------------------------------------------
	;  All done if at the smallest submatrix
	;----------------------------------------------------
	if n_elements(b) eq 1 then begin
	  g = g1
	  return
	endif

	;----------------------------------------------------
	;  Now have square-root of b11, build and return
	;  square-root of original matrix b.
	;----------------------------------------------------
	alpha = b[0,0]		; First element.
	v = b[1:*,0]		; Top row except 1st element.
	g = b*0			; Array of same type and size.
	t = sqrt(alpha)
	g[0,0] = t 		; First element of SqRt.
	g[1:*,0] = v/t		; Top row (except 1st element) of SqRt.
	g[1,1] = g1		; Square-root of b11.

	end
