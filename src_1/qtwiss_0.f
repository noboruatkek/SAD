      subroutine qtwiss(latt,twiss,gammab,idp,la,lb,over)
      use tfstk
      use ffs
      use tffitcode
      implicit none
      integer*4 latt(2,nlat),idp,la,lb
      real*8 twiss(nlat*(2*ndim+1),ntwissfun),gammab(nlat)
      real*8 trans(4,5),cod(6)
      logical*4 over
      call qtwiss1(latt,twiss,gammab,idp,la,lb,
     $     trans,cod,.false.,over)
      return
      end

      subroutine qtwiss1(latt,twiss,gammab,idp,la,lb,
     $     tr,cod,mat,over)
      use tfstk
      use ffs
      use tffitcode
      implicit none
      integer*4 latt(2,nlat),idp,la,lb,ip0,l1,i,l,ip1,ip,ltyp,
     $     j,le,ld,lp,mfr,itgetfpe,k,ibb,ibg,ntfun
      real*8 twiss(nlat*(2*ndim+1),ntwissfun),gammab(nlat),
     $     epschop
      parameter (epschop=1.d-30)
      real*8 trans(4,5),cod(6),tr(4,5),rxy(4,5),
     $     r1,r2,r3,r4,detr,rr,sqrdet,trtr,bx0,by0,
     $     ax0,ay0,al,pxi,pyi,pxisq,pyisq,pzi,ale,alz,psi1,psi2,
     $     theta0,x,px,y,detp,aa,cc,dpsix,bb,dd,dpsiy,
     $     detm,ex0,epx0,ey0,epy0,t1,t2,t3,t4,bz,
     $     r15,r25,r35,r45,pr,a,dpz,trf00,dtheta,phi,
     $     apsi1,apsi2,sspc0,sspc,vcphic0,vcalpha0,fb1,fb2,
     $     chi1m,chi2m
      logical*4 over,coup,normal,mat,calpol0,insmat,err
      real*8 a11,a12,a13,a14,a21,a22,a23,a24,a31,a32,a33,
     $     a34,a41,a42,a43,a44,a15,a25,a35,a45
      real*8 u11,u12,u13,u14,u21,u22,u23,u24,u31,u32,u33,
     $     u34,u41,u42,u43,u44,u15,u25,u35,u45
      equivalence (a11,trans(1,1)),(a12,trans(1,2)),(a13,trans(1,3)),
     1            (a14,trans(1,4)),(a21,trans(2,1)),(a22,trans(2,2)),
     1            (a23,trans(2,3)),(a24,trans(2,4)),
     1            (a31,trans(3,1)),(a32,trans(3,2)),(a33,trans(3,3)),
     1            (a34,trans(3,4)),(a41,trans(4,1)),(a42,trans(4,2)),
     1            (a43,trans(4,3)),(a44,trans(4,4)),
     1            (a15,trans(1,5)),(a25,trans(2,5)),(a35,trans(3,5)),
     1            (a45,trans(4,5))
      equivalence (u11,rxy(1,1)),(u12,rxy(1,2)),(u13,rxy(1,3)),
     1            (u14,rxy(1,4)),(u21,rxy(2,1)),(u22,rxy(2,2)),
     1            (u23,rxy(2,3)),(u24,rxy(2,4)),
     1            (u31,rxy(3,1)),(u32,rxy(3,2)),(u33,rxy(3,3)),
     1            (u34,rxy(3,4)),(u41,rxy(4,1)),(u42,rxy(4,2)),
     1            (u43,rxy(4,3)),(u44,rxy(4,4)),
     1            (u15,rxy(1,5)),(u25,rxy(2,5)),(u35,rxy(3,5)),
     1            (u45,rxy(4,5))
      real*8, parameter :: almostone=1.d0-1.d-16
c     begin initialize for preventing compiler warning
      normal=.false.
      sqrdet=0.d0
      dpsix=0.d0
      dpsiy=0.d0
      ax0=0.d0
      ay0=0.d0
      bx0=0.d0
      by0=0.d0
      rr=0.d0
