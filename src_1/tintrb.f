      module intrb
      implicit none
      real*8 a1,a2
      end module

      subroutine tintrb(trans,cod,beam,bmi,al,al1,ll)
      use intrb
      use temw, diagr=>r, diagri=>ri
      use touschek_table
      use tfstk
      use ffs_flag
      use tmacro
      implicit none
      real*8 fintrb
      external fintrb
      integer*4 i,j,ll
      real*8 trans(6,12),cod(6),beam(42),bmi(21)
      real*8 pl(3,3),r(3,3),eig(3),xx(3,3),xxs(3,3),
     $     touckf,bint,e1,e2,e3
      real*8 xp(3,3),transw(6,6),
     $     al,al1,pxi,pyi,s,pr,pzi,alx,ale,alz,hi,a,b,d,vol,
     $     bm,ptrans,extrans,eytrans,eztrans,tf,aez,aex0,aey0,
     $     aez0,aexz,aeyz,f1,f2,f3,bn,bmax,bmin,ci,pvol,vol1,
     $     transa(6,6),transsp(6,6)
      integer*4 ia(6,6)
      real*8 trans1(6,6),trans2(6,6)
c     real*8  vmin/0.d0/
      data ia/ 1, 2, 4, 7,11,16,
     1         2, 3, 5, 8,12,17,
     1         4, 5, 6, 9,13,18,
     1         7, 8, 9,10,14,19,
     1        11,12,13,14,15,20,
     1        16,17,18,19,20,21/
      if(al .le. 0.d0)then
        bmi=0.d0
        return
      endif
      pxi=cod(2)
      pyi=cod(4)
      s=pxi**2+pyi**2
      pr=1.d0+cod(6)
      pzi=pr*(1.d0+sqrt1(-s/pr**2))
c      pzi=pr*sqrt(1.d0-s/pr**2)
c      pzi=pr-s/(pr+sqrt(pr**2-s))
      call tinitr(trans1)
      alx=(.5d0*al-al1)
      ale=alx/pzi
      alz=ale/pzi**2
      trans1(1,2)=ale+pxi**2*alz
      trans1(1,4)=pxi*pyi*alz
      trans1(1,6)=-pxi*alz*pr
      trans1(3,2)=trans1(1,4)
      trans1(3,4)=ale+pyi**2*alz
      trans1(3,6)=-pyi*alz*pr
      trans1(5,2)=trans1(1,6)
      trans1(5,4)=trans1(3,6)
      hi=p2h(p0*pr)
c      hi=p0*pr*sqrt(1.d0+1.d0/(p0*pr)**2)
c      hi=sqrt(1.d0+(pr*p0)**2)
      trans1(5,6)=h0/hi**3*alx+s*alz
      if(wspac)then
        call tmov(beam(22),bmi,21)
        call tadd(bmi,beam,bmi,21)
        call tmulbs(bmi,trans1,.false.,.false.)
        call twspace(transsp,cod,al,bmi)
        call tmov(trans1,trans2,36)
        call tmultr(trans2,transsp,6)
        call tinv(trans1,transa,6,6)
        call tmultr(trans2,transa,6)
        call tmultr(trans,trans2,irad)
        call tmulbs(beam,trans2,.false.,.false.)
      endif
      if(intra)then
        call tmov(beam(22),bmi,21)
