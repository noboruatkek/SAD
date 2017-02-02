      subroutine tfprint(word,lfno,force,itx,next,exist)
      use tfstk
      use tfcode
      use iso_c_binding
      implicit none
      type (sad_list), pointer :: klx
      type (sad_symdef), pointer :: symd
      type (sad_namtbl),pointer :: loc
      type (sad_descriptor) kx
      integer*8 kax
      integer*4 itx,nc,lfno,itfpeeko,next,lpw,next1
      logical*4 exist,force,pri
      character*(*) word
      character peekch
      integer*4 itfgetrecl,l,itfdownlevel,lenw
      real*8 , parameter :: amaxline=8
      character*255 word0,word1
      itx=-1
      call unreadbuf(word)
      lpw=itfgetrecl()
 1    levele=levele+1
      itx=itfpeeko(kx,next)
      select case (itx)
      case (-1)
        call cssetp(next)
        exist=.true.
        go to 9100
      case (-2)
        call getwrd(word)
        exist=word(1:1) .eq. ' '
        go to 9100
      case (-3)
        call getwrd(word)
        word='END'
        exist=.false.
        go to 9100
      case default
        if(force)then
          exist=.true.
        else
c     if(isnan(rfromk(kx)))then
c     write(*,'(z16)')kx
c     endif
          if(ktfoperqd(kx,kax))then
            if(kx%k .eq. ktfoper+mtfnull)then
              go to 8000
            endif
            kx%k=ktfsymbol+klist(ifunbase+kax)
          endif
          if(ktfsymbolqdef(kx%k,symd))then
            call peekwd(word,next1)
            l=lenw(word)
            word0=word(1:l)
            call sym_namtbl(symd%sym,loc)
            nc=loc%str%nch
            word1=loc%str%str(1:nc)
            call capita(word0(1:l))
            call capita(word1(1:nc))
            if(word0 .eq. word1)then
              call cssetp(next1)
              exist=word0(1:1) .eq. ' '
              go to 9000
            elseif(l .gt. nc)then
              if(word0(1:nc) .eq. word1 .and.
     $             (word0(nc+1:nc+1) .eq. '{' .or.
     $             word0(nc+1:nc+1) .eq. '(' .or.
     $             word0(nc+1:nc+1) .eq. '~' .or.
     $             word0(nc+1:nc+1) .eq. '.'))then
                call cssetp(next1)
                exist=.false.
                go to 9000
              endif
            endif
          elseif(ktflistqd(kx,klx))then
            if(klx%head .ne. ktfoper+mtfcomplex .and.
     $           klx%head .ne. ktfoper+mtflist .and.
     $           ktfoperqd(klx%dbody(0)) .and. klx%ref .le. 0)then
              call getwrd(word)
              exist=word(1:1) .eq. ' '
              go to 9000
            endif
          endif
        endif
      end select
 8000 call cssetp(next)
      pri=(force .or. peekch(next) .ne. ';') .and.
     $     kx%k .ne. ktfoper+mtfnull
      if(pri)then
        call tfsetout(kx,lfno,amaxline)
      endif
      l=itfdownlevel()
