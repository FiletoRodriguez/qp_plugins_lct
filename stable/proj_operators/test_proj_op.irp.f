program projected_operators
  implicit none
  BEGIN_DOC
! TODO
  END_DOC
! read_wf = .True.
! touch read_wf
! call routine_v
! call routine_rho 
! call routine_final
  call routine_valence

end

subroutine routine_valence
 implicit none
 integer :: ipoint,k,l,i,j
 double precision :: accu_val,accu_ful, weight,r(3),integral_psi_val,integral_psi_ful
 accu_val = 0.d0
 accu_ful = 0.d0
 do ipoint  = 1, n_points_final_grid
  weight=final_weight_at_r_vector(ipoint)
  r(1) = final_grid_points(1,ipoint)
  r(2) = final_grid_points(2,ipoint)
  r(3) = final_grid_points(3,ipoint)
  call integral_f_HF_valence_ab(r,integral_psi_val)
  call integral_of_f_12_hf_over_beta(r,integral_psi_ful)
  accu_val += integral_psi_val * weight
  accu_ful += integral_psi_ful * weight
 enddo
!print*,'integral_f_hf        = ',integral_f_hf
 print*,'accu_val             = ',accu_val
!print*,'accu_ful             = ',accu_ful
!print*,'psi_energy_two_e_ab  = ',psi_energy_two_e_ab
!print*,'integral_r1r2_f_HF_ab= ',integral_r1r2_f_HF_ab
 double precision :: accu_2
 accu_2 = 0.d0
 do i = n_core_orb+1, elec_alpha_num
  do j = n_core_orb+1, elec_beta_num
!do i = 1,n_core_orb
! do j = 1,n_core_orb
   accu_2 += mo_two_e_integrals_jj(j,i)
  enddo
 enddo
 print*,'accu_2               = ',accu_2
end

subroutine routine_rho
 implicit none
 print*,'integral_r1r2_f_HF_aa = ',integral_r1r2_f_HF_aa
 print*,'psi_energy_two_e      = ',psi_energy_two_e

end
subroutine routine_v
 implicit none
 integer :: ipoint,k,l
 double precision :: accu, weight,r(3),integral_of_f_PSI_ab_over_2,f_HF_aa_integrated
 accu = 0.d0
 do ipoint  = 1, n_points_final_grid
  weight=final_weight_at_r_vector(ipoint)
  r(1) = final_grid_points(1,ipoint)
  r(2) = final_grid_points(2,ipoint)
  r(3) = final_grid_points(3,ipoint)
  accu += f_HF_aa_integrated(r) * weight
! accu += integral_of_f_PSI_ab_over_2(r) * weight
 enddo
 print*,'accu                   = ',accu
 print*,'psi_energy_two_e      = ',psi_energy_two_e
!print*,'integral_f_hf          = ',integral_f_hf
 accu = 0.d0
 integer :: i,j
 do i = 1, mo_num
  do j = 1, mo_num
   accu +=  two_bod_alpha_beta_mo(j,j,i,i,1)
  enddo
 enddo
 print*,'accu = ',accu
end
 

subroutine routine_final
 implicit none
 integer :: i,j,k,nx
 double precision :: dx,xmax,r12
 double precision :: r1(3),r2(3),numerator,denominator,f_HF_aa,HF_two_body_dm_aa,potential
 xmax = 2.d0
 nx = 10000
 dx = xmax/dble(nx)
 r1 = 0.d0
 r2 = r1
 
 double precision :: laplacian_f,value_f_HF_aa
 double precision :: laplacian_hf,HF_two_bod
 call f_HF_aa_spherical_averaged(r1,0.d0,laplacian_f,value_f_HF_aa)
 call HF_two_body_dm_aa_spherical_laplacian(r1,0.d0,HF_two_bod,laplacian_HF)
 double precision :: mu
 print*,'laplacian_f = ',laplacian_f
 print*,'laplacian_HF= ',laplacian_HF
 mu = laplacian_f/laplacian_HF
 print*,'mu = ',mu
 do i = 1, nx
  r2(1) += dx
  r2(2) += dx
  r12 = dsqrt((r1(1) - r2(1))**2 + (r1(2) - r2(2))**2  + (r1(3) - r2(3))**2 )
  numerator = f_HF_aa(r1,r2) 
  denominator = HF_two_body_dm_aa(r1,r2)
  potential = numerator/denominator
  write(33,'(100(F16.10,X))')r12,potential,erf(mu * r12)/r12,1.d0/r12,numerator,denominator,numerator/denominator
 enddo

end
