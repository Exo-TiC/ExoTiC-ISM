;-----------------------------------------------------------
;  ellipsoid_int_demo.pro = Demo for ellipsoid_int.pro
;  R. Sterner, 2004 Aug 31
;       R. Sterner, 2010 May 04 --- Converted arrays from () to [].
;-----------------------------------------------------------

	pro ellipsoid_int_demo

	;------------------------------------------
	;  Set up parameters
	;  Center of planet at (0,0,0).
	;------------------------------------------
	a = 3000.		; Semimajor and seminor axes
	b = 2500.		; of planet.  Very flattened.

	x1 = 5000.D0		; Spacecraft position.
	y1 = 0.D0
	z1 = 0.D0
	sp = [x1,y1,z1]		; Pack up as a vector.
	vw = [-1.,.2,.2]	; Look direction vector.
	rd = 18.			; Footprint radius (deg).
	tn = tan(rd/!radeg)	; Tangent of radius.
	n = 200			; # points around sensor field.

	ang = maken(0.,2*!pi,n)	; Angles around sensor field.
	sn = sin(ang)
	cs = cos(ang)

	;------------------------------------------
	;  Compute sensor vectors
	;  Gives (x,y,z) for points around a
	;  circular field of view of radius rd.
	;------------------------------------------
	u0 = unit(-sp)		; Unit vector toward planet center.
	u1 = unit(vw)		; Unit vector in view direction.
	v0 = total(u0*u1)*u1	; Component of -sp along view direction.
	u2 = unit(u0 - v0)	; Unit vector perp to u1.
	u3 = crossp(u1,u2)	; Unit vector perp to u1 and u2.
	b1 = tn*u2		; Basis vector 1.  Of sensor field.
	b2 = tn*u3		; Basis vector 2.

	x2 = sp[0] + u1[0] + b1[0]*cs + b2[0]*sn
	y2 = sp[1] + u1[1] + b1[1]*cs + b2[1]*sn
	z2 = sp[2] + u1[2] + b1[2]*cs + b2[2]*sn

	;------------------------------------------
	;  Find intersections on ellipsoid
	;------------------------------------------
	ellipsoid_int,x1,y1,z1,x2,y2,z2,a,b,xi,yi,zi, $
	  flag=flag,lat=lat,lng=lng,/refresh
	;------  Keep results only when they intersect surface  ----
	w = where(flag gt 0)
	lat = lat[w]
	lng = lng[w]
	xi = xi[w]
	yi = yi[w]
	zi = zi[w]

	;------------------------------------------
	;  Plot (on Earth map just for fun)
	;------------------------------------------
	map_set, /cont
	wshow
	plots,lng,lat,col=255, psym=3

	end
