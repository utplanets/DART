! DART software - Copyright UCAR. This open source software is provided
! by UCAR, "as is", without charge, subject to all terms of use at
! http://www.image.ucar.edu/DAReS/DART/DART_download
!
! $Id$

PROGRAM convertdate

use time_manager_mod

implicit none

! version controlled file description for error handling, do not edit
character(len=256), parameter :: source   = &
   "$URL$"
character(len=32 ), parameter :: revision = "$Revision$"
character(len=128), parameter :: revdate  = "$Date$"

integer :: direction
type(time_type)   :: atime
integer           :: year, month, day, hour, minute, second
integer           :: jday
integer           :: days, seconds

!  days prior to beginning of each month (non&) leap year

!  begin
write(6,*) 'Which direction? '
write(6,*) 'YYYY DDD HH MM SS ===>  Gregorian Mars day and second  (1)'
write(6,*) 'YYYY DDD HH MM SS <===  Gregorian Mars day and second  (2)'
!write(6,*) 'YYYY MM DD          ===>  Julian day of year YYYY   (3)'
!write(6,*) 'YYYY MM DD          <===  Julian day of year YYYY   (4)'

read(5,*) direction

if ( direction == 1 ) then
   write(*,*) 'Input MARS :: YYYY DDD HH MM SS: '
   read(*,*) year, day, hour, minute, second
   !mars has no months
   atime=set_date_gregorian_mars(year, 1, day, hour, minute, second)
   call get_time (atime, seconds, days)
   write(*,*) 'Gregorian MARS days and second: ', days, seconds

else if ( direction == 2 ) then
   write(*,*) 'Input Gregorian MARS days and second: '
   read(*,*) days, seconds
   atime = set_time(seconds, days)
   call get_date_gregorian_mars(atime, year, month, day, hour, minute, second)
   write (*,FMT='(I4,I5,3I3.2)') year, day, hour, minute, second
endif

end program convertdate

! <next few lines under version control, do not edit>
! $URL$
! $Id$
! $Revision$
! $Date$