c     end   initialize for preventing compiler warning
      call wspaccheck
      call tfclrtparaed
      call tclrfpe
      irad=6
      trf00=trf0
      vcphic0=vcphic
      vcalpha0=vcalpha
      if(trpt)then
        trf0=0.d0
        vcphic=0.d0
        vcalpha=1.d0
      endif
      calpol0=calpol
      calpol=.false.
      over=.false.
      insmat=.false.
      ip0=(ndim+idp)*nlat
      l1=ip0+la
      if(mat)then
        tr=0.d0
        tr(1,1)=1.d0
        tr(3,3)=1.d0
        tr(2,2)=1.d0
        tr(4,4)=1.d0
      else
        do i=mfitex,ntwissfun
          if(abs(twiss(l1,i)) .lt. epschop)then
            twiss(l1,i)=0.d0
          endif
        enddo
        cod=twiss(l1,mfitdx:mfitddp)
        r1=twiss(l1,mfitr1)
        r2=twiss(l1,mfitr2)
        r3=twiss(l1,mfitr3)
        r4=twiss(l1,mfitr4)
        detr=r1*r4-r2*r3
        normal=detr .lt. 1.d0
        if(normal)then
          sqrdet=sqrt(1.d0-detr)
        endif
      endif
      dvfs=0.d0
      call tesetdv(cod(6))
      sspc0=rlist(ifpos+la-1)
      if(orbitcal)then
        ntfun=ntwissfun
      else
        ntfun=mfitr4
      endif
      do 10 l=la+1,lb
        l1=l-1
        ip1=ip0+l1
        ip=ip1+1
        ltyp=idtype(latt(1,l1))
        if(.not. orbitcal)then
          cod=twiss(ip1,mfitdx:mfitddp)
          call tesetdv(cod(6))
        endif
        if(ltyp .lt. 42)then
          if(mat)then
            if(itgetfpe() .ne. 0)then
              call tclrfpe
              over=.true.
              go to 9000
            endif
            trtr=tr(1,1)+tr(2,2)+tr(3,3)+tr(4,4)
            if(trtr .gt. 0.d0)then
            elseif(trtr .le. 0.d0)then
            else
              over=.true.
              go to 9000
            endif
            if(insmat)then
              if(ltyp .eq. icINS)then
                insmat=.false.
              endif
              go to 1010
            endif
          else
            bx0=twiss(ip1,mfitbx)
            by0=twiss(ip1,mfitby)
            if(bx0 .gt. 0.d0 .and. by0 .gt. 0.d0 .and.
     $           itgetfpe() .eq. 0)then
            else
              do j=ip1-1,ip0+la,-1
                if(twiss(j,mfitbx) .gt. 0.d0
     $               .and. twiss(j,mfitby) .gt. 0.d0)then
                  ip1=j
                  go to 12
                endif
              enddo
              ip1=ip0+la
 12           continue
              forall(k=1:ntfun)twiss(ip1+1:ip0+lb,k)=twiss(ip1,k)
              over=.true.
              go to 9000
            endif
            ax0=twiss(ip1,mfitax)
            ay0=twiss(ip1,mfitay)
          endif
          call tfbndsol(l1,ibg,ibb)
          if(ibg .gt. 0)then
            call qsol(trans,cod,gammab,latt,l1,coup)
            go to 20
          endif
          le=latt(2,l1)
          ld=idval(latt(1,l1))
          if(ideal)then
            lp=ld
          else
            lp=le
          endif
          al=rlist(lp+1)
          go to (
     $         1100,1200,1010,1400,1010,1600,1010,1600,1010,1600,
     1         1010,1600,1010,1010,1010,1010,1010,1010,1010,2000,
     1         2100,2200,1010,1010,1010,1010,1010,1010,1010,3000,
     1         3100,3200,3300,3400,3500,1010,1010,1010,1010,1010,
     $         4100),
     1      ltyp
          go to 1010
 1100     pr=1.d0+cod(6)
          pxi=cod(2)
          pyi=cod(4)
          pxisq=pxi**2
          pyisq=pyi**2
          a=pxisq+pyisq
          dpz=-a/pr/(1.d0+sqrt(max(0.d0,1.d0-a/pr**2)))
          pzi=pr+dpz
          ale=al/pzi
          alz=ale/pzi**2
          a12=ale+pxisq*alz
          a14=pxi*pyi*alz
          a15=-pr*pxi*alz
          a32=a14
          a34=ale+pyisq*alz
          a35=-pr*pyi*alz
          cod(1)=cod(1)+pxi*ale
          cod(3)=cod(3)+pyi*ale
          cod(5)=cod(5)+dpz*ale-dvemit*al
          if(mat .and. .not. wspac)then
            tr(1,1)=tr(1,1)+a12*tr(2,1)+a14*tr(4,1)
            tr(1,2)=tr(1,2)+a12*tr(2,2)+a14*tr(4,2)
            tr(1,3)=tr(1,3)+a12*tr(2,3)+a14*tr(4,3)
            tr(1,4)=tr(1,4)+a12*tr(2,4)+a14*tr(4,4)
            tr(1,5)=tr(1,5)+a12*tr(2,5)+a14*tr(4,5)+a15
            tr(3,1)=tr(3,1)+a32*tr(2,1)+a34*tr(4,1)
            tr(3,2)=tr(3,2)+a32*tr(2,2)+a34*tr(4,2)
            tr(3,3)=tr(3,3)+a32*tr(2,3)+a34*tr(4,3)
            tr(3,4)=tr(3,4)+a32*tr(2,4)+a34*tr(4,4)
            tr(3,5)=tr(3,5)+a32*tr(2,5)+a34*tr(4,5)+a35
            go to 30
          else
            coup=a14 .ne. 0.d0
            a11=1.d0
            a13=0.d0
            a21=0.d0
            a22=1.d0
            a23=0.d0
            a24=0.d0
            a25=0.d0
            a31=0.d0
            a33=1.d0
            a41=0.d0
            a42=0.d0
            a43=0.d0
            a44=1.d0
            a45=0.d0
            go to 20
          endif
 1200     continue
          if(rlist(latt(2,l1)+ilist(1,latt(2,l1))) .gt. 0.d0)then
            psi1=rlist(lp+kytbl(kwE1,icBEND))
            psi2=rlist(lp+kytbl(kwE2,icBEND))
            apsi1=rlist(lp+kytbl(kwAE1,icBEND))
            apsi2=rlist(lp+kytbl(kwAE2,icBEND))
            fb1=rlist(lp+kytbl(kwF1,icBEND))
     $           +rlist(lp+kytbl(kwFB1,icBEND))
            fb2=rlist(lp+kytbl(kwF1,icBEND))
     $           +rlist(lp+kytbl(kwFB2,icBEND))
          else
            psi1=rlist(lp+kytbl(kwE2,icBEND))
            psi2=rlist(lp+kytbl(kwE1,icBEND))
            apsi1=rlist(lp+kytbl(kwAE2,icBEND))
            apsi2=rlist(lp+kytbl(kwAE1,icBEND))
            fb2=rlist(lp+kytbl(kwF1,icBEND))
     $           +rlist(lp+kytbl(kwFB1,icBEND))
            fb1=rlist(lp+kytbl(kwF1,icBEND))
     $           +rlist(lp+kytbl(kwFB2,icBEND))
          endif
          dtheta=rlist(lp+kytbl(kwDROT,icBEND))
          theta0=rlist(lp+kytbl(kwROT,icBEND))+dtheta
          call qbend(trans,cod,al,rlist(lp+2)+rlist(lp+11),
     1         rlist(lp+2),psi1,psi2,apsi1,apsi2,rlist(lp+8),
     1         rlist(lp+kytbl(kwDX,icBEND)),
     $         rlist(lp+kytbl(kwDY,icBEND)),
     $         theta0,dtheta,
     $         fb1,fb2,
     $         nint(rlist(lp+kytbl(kwFRMD,icBEND))),
     $         rlist(lp+kytbl(kwFRIN,icBEND)) .eq. 0.d0,
     $         rlist(lp+kytbl(kwEPS,icBEND)),
     1         coup)
          go to 20
 1400     continue
          mfr=nint(rlist(lp+12))
          if(rlist(latt(2,l1)+ilist(1,latt(2,l1))) .lt. 0.d0)then
            mfr=mfr*(11+mfr*(2*mfr-9))/2
          endif
          call qquad(trans,cod,al,
     1         rlist(lp+2),rlist(lp+5),rlist(lp+6),
     1         rlist(lp+4),rlist(lp+9) .eq. 0.d0,
     $         rlist(lp+10),rlist(lp+11),
     $         mfr,rlist(lp+13),rlist(lp+14) .eq. 0.d0,coup)
          go to 20
 1600     continue
          call qthin(trans,cod,ltyp,al,rlist(lp+2),
     1               rlist(lp+5),rlist(lp+6),rlist(lp+4),coup)
          go to 20
 2000     write(*,*)'Qtwiss: implementation error of solenoid ',l1
          go to 1010
 2100     write(*,*)'Use BEND with ANGLE=0 for ST.'
          stop
 2200     phi=rlist(lp+kytbl(kwANGL,icMULT))
          mfr=nint(rlist(lp+14))
          if(rlist(latt(2,l1)+ilist(1,latt(2,l1))) .ge. 0.d0)then
            psi1=rlist(lp+kytbl(kwE1,icMULT))
            psi2=rlist(lp+kytbl(kwE2,icMULT))
            apsi1=rlist(lp+kytbl(kwAE1,icMULT))
            apsi2=rlist(lp+kytbl(kwAE2,icMULT))
            fb1=rlist(lp+kytbl(kwFB1,icMULT))
            fb2=rlist(lp+kytbl(kwFB2,icMULT))
            chi1m=rlist(lp+kytbl(kwCHI1,icMULT))
            chi2m=rlist(lp+kytbl(kwCHI2,icMULT))
          else
            mfr=mfr*(11+mfr*(2*mfr-9))/2
            psi1=rlist(lp+kytbl(kwE2,icMULT))
            psi2=rlist(lp+kytbl(kwE1,icMULT))
            apsi1=rlist(lp+kytbl(kwAE2,icMULT))
            apsi2=rlist(lp+kytbl(kwAE1,icMULT))
            fb2=rlist(lp+kytbl(kwFB1,icMULT))
            fb1=rlist(lp+kytbl(kwFB2,icMULT))
            chi1m=-rlist(lp+kytbl(kwCHI1,icMULT))
            chi2m=-rlist(lp+kytbl(kwCHI2,icMULT))
          endif
          bz=0.d0
          call qmult(trans,cod,gammab,l1,al,
     $         rlist(lp+kytbl(kwK0,icMULT)),bz,
     $         phi,psi1,psi2,apsi1,apsi2,
     1         rlist(lp+3),rlist(lp+4),rlist(lp+5),
     $         chi1m,chi2m,rlist(lp+8),
     $         rlist(lp+kytbl(kwDROT,icMULT)),
     $         rlist(lp+9),
     $         rlist(lp+11) .eq. 0.d0,
     $         rlist(lp+12),rlist(lp+13),mfr,fb1,fb2,
     $         rlist(lp+kytbl(kwK0FR,icMULT)) .eq. 0.d0,
     $         rlist(lp+15),rlist(lp+16),rlist(lp+17),rlist(lp+18),
     $         rlist(lp+kytbl(kwW1,icMULT)),
     $         coup)
          go to 20
 3000     call qtest(trans,cod,al,rlist(lp+2),coup)
          go to 20
 3100     mfr=nint(rlist(lp+kytbl(kwFRMD,icCAVI)))
          if(rlist(latt(2,l1)+ilist(1,latt(2,l1))) .ge. 0.d0)then
          else
            mfr=mfr*(11+mfr*(2*mfr-9))/2
          endif
          call qcav(trans,cod,gammab,l1,
     1         al,rlist(lp+2),rlist(lp+3),rlist(lp+4),rlist(lp+5),
     $         rlist(lp+13),rlist(lp+14),rlist(lp+15),
     $         rlist(lp+16),rlist(lp+17),rlist(lp+18),rlist(lp+19),
     $         rlist(lp+kytbl(kwFRIN,icCAVI)) .eq. 0.d0,mfr,
     $         coup)
          go to 20
 3200     call qtcav(trans,cod,
     $         al,rlist(lp+2),rlist(lp+3),rlist(lp+4),rlist(lp+5),
     $         rlist(lp+6),rlist(lp+7),rlist(lp+8),coup)
          go to 20
 3300     call qemap(trans,cod,l1,coup,err)
          if(err)then
            go to 1010
          endif
          go to 20
 3400     call qins(trans,cod,latt,twiss,gammab,l1,idp,
     $         rlist(lp+19) .ge. 0.d0,rlist(lp+1),rlist(lp+20),coup,
     $         mat,insmat)
          if(insmat)then
            go to 1010
          endif
          if(coup)then
            go to 20
          else
            go to 10
          endif
 3500     call qcoord(trans,cod,
     1                rlist(lp+1),rlist(lp+2),rlist(lp+3),
     1                rlist(lp+4),rlist(lp+5),rlist(lp+6),
     1                rlist(lp+7) .eq. 0.d0,coup)
          go to 20
 4100     continue
 1010     if(wspac)then
            if(l .eq. lb)then
              trans=0.d0
              trans(1,1)=1.d0
              trans(2,2)=1.d0
              trans(3,3)=1.d0
              trans(4,4)=1.d0
              coup=.false.
              go to 20
            endif
          endif
          if(.not. mat)then
            twiss(ip,1:ntfun)=twiss(ip1,1:ntfun)
          endif
          go to 10
 20       if(wspac)then
            sspc=(rlist(ifpos+l1)+rlist(ifpos+l1-1))*.5d0
            call qwspac(trans,cod,sspc-sspc0,
     $           rlist(ifsize+(l1-1)*21),coup)
            sspc0=sspc
            coup=.true.
          endif
          if(coup)then
            if(mat)then
              x =tr(1,1)
              px=tr(2,1)
              y =tr(3,1)
              tr(1,1)=a11*x+a12*px+a13*y+a14*tr(4,1)
              tr(2,1)=a21*x+a22*px+a23*y+a24*tr(4,1)
              tr(3,1)=a31*x+a32*px+a33*y+a34*tr(4,1)
              tr(4,1)=a41*x+a42*px+a43*y+a44*tr(4,1)
              x =tr(1,2)
              px=tr(2,2)
              y =tr(3,2)
              tr(1,2)=a11*x+a12*px+a13*y+a14*tr(4,2)
              tr(2,2)=a21*x+a22*px+a23*y+a24*tr(4,2)
              tr(3,2)=a31*x+a32*px+a33*y+a34*tr(4,2)
              tr(4,2)=a41*x+a42*px+a43*y+a44*tr(4,2)
              x =tr(1,3)
              px=tr(2,3)
              y =tr(3,3)
              tr(1,3)=a11*x+a12*px+a13*y+a14*tr(4,3)
              tr(2,3)=a21*x+a22*px+a23*y+a24*tr(4,3)
              tr(3,3)=a31*x+a32*px+a33*y+a34*tr(4,3)
              tr(4,3)=a41*x+a42*px+a43*y+a44*tr(4,3)
              x =tr(1,4)
              px=tr(2,4)
              y =tr(3,4)
              tr(1,4)=a11*x+a12*px+a13*y+a14*tr(4,4)
              tr(2,4)=a21*x+a22*px+a23*y+a24*tr(4,4)
              tr(3,4)=a31*x+a32*px+a33*y+a34*tr(4,4)
              tr(4,4)=a41*x+a42*px+a43*y+a44*tr(4,4)
              x =tr(1,5)
              px=tr(2,5)
              y =tr(3,5)
              tr(1,5)=a11*x+a12*px+a13*y+a14*tr(4,5)+a15
              tr(2,5)=a21*x+a22*px+a23*y+a24*tr(4,5)+a25
              tr(3,5)=a31*x+a32*px+a33*y+a34*tr(4,5)+a35
              tr(4,5)=a41*x+a42*px+a43*y+a44*tr(4,5)+a45
            else
              r1=twiss(ip1,mfitr1)
              r2=twiss(ip1,mfitr2)
              r3=twiss(ip1,mfitr3)
              r4=twiss(ip1,mfitr4)
              if(normal)then
                r15=sqrdet*twiss(ip1,mfitex)
     1               +r4*twiss(ip1,mfitey)-r2*twiss(ip1,mfitepy)
                r25=sqrdet*twiss(ip1,mfitepx)
     1               -r3*twiss(ip1,mfitey)+r1*twiss(ip1,mfitepy)
                r35=sqrdet*twiss(ip1,mfitey)
     1               -r1*twiss(ip1,mfitex)-r2*twiss(ip1,mfitepx)
                r45=sqrdet*twiss(ip1,mfitepy)
     1               -r3*twiss(ip1,mfitex)-r4*twiss(ip1,mfitepx)
                u11= a11*sqrdet-a13*r1-a14*r3
                u12= a12*sqrdet-a13*r2-a14*r4
                u13= a11*r4-a12*r3+a13*sqrdet
                u14=-a11*r2+a12*r1+a14*sqrdet
                u15= a11*r15+a12*r25+a13*r35+a14*r45+a15
                u21= a21*sqrdet-a23*r1-a24*r3
                u22= a22*sqrdet-a23*r2-a24*r4
                u23= a21*r4-a22*r3+a23*sqrdet
                u24=-a21*r2+a22*r1+a24*sqrdet
                u25= a21*r15+a22*r25+a23*r35+a24*r45+a25
                u31= a31*sqrdet-a33*r1-a34*r3
                u32= a32*sqrdet-a33*r2-a34*r4
                u33= a31*r4-a32*r3+a33*sqrdet
                u34=-a31*r2+a32*r1+a34*sqrdet
                u35= a31*r15+a32*r25+a33*r35+a34*r45+a35
                u41= a41*sqrdet-a43*r1-a44*r3
                u42= a42*sqrdet-a43*r2-a44*r4
                u43= a41*r4-a42*r3+a43*sqrdet
                u44=-a41*r2+a42*r1+a44*sqrdet
                u45= a41*r15+a42*r25+a43*r35+a44*r45+a45
              else
                call twiss2r(r1,r2,r3,r4,r1,r2,r3,r4,sqrdet)
                r15=-r1*twiss(ip1,mfitex)-r2*twiss(ip1,mfitepx)
     1               +sqrdet*twiss(ip1,mfitey)
                r25=-r3*twiss(ip1,mfitex)-r4*twiss(ip1,mfitepx)
     1               +sqrdet*twiss(ip1,mfitepy)
                r35=sqrdet*twiss(ip1,mfitex)
     1               +r4*twiss(ip1,mfitey)-r2*twiss(ip1,mfitepy)
                r45=sqrdet*twiss(ip1,mfitepx)
     1               -r3*twiss(ip1,mfitey)+r1*twiss(ip1,mfitepy)
                u11=-a11*r1-a12*r3+a13*sqrdet
                u12=-a11*r2-a12*r4+a14*sqrdet
                u13= a11*sqrdet+a13*r4-a14*r3
                u14= a12*sqrdet-a13*r2+a14*r1
                u15= a11*r15+a12*r25+a13*r35+a14*r45+a15
                u21=-a21*r1-a22*r3+a23*sqrdet
                u22=-a21*r2-a22*r4+a24*sqrdet
                u23= a21*sqrdet+a23*r4-a24*r3
                u24= a22*sqrdet-a23*r2+a24*r1
                u25= a21*r15+a22*r25+a23*r35+a24*r45+a25
                u31=-a31*r1-a32*r3+a33*sqrdet
                u32=-a31*r2-a32*r4+a34*sqrdet
                u33= a31*sqrdet+a33*r4-a34*r3
                u34= a32*sqrdet-a33*r2+a34*r1
                u35= a31*r15+a32*r25+a33*r35+a34*r45+a35
                u41=-a41*r1-a42*r3+a43*sqrdet
                u42=-a41*r2-a42*r4+a44*sqrdet
                u43= a41*sqrdet+a43*r4-a44*r3
                u44= a42*sqrdet-a43*r2+a44*r1
                u45= a41*r15+a42*r25+a43*r35+a44*r45+a45
              endif
              detp=(u11*u22-u21*u12+u33*u44-u43*u34)*.5d0
              normal=detp .gt. xyth
              if(normal)then
                sqrdet=sqrt(detp)
                u11=u11/sqrdet
                u12=u12/sqrdet
                u21=u21/sqrdet
                u22=u22/sqrdet
                u33=u33/sqrdet
                u34=u34/sqrdet
                u43=u43/sqrdet
                u44=u44/sqrdet
                r1=-u31*u22+u32*u21
                r2= u31*u12-u32*u11
                r3=-u41*u22+u42*u21
                r4= u41*u12-u42*u11
                twiss(ip,mfitr1)=r1
                twiss(ip,mfitr2)=r2
                twiss(ip,mfitr3)=r3
                twiss(ip,mfitr4)=r4
