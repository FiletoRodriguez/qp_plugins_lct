
BEGIN_PROVIDER [ logical, mo_two_e_integrals_tc_int_in_map ]
  implicit none
  use f77_zmq
  use map_module
  BEGIN_DOC
  !  Map of Atomic integrals
  !     i(r1) j(r2) 1/r12 k(r1) l(r2)
  END_DOC

  integer                        :: i,j,k,l
  double precision               :: cpu_1,cpu_2, wall_1, wall_2
  double precision               :: integral, wall_0
  include 'utils/constants.include.F'

  ! For integrals file
  integer(key_kind),allocatable  :: buffer_i(:)
  integer,parameter              :: size_buffer = 1024*64
  real(integral_kind),allocatable :: buffer_value(:)

  integer                        :: n_integrals, rc
  integer                        :: kk, m, j1, i1, lmax
  character*(64)                 :: fmt
  !!deriv_mu_r_pot_physicist_mo
  PROVIDE mo_tc_sym_two_e_pot_in_map mo_non_hermit_term mo_two_e_integrals_in_map
!  endif
  double precision               :: map_mb
!  PROVIDE read_mo_two_e_integrals_tc_int io_mo_two_e_integrals_tc_int
!  if (read_mo_two_e_integrals_tc_int) then
!    print*,'Reading the mo tc_int integrals'
!      call map_load_from_disk(trim(ezfio_filename)//'/work/mo_ints_tc_int',mo_integrals_tc_int_map)
!      print*, 'mo tc_int integrals provided'
!      mo_two_e_integrals_tc_int_in_map = .True.
!      return
!  endif

  print*, 'Providing the mo tc_int integrals'
  call wall_time(wall_0)
  call wall_time(wall_1)
  call cpu_time(cpu_1)

  integer(ZMQ_PTR) :: zmq_to_qp_run_socket, zmq_socket_pull
  call new_parallel_job(zmq_to_qp_run_socket,zmq_socket_pull,'mo_integrals_tc_int')

  character(len=:), allocatable :: task
  allocate(character(len=mo_num*12) :: task)
  write(fmt,*) '(', mo_num, '(I5,X,I5,''|''))'
  do l=1,mo_num
    write(task,fmt) (i,l, i=1,l)
    integer, external :: add_task_to_taskserver
    if (add_task_to_taskserver(zmq_to_qp_run_socket,trim(task)) == -1) then
      stop 'Unable to add task to server'
    endif
  enddo
  deallocate(task)

  integer, external :: zmq_set_running
  if (zmq_set_running(zmq_to_qp_run_socket) == -1) then
    print *,  irp_here, ': Failed in zmq_set_running'
  endif

  PROVIDE nproc
  !$OMP PARALLEL DEFAULT(shared) private(i) num_threads(nproc+1)
      i = omp_get_thread_num()
      if (i==0) then
        call mo_two_e_integrals_tc_int_in_map_collector(zmq_socket_pull)
      else
        call mo_two_e_integrals_tc_int_in_map_slave_inproc(i)
      endif
  !$OMP END PARALLEL

  call end_parallel_job(zmq_to_qp_run_socket, zmq_socket_pull, 'mo_integrals_tc_int')


  print*, 'Sorting the map'
  call map_sort(mo_integrals_tc_int_map)
  call cpu_time(cpu_2)
  call wall_time(wall_2)
  integer(map_size_kind)         :: get_mo_tc_int_map_size, mo_tc_int_map_size
  mo_tc_int_map_size = get_mo_tc_int_map_size()

  print*, 'mo tc_int integrals provided:'
  print*, ' Size of mo tc_int map :         ', map_mb(mo_integrals_tc_int_map) ,'MB'
  print*, ' Number of mo tc_int integrals :', mo_tc_int_map_size
  print*, ' cpu  time :',cpu_2 - cpu_1, 's'
  print*, ' wall time :',wall_2 - wall_1, 's  ( x ', (cpu_2-cpu_1)/(wall_2-wall_1+tiny(1.d0)), ' )'

  mo_two_e_integrals_tc_int_in_map = .True.

!  if (write_mo_two_e_integrals_tc_int) then
!    call ezfio_set_work_empty(.False.)
!    call map_save_to_disk(trim(ezfio_filename)//'/work/mo_ints_tc_int',mo_integrals_tc_int_map)
!    call ezfio_set_mo_two_e_tc_int_ints_io_mo_two_e_integrals_tc_int("Read")
!  endif

END_PROVIDER




