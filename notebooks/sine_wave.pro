pro sine_wave

; Some plotting black magic because IDL is crazy
!p.background=16777215L
!p.color=0L

; Create test data
x = (FINDGEN(200) / 20) - 5
arg_true = 3
ph_true = !DPI + !DPI/3
sigma_true = 0.8
err_true = 1.0   ; RANDOMN uses an std=1, so I'l stick to that

y = arg_true * SIN(x + ph_true)
y = y + RANDOMN(seed, 200)

; Plot test data
s = plot(x, y, SYMBOL='dot', LINESTYLE='none', TITLE='Fake data')

; Prepare fitting with MPFIT
fa = {X:x, arg:arg_true, ph:ph_true}
parinfo = REPLICATE({value:0.D, fixed:0, limited:[0,0], limits:[0.D,0]}, 2)

; Perform fit
result = MPFIT('custom_sine', functargs=fa, BESTNORM=bestnorm, COVAR=covar, PERROR=perror, $
                PARINFO=parinfo, niter=niter, maxiter=maxiter, status=status, Nfree=nfree)


END


FUNCTION custom_sine, x, arg, ph
y = arg * SIN(x + ph)
return, y

END