c        call tmov(trans,transa,36)
c      call tadd(transa,trans(1,7),transa,36)
c        call tmulbs(bmi,transa,.false.)
        call tadd(bmi,beam,bmi,21)
        if(caltouck)then
          call tmov(diagr,transw,36)
          call tmultr(transw,trans,6)
        endif
        a=p0**2/(hi+1.d0)
        b=a/hi
        d=1.d0/hi
        call tinitr(trans2)
        trans2(1,1)=1.d0+a*pxi**2
        trans2(1,3)=a*pxi*pyi
        trans2(1,5)=a*pxi*pzi
        trans2(3,1)=trans2(1,3)
        trans2(3,3)=1.d0+a*pyi**2
        trans2(3,5)=a*pyi*pzi
        trans2(5,1)=trans2(1,5)
        trans2(5,3)=trans2(3,5)
        trans2(5,5)=1.d0+a*pzi**2
        trans2(2,2)=d+b*(pzi**2+pyi**2)
        trans2(2,4)=-b*pxi*pyi
        trans2(2,6)=-b*pxi*pzi
        trans2(4,2)=trans2(2,4)
        trans2(4,4)=d+b*(pzi**2+pxi**2)
        trans2(4,6)=-b*pyi*pzi
        trans2(6,2)=trans2(2,6)
        trans2(6,4)=trans2(4,6)
        trans2(6,6)=d+b*s
        do 3010 i=1,6
          trans2(i,2)=trans2(i,2)-pxi/pzi*trans2(i,6)
          trans2(i,4)=trans2(i,4)-pyi/pzi*trans2(i,6)
          trans2(i,5)=(pxi*trans2(i,1)+pyi*trans2(i,3)
     $         +pzi*trans2(i,5))/pr
          trans2(i,6)=pr/pzi*trans2(i,6)
 3010   continue
        call tmultr(trans1,trans2,6)
        call tmulbs(bmi,trans1,.false.,.false.)
        xx(1,1)=bmi(ia(1,1))
        xx(2,1)=bmi(ia(3,1))
        xx(3,1)=bmi(ia(5,1))
        xx(2,2)=bmi(ia(3,3))
        xx(3,2)=bmi(ia(5,3))
        xx(3,3)=bmi(ia(5,5))
        call eigs33(xx,r,eig)
        vol1=sqrt(max(1.d-80,eig(1)*eig(2)*eig(3)))
        vol=sqrt((4.d0*pi)**3)*vol1
        bm=sqrt(min(abs(eig(1)),abs(eig(2)),abs(eig(3))))
        call tmov(xx,xxs,9)
        xp(1,1)=bmi(ia(1,2))
        xp(1,2)=bmi(ia(1,4))
        xp(1,3)=bmi(ia(1,6))
        xp(2,1)=bmi(ia(3,2))
        xp(2,2)=bmi(ia(3,4))
        xp(2,3)=bmi(ia(3,6))
        xp(3,1)=bmi(ia(5,2))
        xp(3,2)=bmi(ia(5,4))
        xp(3,3)=bmi(ia(5,6))
        call sols33(xxs,xp)
        pl(1,1)=bmi(ia(2,2))
     1       -bmi(ia(2,1))*xp(1,1)-bmi(ia(2,3))*xp(2,1)
     $       -bmi(ia(2,5))*xp(3,1)
        pl(2,1)=bmi(ia(4,2))
     1       -bmi(ia(4,1))*xp(1,1)-bmi(ia(4,3))*xp(2,1)
     $       -bmi(ia(4,5))*xp(3,1)
        pl(3,1)=bmi(ia(6,2))
     1       -bmi(ia(6,1))*xp(1,1)-bmi(ia(6,3))*xp(2,1)
     $       -bmi(ia(6,5))*xp(3,1)
        pl(2,2)=bmi(ia(4,4))
     1       -bmi(ia(4,1))*xp(1,2)-bmi(ia(4,3))*xp(2,2)
     $       -bmi(ia(4,5))*xp(3,2)
        pl(3,2)=bmi(ia(6,4))
     1       -bmi(ia(6,1))*xp(1,2)-bmi(ia(6,3))*xp(2,2)
     $       -bmi(ia(6,5))*xp(3,2)
        pl(3,3)=bmi(ia(6,6))
     1       -bmi(ia(6,1))*xp(1,3)-bmi(ia(6,3))*xp(2,3)
     $       -bmi(ia(6,5))*xp(3,3)
        call eigs33(pl,r,eig)
        ptrans=sqrt(abs(eig(1)+eig(2)+eig(3)))
        pvol=sqrt(max(1.d-80,eig(1)*eig(2)*eig(3)))
        if(vol .ne. 0.d0 .and. caltouck)then
          if(ptrans .ne. 0.d0)then
            call tmultr(transw,trans1,6)
            call tinv(transw,trans2,6,6)
            extrans=(trans2(1,6)**2+trans2(2,6)**2)*ptrans**2
            eytrans=(trans2(3,6)**2+trans2(4,6)**2)*ptrans**2
            eztrans=(trans2(5,6)**2+trans2(6,6)**2)*ptrans**2
            tf=al/vol/(ptrans*p0)**3
            if(eztrans .ne. 0.d0)then
              do 4010 i=1,ntouckl
                aez=(.002d0+i*.002d0)**2
     $               *(diagri(5,6)**2+diagri(6,6)**2)
                touckl(i)=touckl(i)+touckf(aez/eztrans)*tf
                toucke(i,ll)=toucke(i,ll)+touckf(aez/eztrans)*tf
 4010         continue
              do 4020 i=1,ntouckx
                aex0=(tampl(i,1)**2)*(abs(emx)+abs(emy))
                aey0=(tampl(i,2)**2)*(abs(emx)+abs(emy))
                do 4030 j=1,ntouckz
                  aez0=(tampl(j,3)**2)*abs(emz)
                  aexz=1.d0/(extrans/aex0+eztrans/aez0)
                  touckm(j,i,1)=touckm(j,i,1)+touckf(aexz)*tf
                  aeyz=1.d0/(eytrans/aey0+eztrans/aez0)
                  touckm(j,i,2)=touckm(j,i,2)+touckf(aeyz)*tf
 4030           continue
 4020         continue
            endif
          endif
        else
          call tfill(touckl,1.d20,ntouckl)
          call tfill(touckm,1.d20,ntouckx*ntouckz*3)
        endif
        a1=eig(1)/eig(2)
        a2=eig(1)/eig(3)
        f1=2.d0*bint(fintrb,0.d0,hpi,1.d-3,1.d-19)*eig(1)
        a1=eig(2)/eig(3)
        a2=eig(2)/eig(1)
        f2=2.d0*bint(fintrb,0.d0,hpi,1.d-3,1.d-19)*eig(2)
        a1=eig(3)/eig(1)
        a2=eig(3)/eig(2)
        f3=2.d0*bint(fintrb,0.d0,hpi,1.d-3,1.d-19)*eig(3)
        e1=f2+f3-2.d0*f1
        e2=f3+f1-2.d0*f2
        e3=f1+f2-2.d0*f3
        pl(1,1)=r(1,1)*r(1,1)*e1+r(1,2)*r(1,2)*e2+r(1,3)*r(1,3)*e3
        pl(2,1)=r(2,1)*r(1,1)*e1+r(2,2)*r(1,2)*e2+r(2,3)*r(1,3)*e3
        pl(3,1)=r(3,1)*r(1,1)*e1+r(3,2)*r(1,2)*e2+r(3,3)*r(1,3)*e3
        pl(2,2)=r(2,1)*r(2,1)*e1+r(2,2)*r(2,2)*e2+r(2,3)*r(2,3)*e3
        pl(3,2)=r(3,1)*r(2,1)*e1+r(3,2)*r(2,2)*e2+r(3,3)*r(2,3)*e3
        pl(3,3)=r(3,1)*r(3,1)*e1+r(3,2)*r(3,2)*e2+r(3,3)*r(3,3)*e3
        bn=abs(vol/pbunch)**(1.d0/3.d0)
        bmax=max(1.d-80,min(bm,bn))
        bmin=max(rclassic/(ptrans*p0)**2,
     1       sqrt(abs(
     1       vol/pi/(ptrans*p0/h0*c)/pbunch
     $       /max(taurdx,taurdy,taurdz)))
     1       )