c                write(*,'(a,1p6g15.7)')
c     $               'qtwiss-coup-n  ',r1,r2,r3,r4,r1*r4-r2*r3,detp
                twiss(ip,mfitex)=u15*sqrdet
     1               -twiss(ip,mfitr4)*u35+twiss(ip,mfitr2)*u45
                twiss(ip,mfitepx)=u25*sqrdet
     1               +twiss(ip,mfitr3)*u35-twiss(ip,mfitr1)*u45
                twiss(ip,mfitey)=u35*sqrdet+
     1               twiss(ip,mfitr1)*u15+twiss(ip,mfitr2)*u25
                twiss(ip,mfitepy)=u45*sqrdet+
     1               twiss(ip,mfitr3)*u15+twiss(ip,mfitr4)*u25
                aa=bx0*u11-ax0*u12
                cc=(u12-ax0*aa)/bx0
                twiss(ip,mfitax) =-(u21*aa+u22*cc)
                twiss(ip,mfitbx) =u11*aa+u12*cc
                dpsix=atan2(u12,aa)
                bb=by0*u33-ay0*u34
                dd=(u34-ay0*bb)/by0
                twiss(ip,mfitay) =-(u43*bb+u44*dd)
                twiss(ip,mfitby) =u33*bb+u34*dd
                dpsiy=atan2(u34,bb)
              else
                detm=(u31*u42-u32*u41+u13*u24-u14*u23)*.5d0
                sqrdet=sqrt(abs(detm))
                u31=u31/sqrdet
                u32=u32/sqrdet
                u41=u41/sqrdet
                u42=u42/sqrdet
                u13=u13/sqrdet
                u14=u14/sqrdet
                u23=u23/sqrdet
                u24=u24/sqrdet
                r1=-u11*u42+u12*u41
                r2= u11*u32-u12*u31
                r3=-u21*u42+u22*u41
                r4= u21*u32-u22*u31
                twiss(ip,mfitex)=u35*sqrdet
     1               -r4*u15+r2*u25
                twiss(ip,mfitepx)=u45*sqrdet
     1               +r3*u15-r1*u25
                twiss(ip,mfitey)=u15*sqrdet
     1               +r1*u35+r2*u45
                twiss(ip,mfitepy)=u25*sqrdet
     1               +r3*u35+r4*u45
                call r2twiss(r1,r2,r3,r4,
     $               twiss(ip,mfitr1),twiss(ip,mfitr2),
     $               twiss(ip,mfitr3),twiss(ip,mfitr4))
                aa=bx0*u31-ax0*u32
                cc=(u32-ax0*aa)/bx0
                twiss(ip,mfitax) =-(u41*aa+u42*cc)
                twiss(ip,mfitbx) =u31*aa+u32*cc
                if(aa .eq. 0.d0)then
                  dpsix=sign(hpi,u32)
                else
                  dpsix=atan2(u32,aa)
                endif
                bb=by0*u13-ay0*u14
                dd=(u14-ay0*bb)/by0
                twiss(ip,mfitay) =-(u23*bb+u24*dd)
                twiss(ip,mfitby) =u13*bb+u14*dd
                if(bb .eq. 0.d0)then
                  dpsiy=sign(hpi,u14)
                else
                  dpsiy=atan2(u14,bb)
                endif
              endif
            endif
          else
            if(mat)then
              x =tr(1,1)
              y =tr(3,1)
              tr(1,1)=a11*x+a12*tr(2,1)
              tr(2,1)=a21*x+a22*tr(2,1)
              tr(3,1)=a33*y+a34*tr(4,1)
              tr(4,1)=a43*y+a44*tr(4,1)
              x =tr(1,2)
              y =tr(3,2)
              tr(1,2)=a11*x+a12*tr(2,2)
              tr(2,2)=a21*x+a22*tr(2,2)
              tr(3,2)=a33*y+a34*tr(4,2)
              tr(4,2)=a43*y+a44*tr(4,2)
              x =tr(1,3)
              y =tr(3,3)
              tr(1,3)=a11*x+a12*tr(2,3)
              tr(2,3)=a21*x+a22*tr(2,3)
              tr(3,3)=a33*y+a34*tr(4,3)
              tr(4,3)=a43*y+a44*tr(4,3)
              x =tr(1,4)
              y =tr(3,4)
              tr(1,4)=a11*x+a12*tr(2,4)
              tr(2,4)=a21*x+a22*tr(2,4)
              tr(3,4)=a33*y+a34*tr(4,4)
              tr(4,4)=a43*y+a44*tr(4,4)
              x =tr(1,5)
              y =tr(3,5)
              tr(1,5)=a11*x+a12*tr(2,5)+a15
              tr(2,5)=a21*x+a22*tr(2,5)+a25
              tr(3,5)=a33*y+a34*tr(4,5)+a35
              tr(4,5)=a43*y+a44*tr(4,5)+a45
            else
              if(ltyp .eq. 31)then
                ex0 =twiss(ip1,mfitex)*a11
                epx0=twiss(ip1,mfitepx)*a11
                ey0 =twiss(ip1,mfitey)*a11
                epy0=twiss(ip1,mfitepy)*a11
              else
                ex0 =twiss(ip1,mfitex)
                epx0=twiss(ip1,mfitepx)
                ey0 =twiss(ip1,mfitey)
                epy0=twiss(ip1,mfitepy)
              endif
              if(normal)then
                t1= twiss(ip1,mfitr1)*a22-twiss(ip1,mfitr2)*a21
                t2=-twiss(ip1,mfitr1)*a12+twiss(ip1,mfitr2)*a11
                t3= twiss(ip1,mfitr3)*a22-twiss(ip1,mfitr4)*a21
                t4=-twiss(ip1,mfitr3)*a12+twiss(ip1,mfitr4)*a11
                r1= a33*t1+a34*t3
                r2= a33*t2+a34*t4
                r3= a43*t1+a44*t3
                r4= a43*t2+a44*t4
                twiss(ip,mfitr1)=r1
                twiss(ip,mfitr2)=r2
                twiss(ip,mfitr3)=r3
                twiss(ip,mfitr4)=r4
                twiss(ip,mfitex) =
     1               a11*ex0+a12*epx0
     1               +sqrdet*a15-r4*a35+r2*a45
                twiss(ip,mfitepx) =
     1               a21*ex0+a22*epx0
     1               +sqrdet*a25+r3*a35-r1*a45
                twiss(ip,mfitey) =
     1               a33*ey0+a34*epy0
     1               +sqrdet*a35+r1*a15+r2*a25
                twiss(ip,mfitepy)=
     1               a43*ey0+a44*epy0
     1               +sqrdet*a45+r2*a15+r4*a25
                aa=bx0*a11-ax0*a12
                cc=(a12-ax0*aa)/bx0
                twiss(ip,mfitax) =-(a21*aa+a22*cc)
                twiss(ip,mfitbx) =a11*aa+a12*cc
                dpsix=atan2(a12,aa)
                bb=by0*a33-ay0*a34
                dd=(a34-ay0*bb)/by0
                twiss(ip,mfitay) =-(a43*bb+a44*dd)
                twiss(ip,mfitby) =a33*bb+a34*dd
                dpsiy=atan2(a34,bb)
              else
                call twiss2r(
     $               twiss(ip1,mfitr1),twiss(ip1,mfitr2),
     $               twiss(ip1,mfitr3),twiss(ip1,mfitr4),
     $               r1,r2,r3,r4,sqrdet)
                t1= r1*a44-r2*a43
                t2=-r1*a34+r2*a33
                t3= r3*a44-r4*a43
                t4=-r3*a34+r4*a33
                r1= a11*t1+a12*t3
                r2= a11*t2+a12*t4
                r3= a21*t1+a22*t3
                r4= a21*t2+a22*t4
                call r2twiss(r1,r2,r3,r4,
     $               twiss(ip,mfitr1),twiss(ip,mfitr2),
     $               twiss(ip,mfitr3),twiss(ip,mfitr4))
                twiss(ip,mfitex) =
     1               a33*ex0+a34*epx0
     1               +sqrdet*a35+(-r4*a15+r2*a25)
                twiss(ip,mfitepx) =
     1               a43*ex0+a44*epx0
     1               +sqrdet*a45+(r3*a15-r1*a25)
                twiss(ip,mfitey) =
     1               a11*ey0+a12*epy0
     1               +sqrdet*a15+(r1*a35+r2*a45)
                twiss(ip,mfitepy)=
     1               a21*ey0+a22*epy0
     1               +sqrdet*a25+(r3*a35+r4*a45)
                aa=bx0*a33-ax0*a34
                cc=(a34-ax0*aa)/bx0
                twiss(ip,mfitax) =-(a43*aa+a44*cc)
                twiss(ip,mfitbx) =a33*aa+a34*cc
                dpsix=atan2(a34,aa)
                bb=by0*a11-ay0*a12
                dd=(a12-ay0*bb)/by0
                twiss(ip,mfitay) =-(a21*bb+a22*dd)
                twiss(ip,mfitby) =a11*bb+a12*dd
                dpsiy=atan2(a12,bb)
              endif
            endif
          endif
 30       if(.not. mat)then
            if(orbitcal)then
              twiss(ip,mfitdx:mfitddp)=cod
            endif
            twiss(ip,mfitnx)=twiss(ip1,mfitnx)+dpsix
            twiss(ip,mfitny)=twiss(ip1,mfitny)+dpsiy
          endif
        elseif(.not. mat)then
          twiss(ip,1:ntfun)=twiss(ip1,1:ntfun)
        endif
 10   continue
 9000 calpol=calpol0
      trf0=trf00
      vcphic=vcphic0
      vcalpha=vcalpha0
      return
      end

      subroutine qtrans(latt,gammab,la,lb,trans,cod,over)
      use tfstk
      use ffs
      use tffitcode
      implicit none
      integer*4 latt(2,nlat),la,lb,la1,lb1
      real*8 gammab(nlat),trans(4,5),cod(6),fra,frb
      logical*4 over
      call tffsbound1(nlat,latt,la,lb,la1,fra,lb1,frb)
