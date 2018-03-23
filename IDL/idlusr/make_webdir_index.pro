;------------------------------------------------------------------------------
;  make_webdir_index.pro = Make an index for a web directory.
;  R. Sterner, 2013 Mar 13
;------------------------------------------------------------------------------

        pro make_webdir_index, dir, target=targ0, link=linktxt, save=out, $
          recurse=recurse, verbose=verb, help=hlp

        if keyword_set(hlp) then begin
          print,' Make an index for a web directory.'
          print,' make_webdir_index, dir'
          print,'   dir = Directory to process (def=current).  in'
          print,' Keywords:'
          print,'   TARGET=targ Target *.html file to find (def=index.html).'
          print,'   LINK=linktxt Returned link text.'
          print,'   SAVE=out Name of output *.html file (def=targ).'
          print,'   /VERBOSE List steps as they happen.'
          print,'   /RECURSE Recurse down through all subdirectories.'
          print,' Notes: Generates an index to each directory or file in'
          print,'   the current directory.'
          return
        endif

        ;-------------------------------------------------
        ;  Deal with target directory
        ;-------------------------------------------------
        if n_elements(dir) eq 0 then dir='.'
        if keyword_set(verb) then print,' Target dir: '+dir

        ;-------------------------------------------------
        ;  Deal with target html file
        ;-------------------------------------------------
        if n_elements(targ0) ne 0 then targ=targ0 else targ='index.html'
        if keyword_set(verb) then print,' Target html file: '+targ

        ;-------------------------------------------------
        ;  Deal with save html file
        ;-------------------------------------------------
        if n_elements(out) eq 0 then out=targ
        if keyword_set(verb) then print,' Will save in file: '+out

        ;-------------------------------------------------
        ;  Look for target html
        ;-------------------------------------------------
        file = filename(dir,targ,/nosym)
        if keyword_set(verb) then print,' Looking for target file '+file
        f = file_search(file,count=n)
        if n eq 1 then begin
          if keyword_set(verb) then print,' Done with directory, found target file '+file
          linktxt = file
          return
        endif

        ;-------------------------------------------------
        ;  Look for any single html
        ;-------------------------------------------------
        file = filename(dir,'*.html',/nosym)
        if keyword_set(verb) then print,' Looking for '+file
        f = file_search(file,count=n)
        if n eq 1 then begin
          if keyword_set(verb) then print,' Done with directory, found '+file
          linktxt = file
          return
        endif

        ;-------------------------------------------------
        ;  Found multiple html
        ;-------------------------------------------------
        if n gt 1 then begin
          print,' Error in make_webdir_index: Multiple *.html found.'
          print,'   Directory ignored: '+dir
          linktxt = ''
          return
        endif

        ;-------------------------------------------------
        ;  Make target html
        ;-------------------------------------------------
        cd, curr=cdir
        filebreak, cdir, name=nam

        ;---  Start target file  ---
        if keyword_set(verb) then print,' Starting output.'
        txt = ['<html>','<head>','<title>Index for '+nam+'</title>', $
               '</head>',' ','<body bgcolor="white">','<blockquote>',' ', $
               '<p>','<h3>Index for '+nam+'</h3>']
        
        ;---  Find all files  ---        
        list = file_search(count=nlist)
        if keyword_set(verb) then print,' Loop over files found in target directory: ',nlist

        ;---  Loop over list  ---
        for i=0, nlist-1 do begin
          fi = list[i]                                  ; i'th file.
          if keyword_set(verb) then print,'   Looking at '+fi
          flag = file_test(fi,/directory)               ; Directory?
          if flag eq 0 then begin                       ; Not directory.
            if keyword_set(verb) then print,'   Not a directory, just add link to it.'
            t = '<p><a href="'+fi+'">'+fi+'</a>'        ;   Link to file.
            txt = [txt,t]                               ;   Add link.
          endif else begin                              ; Is directory.
            ;---  Look for target file in directory  ---
            file = filename(fi,targ,/nosym)
            if keyword_set(verb) then print,'   Was a directory, look for target file: '+file
            f = file_search(file,count=n)
            if n eq 1 then begin
              if keyword_set(verb) then print,'   Found target file, add link to it.'
              t = '<p><a href="'+file+'">'+file+'</a>'  ; Link to file.
              txt = [txt,t]                             ; Add link.
              continue                                  ; Go to next list item.
            endif
            ;---  Look for any single *.html file in directory  ---
            file = filename(fi,'*.html',/nosym)
            if keyword_set(verb) then print,'   Was a directory, look for any single *.html file: '+file
            f = file_search(file,count=n)
            if n eq 1 then begin
              if keyword_set(verb) then print,'   Found '+f+', add link to it.'
              t = '<p><a href="'+f+'">'+f+'</a>'  ; Link to file.
              txt = [txt,t]                             ; Add link.
              continue                                  ; Go to next list item.
              return
            endif
            ;---  Multiple html in directory  ---
            if n gt 1 then begin
              print,' Error in make_webdir_index: Multiple *.html found.'
              print,'   Subdirectory ignored: '+fi
              continue
            endif
            ;---  Recurse  ---
            if keyword_set(recurse) then begin
              if keyword_set(verb) then print,'   Recurse requested, code not ready.'
              stop
              make_webdir_index, fi, target=targ, link=linktxt, recurse=recurse
            endif
          endelse

        endfor ; i

        ;---  Finish target file  ---
        if keyword_set(verb) then print,' Finish building target file and save.'
        txt = [txt,' ','</blockquote>','</body>','</html>'] 
        putfile, targ, txt


        end