c     write(*,*)'bmin,bmax,vol ',bmin,bmax,vol
c     bmin=rclassic
        ci=cintrb*al*log(2.d0*bmax/bmin)/vol1/pvol/h0**4
c        write(*,*)'tintrb ',vol1*pvol,ci,pl
c     write(*,*)log(2.d0*bmax/bmin)
c     if(ci .gt. vmin)then
c     vmin=ci
c     write(*,*)vmin,cintrb,bmin
c     endif
        bmi=0.d0
        bmi(ia(2,2))=ci*pl(1,1)
        bmi(ia(4,2))=ci*pl(2,1)
        bmi(ia(6,2))=ci*pl(3,1)
        bmi(ia(4,4))=ci*pl(2,2)
        bmi(ia(6,4))=ci*pl(3,2)
        bmi(ia(6,6))=ci*pl(3,3)
        call tinv(trans1,trans2,6,6)
        call tmulbs(bmi,trans2,.false.,.false.)
        call tadd(beam,bmi,beam,21)
        call tinv(trans,transa,6,6)
        call tmulbs(bmi,transa,.false.,.false.)
      endif
      return
      end

      real*8 function fintrb(t)
      use intrb
      implicit none
      real*8 t,cost,sqsint
      cost=cos(t)
      sqsint=(1.d0-cost)*(1.d0+cost)
      fintrb=sqsint*cost/
     1       sqrt((sqsint+a1*cost**2)*(sqsint+a2*cost**2))
c     fintrb=t/sqrt(((1.d0-a1)*t+a1)*((1.d0-a2)*t+a2))
      return
      end

      real*8 function touckf(x)
c
c Approximation of C[x]/x \propto 1/tau .
c
      implicit none
      real*8 x,eeuler,a,b
c      parameter (eeuler=7.98221278918726d0,a=5.5077d0,b=1.1274d0)
      parameter (eeuler=7.982212789187259d0,a=5.62966d0,b=0.75159d0)
      if(x .eq. 0.d0)then
        touckf=1.d200
      else
        touckf=(log(1.d0/x/eeuler+1.d0)*exp(-x)
     1          *(b+eeuler*x)/(b+x*(a+2.d0*x)))/x
      endif
      return
      end

      subroutine twspace(trans,cod,al,beam)
      use tfstk
      use tmacro
      implicit none
      real*8 trans(6,6),cod(6),al,beam(21),
     $     xx1,yy1,xy1,u,v,a,c2,s2,sx,sy,p1,h1,f,akx,aky,
     $     aks,akd,sigzsq
      integer*4 ia(6,6)
      data ia/ 1, 2, 4, 7,11,16,
     1         2, 3, 5, 8,12,17,
     1         4, 5, 6, 9,13,18,
     1         7, 8, 9,10,14,19,
     1        11,12,13,14,15,20,
     1        16,17,18,19,20,21/
      sigzsq=beam(ia(5,5))
      xx1=beam(ia(1,1))-beam(ia(5,1))**2/sigzsq
      yy1=beam(ia(3,3))-beam(ia(5,3))**2/sigzsq
      xy1=beam(ia(3,1))-beam(ia(5,1))*beam(ia(5,3))/sigzsq
      u=xx1-yy1
      v=2.d0*xy1
      a=sqrt(u**2+v**2)
      c2=u/a
      s2=v/a
      sx=(xx1+yy1)*.5d0
      sy=sqrt(sx-a*.5d0)
      sx=sqrt(sx+a*.5d0)
