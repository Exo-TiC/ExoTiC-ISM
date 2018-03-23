;-----  ellipsoid_int.pro = Intersection of a line with an ellipsoid  ----
;	R. Sterner, 2000 Aug 7
;	R. Sterner, 2004 Aug 31 --- Added /DEBUG.  Rederived and fixed.
;       R. Sterner, 2010 May 04 --- Converted arrays from () to [].

	pro ellipsoid_int, x1,y1,z1,x2,y2,z2,a,b,xi,yi,zi,  $
	  refresh=refresh, flag=flag, lng=lng, lat=lat, $
	  debug=debug, help=hlp

	common ellipsoid_int_com, aa, bb, aa2, bb2, aabb, $
	  latcor, pi_2, radeg

	if (n_params(0) lt 8) or keyword_set(hlp) then begin
	  print,' Find the intersection of a line with an ellipsoid.'
	  print,' ellipsoid_int, x1,y1,z1,x2,y2,z2,a,b,xi,yi,zi'
	  print,'   x1,y1,z1 = x,y,z of point 1 on a line.        in'
	  print,'   x2,y2,z2 = x,y,z of point 2 on a line.        in'
	  print,'   a,b = Ellipsoid semimajor and semiminor axes. in'
	  print,'   xi,yi,zi = x,y,z of intersection point.       out'
	  print,' Keywords:'
	  print,'   FLAG=flag  Number of intersections: 0,1, or 2.'
	  print,'   LAT=lat, LNG=lng  Return geodetic lat/long (deg).'
	  print,'   /REFRESH means recompute constants for new a and b.'
	  print,'   /DEBUG list details for debugging (first point only).'
	  print,' Notes: For ellipsoid of revolution centered at origin.'
	  print,'   Intended for satellite sensor look vectors intersecting'
	  print,'   the earth.  Line point 1 should be the satellite'
	  print,'   position.  Point 2 should be along the sensor look'
	  print,'   direction.  Only the nearest (if any) intersection'
	  print,'   is returned. Make sure at least floating values are used.'
	  print,'   Also works for arrays, typically point 2 might be an array.'
	  print,'   Use returned FLAG values to determine which rays'
	  print,'   actually intersected the surface.'
	  return
	endif

	;------------------------------------------------------
	;  Precompute some constants
	;------------------------------------------------------
	if (n_elements(aa) eq 0) or keyword_set(refresh) then begin
	  print,' Computing constants'
	  aa = a*a		; a^2
	  bb = b*b		; b^2
	  aa2 = aa*2		; 2*a^2
	  bb2 = bb*2		; 2*b^2
	  aabb = aa*bb		; a^2*b^2
	  latcor = a/b
	  pi_2 = !dpi/2.D0
	  radeg = 180D0/!dpi
	endif

	;------------------------------------------------------
	;  Look direction vector
	;------------------------------------------------------
	dx = x2 - x1
	dy = y2 - y1
	dz = z2 - z1

	;------------------------------------------------------
	;  Compute quadratic coefficients
	;
	;  Equation of ellipsoid:
	;    x^2/a^2 + y^2/a^2 + z^2/b^2 = 1
	;
	;  Parametric equation of line between P1 and P2:
	;    x(t) = x1 + (x2-x1)*t = x1 + dx*t
	;    y(t) = y1 + (y2-y1)*t = y1 + dy*t
	;    z(t) = z1 + (z2-z1)*t = z1 + dz*t
	;
	;  Substitute x,y,z of line into equation of ellipsoid:
	;    t^2 * (b^2*dx^2 + b^2*dy^2 + a^2*dz^2)
	;    + t * (2*b^2*dx*x1 + 2*b^2*dy*y1 + 2*a^2*dz*z1)
	;        + (b^2*x1^2 + b^2*y1^2 + a^2*z1^2 - a^2*b^2) = 0
	;
	;  aq*t^2 + bq*t + cq = 0.  Solve for t.
	;  Check discriminant: d = bq*bq - 4*aq*cq, d must be GE 0.
	;------------------------------------------------------
	aq = bb*dx*dx  + bb*dy*dy  + aa*dz*dz
	bq = bb2*dx*x1 + bb2*dy*y1 + aa2*dz*z1
	cq = bb*x1*x1  + bb*y1*y1  + aa*z1*z1  - aabb

	;------------------------------------------------------
	;  Discriminant
	;
	;  d lt 0: No intersections.
	;  d eq 0: One intersection.
	;  d gt 0: Two intersections.  Take closest = min(t).
	;------------------------------------------------------
	d = bq*bq - 4*aq*cq
	n = n_elements(d)
	sz = size([d])
	val = x1[0]*0
	flag = make_array(size=sz,/int)
	we = where(d eq 0,c)  &  if c gt 0 then flag[we] = 1
	wg = where(d gt 0,c)  &  if c gt 0 then flag[wg] = 2
	w = where(flag gt 0,c)		; Any intersections?

	;------------------------------------------------------
	;  Debug
	;------------------------------------------------------
	if keyword_set(debug) then begin
	  print,' '
	  print,' ellipsoid_int:'
	  print,' Ellipsoid size a,b: ',a,b
	  print,'   aa, aa2, bb, bb2, aabb: ',aa, aa2, bb, bb2, aabb
	  print,' Point 1 x,y,z: ',x1[0],y1[0],z1[0]
	  print,' Point 2 x,y,z: ',x2[0],y2[0],z2[0]
	  print,' Vector from P1 to P2 dx,dy,dz: ',dx[0],dy[0],dz[0]
	  print,' A*t^2 + B*t + C = 0.  A, B, C: ',aq,bq,cq
	  print,' Discriminant: ',d[0]
	endif
	;----------------------------------------------

	if c eq 0 then return		; No.

	;------------------------------------------------------
	;  Find intersection point
	;------------------------------------------------------
	xi = make_array(size=sz,value=val)
	yi = xi
	zi = xi
	root = sqrt(d[w])
	u = (-bq[w]-root)/(2*aq[w])	; Nearest intersection.
	xi[w] = x1[w] + u*dx[w]		; Surface point.
	yi[w] = y1[w] + u*dy[w]
	zi[w] = z1[w] + u*dz[w]

	if keyword_set(debug) then begin
	  print,' t: ',u
	  print,' xi, yi, zi: ',xi[0],yi[0],zi[0]
	endif

	;------------------------------------------------------
	;  Convert to lat/long
	;------------------------------------------------------
	if not arg_present(lat) then return

	recpol3d,xi[w],yi[w],zi[w],r,az,ax  ; Rectangular to Spherical Polar.
	lat0 = pi_2 - az		    ; Geocentric long/lat (radians).
	lat = make_array(size=sz,value=val)
	lng = lat
	lat[w] = atan(latcor*tan(lat0))*radeg  ; Geodetic Lat from Geocentric.
	lng[w] = ax*radeg

	end