c      if(levele .le. 3)then
c        call tfclearlocal
c      endif
      go to 1
 9000 call tfsetout(kx,0,amaxline)
 9100 l=itfdownlevel()
      return
      end

      subroutine tfsetout(kx,lfno,amaxline)
      use tfstk
      implicit none
      type (sad_descriptor) kx
      type (sad_list), pointer ::klarg
      type (sad_symdef), pointer :: sdout
      integer*8 karg,kh,ktdhtaloc,kad,kan,ktdaloc
      integer*4 lfno,irtc,itfhasharg
      real*8 al,amaxline
      al=rlist(iaxline)+1.d0
      rlist(iaxline)=al
      karg=ktavaloc(-1,1,klarg)
      klarg%head=ktfsymbol+ktfcopy1(iaxout)
      klarg%rbody(1)=al
      call loc_symdef(iaxout,sdout)
      kad=sdout%downval
      if(kad .eq. 0)then
        kad=ktdhtaloc(iaxout-5,int8(0),15)
      endif
      ilist(2,kad-1)=ior(ilist(2,kad-1),1)
      kh=itfhasharg(ktflist+karg,ilist(2,kad+2))+kad+3
      kan=ktdaloc(int8(0),kh,klist(kh),ktfref,karg,kx,karg,.false.)
      rlist(kan+7)=1.d100
      if(lfno .gt. 0)then
        call tfprintout(amaxline,irtc)
        if(irtc .gt. 0 .and. ierrorprint .ne. 0)then
          call tfreseterror
        endif
      endif
      return
      end

      subroutine tfprintout(amaxline,irtc)
      use tfstk
      use tfrbuf
      use ffs_flag
      implicit none
      type (sad_list), pointer :: kl
      type (sad_symbol), pointer :: sym
      integer*8 kad,kah,ka,k,kt,kx,k1,isp0
      integer*4 irtc,l,lenw,itfhasharg
      real*8 al,amaxline
      character*10 n,autofg
      integer*8 iaxshort
      data iaxshort/0/
      al=rlist(iaxline)
      if(al .gt. 0.d0)then
        if(iaxshort .eq. 0)then
          call tfsyeval(kxsymbolf('System`Short',12,.true.),
     $         iaxshort,irtc)
        endif
        isp=isp+1
        ktastk(isp)=iaxshort
        ktastk2(isp)=isp+1
        isp=isp+1
        rtastk(isp)=al
        kad=klist(iaxout-5)
        kah=itfhasharg(ktfref+isp-1,ilist(2,kad+2))
        isp=isp-2
        kad=klist(kad+kah+3)
        n=autofg(al,'S10.0')
        l=lenw(n)
        write(prolog,'($,''Out['',a,'']:= '')')n(1:l)
        ncprolog=l+8
        do while(kad .ne. 0)
          if(al .eq. rlist(ktfaddr(klist(kad+3))+1))then
            k=klist(kad+6)
            ka=ktfaddr(k)
            kt=k-ka
            if(ktflistq(k,kl) .and. ktfsymbolq(kl%head,sym) .and.
     $           sym%gen .eq. -3)then
              call tfclassmember(k,iaxshort,k1,.true.,irtc)
              if(irtc .gt. 0)then
                return
              elseif(irtc .ne. 0)then
                go to 10
              endif
              isp=isp+1
              isp0=isp
              ktastk(isp)=k1
              call tfefunref(isp0,kx,.true.,irtc)
              isp=isp0-1
              ncprolog=0
              return
            endif
 10         isp=isp+1
            isp0=isp
            ktastk(isp)=iaxshort
            isp=isp+1
            ktastk(isp)=k
            isp=isp+1
            rtastk(isp)=amaxline
            call tfefunref(isp0,kx,.true.,irtc)
            isp=isp0-1
            ncprolog=0
            return
          endif
          kad=klist(kad)
        enddo
        ncprolog=0
      endif
      return
      end

      subroutine tftruncprint(str,lrecl,delim,null,lfno)
      implicit none
      integer*4 lrecl,lfno,i1,i2,l
      character*(*) str,delim
      logical*4 null
      l=len_trim(str)
      i1=1
      do while(.true.)
        if(i1+lrecl .gt. l)then
          if(l .lt. i1)then
            if(null)then
              write(lfno,*)
            endif
          else
            write(lfno,'(a)')str(i1:l)
          endif
          return
        else
          i2=i1+lrecl-1
          do while(index(delim,str(i2:i2)) .le. 0)
            i2=i2-1
            if(i2 .lt. i1)then
              i2=i1+lrecl-1
              go to 10
            endif
          enddo
 10       write(lfno,'(a)')str(i1:i2)
          i1=i2+1
        endif
      enddo
      end
          
      subroutine unreadbuf(word)
      use tfstk
      use ffs_flag
      use tmacro
      implicit none
      include 'inc/TFCSI.inc'
      integer*4 l,lenw,ip1,i
      character*(*) word
      character*255 word1,word2
      l=lenw(word)
      if(l .le. 0)then
        return
      endif
      word2(1:l)=word(1:l)
      if(convcase)then
        call capita(word2(1:l))
      endif
      ip1=ipoint-l
      do i=ip1,2,-1
        word1(1:l)=buffer(i:i+l-1)
        if(convcase)then
          call capita(word1(1:l))
        endif
        if(word1(1:l) .eq. word2(1:l))then
          if(index(delim(1:ldel),buffer(i+l:i+l)) .gt. 0 .and.
     $         (index(delim(1:ldel),buffer(i-1:i-1)) .gt. 0 .or.
     $         index('0123456789.',buffer(i-1:i-1)) .gt. 0))then
            ipoint=i
            return
          endif
        endif
      enddo
      write(*,*)'Buffer is damaged at unreadbuf. ',
     $     ipoint,lrecl,' ',word(1:l)
      call skipline
      return
      end