c      write(*,*)sy,a,u,v,xx1,yy1
      p1=(1.d0+cod(6))*p0
      h1=p2h(p1)
c      h1=p1*sqrt(1.d0+1.d0/p1**2)
c      h1=sqrt(1.d0+p1**2)
      f=2.d0*pbunch*rclassic*al/(p1**2*h1*(sx+sy)
     $     *sqrt(2.d0*pi*sigzsq))
      akx=f/sx
      aky=f/sy
      aks=(akx+aky)*.5d0
      akd=(akx-aky)*.5d0
      call tinitr(trans)
      trans(2,1)=aks+akd*c2
      trans(2,3)=akd*s2
      trans(4,1)=trans(2,3)
      trans(4,3)=aks-akd*c2
      return
      end

      subroutine qwspac(trans,cod,al,beam,coup)
      use tfstk
      use tmacro
      implicit none
      real*8 trans(4,5),cod(6),al,beam(42),trs(6,6)
      logical*4 coup
      if(al .eq. 0.d0)then
        return
      endif
      call twspace(trs,cod,al,beam)
      if(coup)then
        trans(1,1)=trans(1,1)+trans(1,2)*trs(2,1)+trans(1,4)*trs(4,1)
        trans(2,1)=trans(2,1)+trans(2,2)*trs(2,1)+trans(2,4)*trs(4,1)
        trans(3,1)=trans(3,1)+trans(3,2)*trs(2,1)+trans(3,4)*trs(4,1)
        trans(4,1)=trans(4,1)+trans(4,2)*trs(2,1)+trans(4,4)*trs(4,1)
        trans(1,3)=trans(1,3)+trans(1,2)*trs(2,3)+trans(1,4)*trs(4,3)
        trans(2,3)=trans(2,3)+trans(2,2)*trs(2,3)+trans(2,4)*trs(4,3)
        trans(3,3)=trans(3,3)+trans(3,2)*trs(2,3)+trans(3,4)*trs(4,3)
        trans(4,3)=trans(4,3)+trans(4,2)*trs(2,3)+trans(4,4)*trs(4,3)
      else
        trans(1,1)=trans(1,1)+trans(1,2)*trs(2,1)
        trans(2,1)=trans(2,1)+trans(2,2)*trs(2,1)
        trans(3,1)=                               trans(3,4)*trs(4,1)
        trans(4,1)=                               trans(4,4)*trs(4,1)
        trans(3,2)=0.d0
        trans(4,2)=0.d0
        trans(1,3)=           trans(1,2)*trs(2,3)
        trans(2,3)=           trans(2,2)*trs(2,3)
        trans(3,3)=trans(3,3)                    +trans(3,4)*trs(4,3)
        trans(4,3)=trans(4,3)                    +trans(4,4)*trs(4,3)
        trans(1,4)=0.d0
        trans(2,4)=0.d0
      endif
      return
      end

      subroutine twspac(np,x,px,y,py,z,g,dv,pz,al,
     $     cod,beam)
      use tfstk
      use ffs_flag
      use tmacro
      implicit none
      integer*4 np,i
      real*8 x(np),px(np),y(np),py(np),z(np),g(np),dv(np),pz(np),
     $     al,cod(6),beam(42),
     $     xx1,yy1,xy1,a,c1,s1,sx,sy,p1,h1,f,dx,dy,
     $     dx1,dy1,dpx,dpy,pr,u,v,theta,sigzsq,
     $     az,dg,dpr,pr1,fx,fy,fu,xc,yc,zc
      integer*4 ia(6,6)
      data ia/ 1, 2, 4, 7,11,16,
     1         2, 3, 5, 8,12,17,
     1         4, 5, 6, 9,13,18,
     1         7, 8, 9,10,14,19,
     1        11,12,13,14,15,20,
     1        16,17,18,19,20,21/
      sigzsq=beam(ia(5,5))
      xx1=beam(ia(1,1))-beam(ia(5,1))**2/sigzsq
      yy1=beam(ia(3,3))-beam(ia(5,3))**2/sigzsq
      xy1=beam(ia(3,1))-beam(ia(5,1))*beam(ia(5,3))/sigzsq
      u=xx1-yy1
      v=2.d0*xy1
      a=sqrt(u**2+v**2)
      theta=atan2(v,u)*.5d0
      c1=cos(theta)
      s1=sin(theta)
      sx=(xx1+yy1)*.5d0
      sy=sqrt(sx-a*.5d0)
      sx=sqrt(sx+a*.5d0)
      if(selfcod)then
        xc=0.d0
        yc=0.d0
        zc=0.d0
        do i=1,np
          xc=xc+x(i)
          yc=yc+y(i)
          zc=zc+z(i)
        enddo
        xc=xc/np
        yc=yc/np
        zc=zc/np
      else
        xc=cod(1)
        yc=cod(3)
        zc=cod(5)
      endif
      p1=(1.d0+cod(6))*p0
      h1=p2h(p1)
