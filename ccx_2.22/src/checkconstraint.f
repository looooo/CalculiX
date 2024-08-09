!     
!     CalculiX - A 3-dimensional finite element program
!     Copyright (C) 1998-2024 Guido Dhondt
!     
!     This program is free software; you can redistribute it and/or
!     modify it under the terms of the GNU General Public License as
!     published by the Free Software Foundation(version 2);
!     
!     
!     This program is distributed in the hope that it will be useful,
!     but WITHOUT ANY WARRANTY; without even the implied warranty of 
!     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the 
!     GNU General Public License for more details.
!     
!     You should have received a copy of the GNU General Public License
!     along with this program; if not, write to the Free Software
!     Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
!     
      subroutine checkconstraint(nobject,objectset,g0,nactive,
     &     nnlconst,ipoacti,ndesi,dgdxglob,nk,nodedesi,iconstacti,
     &     objnorm,inameacti)               
!     
!     check which constraints are active on the basis of the 
!     function values of the constraints     
!     
      implicit none
!     
      character*81 objectset(5,*)
      character*20 empty
!     
      integer iobj,nobject,istat,nactive,nnlconst,inameacti(*),
     &   ipoacti(*),ifree,i,ndesi,nk,node,nodedesi(*),
     &   iconstacti(*),nconst
!     
      real*8 g0(*),bounds(nobject),scale,bound,objnorm(*),obj,
     &   dgdxglob(2,nk,*)
!
      empty='                    '
!   
!     
!     header written in dat file
!     
      write(5,*)
      write(5,*)
      write(5,'(a113)') '  #############################################
     &#################################################################'
      write(5,*) '  A S S E M B L Y   O F   A C T I V E   S E T'
      write(5,*)
      write(5,101)
     &'NUMBER OF    ','CONSTRAINT      ','LE/     ','FUNCTION         ',
     &'FUNCTION         ','FUNCTION      ','  ACTIVE/ ','   NAME OF' 
      write(5,101)
     &'CONSTRAINT   ','FUNCTION        ','GE      ','VALUE            ',
     &'BOUND            ','VIOLATION     ','  INACTIVE','   CONSTRAINT' 
      write(5,'(a113)') '  #############################################
     &#################################################################'
      write(5,*)
!     
!     determine bounds of constraints
!     
      do iobj=2,nobject
         if(objectset(5,iobj)(81:81).eq.'G') then
            read(objectset(1,iobj)(61:80),'(f20.0)',
     &      iostat=istat) bound
            bounds(iobj)=bound
         elseif(objectset(5,iobj)(81:81).eq.'C') then
            if(objectset(1,iobj)(61:80).ne.empty) then
               read(objectset(1,iobj)(61:80),'(f20.0)',
     &         iostat=istat) bound
            else
               write(*,*) '*WARNING in checkconstraint'
               write(*,*) '         no absolute constraint boundary'
               write(*,*) '         defined, system value taken' 
               write(*,*)
               bound=g0(iobj)
            endif
            if(objectset(1,iobj)(41:60).ne.empty) then
               read(objectset(1,iobj)(41:60),'(f20.0)',
     &         iostat=istat) scale
            else
               write(*,*) '*WARNING in checkconstraint'
               write(*,*) '         no relative constraint boundary'
               write(*,*) '         defined, 1.0 taken' 
               write(*,*)
               scale=1.0d0
            endif
            bounds(iobj)=bound*scale
         endif
      enddo
!     
!     determine all active constraints
!     
      nconst=0
      nactive=0
      nnlconst=0
      ifree=1
!
      do iobj=2,nobject
!     
!        determine all active nonlinear constraints
!     
         if(objectset(5,iobj)(81:81).eq.'C') then
            nconst=nconst+1
            if(objectset(1,iobj)(19:20).eq.'LE') then
               objnorm(ifree)=g0(iobj)/bounds(iobj)-1
               if(objnorm(ifree).ge.0.d0) then
                  nactive=nactive+1
                  nnlconst=nnlconst+1
                  ipoacti(ifree)=iobj
                  inameacti(ifree)=iobj
                  iconstacti(ifree)=-1
                  write(5,102) nconst,objectset(1,iobj),'LE  ',
     &               g0(iobj),bounds(iobj),objnorm(ifree),
     &               'ACTIVE  ',objectset(5,iobj)
                  ifree=ifree+1
               else
                  write(5,102) nconst,objectset(1,iobj),'LE  ',
     &               g0(iobj),bounds(iobj),objnorm(ifree),
     &               'INACTIVE',objectset(5,iobj)            
               endif
            elseif(objectset(1,iobj)(19:20).eq.'GE') then
               objnorm(ifree)=-1*(g0(iobj)/bounds(iobj))+1
               if(objnorm(ifree).ge.0.d0) then
                  nactive=nactive+1
                  nnlconst=nnlconst+1
                  ipoacti(ifree)=iobj
                  inameacti(ifree)=iobj
                  iconstacti(ifree)=1
                  write(5,102) nconst,objectset(1,iobj),'GE  ',
     &               g0(iobj),bounds(iobj),objnorm(ifree),
     &               'ACTIVE  ',objectset(5,iobj)
                  ifree=ifree+1
               else
                  write(5,102) nconst,objectset(1,iobj),'GE  ',
     &               g0(iobj),bounds(iobj),objnorm(ifree),
     &               'INACTIVE',objectset(5,iobj)            
               endif
            endif