c      write(*,*)'qtrans ',la,lb,la1,lb1,fra,frb
      cod(5)=0.d0
      call qcod(latt,gammab,1,
     $     la1,fra,lb1,frb,trans,cod,.true.,over)
      return
      end

      subroutine qcod(latt,gammab,idp,
     $     la,fra,lb,frb,
     $     trans,cod0,codfnd,over)
      use tfstk
      use ffs
      use tffitcode
      implicit none
      real*8 conv,cx,bx,cy,by,r0
      integer*4 itmax
      parameter (conv=1.d-20,itmax=15)
      integer*4 latt(2,nlat),idp,la,lb,it,i
      real*8 gammab(nlat),fra,frb,r
      real*8 trans(4,5),cod(6),cod0(6),trans1(4,5),transb(4,5),
     $     transe(4,5),ftwiss(ntwissfun),trans2(4,5),cod00(6)
      logical*4 over,codfnd
      it=0
      r0=1.d100
      cod00=cod0
      do while(it .le. itmax)
        cod=cod0
        if(fra .gt. 0.d0)then
          call qtwissfrac1(ftwiss,latt,0.d0,gammab,
     $         transb,cod,idp,
     $         la,fra,1.d0,.true.,.true.,over)
          call qtwiss1(latt,rlist(iftwis),gammab,idp,la+1,lb,
     $         trans1,cod,.true.,over)
          do i=1,5
            trans2(1,i)=trans1(1,1)*transb(1,i)+trans1(1,2)*transb(2,i)
     $                 +trans1(1,3)*transb(3,i)+trans1(1,4)*transb(4,i)
            trans2(2,i)=trans1(2,1)*transb(1,i)+trans1(2,2)*transb(2,i)
     $                 +trans1(2,3)*transb(3,i)+trans1(2,4)*transb(4,i)
            trans2(3,i)=trans1(3,1)*transb(1,i)+trans1(3,2)*transb(2,i)
     $                 +trans1(3,3)*transb(3,i)+trans1(3,4)*transb(4,i)
            trans2(4,i)=trans1(4,1)*transb(1,i)+trans1(4,2)*transb(2,i)
     $                 +trans1(4,3)*transb(3,i)+trans1(4,4)*transb(4,i)
          enddo
          trans2(:,5)=trans2(:,5)+trans1(:,5)
        else
          call qtwiss1(latt,rlist(iftwis),gammab,idp,la,lb,
     $         trans2,cod,.true.,over)
        endif
        if(frb .gt. 0.d0)then
          call qtwissfrac1(ftwiss,latt,0.d0,gammab,
     $         transe,cod,idp,
     $         lb,0.d0,frb,.true.,.true.,over)
          do i=1,5
            trans(1,i)=transe(1,1)*trans2(1,i)+transe(1,2)*trans2(2,i)
     $                +transe(1,3)*trans2(3,i)+transe(1,4)*trans2(4,i)
            trans(2,i)=transe(2,1)*trans2(1,i)+transe(2,2)*trans2(2,i)
     $                +transe(2,3)*trans2(3,i)+transe(2,4)*trans2(4,i)
            trans(3,i)=transe(3,1)*trans2(1,i)+transe(3,2)*trans2(2,i)
     $                +transe(3,3)*trans2(3,i)+transe(3,4)*trans2(4,i)
            trans(4,i)=transe(4,1)*trans2(1,i)+transe(4,2)*trans2(2,i)
     $                +transe(4,3)*trans2(3,i)+transe(4,4)*trans2(4,i)
          enddo
          trans(:,5)=trans(:,5)+transe(:,5)
        else
          trans=trans2
        endif
        if(.not. orbitcal)then
          codfnd=.true.
        endif
        if(codfnd)then
          cod0=cod
          return
        endif
        if(over)then
          codfnd=.false.
          return
        endif
        cx=.5d0*(trans(1,1)+trans(2,2))
        if(abs(cx) .gt. 1.d0)then
          cx=1.d0/cx
        endif
        bx=abs(trans(1,2)/sqrt(max(1.d-8,1.d0-cx**2)))
        cy=.5d0*(trans(3,3)+trans(4,4))
        if(abs(cy) .gt. 1.d0)then
          cy=1.d0/cy
        endif
        by=abs(trans(3,4)/sqrt(max(1.d-8,1.d0-cy**2)))
        r=(cod(1)-cod0(1))**2+(bx*(cod(2)-cod0(2)))**2
     $       +(cod(3)-cod0(3))**2+(by*(cod(4)-cod0(4)))**2
        if(r .le. conv)then
          codfnd=.true.
          return
        endif
        it=it+1
        if(r .gt. r0)then
          cod0=.5d0*(cod00+cod0)
        else
          r0=r
          cod00=cod0
          cod(1)=-cod(1)+trans(1,1)*cod0(1)+trans(1,2)*cod0(2)
     $         +trans(1,3)*cod0(3)+trans(1,4)*cod0(4)
          cod(2)=-cod(2)+trans(2,1)*cod0(1)+trans(2,2)*cod0(2)
     $         +trans(2,3)*cod0(3)+trans(2,4)*cod0(4)
          cod(3)=-cod(3)+trans(3,1)*cod0(1)+trans(3,2)*cod0(2)
     $         +trans(3,3)*cod0(3)+trans(3,4)*cod0(4)
          cod(4)=-cod(4)+trans(4,1)*cod0(1)+trans(4,2)*cod0(2)
     $         +trans(4,3)*cod0(3)+trans(4,4)*cod0(4)
          trans1=trans
          trans1(1,1)=trans1(1,1)-1.d0
          trans1(2,2)=trans1(2,2)-1.d0
          trans1(3,3)=trans1(3,3)-1.d0
          trans1(4,4)=trans1(4,4)-1.d0
          call tsolvg(trans1,cod,cod0,4,4,4)
        endif
      enddo
      codfnd=.false.
      return
      end

      subroutine qtwissfrac(ftwiss,latt,twiss,gammab,l,fr,over)
      use tfstk
      use ffs
      use tffitcode
      implicit none
      integer*4 latt(2,nlat),l
      real*8 twiss(nlat,-ndim:ndim,ntwissfun),gammab(nlat),fr,
     $     ftwiss(ntwissfun),trans(4,5),cod(6)
      logical*4 over
      call qtwissfrac1(ftwiss,latt,twiss,gammab,trans,cod,
     $     0,l,0.d0,fr,.false.,.false.,over)
      return
      end

      subroutine qtwissfrac1(ftwiss,latt,twiss,gammab,
     $     trans,cod,idp,l,fr1,fr2,mat,force,over)
      use tfstk
      use ffs
      use tffitcode
      implicit none
      integer*4 latt(2,nlat),idp,l,i,nvar
      real*8 twiss(nlat,-ndim:ndim,ntwissfun),gammab(nlat),
     $     vsave(100),twisss(27),ftwiss(ntwissfun),
     $     trans(4,5),cod(6),fr1,fr2,gb0,gb1,dgb
      logical*4 over,chg,mat,force
      call qfracsave(latt(1,l),vsave,nvar,ideal,.true.)
      call qfraccomp(latt(1,l),fr1,fr2,ideal,chg)
      gb0=gammab(l)
      gb1=gammab(l+1)
      dgb=gb1-gb0
      if(chg .or. force)then
        gammab(l)=gb0+fr1*dgb
        gammab(l+1)=gb0+fr2*dgb
        pgev=gammab(l)*amass
        call tphyzp
        if(mat)then
          call qtwiss1(latt,twiss,gammab,idp,l,l+1,
     $         trans,cod,.true.,over)
        elseif(force)then
          call qtwiss(latt,twiss,gammab,idp,l,l+1,over)
        else
