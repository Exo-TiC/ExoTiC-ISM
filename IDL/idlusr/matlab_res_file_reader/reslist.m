%----------------------------------------------
%  reslist.m = List contents of a res file.
%  R. Sterner, 2004 Sep 29
%  M. Keller, 2008 Jan 30 64 bit pointer added.
%  R. Sterner, 2009 May 11 ---  Added help.
%    hdr = reslist(file,[mach])
%      file = res file name.  in
%      mach = endian: 'l' little (def), 'b' big.
%      hdr = res file header. out
%----------------------------------------------

	function h = reslist(file, mach0)

	%----  Deal with endian  --------
	if (nargin == 2)
	    mach1 = mach0;
	else
	    mach1 = 'l';
	end
    
	%--- Check for args  -------------
	if (nargin < 1)
	  disp(' List contents of a res file.')
	  disp(' hdr = reslist( resfile, [endian])')
	  disp('   resfile = Name of resfile.                   in')
	  disp('   endian = Optional endian: ''l'' (def) or ''b''.  in')
	  disp('   hdr = Returned res file header.              out')
	  disp(' ')
	  return
	end

	%--- Open res file and read 3 long ints  ----
	fid = fopen(file,'r',mach1);
	if (fid == -1)
	  [' Error in resget: Could not open file ',file]
	  return
	end
	a = fread(fid,3,'int32');
	if (max(abs(a(2:end))) > 10000)
          disp(' Could not read res file.')
          disp(' Try using a different endian: ''l'' or ''b''')
          disp(' For example: reslist(file,''b'')')
          disp([' Current endian is ',mach1])
          return
	end

	p = a(1);
	if (p<0)
	  p = fread(fid, 1, 'int64');
	end
    
	%---  First value is pointer to header  -----
	status = fseek(fid, p, 'bof');

	%---  Read header  -----
	b = fread(fid,[a(2),a(3)],'uchar');
	status = fclose(fid);
	h = char(b');
	%______________________________________________