!     
!        determine all active linear constraints
!     
         elseif(objectset(5,iobj)(81:81).eq.'G') then
            nconst=nconst+1
            if(objectset(1,iobj)(19:20).eq.'LE') then
               if(g0(iobj).gt.0d0) then
                  if(objectset(1,iobj)(1:12).eq.'MAXSHRINKAGE') then
                     do i=1,ndesi
                        node=nodedesi(i)
                        if(i.eq.1) then
                           objnorm(iobj)=dgdxglob(2,node,iobj)
                           obj=dgdxglob(1,node,iobj)
                        else
                           objnorm(iobj)=
     &                     max(objnorm(iobj),dgdxglob(2,node,iobj))
                           obj=min(obj,dgdxglob(1,node,iobj))
                        endif
                        if(dgdxglob(2,node,iobj).ge.0.d0) then
                           ipoacti(ifree)=i
                           inameacti(ifree)=iobj
                           iconstacti(ifree)=-1
                           ifree=ifree+1
                           nactive=nactive+1
                        endif
                     enddo
                  else
                     do i=1,ndesi
                        node=nodedesi(i)
                        if(i.eq.1) then
                           objnorm(iobj)=dgdxglob(2,node,iobj)
                           obj=dgdxglob(1,node,iobj)
                        else
                           objnorm(iobj)=
     &                     max(objnorm(iobj),dgdxglob(2,node,iobj))
                           obj=max(obj,dgdxglob(1,node,iobj))
                        endif
                        if(dgdxglob(2,node,iobj).ge.0.d0) then
                           ipoacti(ifree)=i
                           inameacti(ifree)=iobj
                           iconstacti(ifree)=-1
                           ifree=ifree+1
                           nactive=nactive+1
                        endif
                     enddo
                  endif
                  write(5,102) nconst,objectset(1,iobj),'LE  ',
     &               abs(obj),bounds(iobj),objnorm(iobj),
     &               'ACTIVE  ',objectset(5,iobj)    
               else
                  if(objectset(1,iobj)(1:12).eq.'MAXSHRINKAGE') then
                     do i=1,ndesi
                        node=nodedesi(i)
                        if(i.eq.1) then
                           objnorm(iobj)=dgdxglob(2,node,iobj)
                           obj=dgdxglob(1,node,iobj)
                        else
                           objnorm(iobj)=
     &                     max(objnorm(iobj),dgdxglob(2,node,iobj))
                           obj=min(obj,dgdxglob(1,node,iobj))
                        endif
                     enddo
                  else
                     do i=1,ndesi
                        node=nodedesi(i)
                        if(i.eq.1) then
                           objnorm(iobj)=dgdxglob(2,node,iobj)
                           obj=dgdxglob(1,node,iobj)
                        else
                           objnorm(iobj)=
     &                     max(objnorm(iobj),dgdxglob(2,node,iobj))
                           obj=max(obj,dgdxglob(1,node,iobj))
                        endif
                     enddo      
                  endif
                  write(5,102) nconst,objectset(1,iobj),'LE  ',
     &               abs(obj),bounds(iobj),objnorm(iobj),
     &               'INACTIVE',objectset(5,iobj)    
               endif
            elseif(objectset(1,iobj)(19:20).eq.'GE') then
               if(g0(iobj).gt.0.d0) then
                  do i=1,ndesi
                     node=nodedesi(i)
                     if(i.eq.1) then
                        objnorm(iobj)=dgdxglob(2,node,iobj)
                        obj=abs(dgdxglob(1,node,iobj))
                     else
                        objnorm(iobj)=
     &                  max(objnorm(iobj),dgdxglob(2,node,iobj))
                        obj=min(obj,abs(dgdxglob(1,node,iobj)))
                     endif
                     if(dgdxglob(2,node,iobj).ge.0.d0) then
                        ipoacti(ifree)=i
                        inameacti(ifree)=iobj
                        iconstacti(ifree)=1
                        ifree=ifree+1
                        nactive=nactive+1
                     endif
                  enddo
                  write(5,102) nconst,objectset(1,iobj),'GE  ',
     &               abs(obj),bounds(iobj),objnorm(iobj),
     &               'ACTIVE  ',objectset(5,iobj)    
               else
                  do i=1,ndesi
                     node=nodedesi(i)
                     if(i.eq.1) then
                        objnorm(iobj)=dgdxglob(2,node,iobj)
                        obj=abs(dgdxglob(1,node,iobj))
                     else
                        objnorm(iobj)=
     &                  max(objnorm(iobj),dgdxglob(2,node,iobj))
                        obj=min(obj,abs(dgdxglob(1,node,iobj)))
                     endif
                  enddo
                  write(5,102) nconst,objectset(1,iobj),'GE  ',
     &               abs(obj),bounds(iobj),objnorm(iobj),
     &               'INACTIVE',objectset(5,iobj)    
               endif
            endif
         endif
      enddo
!     
      return        
!
 101  format(3x,13a,3x,a16,a11,3x,a11,3x,a11,3x,a8,3x,a10,3x,a10)
 102  format(3x,i2,8x,3x,a16,a4,3x,e14.7,3x,e14.7,3x,e14.7,3x,a8,3x,a80)
!
      end
