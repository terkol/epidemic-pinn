module utils
    use mtmod
    implicit none
contains
    subroutine initialize(box_len, walk_pos, walk_cond, n_sick, n_imm)
        integer, intent(inout) :: walk_pos(:,:), walk_cond(:)
        integer, intent(in) :: n_sick, n_imm, box_len
        integer :: i,j
        walk_cond(:n_sick+n_imm) = 1 ! Set first n_sick+n_imm as sick
        walk_cond(:n_imm) = 2 ! Set first n_imm immune, overwriting first sick walkers from previous line

        do i=1, size(walk_pos(:,1)) ! A random number in each coordinate in the walk_pos array
            walk_pos(i,1) = int(grnd()*box_len) 
            walk_pos(i,2) = int(grnd()*box_len)
        enddo
    end subroutine initialize

    subroutine move_walkers(walk_pos, box_len)
        integer, intent(inout) :: walk_pos(:,:)
        integer, intent(in) :: box_len
        integer :: x_moves(size(walk_pos(:,1)))
        integer :: y_moves(size(walk_pos(:,1)))
        integer :: i
        y_moves = 0
        do i=1, size(x_moves) ! Generate all moves that are performed this step
            x_moves(i) = int(grnd()*5)
        enddo
        ! 0 and 1 stay unmodified in x_moves
        where (x_moves == 2) x_moves = -1 ! 2 becomes -1
        where (x_moves == 3) 
            y_moves = 1     ! 3 becomes 1 for y_moves
            x_moves = 0
        endwhere
        where (x_moves == 4) 
            y_moves = -1    ! 4 becomes -1 for y_moves
            x_moves = 0
        endwhere
        ! PBC
        walk_pos(:,1) = modulo(walk_pos(:,1) + x_moves,box_len)
        walk_pos(:,2) = modulo(walk_pos(:,2) + y_moves,box_len) 
    end subroutine move_walkers

    subroutine infect_walkers(walk_pos, walk_cond, p_sick)
        integer, intent(inout) :: walk_pos(:,:), walk_cond(:)
        real, intent(in) :: p_sick
        logical :: exposed(size(walk_pos(:,1)))
        real :: r(size(walk_pos(:,1)))
        integer :: i, s
        s = size(exposed)
        exposed = .false.
        do i = 1, s     ! Loop through all walkers and if one is sick, see which other walkers are in the same spot and mark them as exposed
            r(i) = grnd() ! Also generate a random number for each walker to see which ones get infected after getting exposed
            if (walk_cond(i) == 1) then
                exposed = exposed .or. ( (walk_pos(:,1) == walk_pos(i,1)) .and. (walk_pos(:,2) == walk_pos(i,2)) )
            end if
        end do
        where (exposed .and. (walk_cond == 0) .and. (r < p_sick)) walk_cond = 1     ! 1 = sick
    end subroutine infect_walkers

    subroutine heal_walkers(walk_pos, walk_cond, p_heal)
        integer, intent(inout) :: walk_pos(:,:), walk_cond(:)
        real, intent(in) :: p_heal
        integer :: i, j
        do i=1, size(walk_pos(:,1)) ! Loop through walkers and if they are infected, generate a random number to see if they are healed
            if (walk_cond(i) == 1) then
                if (grnd() < p_heal) walk_cond(i) = 2   ! 2 = immune
            endif
        enddo
    end subroutine heal_walkers
end module utils