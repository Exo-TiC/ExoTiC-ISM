%----------------------------------------------------------
%  resget.m = Get a value from a res file.
%  R. Sterner, 2004 Sep 29
%  R. Sterner, 2004 Sep 29 --- Added 1 missing '.
%  R. Sterner, B. Gotwols, 2005 Jan 27 --- Fixed for 1-D arrays.
%  M. Keller, 2008 Jan 30 64 bit pointer added.
%  R. Sterner, 2009 May 11 --- Upgraded the help text.
%
%    val = resget(file,tag,[mach])
%      file = res file name.  in
%      tag = tag of item.     in
%      val = returned value.  out
%      mach = optional endian (Little: 'l' def, Big: 'b').
%
%  Note: Scalars are always returned as strings,
%    convert as needed.
%
%  I just learned Matlab today (2004 Sep 29), so this
%  code may not be the best.  But it seems to work.
%
%  Limitations:
%    FIXED: Does not yet work for extended file pointer.
%    Does not get comments.
%    Gets only the first repeated tag.
%    Endian not automatic.
%----------------------------------------------------------

	function v = resget(file,tag,mach0)


	%----  Deal with endian  --------
	if (nargin == 3)
          mach1 = mach0;
	else
          mach1 = 'l';
	end

	%--- Check for args  -------------
	if (nargin < 2)
	  disp(' Get a value from a res file.')
	  disp(' val = resget( resfile, tag [endian])')
	  disp('   resfile = name of resfile.                  in')
	  disp('   tag = tag name of item to get.              in')
	  disp('   endian = Optional endian: ''l'' (def) or ''b''. in')
	  disp('   val = returned value.                       out')
	  disp(' ')
	  disp(' Note: Scalars are always returned as strings,')
	  disp('   convert as needed.')
	  return
	end

	%--- Open res file and read 3 long ints  ----
	fid = fopen(file,'r',mach1);
	if (fid == -1)
	  [' Error in resget: Could not open file ' file]
	  return
	end
	a = fread(fid,3,'int32');
	if (max(abs(a(2:end))) > 10000)
          disp(' Could not read res file.')
          disp(' Try using a different endian: ''l'' or ''b''')
          disp(' For example: resget(file,tag,''b'')')
          disp([' Current endian is ',mach1])
          return
	end

        p = a(1);
        if (p<0)
          p = fread(fid, 1, 'int64');
        end

	%---  First value is pointer to header  -----
	fseek(fid, p, 'bof');

	%---  Read header  -----
	b = fread(fid,[a(2),a(3)],'uchar');
	h = char(b');

	%------  Search for tag  -------
	[n,tmp] = size(h);			% # header lines.

	for i=1:n
	  txt = h(i,:);				% Grab i'th header line.
	  [tok,rem] = strtok(txt);		% Get tag.
	  if strcmpi(tag,tok)			% Is tag the target?
	    [del,val] = strtok(rem);		% Get delimiter.

	    %--------  Scalar value  -----------
	    if strcmp(del,'=')			% Scalar value.
		v = val;			% Return value as a string.
		fclose(fid);
		return
	    %--------  Array value  -----------
	    else				% Array value.
	        [des,rem] = strtok(val);	% Array descriptor, 'at add'
		[tmp,adds] = strtok(rem);	% at, array address.
		add = str2num(adds);		% Numeric address.
		[typ,rem] = strtok(des,'(');	% Typ and dimensions.
		typ = typ(1:end-3);		% Drop trailing ARR.
		%--- Pick out dimensions from rem  ----
		k = [findstr(',',rem),length(rem)]; % Find commas, include end.
		nd = length(k);			% # dimensions.
		dims = [0];			% Seed value, drop later.
		for j=1:nd			% Loop through dimensions.
		  if (j == 1)			% First is special.
		    lo =2;			% Dimension j start index.
		    hi = k(j)-1;		% Dimension j end index.
		  else
		    lo = k(j-1)+1;		% Dimension j start index.
		    hi = k(j)-1;		% Dimension j end index.
		  end
		  dims = [dims, str2num(rem(lo:hi))];	% Grab dimension j.
		end  % for j=1:nd
		dims = dims(2:end);		% List of dimensions (drop seed)
		tot = prod(dims);		% Total # elements.
	        if (length(dims) == 1)		% 1-D case.
                  dims=[1,dims];
	        end

		%---  Move to start of array in res file  ------
		fseek(fid, add, 'bof');  	% Move to array start byte.

		switch typ			% Convert type to matlab type.
		  case 'BYT'
		    mtyp = '*uchar';
		  case 'INT'
		    mtyp = '*int16';
		  case 'LON'
		    mtyp = '*int32';
		  case 'FLT'
		    mtyp = '*float32';
		  case 'DBL'
		    mtyp = '*float64';
		  case 'COMPLEX'			% Special case.
		    tmp = fread(fid,tot*2,'*float32');	% Read all as floats.
		    tmp = reshape(tmp,[2,tot]);		% Reshape and
		    cr = tmp(1,:);			% pick off real and
		    ci = tmp(2,:);			% imaginary parts.
		    fclose(fid);
		    v = reshape(complex(cr,ci),dims);	% Make complex.
		    return
		  case 'CHR'
		    mtyp = 'uchar';
		  case 'DCOMPLEX'			% Special case.
		    tmp = fread(fid,tot*2,'*float64');	% Read all as floats.
		    tmp = reshape(tmp,[2,tot]);		% Reshape and
		    cr = tmp(1,:);			% pick off real and
		    ci = tmp(2,:);			% imaginary parts.
		    fclose(fid);
		    v = reshape(complex(cr,ci),dims);	% Make complex.
		    return
		  case 'UINT'
		    mtyp = '*uint16';
		  case 'ULON'
		    mtyp = '*uint32';
		  case 'LON64'
		    mtyp = 'int64';	% *int64 fails, so output is double.
		  case 'ULON64'
		    mtyp = 'uint64';	% *uint64 fails, so output is double.
		end  % switch

		tmp = fread(fid,tot,mtyp);		% Read data.
		fclose(fid);				% Close res file.
		v = reshape(tmp,dims);			% Make correct shape.
	        if strcmp(typ,'CHR'), v=char(v'); end	% CHR only.
		return
	    end  % if strcmp(del,'=')
	  end  % if strcmp(tag,tok)
	end  % for i=1:n

	%------  No match, tag not found  --------
	status = fclose(fid);		% No match.
	v = '';				% Return null.

	%______________________________________________
