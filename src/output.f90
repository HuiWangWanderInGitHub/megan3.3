subroutine write_output_file(g,YYYY,MM,DD,MECHANISM)
  implicit none
  type(grid_type) , intent(in) :: g
  character(len=5), intent(in) :: MECHANISM
  character(len=4), intent(in) :: YYYY
  character(len=2), intent(in) :: MM,DD
  !local vars
  integer             :: ncid,var_id,t_dim_id,x_dim_id,y_dim_id,z_dim_id,str_dim_id,s_dim_id,var_dim_id
  integer             :: k!,i,j
  character(len=50)   :: out_file
  character(len=10)   :: current_date
                        
   current_date=YYYY//"-"//MM//"-"//DD
   !File name
   out_file="emis_bio_"//current_date//"_"//trim(MECHANISM)//".nc"
   print '(/" Writing out file: ",A/)',trim(out_file)

   !Crear NetCDF
   call check(nf90_create(trim(out_file), NF90_CLOBBER, ncid))
     !Defino dimensiones
     call check(nf90_def_dim(ncid, "DateStrLen", 19, str_dim_id    ))
     call check(nf90_def_dim(ncid, "time", 24     , t_dim_id       ))
     call check(nf90_def_dim(ncid, "x"   , g%nx   , x_dim_id       ))
     call check(nf90_def_dim(ncid, "y"   , g%ny   , y_dim_id       ))

     !Defino variables
     call check(nf90_def_var(ncid,"lat"  , NF90_FLOAT  , [x_dim_id,y_dim_id], var_id) )
     call check(nf90_def_var(ncid,"lon"  , NF90_FLOAT  , [x_dim_id,y_dim_id], var_id) )
     call check(nf90_def_var(ncid,"cell_area", NF90_FLOAT  , [x_dim_id,y_dim_id], var_id) )
     !time
     call check(nf90_def_var(ncid,"time" ,NF90_INT       , [t_dim_id], var_id  ));
     call check(nf90_put_att(ncid, var_id,"units"        , "seconds since "//current_date//" 00:00:00 UTC" ));  !"%Y-%m-%d %H:%M:%S"
     call check(nf90_put_att(ncid, var_id,"long_name"    , "time"              ));
     call check(nf90_put_att(ncid, var_id,"axis"         , "T"                 ));
     call check(nf90_put_att(ncid, var_id,"calendar"     , "standard"          ));
     call check(nf90_put_att(ncid, var_id,"standard_name", "time"              ));

     !Creo variables:
     do k=1,NMGNSPC !n_scon_spc !
        call check( nf90_def_var(ncid, trim(mech_spc(k)) , NF90_FLOAT, [x_dim_id,y_dim_id,t_dim_id], var_id)   )
        !call check( nf90_put_att(ncid, var_id, "units"      , "mole m-2 s-1"       ))
        !call check( nf90_put_att(ncid, var_id, "var_desc"   , trim(mech_spc(k))//" emision flux"      ))
        call check( nf90_put_att(ncid, var_id, "units"      , "mole s-1"          ))   !if multiplied by cell_area
        call check( nf90_put_att(ncid, var_id, "var_desc"   , trim(mech_spc(k))//" emision rate"      )) 
     end do
   call check(nf90_enddef(ncid))   !End NetCDF define mode
   
   !Abro NetCDF y guardo variables de salida
   call check(nf90_open(trim(out_file), nf90_write, ncid       ))
     call check(nf90_inq_varid(ncid,"lat"      ,var_id)); call check(nf90_put_var(ncid, var_id, lat ))
     call check(nf90_inq_varid(ncid,"lon"      ,var_id)); call check(nf90_put_var(ncid, var_id, lon ))
     call check(nf90_inq_varid(ncid,"cell_area",var_id)); call check(nf90_put_var(ncid, var_id, cell_area ))
     call check(nf90_inq_varid(ncid,"time",var_id))     ; call check(nf90_put_var(ncid, var_id, [ (60*60*k,k=0,23 ) ] ))
     do k=1,NMGNSPC !n_scon_spc !,NMGNSPC
       print*,"    Especie:",trim(mech_spc(k)) !debug
       call check(nf90_inq_varid(ncid,trim(mech_spc(k)),var_id)); call check(nf90_put_var(ncid, var_id, out_buffer_all(:,:,k,:) )) 
     enddo
   call check(nf90_close( ncid ))
end subroutine write_output_file
