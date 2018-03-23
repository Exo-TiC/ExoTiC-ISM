        ;=================================================
        ;  stack__define.pro = Stack object.
        ;  Push and pop values on and off a stack.
        ;  R. Sterner, 2012 Jul 16
        ;=================================================
 
        ;=================================================
        ;  HELP = Give help for the stack object.
        ;=================================================
 
        pro stack::help
 
        print,' '
        print,' Stack object.  May set up multiple stacks.'
        print,' To create a stack object:'
        print,"   stk = obj_new('stack',n,type=typ)"
        print,'       n = Max size of stack (def=10).'
        print,'       typ = Data type of stack (def=3 for long int).'
        print,'           Can get datatype of x from size(x,/type)'
        print,' To use a stack object:'
        print,'   PUSH: stk->push, x_in, error=err'
        print,'       Push x_in on the stack.  Only n values may be'
        print,'       pushed or an overflow error will occur.'
        print,'       err=0 is ok.'
        print,'   POP: stk->pop, x_out, error=err'
        print,'       Pop x_out off the stack.  If no more values'
        print,'       are available an underflow error will occur.'
        print,'       err=0 is ok.'
        print,'   LIST: stk->list ,[m]'
        print,'       Will list the stack size and type and top'
        print,'       m values on the stack.'
        print,'   CLEAR: stk->clear'
        print,'       Clears everything off the stack.  It is still'
        print,'       defined and ready to push new items on it.'
        print,' To destroy a stack object:'
        print,"   obj_destroy, stk"
        print,' '
 
        end
 
        ;=================================================
        ;  PUSH
        ;=================================================
 
        pro stack::push, x, error=err
 
        in = self.in + 1        ; Index of next space.
 
        if in gt (self.mx-1) then begin
          err = 1
          print,' Overflow error in stack push.'
          print,'   Value not pushed on stack.'
          return
        endif
 
        (*self.p)[in] = x       ; Add value to stack.
        self.in = in            ; Save index.
 
        err = 0
 
        end
 
 
        ;=================================================
        ;  POP
        ;=================================================
 
        pro stack::pop, x, error=err
 
        in = self.in
 
        if in lt 0 then begin
          err = 1
          print,' Underflow error in stack pop.'
          print,'   Value not available.'
          return
        endif
 
        x = (*self.p)[in]       ; Get value from stack.
        self.in = in-1          ; Next index.
 
        err = 0
 
        end
 
 
        ;=================================================
        ;  CLEAR
        ;=================================================
 
        pro stack::clear
 
        self.in = -1
 
        end
 
 
        ;=================================================
        ;  LIST
        ;=================================================
 
        pro stack::list, m
 
        if n_elements(m) eq 0 then m=(self.in+1)<10
        mm = m < (self.in+1)
        print,' '
        print,' Stack is of type '+strtrim(size(*self.p,/type),2)+', '
        print,' max depth '+strtrim(self.mx,2)+', '
        print,' and currently contains '+strtrim(self.in+1,2)+ $
          ' values.'
        print,' '
        if self.in lt 0 then return
        print,' The top '+strtrim(mm,2) + ' value'+plural(mm)+' are:'
        for i=mm-1,0,-1 do print,(mm-1)-i, (*self.p)[i]
        print,' '
 
        end
 
 
        ;=================================================
        ;  INIT
        ;=================================================
 
        function stack::init, n, type=typ
 
        if n_elements(n) eq 0 then n=10         ; Default stack size.
        if n_elements(typ) eq 0 then typ=3      ; Default stack typ (long int).
        self.p = ptr_new(make_array(n,type=typ)); Pointer to stack array.
        self.in = -1                            ; Current stack index.
        self.mx = n                             ; Stack size.
 
        return, 1
        end
 
 
        ;=================================================
        ;  Stack object structure
        ;=================================================
 
        pro stack__define
 
        tmp = { stack, $
                p: ptr_new(), $         ; Pointer to stack array.
                in: 0L, $               ; Current stack item index.
                mx: 0L }                ; Size of stack.
 
        end
