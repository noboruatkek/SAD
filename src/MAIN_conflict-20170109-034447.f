      module version
        character*19, parameter ::
c                     /'1234567890123456789'/
     $     versionid  ='1.0.10.11k64-pre4  ',
     $     versiondate='12/24/201600:00:00 '
        character*25 builtdate
        character*30 startdat
      end module

      program MAIN
      use version
      use maccbk
      implicit none
c
c
      call fdate1(startdat)
      call buildinfo_get_string('Built:Date', builtdate)
c
      write(*,*)
     $     '*** Welcome to SAD Ver.',versionid(1:len_trim(versionid)),
     $     ' built at ',builtdate(1:len_trim(builtdate)),' ***'
      write(*,*)'*** Today: ',startdat(1:len_trim(startdat)),' ***'
c
      call inimem
      call inifil
      call initbl
      call tftokinit
      call ktfinitshare
c
      call toplvl
      end