c      h1=p1*sqrt(1.d0+1.d0/p1**2)
      f=pbunch*rclassic*al/(p1**2*h1*sqrt(2.d0*pi*sigzsq))
      do i=1,np
        dx=x(i)-xc
        dy=y(i)-yc
        dx1= dx*c1+dy*s1
        dy1=-dx*s1+dy*c1
        az=f*exp(-.5d0*(z(i)-zc)**2/sigzsq)
        call twspfu(dx1,dy1,sx,sy,fx,fy,fu)
c        bb=bbkick1(dx1,dy1,sx,sy)
c        call bbkick(dcmplx(sx,sy),dcmplx(dx1,dy1),
c     $       bb,1,tr)
c        fx=az*dble(bb)
c        fy=az*dimag(bb)
c        dg=-(z(i)-zc)/sigzsq*az*
c     $       twspu(dx1,dy1,sx,sy,4.d-2,1.d-4)
        fx=-az*fx
        fy=-az*fy
        dg=-(z(i)-zc)/sigzsq*az*fu
        dpx= fx*c1-fy*s1
        dpy= fx*s1+fy*c1
c        dpr=g(i)*(2.d0+g(i))
        dpr=g(i)
        pr=1.d0+dpr
        dpr=dpr+dg
        pr1=1.d0+dpr
        px(i)=(px(i)*pr+dpx)/pr1
        py(i)=(py(i)*pr+dpy)/pr1
c        g(i)=dpr/(1.d0+sqrt(pr1))
        g(i)=dpr
        h1=p2h(p0*pr1)
c        h1=p0*pr1*sqrt(1.d0+1.d0/(p0*pr1)**2)
c        h1=sqrt(1.d0+(p0*pr1)**2)
        dv(i)=-dpr*(1.d0+pr1)/h1/(h1+pr1*h0)+dvfs
      enddo
      return
      end

      module wspf
      implicit none
      real*8 a,b,r,eps
      end module

      real*8 function twspu(x,y,sigx,sigy,epslon,epsabs)
      use wspf
      implicit none
      real*8 x,y,sigx,sigy,u
      real*8 twspurec,epslon,epsabs,
     $     gamma0log,c,d,f0,f1,f2,f3,d2,
     $     ax,ay,r1,sig2,twspf1,rombint
      external twspf1
      if(sigx .lt. sigy)then
        twspu=twspurec(y,x,sigy,sigx,epslon,epsabs)
        return
      endif
      sig2=sigx*(sigx+sigy)
      ax=x/sig2
      ay=y/sig2
      a=.5d0*x*ax
      b=.5d0*y*ay
      r=sigy/sigx
      if(r .eq. 1.d0)then
        u=2.d0*(a+b)
        if(u .eq. 0.d0)then
          twspu=0.d0
        else
          twspu=gamma0log(u)
        endif
        return
      endif
      twspu=2.d0*(a+b/r)
      if(twspu .le. min(epslon,epsabs*10d0))then
        twspu=2.d0*(a+b/r)+log(.5d0+.5d0*r)
      elseif(a+b .lt. 30.d0)then
        twspu=2.d0*rombint(twspf1,0.d0,1.d0,epslon,epsabs)
     $       +log(.5d0+.5d0*r)
      else
        r1=1.d0-r
        u=a+b
        c=r1/u
        d=(a-b)/u
        d2=d**2
        f0=1.d0-d2
        f1=f0-d2
        f2=3.d0-4.d0*d2
        f3=4.d0*f0*f1-f2
        twspu=gamma0log(2.d0*u)
     $       -c*(64.d0*d+c*(-48.d0*f1
     $       +c*(-80.d0*d*f2+c*(210.d0*f3
     $       +c*(756.d0*d*(f2+2.d0*f3)
     $       +c*(3465.d0*(2.d0*(d*f2)**2-1.d0)
     $       +c*(19305.d0*d*(1.d0-4.d0*f1*(f3+f1)))))))))/128.d0
