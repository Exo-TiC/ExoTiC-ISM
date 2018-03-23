;---  testwhoami.pro = Test whoami  ---
;  R. Sterner, 2010 Apr 09

        pro testwhoami

        whoami,dir,file
        print,'-----  Called routine:'
        help,dir,file
        print,'-----'

        whocalledme,dir,file
        print,'-----  Parent routine:'
        help,dir,file
        print,'-----'

        end
