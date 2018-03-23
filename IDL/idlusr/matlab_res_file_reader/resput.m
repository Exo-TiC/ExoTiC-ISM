%------------------------------------------------------------------------------
%  resput.m = Put a value into a res file.
%  R. Sterner, 2010 Apr 22
%
%  resput, file, tag, val
%      file = res file name.   in
%      tag = tag of item.      in
%      val = value to insert.  in
%
%  This routine always writes an extended size res file
%  (will not have the 4GB limit).
%------------------------------------------------------------------------------

	function resput(file,tag,val)

        %===================================================
        %  Display help text if too few arguments
        %===================================================
        if (nargin < 3)
          disp(' Put a value into a res file.')
          disp(' resput( resfile, tag, val)')
          disp('   resfile = name of resfile.       in')
          disp('   tag = tag name of item to get.   in')
          disp('   val = value to insert.           in')
          disp(' ')
          disp(' The res file will be created if it does not exist.')
          disp(' ')
          disp(' OR')
          disp(' To add a comment to a res file:')
          disp(' resput( resfile, ''comment='',text)')
          disp(' ')
          disp(' where text is a text string, one line only.')
          disp(' ')
          disp(' Text strings are always saved as character arrays.')
          disp(' Numeric scalars are saved in the header as strings')
          disp(' and must be converted to the desired data type when read.')
          disp(' ')
          return
        end

        %===================================================
        %  Open res file
        %
        %  A res file constists of 3 parts:
        %    [1] Info needed to access the header,
        %    [2] Any arrays saved i the file,
        %    [3] The header.
        %
        %  The header is a text array and contains comments
        %  and scalar values, and descriptions of any arrays
        %  saved in the file.  The array descriptions give
        %  the data type and dimensions and the byte location
        %  of the array in the file.  The header is at the end
        %  of the file since its size changes as data is added
        %  to the file.
        %
        %  The res files written by this routine always have
        %  at the front of the file three 32-bit integers and
        %  one 64-bit integer.  The three 32-bit ints are
        %  read into the array p, which is 12 bytes long.
        %  p(1) is always -1 indicating extended size file.
        %  p(2) is the width in characters of the header lines.
        %  p(3) is the number of the header lines.
        %  The 64-bit int, p64, has the file location in bytes
        %  of the header, and takes 8 bytes.  The first array
        %  comes after these items so will start at byte 20
        %  in the file.
        %===================================================
        fid = fopen(file,'r+');      % Try to open for read and write.
        if (fid == -1)               % If not opened then create it.
          %---  Set up pointers and open file  ---
          p = int32([-1,0,0]);       % Use extended file size.
          p64 = int64(20);           % Location of 1st array.
          fid = fopen(file,'w');     % Try to create a new res file.
          if (fid == -1)             % Could not open new file, give up.
            disp([' Error in resput: Cannot create res file ',file])
            return
          end
          %---  Write pointers and close  ---
          fwrite(fid,p,'int32');     % Write -1 0 0 as int32.
          fwrite(fid,p64,'int64');   % Write 20 as int64.
          fclose(fid);               % Close (was write only).
          %---  Open for read/write  ---
          fid = fopen(file,'r+');    % Now open for read and write.
          if (fid == -1)             % Failed.  Give up.
            disp([' Error in resput: failure on res file ',file])
            return
          end
        end

        %===================================================
        %  Read pointers and header
        %===================================================
        p = fread(fid,3,'int32');    % Dimensions of header array.
        p64 = fread(fid,1,'int64');  % Pointer to header array.
        wid = p(2);                  % Width of header array.
        nln = p(3);                  % N lines in header array.
        if (wid > 0)                 % If there is a header ...
          fseek(fid,p64,'bof');      % Jump to its position.
          hd = fread(fid,[wid,nln],'int8');  % read header array.
          hd = char(hd');            % Transpose and convert to text.
          if strcmpi(strcat(hd(nln,:)),'END') == 1  % Is last line END?
            hd = hd(1:nln-1,:);      % Yes, drop it.
          end
        end

        %===================================================
        %  Prepare header entry for given item
        %
        %  Must test item for each data type, when a match
        %  is found set the res file datatype code, and the
        %  Matlab data type code to write it out.
        %
        %  Data type codes used by the res file:
        %    BYT, INT, LON, FLT, DBL, COMPLEX, STR,
        %    DCOMPLEX, UINT, ULON, LON64, ULON64.
        %  Complex data types not handled here, must
        %  save real and imaginary parts.
        %
        %  Text strings are stored as character arrays.
        %  Scalar numeric items are stored in the header
        %  as text and must be converted to numeric after
        %  they are read if needed.
        %===================================================
        v = val';                    % Working copy (transposed).

        %---------------------------------------------------
        %  Array
        %
        %  Find data type and set precision, prc, for
        %  writing the array to the res file, and also set
        %  the res file data type to use for the array
        %  descriptor in the header.
        %---------------------------------------------------
        if (numel(val) > 1)          % Array if more than 1 element?
          %---  get data type  ---
          if (isa(val,'int8') == 1)
            prc = 'int8';
            typ = 'BYT';
          elseif (isa(val,'int16') == 1)
            prc = 'int16';
            typ = 'INT';
          elseif (isa(val,'int32') == 1)
            prc = 'int32';
            typ = 'LON';
          elseif (isa(val,'int64') == 1)
            prc = 'int64';
            typ = 'LON64';
          elseif (isa(val,'uint8') == 1)
            prc = 'uint8';
            typ = 'BYT';
          elseif (isa(val,'uint16') == 1)
            prc = 'uint16';
            typ = 'UINT';
          elseif (isa(val,'uint32') == 1)
            prc = 'uint32';
            typ = 'ULON';
          elseif (isa(val,'uint64') == 1)
            prc = 'uint64';
            typ = 'ULON64';
          elseif (isa(val,'single') == 1)
            prc = 'single';
            typ = 'FLT';
          elseif (isa(val,'double') == 1)
            prc = 'double';
            typ = 'DBL';
          elseif (isa(val,'char') == 1)
            %---  Text string  ---
            if (numel(findstr(tag,'=')) == 0) % Not a keyword.
              prc = 'int8';
              typ = 'CHR';           % Special res file type.
              v = int8(val');        % Modify for write.
            %---  Comment for header  ---
            else                     % Was a keyword.
              v = ''                 % Clear value.  Size is 0.
              hline = ['*',val];     % Comment line to add.
            end
          end
          %---  Get dimensions  ---
          pcur = p64                 % Pointer to current insertion point.
          sz = size(v);              % Get dimensions of v.
          %---  Have an array to write out  ---
          if (sz(1) > 0)             % Not a null string.
            nd = numel(sz);          % Number of dimensions.
            dims = num2str(sz(1));   % First dimension.
            for i=2:nd-1 dims=[dims,',',num2str(sz(i))]; end % Middle dims.
	    if (sz(nd) > 1)          % Last dim. Ignore if 1.
              dims=[dims,',',num2str(sz(nd))];
            end
            %---  Add array description to header  ---
            hline = [tag,' == ',typ,'ARR(',dims,') at ',num2str(pcur)]
            %---  Write out array  ---
            fseek(fid,pcur,'bof');   % Jump to insertion point.
            fwrite(fid,v,prc);       % Write array.
            pcur = ftell(fid);       % New insertion pt (just before header).
          end

        %---------------------------------------------------
        %  Scalar
        %
        %  Only numeric items will be scalars (since text
        %  is stored in character arrays).  A numeric items 
        %  will be one of the integers, a single precision 
        %  float, or a double precision float.  Formats are
        %  used to make sure to include enough digits in the
        %  values in the header.
        %
        %  Found a Matlab bug for int64 type: num2str gave
        %  an error when using a format ('%i').  Skipped
        %  the format in this case.  Don't need for ints.
        %  Found that Matlab 7 does not fully support int64.
        %---------------------------------------------------
        else
          pcur = p64;                     % Pointer to current insertion point.
	  fmt = '%i';                     % Format for integers.
          if (isa(val,'single') == 1)     % Format for singles.
            fmt = '%#.8G';
          elseif (isa(val,'double') == 1) % Format for doubles.
            fmt = '%#.17G';
          end
          if (isa(val,'int64') == 1)         % Handle matlab bug for int64.
	    hline = [tag,' = ',num2str(v)];  % No format.
          elseif (isa(val,'uint64') == 1)    % Handle matlab bug for uint64.
	    hline = [tag,' = ',num2str(v)];  % No format.
          else
	    hline = [tag,' = ',num2str(v,fmt)];
          end
        end

        %===================================================
        %  Wrte out header
        %===================================================
        %---  Update header  ---
        if (nln == 0)                % nln is # header lines.  New header.
          hd = char(hline,'END');    % Only one line in header.
        else                         % Add to old header.
          hd = char(hd,hline,'END')  % Add new line to header.
        end
        %---  Write out header  ---
        sz = size(hd);               % Get new header size.
        wid = sz(2);
        nln = sz(1);
        p = [-1 wid nln];            % Update header info.
        b = int8(hd');               % Convert transposed header to bytes.
        fseek(fid,pcur,'bof');       % Jump to header position.
        fwrite(fid,b,'int8');        % Write header.
        %---  Update pointers  ---
        fseek(fid,0,'bof');          % Jump to front of file.
        fwrite(fid,p,'int32');       % Write header size pointers.
        fwrite(fid,pcur,'int64');    % Write header position.
        fclose(fid);                 % Close file.

%______________________________________________________________________________