c        dy(1)=-(a+b)**2+2.d0*b*(1.d0-r)
c        r1=1.d0+r
c        ev=exp(-(a+b/r**2)*r1)
c        dy(2)=2.d0*(ev*(b/r**3+r*(a+1.d0/r1))-r/r1)/r1
c        twspu=2.d0*splint(twspf1,0.d0,1.d0,3,dy,
c     $       epslon,epsabs,8)+rlog
      endif
      return
      end

      real*8 function twspurec(x,y,sigx,sigy,epslon,epsabs)
      implicit none
      real*8 x,y,sigy,sigx,twspu,epslon,epsabs
      twspurec=twspu(x,y,sigx,sigy,epslon,epsabs)
      return
      end

      real*8 function twspf1(v)
      use wspf
      implicit none
      real*8 f,t,v,x,w,tsq
      t=(1.d0-r)*(1.d0-v)+r
      tsq=t**2
      f=a+b/tsq
      w=v*(1.d0+t)
      x=w*f
      if(x .lt. 0.001d0)then
        twspf1=f*(1.d0-x/2.d0*(1.d0-x/3.d0*
     $       (1.d0-x/4.d0*(1.d0-x/5.d0*
     $       (1.d0-x/6.d0)))))
      else
        twspf1=(1.d0-exp(-x))/w
      endif
      return
      end

      subroutine twspfu(x,y,sigx,sigy,fx,fy,fu)
      use tfstk
      implicit none
      integer*8 ktaloc,iu
      integer*4 nr,nx,ny,m
      real*8 x,y,sigy,sigx,fx,fy,fu
      parameter (nr=20,nx=60,ny=60,m=(nr+1)*(nx+1)*(ny+1))
      data iu /0/
      if(iu .eq. 0)then
        iu=ktaloc(8*m)
        call twspfuinit(
     $       rlist(iu),rlist(iu+m),rlist(iu+2*m),
     $       rlist(iu+3*m),rlist(iu+4*m),rlist(iu+5*m),
     $       rlist(iu+6*m),rlist(iu+7*m))
      endif
      if(sigx .lt. sigy)then
        call twspfu0(y,x,sigy,sigx,fy,fx,fu,
     $       rlist(iu),rlist(iu+m),rlist(iu+2*m),
     $       rlist(iu+3*m),rlist(iu+4*m),rlist(iu+5*m),
     $       rlist(iu+6*m),rlist(iu+7*m))
      else
        call twspfu0(x,y,sigx,sigy,fx,fy,fu,
     $       rlist(iu),rlist(iu+m),rlist(iu+2*m),
     $       rlist(iu+3*m),rlist(iu+4*m),rlist(iu+5*m),
     $       rlist(iu+6*m),rlist(iu+7*m))
      endif
      return
      end

      subroutine twspfu0(x,y,sigx,sigy,fx,fy,fu,
     $     u,uxx,uyy,uxxyy,urr,uxxrr,uyyrr,uxxyyrr)
      implicit none
      integer*4 nr,nx,i,j,n,ny
      real*8 xm,xstep,x,y,r,sigy,sigx,fx,fy,fu,
     $     rstep,rm,ym,ystep
      parameter (nr=20,nx=60,ny=60,xm=15.d0,ym=30.d0,rm=5.d0)
      parameter (xstep=xm/nx,rstep=rm/nr**2,ystep=ym/ny)
      real*8 u(0:nx,0:ny,0:nr),uxx(0:nx,0:ny,0:nr),
     $     uyy(0:nx,0:ny,0:nr),uxxyy(0:nx,0:ny,0:nr)
      real*8 urr(0:nx,0:ny,0:nr),uxxrr(0:nx,0:ny,0:nr),
     $     uyyrr(0:nx,0:ny,0:nr),uxxyyrr(0:nx,0:ny,0:nr)
      real*8 rl,ax,ay,aax,aay,ar,bax,bay,aax2,aay2,ar2,
     $     br,br2,bax2,bay2,u0,u1,u2,u3,twspu,
     $     uxx0,uxx1,uxx2,uxx3,uyy0,uyy1,uyy2,uyy3,
     $     uxxyy0,uxxyy1,uxxyy2,uxxyy3,
     $     up,uq,ur,us,uyyp,uyyq,uxxr,uxxs
      complex*16 z,bbkick1
      integer*4 i1,j1,n1
      r=sigy/sigx
      rl=sqrt(-log10(r)/rstep)
      n=int(rl)
      if(n .ge. nr)then
        go to 9000
      endif
      ax=abs(x)/sigx/xstep
      i=int(ax)
      if(i .ge. nx)then
        go to 9000
      endif
      ay=abs(y)/sigy/ystep
      j=int(ay)
      if(j .ge. ny)then
        go to 9000
      endif
      i1=i+1
      j1=j+1
      n1=n+1
      bax=ax-i
      bay=ay-j
      br=rl-n
      aax=1.d0-bax
      aay=1.d0-bay
      ar=1.d0-br
      ar2=-br*(ar+1.d0)
      br2=-ar*(br+1.d0)
      aax2=-bax*(aax+1.d0)
      bax2=-aax*(bax+1.d0)
      aay2=-bay*(aay+1.d0)
      bay2=-aay*(bay+1.d0)
