!
!     CalculiX - A 3-dimensional finite element program
!              Copyright (C) 1998-2024 Guido Dhondt
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
      subroutine updatecont2d(koncont,ncont,co,cg,straight)
!
!     update geometric date of the contact master surface triangulation
!
      implicit none
!
      integer koncont(3,*),ncont,i,j,k,node
!
      real*8 co(2,*),cg(2,*),straight(9,*),col(2,3)
!
      do i=1,ncont
         do j=1,3
            node=koncont(j,i)
            do k=1,2
               col(k,j)=co(k,node)
            enddo
         enddo
!
!        center of gravity of the triangles
!
         do k=1,2
            cg(k,i)=col(k,1)
         enddo
         do j=2,3
            do k=1,2
               cg(k,i)=cg(k,i)+col(k,j)
            enddo
         enddo
         do k=1,2
            cg(k,i)=cg(k,i)/3.d0
         enddo
!
!        calculating the equation of the triangle plane and the planes
!        perpendicular on it and through the triangle edges
!
         call straighteq2d(col,straight(1,i))
!
      enddo
!
      return
      end
