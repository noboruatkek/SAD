      subroutine NewGRF(id)
      use maccbk
      implicit none
      integer*4 id,LPARM,LBUF,mtaloc,mctaloc
      include 'inc/MACCODE.inc'
      include 'inc/MACVAR.inc'
       parameter(LPARM=10,LBUF=1+2*1024)
c
       idtype(id)=icGRAF
       idval(id)=mctaloc(LPARM)
c       idval(id)=mcfallo(LPARM)
       ilist(2,idval(id))=mtaloc(LBUF)
c       ilist(2,idval(id))=mfalloc(LBUF)
       ilist(1,idval(id))=LBUF
       ilist(1,ilist(2,idval(id)))=LBUF
       ilist(1,idval(id)+1)=50+id
c      ilist(1,idval(id)+1)=50+gid
c      ilist(1,idval(id)+1)=fopen(gid)
       ilist(2,idval(id)+1)=ilist(2,idval(id))+1
       return
       end