c      write(*,*)'twspfu ',sigx,sigy
      u0=ar*(u(i,j,n)+ar2*urr(i,j,n))+
     $     br*(u(i,j,n1)+br2*urr(i,j,n1))
      u1=ar*(u(i1,j,n)+ar2*urr(i1,j,n))+
     $     br*(u(i1,j,n1)+br2*urr(i1,j,n1))
      u2=ar*(u(i,j1,n)+ar2*urr(i,j1,n))+
     $     br*(u(i,j1,n1)+br2*urr(i,j1,n1))
      u3=ar*(u(i1,j1,n)+ar2*urr(i1,j1,n))+
     $     br*(u(i1,j1,n1)+br2*urr(i1,j1,n1))
      uxx0=ar*(uxx(i,j,n)+ar2*uxxrr(i,j,n))+
     $     br*(uxx(i,j,n1)+br2*uxxrr(i,j,n1))
      uxx1=ar*(uxx(i1,j,n)+ar2*uxxrr(i1,j,n))+
     $     br*(uxx(i1,j,n1)+br2*uxxrr(i1,j,n1))
      uxx2=ar*(uxx(i,j1,n)+ar2*uxxrr(i,j1,n))+
     $     br*(uxx(i,j1,n1)+br2*uxxrr(i,j1,n1))
      uxx3=ar*(uxx(i1,j1,n)+ar2*uxxrr(i1,j1,n))+
     $     br*(uxx(i1,j1,n1)+br2*uxxrr(i1,j1,n1))
      uyy0=ar*(uyy(i,j,n)+ar2*uyyrr(i,j,n))+
     $     br*(uyy(i,j,n1)+br2*uyyrr(i,j,n1))
      uyy1=ar*(uyy(i1,j,n)+ar2*uyyrr(i1,j,n))+
     $     br*(uyy(i1,j,n1)+br2*uyyrr(i1,j,n1))
      uyy2=ar*(uyy(i,j1,n)+ar2*uyyrr(i,j1,n))+
     $     br*(uyy(i,j1,n1)+br2*uyyrr(i,j1,n1))
      uyy3=ar*(uyy(i1,j1,n)+ar2*uyyrr(i1,j1,n))+
     $     br*(uyy(i1,j1,n1)+br2*uyyrr(i1,j1,n1))
      uxxyy0=ar*(uxxyy(i,j,n)+ar2*uxxyyrr(i,j,n))+
     $     br*(uxxyy(i,j,n1)+br2*uxxyyrr(i,j,n1))
      uxxyy1=ar*(uxxyy(i1,j,n)+ar2*uxxyyrr(i1,j,n))+
     $     br*(uxxyy(i1,j,n1)+br2*uxxyyrr(i1,j,n1))
      uxxyy2=ar*(uxxyy(i,j1,n)+ar2*uxxyyrr(i,j1,n))+
     $     br*(uxxyy(i,j1,n1)+br2*uxxyyrr(i,j1,n1))
      uxxyy3=ar*(uxxyy(i1,j1,n)+ar2*uxxyyrr(i1,j1,n))+
     $     br*(uxxyy(i1,j1,n1)+br2*uxxyyrr(i1,j1,n1))
      up=aax*(u0+aax2*uxx0)+bax*(u1+bax2*uxx1)
      uq=aax*(u2+aax2*uxx2)+bax*(u3+bax2*uxx3)
      uyyp=aax*(uyy0+aax2*uxxyy0)+bax*(uyy1+bax2*uxxyy1)
      uyyq=aax*(uyy2+aax2*uxxyy2)+bax*(uyy3+bax2*uxxyy3)
      fu=aay*(up+aay2*uyyp)+bay*(uq+bay2*uyyq)
      fy=((uq-up)-(3.d0*aay2+2.d0)*uyyp+(3.d0*bay2+2.d0)*uyyq)
     $     /ystep/sigy