c          forall(i=1:ntwissfun)twisss(i)=twiss(l+1,idp,i)
          twisss(1:ntwissfun)=twiss(l+1,idp,1:ntwissfun)
          call qtwiss(latt,twiss,gammab,idp,l,l+1,over)
          ftwiss(1:ntwissfun)=twiss(l+1,idp,1:ntwissfun)
          twiss(l+1,idp,1:ntwissfun)=twisss(1:ntwissfun)
c          do i=1,ntwissfun
c            ftwiss(i)=twiss(l+1,idp,i)
c            twiss(l+1,idp,i)=twisss(i)
c          enddo
        endif
        gammab(l)=gb0
        gammab(l+1)=gb1
        if(chg)then
          call qfracsave(latt(1,l),vsave,nvar,ideal,.false.)
        endif
      else
        forall(i=1:ntwissfun) ftwiss(i)=twiss(l+1,idp,i)
      endif
      return
      end

      subroutine qfracsave(latt,vsave,nvar,ideal,save)
      use tfstk
      implicit none
      include 'inc/MACCODE.inc'
      include 'inc/MACKW.inc'
      integer*4 latt(2),lt,nvar
      real*8 vsave(1)
      logical*4 ideal,save
      if(save)then
        lt=idtype(latt(1))
        nvar=kytbl(kwmax,lt)-1
        if(ideal)then
          call tmov(rlist(idval(latt(1))+1),vsave,nvar)
        else
          call tmov(rlist(latt(2)+1),vsave,nvar)
        endif
      else
        if(ideal)then
          call tmov(vsave,rlist(idval(latt(1))+1),nvar)
        else
          call tmov(vsave,rlist(latt(2)+1),nvar)
        endif
      endif
      return
      end

      subroutine qfraccomp(latt,rx1,rx2,ideal,chg)
      use tfstk
      implicit none
      include 'inc/MACCODE.inc'
      include 'inc/MACKW.inc'
      integer*4 latt(2),ip,lt,ifr
      real*8 r,dl,rx1,rx2,f1,f2,fr0
      logical*4 ideal,chg
      chg=.false.
      r=rx2-rx1
      if(r .eq. 1.d0)then
        return
      endif
      if(rx1 .eq. 0.d0)then
        f1=1.d0
      else
        f1=0.d0
      endif
      if(rx2 .eq. 1.d0)then
        f2=1.d0
      else
        f2=0.d0
      endif
      lt=idtype(latt(1))
      if(ideal)then
        ip=idval(latt(1))
      else
        ip=latt(2)
      endif
      go to (1100,1200,1010,1400,1010,1600,1010,1600,1010,1600,
     1       1010,1600,1010,1010,1010,1010,1010,1010,1010,1010,
     1       1600,2200,1010,1010,1010,1010,1010,1010,1010,1010,
     1       3100,3200),lt
      go to 1010
 1100 go to 9000
 1200 ifr=ip+kytbl(kwFRMD,lt)
      if(rlist(ifr) .eq. 0.d0)then
        rlist(ip+kytbl(kwF1,icBEND))=0.d0
      endif
      rlist(ifr)=-f1-2.d0*f2
      if(r .ne. 0.d0)then
        if(rlist(ip+ilist(1,ip)) .gt. 0.d0)then
          rlist(ip+kytbl(kwE1,icBEND))=
     $         rlist(ip+kytbl(kwE1,icBEND))*f1/r
          rlist(ip+kytbl(kwE2,icBEND))=
     $         rlist(ip+kytbl(kwE2,icBEND))*f2/r
        else
          rlist(ip+kytbl(kwE1,icBEND))=
     $         rlist(ip+kytbl(kwE1,icBEND))*f2/r
          rlist(ip+kytbl(kwE2,icBEND))=
     $         rlist(ip+kytbl(kwE2,icBEND))*f1/r
        endif
      endif
      rlist(ip+kytbl(kwANGL,icBEND))=
     $     rlist(ip+kytbl(kwANGL,icBEND))*r
      rlist(ip+kytbl(kwK1,icBEND))=rlist(ip+kytbl(kwK1,icBEND))*r
      rlist(ip+kytbl(kwK0,icBEND))=rlist(ip+kytbl(kwK0,icBEND))*r
