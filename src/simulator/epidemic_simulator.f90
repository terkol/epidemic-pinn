program epidemic_simulator
    use utils
    implicit none
    integer :: sim_len, box_len, n_walk, n_sick, n_imm, seed
    real :: p_sick, p_heal
    integer, allocatable :: walk_pos(:,:)
    integer, allocatable :: walk_cond(:)
    integer :: i,j
    character(len=256) :: arg, fname, run

    if (command_argument_count() /= 8) then
        print*, 'ERROR: program requires eight inputs: sim_len, box_len, n_walk, n_sick, n_imm, seed, p_sick, p_heal'
        stop
    endif
    call get_command_argument(1, arg)
    read(arg,*) sim_len
    if (sim_len < 0) then
        print*, 'ERROR: simulation length (argument 1) must be positive'
        stop
    endif 

    call get_command_argument(2, arg)
    read(arg,*) box_len
    call get_command_argument(3, arg)
    read(arg,*) n_walk
    if (n_walk < 0) then
        print*, 'ERROR: n_walk (argument 3) must be positive'
        stop
    endif

    call get_command_argument(4, arg)
    read(arg,*) n_sick
    if (n_sick < 0) then
        print*, 'ERROR: n_sick (argument 4) must be positive'
        stop
    elseif (n_sick > n_walk) then
        print*, 'ERROR: n_sick (argument 4) cannot be higher than n_walk (argument 3)'
        stop
    endif

    call get_command_argument(5, arg)
    read(arg,*) n_imm
    if (n_imm < 0) then
        print*, 'ERROR: n_imm (argument 5) must be positive'
        stop
    elseif (n_imm > n_walk) then
        print*, 'ERROR: n_imm (argument 4) cannot be higher than n_walk (argument 3)'
        stop
    elseif (n_sick+n_imm > n_walk) then
        print*, 'ERROR: the sum of n_sick (argument 4) and n_imm (argument 5) cannot be larger than n_walk (argument 3)'
        stop
    endif

    call get_command_argument(6, arg)
    read(arg,*) p_sick
    if ((p_sick<0).or.(p_sick>1)) then
        print*,'ERROR: p_sick (argument 5) must be a float between 0 and 1'
        stop
    endif

    call get_command_argument(7, arg)
    read(arg,*) p_heal
    if ((p_heal<0).or.(p_heal>1)) then
        print*,'ERROR: p_sick (argument 5) must be a float between 0 and 1'
        stop
    endif

    call get_command_argument(8, arg)
    read(arg,*) seed
    write(*,'(A)') "Inputs:"
    print*,'Simulation length',sim_len
    print*,'Box side length', box_len
    print*,'Amount of walkers', n_walk
    print*,'Amount of t=0 sick walkers', n_sick
    print*,'Amount of t=0 immune walkers', n_imm
    print*,'Probability of infection', p_sick
    print*,'Probability to recover', p_heal
    print*,'RNG seed', seed
    
    allocate(walk_pos(n_walk,2))
    walk_pos = 0
    allocate(walk_cond(n_walk))
    walk_cond = 0

    call sgrnd(seed)
    write(fname,'(I0,"_",I0,"_",I0,"_",I0,"_",I0,"_",F0.3,"_",F0.3,"_",I0,".txt")') &
        sim_len,box_len, n_walk, n_sick, n_imm, p_sick,p_heal,seed

    open(1, file=trim('run')//"/"//trim(fname), action="write", status="replace")
    open(2, file=trim('run')//"/"//"epidemic.xyz", action="write", status="replace")

    write(1,'(A7)') 'inf,imm'
    write(1,'(I0,",",I0)') count(walk_cond==1), count(walk_cond==2)
    print*
    write(*,'(A)', advance='no') "Simulating..."
    call initialize(box_len, walk_pos, walk_cond, n_sick, n_imm) ! Set initial positions and health conditions

    do i=1, sim_len
        if (mod(i,100)==0) write(*,'(A)', advance='no') "." ! Print a period every 100 steps as a display of progress
        call move_walkers(walk_pos, box_len) 
        call infect_walkers(walk_pos, walk_cond, p_sick)
        call heal_walkers(walk_pos, walk_cond, p_heal)
        ! Write the amount of infected and immune walkers into the .txt file
        write(1,'(I0,",",I0)') count(walk_cond==1), count(walk_cond==2)

        ! Write the positions of all walkers into the .xyz file
        write(2,'(I0)') n_walk
        write(2,'(A5,1X,I0)') '#Step',i
        do j=1,n_walk
            write(2,'(I0,1X,I0,1X,I0,1X,I0)') 1,walk_pos(j,1),walk_pos(j,2),walk_cond(j)
        enddo
        ! if (count(walk_cond == 1) == 0) exit ! Stop early if no infected left
    enddo
    close(1)
    close(2)

    write(*,'(A)') "Simulation complete"
    print*, 'Data stored in files: '
    print*, trim('run')//"/"//trim(fname)
    print*, trim('run')//"/"//"epidemic.xyz"
end program epidemic_simulator