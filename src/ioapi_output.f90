module ioapi_output_mod
   use M3UTILIO
   implicit none
   private
   public :: write_output_file_ioapi

contains

   subroutine write_output_file_ioapi(nx, ny, dx, dy, yyyy, ddd, mm, dd, &
                                      mechanism, griddesc_file, gridname_in, output_dir, &
                                      nspc, spc_names, emis)
      implicit none

      integer, intent(in) :: nx, ny, nspc
      real, intent(in)    :: dx, dy
      character(len=*), intent(in) :: yyyy, ddd, mm, dd
      character(len=*), intent(in) :: mechanism
      character(len=*), intent(in) :: griddesc_file
      character(len=*), intent(in) :: gridname_in
      character(len=*), intent(in) :: output_dir
      character(len=*), intent(in) :: spc_names(nspc)
      ! Pass the full allocated mechanism buffer from the driver.
      ! The CONTIGUOUS assumed-shape dummy avoids a very large copy-in
      ! temporary when NMGNSPC is smaller than n_spca_spc.
      real, intent(in), contiguous :: emis(:,:,:,0:)

      character(len=16), parameter :: OUT_LNAME = 'MGNOUT'
      character(len=16), parameter :: PROGNAME  = 'MEGAN3'

      character(len=16)  :: gridname, cname
      character(len=512) :: out_file
      integer :: logdev, iy, ijday, jdate, jtime
      integer :: s, t
      real, allocatable :: slab(:,:,:)
      real(8), parameter :: grid_tol = 1.0d-3
      logical :: ok, griddesc_exists

      if (nspc > MXVARS3) then
         write(*,*) 'IOAPI error: number of species exceeds MXVARS3: ', nspc, MXVARS3
         error stop
      end if

      ! Validate the full MEGAN mechanism buffer before any IOAPI call.
      if (size(emis,1) /= nx .or. size(emis,2) /= ny) then
         write(*,*) 'IOAPI error: emission-buffer horizontal dimensions do not match grid.'
         write(*,*) '  buffer nx,ny = ', size(emis,1), size(emis,2)
         write(*,*) '  grid   nx,ny = ', nx, ny
         error stop
      end if
      if (size(emis,3) < nspc) then
         write(*,*) 'IOAPI error: emission buffer has fewer species than requested.'
         write(*,*) '  buffer species = ', size(emis,3)
         write(*,*) '  requested      = ', nspc
         error stop
      end if
      if (size(emis,4) /= 24 .or. lbound(emis,4) /= 0 .or. ubound(emis,4) /= 23) then
         write(*,*) 'IOAPI error: emission time dimension must be 0:23.'
         write(*,*) '  lower, upper, size = ', lbound(emis,4), ubound(emis,4), size(emis,4)
         error stop
      end if

      allocate(slab(nx,ny,1))

      ! All run-time IOAPI configuration comes from the MEGAN namelist.
      ! Do not fall back to shell variables such as $GRIDDESC or $GDNAM3D.
      if (len_trim(griddesc_file) == 0) then
         write(*,*) 'IOAPI error: griddesc_file is empty in &megan_nl.'
         error stop
      end if

      inquire(file=trim(griddesc_file), exist=griddesc_exists)
      if (.not. griddesc_exists) then
         write(*,*) 'IOAPI error: GRIDDESC file does not exist: ', trim(griddesc_file)
         error stop
      end if

      gridname = adjustl(gridname_in)
      if (len_trim(gridname) == 0) then
         write(*,*) 'IOAPI error: ioapi_gridname is empty in &megan_nl.'
         error stop
      end if

      ! I/O API uses logical names internally.  Set GRIDDESC from the
      ! namelist here so no external export/setenv command is needed.
      if (.not. SETENVVAR('GRIDDESC', trim(griddesc_file))) then
         write(*,*) 'IOAPI error: failed to set GRIDDESC = ', trim(griddesc_file)
         error stop
      end if

      ! INIT3 may be called repeatedly; subsequent calls are no-ops in I/O API.
      logdev = INIT3()

      GDNAM3D = trim(gridname)
      ok = DSCGRID(trim(GDNAM3D), cname, GDTYP3D, &
                   P_ALP3D, P_BET3D, P_GAM3D, XCENT3D, YCENT3D, &
                   XORIG3D, YORIG3D, XCELL3D, YCELL3D, &
                   NCOLS3D, NROWS3D, NTHIK3D)
      if (.not. ok) then
         write(*,*) 'IOAPI error: grid ', trim(GDNAM3D), ' not found in GRIDDESC.'
         error stop
      end if

      ! Require the GRIDDESC grid to be exactly the MEGAN output grid.
      ! For a MEGAN sub-domain, define a matching sub-domain entry in GRIDDESC.
      if (NCOLS3D /= nx .or. NROWS3D /= ny) then
         write(*,*) 'IOAPI grid mismatch.'
         write(*,*) '  GRIDDESC nx,ny = ', NCOLS3D, NROWS3D
         write(*,*) '  MEGAN    nx,ny = ', nx, ny
         error stop
      end if

      if (abs(XCELL3D-dble(dx)) > grid_tol .or. abs(YCELL3D-dble(dy)) > grid_tol) then
         write(*,*) 'IOAPI grid-cell mismatch.'
         write(*,*) '  GRIDDESC dx,dy = ', XCELL3D, YCELL3D
         write(*,*) '  WRF/MEGAN dx,dy = ', dx, dy
         error stop
      end if

      read(yyyy,*) iy
      read(ddd,*)  ijday
      jdate = iy*1000 + ijday

      FTYPE3D = GRDDED3
      NLAYS3D = 1
      NVARS3D = nspc
      SDATE3D = jdate
      STIME3D = 0
      TSTEP3D = 10000
      MXREC3D = 24

      ! Surface-emission file: only one layer is stored.  CMAQ/I/O API grid
      ! checks do not use vertical-coordinate values for NLAYS=1, but a valid
      ! I/O API vertical definition is still supplied in the file header.
      VGTYP3D    = VGSGPH3
      VGTOP3D    = 100.0
      VGLVS3D(1) = 1.0
      VGLVS3D(2) = 0.0

      VNAME3D = ' '
      UNITS3D = ' '
      VDESC3D = ' '
      VTYPE3D = M3REAL
      FDESC3D = ' '
      UPDSC3D = ' '

      FDESC3D(1) = 'MEGAN3 biogenic emissions for CMAQ/I-O API'
      FDESC3D(2) = 'Chemical mechanism: '//trim(mechanism)
      FDESC3D(3) = 'Units: mol/s per model grid cell'

      do s = 1, nspc
         if (len_trim(spc_names(s)) > NAMLEN3) then
            write(*,*) 'IOAPI error: species name exceeds 16 characters: ', trim(spc_names(s))
            error stop
         end if
         VNAME3D(s) = trim(spc_names(s))
         UNITS3D(s) = 'mol/s'
         VDESC3D(s) = trim(spc_names(s))//' biogenic emission rate'
         VTYPE3D(s) = M3REAL
      end do

      if (trim(output_dir) == '' .or. trim(output_dir) == '.') then
         out_file = 'emis_bio_'//yyyy//'-'//mm//'-'//dd//'_'//trim(mechanism)//'_IOAPI.nc'
      else
         out_file = trim(output_dir)//'/emis_bio_'//yyyy//'-'//mm//'-'//dd//'_'// &
                    trim(mechanism)//'_IOAPI.nc'
      end if

      print '(/" writing IOAPI file: ",a/)', trim(out_file)

      if (.not. SETENVVAR(OUT_LNAME, trim(out_file))) then
         write(*,*) 'IOAPI error: failed to set logical file ', trim(OUT_LNAME)
         error stop
      end if

      if (.not. OPEN3(OUT_LNAME, FSCREA3, PROGNAME)) then
         write(*,*) 'IOAPI error: OPEN3 failed for ', trim(out_file)
         error stop
      end if

      jtime = 0
      do t = 0, 23
         do s = 1, nspc
            ! WRITE3 expects one complete gridded variable.  Use an explicit
            ! one-layer 3-D slab instead of relying on a rank-2 array section.
            slab(:,:,1) = emis(:,:,s,t)
            if (.not. WRITE3(OUT_LNAME, trim(VNAME3D(s)), jdate, jtime, slab)) then
               write(*,*) 'IOAPI error writing ', trim(VNAME3D(s)), ' at ', jdate, jtime
               deallocate(slab)
               error stop
            end if
         end do
         call NEXTIME(jdate, jtime, TSTEP3D)
      end do

      deallocate(slab)

      if (.not. CLOSE3(OUT_LNAME)) then
         write(*,*) 'IOAPI warning: CLOSE3 failed for ', trim(out_file)
      end if

   end subroutine write_output_file_ioapi

end module ioapi_output_mod