c      write(*,*)'twspfu ',ay,j,fy,uyy0,uyy2,uyyp,uyyq
      ur=aay*(u0+aay2*uyy0)+bay*(u2+bay2*uyy2)
      us=aay*(u1+aay2*uyy1)+bay*(u3+bay2*uyy3)
      uxxr=aay*(uxx0+aay2*uxxyy0)+bay*(uxx2+bay2*uxxyy2)
      uxxs=aay*(uxx1+aay2*uxxyy1)+bay*(uxx3+bay2*uxxyy3)
      fx=((us-ur)-(3.d0*aax2+2.d0)*uxxr+(3.d0*bax2+2.d0)*uxxs)
     $     /xstep/sigx
      if(x .gt. 0.d0)then
        fx=-fx
      endif
      if(y .gt. 0.d0)then
        fy=-fy
      endif
      return
 9000 z=bbkick1(x,y,sigx,sigy)
      fx=dble(z)
      fy=dimag(z)
      fu=twspu(x,y,sigx,sigy,1.d-8,1.d-11)
c      write(*,*)'twspfu ',x,y,sigx,sigy
      return
      end
      
      subroutine twspfuinit(u,uxx,uyy,uxxyy,urr,uxxrr,uyyrr,uxxyyrr)
      implicit none
      integer*4 nr,nx,ny,i,j,n
      real*8 xm,xstep,ym,ystep,x,y,r,twspu,
     $     rstep,rm,ystepr
      parameter (nr=20,nx=60,ny=60,xm=15.d0,ym=30.d0,rm=5.d0)
      parameter (xstep=xm/nx,rstep=rm/nr**2,ystep=ym/ny)
      complex*16 bbkick1
      real*8 u(0:nx,0:ny,0:nr),uxx(0:nx,0:ny,0:nr),
     $     uyy(0:nx,0:ny,0:nr),uxxyy(0:nx,0:ny,0:nr)
      real*8 urr(0:nx,0:ny,0:nr),uxxrr(0:nx,0:ny,0:nr),
     $     uyyrr(0:nx,0:ny,0:nr),uxxyyrr(0:nx,0:ny,0:nr)
      real*8 s(0:ny),dds(0:ny),work(0:ny)
      real*8 sxx(0:nr),ddsxx(0:nr)
      real*8 syy(0:nr),ddsyy(0:nr)
      real*8 sxxyy(0:nr),ddsxxyy(0:nr)
      do n=0,nr
        r=10.d0**(-n**2*rstep)
        ystepr=r*ystep
        do i=0,nx
          x=xstep*i
          do j=0,ny
            y=j*ystepr
            s(j)=twspu(x,y,1.d0,r,1.d-8,1.d-11)
            u(i,j,n)=s(j)
          enddo
          dds(0)=0.d0
          dds(ny)=-dimag(bbkick1(x,ny*ystepr,1.d0,r))*ystepr
          call spline1(ny+1,s,dds,work,1,1)
          do j=0,ny
            uyy(i,j,n)=dds(j)
          enddo
        enddo
        do j=0,ny
          dds(0)=0.d0
          dds(nx)=-dble(bbkick1(xm,j*ystepr,1.d0,r))*xstep
          call spline1(nx+1,u(0,j,n),uxx(0,j,n),work,1,1)
          s(j)=uxx(0,j,n)
        enddo
        dds(0)=0.d0
        call spline1(ny+1,s,dds,work,1,0)
        do j=0,ny
          uxxyy(0,j,n)=dds(j)
          s(j)=uxx(nx,j,n)
        enddo
        call spline1(ny+1,s,dds,work,0,0)
        do j=0,ny
          uxxyy(nx,j,n)=dds(j)
          call spline1(nx+1,uyy(0,j,n),uxxyy(0,j,n),work,2,2)
        enddo
      enddo
      do i=0,nx
        do j=0,ny
          do n=0,nr
            s(n)=u(i,j,n)
            sxx(n)=uxx(i,j,n)
            syy(n)=uyy(i,j,n)
            sxxyy(n)=uxxyy(i,j,n)
          enddo
          dds(0)=0.d0
          ddsxx(0)=0.d0
          ddsyy(0)=0.d0
          ddsxxyy(0)=0.d0
          call spline1(nr+1,s,dds,work,1,0)
          call spline1(nr+1,sxx,ddsxx,work,1,0)
          call spline1(nr+1,syy,ddsyy,work,1,0)
          call spline1(nr+1,sxxyy,ddsxxyy,work,1,0)
          do n=0,nr
            urr(i,j,n)=dds(n)
            uxxrr(i,j,n)=ddsxx(n)
            uyyrr(i,j,n)=ddsyy(n)
            uxxyyrr(i,j,n)=ddsxxyy(n)
          enddo
        enddo
      enddo
      return
      end

      subroutine wspaccheck
      use tfstk
      use ffs
      implicit none
      if(wspac .and. ifsize .eq. 0)then
        write(*,*)'WSPAC without beam matrix. ',
     $       'You need EMIT with CODPLOT.'
        call forcesf()
      endif
      return
      end