c      write(*,*)'qfraccomp ',r,
c     $     rlist(ip+kytbl(kwANGL,icBEND)),
c     $     rlist(ip+kytbl(kwK1,icBEND)),
c     $     rlist(ip+kytbl(kwK0,icBEND))
      go to 9000
 1400 rlist(ip+2)=rlist(ip+2)*r
      go to 8000
 1600 rlist(ip+2)=rlist(ip+2)*r
      go to 9000
 2200 rlist(ip+kytbl(kwK0,icMULT):ip+kytbl(kwMAX,icMULT)-1)=
     $       rlist(ip+kytbl(kwK0,icMULT):ip+kytbl(kwMAX,icMULT)-1)*r
      dl=(1.d0-r)*rlist(ip+1)*.5d0
      rlist(ip+3)=rlist(ip+3)-dl*sin(rlist(ip+6))
      rlist(ip+4)=rlist(ip+4)-dl*sin(rlist(ip+7))
      rlist(ip+5)=rlist(ip+5)
     $     +dl*(1.d0-cos(rlist(ip+6))*cos(rlist(ip+7)))
      rlist(ip+15)=rlist(ip+15)*r
      rlist(ip+kytbl(kwW1,icMULT))=rlist(ip+kytbl(kwW1,icMULT))*r
      if(rlist(ip+kytbl(kwANGL,icMULT)) .ne. 0.d0)then
        ifr=ip+kytbl(kwFRMD,lt)
        if(rlist(ifr) .eq. 0.d0)then
          rlist(ip+kytbl(kwF1,icMULT))=0.d0
        endif
        rlist(ifr)=-f1-2.d0*f2
        if(rlist(ip+ilist(1,ip)) .gt. 0.d0)then
          rlist(ip+kytbl(kwE1,icMULT))=
     $         rlist(ip+kytbl(kwE1,icMULT))*f1/r
          rlist(ip+kytbl(kwE2,icMULT))=
     $         rlist(ip+kytbl(kwE2,icMULT))*f2/r
        else
          rlist(ip+kytbl(kwE1,icMULT))=
     $         rlist(ip+kytbl(kwE1,icMULT))*f2/r
          rlist(ip+kytbl(kwE2,icMULT))=
     $         rlist(ip+kytbl(kwE2,icMULT))*f1/r
        endif
        rlist(ip+kytbl(kwANGL,icMULT))=
     $       rlist(ip+kytbl(kwANGL,icMULT))*r
        go to 9000
      endif
      go to 8000
 3100 rlist(ip+2)=rlist(ip+2)*r
      rlist(ip+9)=rlist(ip+9)*r
      rlist(ip+16)=rlist(ip+16)*r
      go to 8000
 3200 rlist(ip+2)=rlist(ip+2)*r
      rlist(ip+9)=rlist(ip+9)*r
      go to 9000
 8000 ifr=ip+kytbl(kwFRMD,lt)
      fr0=rlist(ifr)
      if(fr0 .eq. 0.d0 .or. fr0 .eq. 2)then
        if(kytbl(kwF1,lt) .ne. 0)then
          rlist(ip+kytbl(kwF1,lt))=0.d0
        endif
      endif
      if(fr0 .eq. 0.d0 .or. fr0 .eq. 1)then
        if(kytbl(kwF2,lt) .ne. 0)then
          rlist(ip+kytbl(kwF2,lt))=0.d0
        endif
      endif
      if(fr0 .eq. 0)then
        fr0=3.d0
      endif
      rlist(ifr)=0.d0
      if(f1 .ne. 0.d0)then
        if(rlist(ip+ilist(1,ip)) .gt. 0.d0)then
          if(fr0 .eq. 3.d0 .or. fr0 .eq. 1.d0)then
            rlist(ifr)=1.d0
          endif
        else
          if(fr0 .eq. 3.d0 .or. fr0 .eq. 2.d0)then
            rlist(ifr)=2.d0
          endif
        endif
      endif
      if(f2 .ne. 0.d0)then
        if(rlist(ip+ilist(1,ip)) .gt. 0.d0)then
          if(fr0 .eq. 3.d0 .or. fr0 .eq. 2.d0)then
            rlist(ifr)=rlist(ifr)+2.d0
          endif
        else
          if(fr0 .eq. 3.d0 .or. fr0 .eq. 1.d0)then
            rlist(ifr)=rlist(ifr)+1.d0
          endif
        endif
      endif
      if(rlist(ifr) .eq. 0.d0)then
        rlist(ifr)=-4.d0
      endif
      go to 9000
 9000 if(kytbl(kwL,lt) .ne. 0)then
        rlist(ip+kytbl(kwL,lt))=rlist(ip+kytbl(kwL,lt))*r
      endif
      chg=.true.
 1010 return
      end