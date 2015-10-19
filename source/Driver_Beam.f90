!**********************************************************************************************************************************
! LICENSING
! Copyright (C) 2015  National Renewable Energy Laboratory
!
!    This file is part of the NWTC Subroutine Library.
!
! Licensed under the Apache License, Version 2.0 (the "License");
! you may not use this file except in compliance with the License.
! You may obtain a copy of the License at
!
!     http://www.apache.org/licenses/LICENSE-2.0
!
! Unless required by applicable law or agreed to in writing, software
! distributed under the License is distributed on an "AS IS" BASIS,
! WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
! See the License for the specific language governing permissions and
! limitations under the License.
!
!**********************************************************************************************************************************
PROGRAM BeamDyn_Driver_Program

   USE BeamDyn

   USE BeamDyn_Subs  ! for crv extract routines
   USE BeamDyn_Types
   USE BeamDyn_driver_subs
   USE NWTC_Library

   IMPLICIT NONE

   ! global glue-code-specific variables

   INTEGER(IntKi)                   :: ErrStat          ! Error status of the operation
   CHARACTER(1024)                  :: ErrMsg           ! Error message if ErrStat /= ErrID_None
   REAL(DbKi)                       :: dt_global        ! fixed/constant global time step
   REAL(DbKi)                       :: t_initial        ! time at initialization
   REAL(DbKi)                       :: t_final          ! time at simulation end 
   REAL(DbKi)                       :: t_global         ! global-loop time marker
   INTEGER(IntKi)                   :: n_t_final        ! total number of time steps
   INTEGER(IntKi)                   :: n_t_global       ! global-loop time counter
   INTEGER(IntKi)                   :: BD_interp_order  ! order of interpolation/extrapolation

   ! Module1 Derived-types variables; see Registry_Module1.txt for details

   TYPE(BD_InitInputType)           :: BD_InitInput
   TYPE(BD_ParameterType)           :: BD_Parameter
   TYPE(BD_ContinuousStateType)     :: BD_ContinuousState
   TYPE(BD_InitOutputType)          :: BD_InitOutput
   TYPE(BD_DiscreteStateType)       :: BD_DiscreteState
   TYPE(BD_ConstraintStateType)     :: BD_ConstraintState
   TYPE(BD_OtherStateType)          :: BD_OtherState
   TYPE(BD_InputType) ,ALLOCATABLE  :: BD_Input(:)
   REAL(DbKi),         ALLOCATABLE  :: BD_InputTimes(:)
   TYPE(BD_OutputType),ALLOCATABLE  :: BD_Output(:)
   REAL(DbKi),ALLOCATABLE           :: BD_OutputTimes(:)
   INTEGER(IntKi)                   :: DvrOut 

   CHARACTER(256)                   :: DvrInputFile
   CHARACTER(256)                   :: RootName


   ! local variables
   Integer(IntKi)                          :: i               ! counter for various loops
   REAL(R8Ki)                              :: start, finish
   REAL(BDKi) , DIMENSION(:), ALLOCATABLE  :: IniVelo         ! Initial Position Vector between origins of Global and blade frames [-]
   
   TYPE(ProgDesc), PARAMETER   :: version   = ProgDesc( 'BeamDyn Driver', 'v1.00.01', '19-Oct-2015' )  ! The version number of this program.
   
   ! -------------------------------------------------------------------------
   ! Initialization of library (especially for screen output)
   ! -------------------------------------------------------------------------      
   CALL NWTC_Init()
      ! Display the copyright notice
   CALL DispCopyrightLicense( version )   
      ! Tell our users what they're running
   CALL WrScr( ' Running '//GetNVD( version )//NewLine//' linked with '//TRIM( GetNVD( NWTC_Ver ))//NewLine )
   
   ! -------------------------------------------------------------------------
   ! Initialization of glue-code time-step variables
   ! -------------------------------------------------------------------------   
   
   CALL GET_COMMAND_ARGUMENT(1,DvrInputFile)
   CALL GetRoot(DvrInputFile,RootName)
   CALL BD_ReadDvrFile(DvrInputFile,t_initial,t_final,dt_global,BD_InitInput,ErrStat,ErrMsg)
      CALL CheckError()
   BD_InitInput%RootName         = TRIM(BD_Initinput%InputFile)
   BD_InitInput%RootDisp(:)      = 0.0_R8Ki
   BD_InitInput%RootOri(:,:)     = 0.0_R8Ki
   BD_InitInput%RootOri(1:3,1:3) = BD_InitInput%GlbRot(1:3,1:3)
   t_global = t_initial
   n_t_final = ((t_final - t_initial) / dt_global )

   ! define polynomial-order for ModName_Input_ExtrapInterp and ModName_Output_ExtrapInterp
   ! Must be 0, 1, or 2
   BD_interp_order = 1

   !Module1: allocate Input and Output arrays; used for interpolation and extrapolation
   ALLOCATE(BD_Input(BD_interp_order + 1)) 
   ALLOCATE(BD_InputTimes(BD_interp_order + 1)) 
   ALLOCATE(BD_Output(BD_interp_order + 1)) 
   ALLOCATE(BD_OutputTimes(BD_interp_order + 1)) 

   CALL BD_Init(BD_InitInput             &
                   , BD_Input(1)         &
                   , BD_Parameter        &
                   , BD_ContinuousState  &
                   , BD_DiscreteState    &
                   , BD_ConstraintState  &
                   , BD_OtherState       &
                   , BD_Output(1)        &
                   , dt_global           &
                   , BD_InitOutput       &
                   , ErrStat             &
                   , ErrMsg )
      CALL CheckError()

!bjj: this is the driver's hack to get initial velocities for the input-output solve      
   CALL AllocAry(IniVelo,BD_Parameter%dof_total,'IniVelo',ErrStat,ErrMsg); 
      CALL CheckError()
   IniVelo = BD_ContinuousState%dqdt
   
   CALL Dvr_InitializeOutputFile(DvrOut,BD_InitOutput,RootName,ErrStat,ErrMsg)
      CALL CheckError()

   BD_InputTimes(1)  = t_initial
   BD_InputTimes(2)  = t_initial 
   BD_OutputTimes(1) = t_initial
   BD_OutputTimes(2) = t_initial


   CALL BD_InputSolve( BD_InputTimes(1), BD_Input(1), BD_Parameter, BD_InitInput,IniVelo,ErrStat, ErrMsg)
   CALL BD_CopyInput (BD_Input(1) , BD_Input(2) , MESH_NEWCOPY, ErrStat, ErrMsg)
   CALL BD_CopyOutput(BD_Output(1), BD_Output(2), MESH_NEWCOPY, ErrStat, ErrMsg)
      CALL CheckError()


   CALL CPU_TIME(start)

   DO n_t_global = 0, n_t_final
     WRITE(*,*) "Time Step: ", n_t_global
     BD_InputTimes(2)  = BD_InputTimes(1) 
     BD_InputTimes(1)  = t_global + dt_global
     BD_OutputTimes(2) = BD_OutputTimes(1) 
     BD_OutputTimes(1) = t_global + dt_global
     CALL BD_InputSolve( BD_InputTimes(1), BD_Input(1), BD_Parameter, BD_InitInput, IniVelo, ErrStat, ErrMsg)
     CALL BD_InputSolve( BD_InputTimes(2), BD_Input(2), BD_Parameter, BD_InitInput, IniVelo, ErrStat, ErrMsg)
        CALL CheckError()

     CALL BD_CalcOutput( t_global, BD_Input(2), BD_Parameter, BD_ContinuousState, BD_DiscreteState, &
                             BD_ConstraintState, &
                             BD_OtherState,  BD_Output(2), ErrStat, ErrMsg)
        CALL CheckError()

     CALL Dvr_WriteOutputLine(t_global,DvrOut,BD_Parameter%OutFmt,BD_Output(2),ErrStat,ErrMsg)
        CALL CheckError()

     IF(BD_Parameter%analysis_type .EQ. 1 .AND. n_t_global .EQ. 1) EXIT 

     CALL BD_UpdateStates( t_global, n_t_global, BD_Input, BD_InputTimes, BD_Parameter, &
                               BD_ContinuousState, &
                               BD_DiscreteState, BD_ConstraintState, &
                               BD_OtherState, ErrStat, ErrMsg )
        CALL CheckError()

      t_global = REAL(n_t_global+1,DbKi) * dt_global + t_initial

   ENDDO

   CALL CPU_TIME(finish)
   
   WRITE(*,*) 'Start: ' , start
   WRITE(*,*) 'Finish: ', finish
   WRITE(*,*) 'Time: '  , finish-start

   CALL Dvr_End()

CONTAINS

   SUBROUTINE Dvr_End()

      character(ErrMsgLen)                          :: errMsg2                 ! temporary Error message if ErrStat /=
      integer(IntKi)                                :: errStat2                ! temporary Error status of the operation
      character(*), parameter                       :: RoutineName = 'Dvr_End'

      IF(DvrOut >0) CLOSE(DvrOut)

      DO i=1,BD_interp_order + 1
          CALL BD_End( BD_Input(i), BD_Parameter, BD_ContinuousState, BD_DiscreteState, &
                           BD_ConstraintState, BD_OtherState, BD_Output(i), ErrStat2, ErrMsg2 )
      ENDDO 
         call SetErrStat( errStat2, errMsg2, errStat, errMsg, RoutineName )

      IF(ALLOCATED(BD_InputTimes )) DEALLOCATE(BD_InputTimes )
      IF(ALLOCATED(BD_OutputTimes)) DEALLOCATE(BD_OutputTimes)

      if (ErrStat >= AbortErrLev) then      
         CALL ProgAbort( 'BeamDyn Driver encountered simulation error level: '&
             //TRIM(GetErrStr(ErrStat)), TrapErrors=.FALSE., TimeWait=3._ReKi )  ! wait 3 seconds (in case they double-clicked and got an error)
      else
         call NormStop()
      end if
   END SUBROUTINE Dvr_End

   subroutine CheckError()
   
      if (ErrStat /= ErrID_None) then
         call WrScr(TRIM(ErrMsg))
         
         if (ErrStat >= AbortErrLev) then
            call Dvr_End()
         end if
      end if
         
   end subroutine CheckError

END PROGRAM BeamDyn_Driver_Program



SUBROUTINE BD_InputSolve( t, u,  p, InitInput, IniVelo, ErrStat, ErrMsg)
 
   USE BeamDyn
   USE BeamDyn_Subs
   USE BeamDyn_Types
   USE NWTC_Library

   REAL(DbKi),             INTENT(IN   ) :: t
   TYPE(BD_InputType),     INTENT(INOUT) :: u
   TYPE(BD_ParameterType), INTENT(IN   ) :: p
   TYPE(BD_InitInputType), INTENT(IN   ) :: InitInput
   REAL(BDKi),             INTENT(IN   ) :: IniVelo(*)
   INTEGER(IntKi),         INTENT(  OUT) :: ErrStat          ! Error status of the operation
   CHARACTER(*),           INTENT(  OUT) :: ErrMsg           ! Error message if ErrStat /= ErrID_None
                                         
   ! local variables                     
   INTEGER(IntKi)                        :: i                ! do-loop counter
   REAL(BDKi)                            :: temp_vec(3)
   REAL(BDKi)                            :: temp_rr(3)
   REAL(BDKi)                            :: temp_R(3,3)
   REAL(BDKi)                            :: temp_r0(3)
   REAL(BDKi)                            :: temp_theta(3)
   REAL(BDKi)                            :: temp33(3,3)
   
   ! ----------------------------------------------------------------------

   ErrStat = ErrID_None
   ErrMsg  = ''

   temp_r0(:) = 0.0_BDKi 
   temp_rr(:) = 0.0_BDKi
   temp_R(:,:)= 0.0_BDKi
   temp_r0(1) = p%GlbPos(2)
   temp_r0(2) = p%GlbPos(3)
   temp_r0(3) = p%GlbPos(1)

   temp_theta(1) = IniVelo(5)*t
   temp_theta(2) = IniVelo(6)*t
   temp_theta(3) = IniVelo(4)*t
   temp_vec(:) = 0.0_BDKi
   temp_vec(:) = 4.0_BDKi*TAN(temp_theta(:)/4.0_BDKi)
   ! gather point forces and line forces

   ! Point mesh: RootMotion 
   ! Calculate root displacements and rotations
   u%RootMotion%Orientation(:,:,:) = 0.0_BDKi
   DO i=1,3
       u%RootMotion%Orientation(i,i,1) = 1.0_BDKi
       u%HubMotion%Orientation (i,i,1) = 1.0_BDKi
   ENDDO
   temp33=u%RootMotion%Orientation(:,:,1) !possible type conversion
   CALL BD_CrvMatrixR(temp_vec,temp33,ErrStat,ErrMsg)
   temp_rr(:) = MATMUL(u%RootMotion%Orientation(:,:,1),temp_r0)
   u%RootMotion%Orientation(:,:,1)   = TRANSPOSE(u%RootMotion%Orientation(:,:,1))
   u%RootMotion%TranslationDisp(:,:) = 0.0_BDKi
   u%RootMotion%TranslationDisp(:,1) = temp_rr(:) - temp_r0(:)
   ! END Calculate root displacements and rotations

   ! Calculate root translational and angular velocities
   u%RootMotion%RotationVel(:,:) = 0.0_BDKi
   u%RootMotion%RotationVel(1,1) = IniVelo(5)
   u%RootMotion%RotationVel(2,1) = IniVelo(6)
   u%RootMotion%RotationVel(3,1) = IniVelo(4)
   u%RootMotion%TranslationVel(:,:) = 0.0_BDKi
   u%RootMotion%TranslationVel(:,1) = MATMUL(BD_Tilde(real(u%RootMotion%RotationVel(:,1),BDKi)),temp_rr)
   ! END Calculate root translational and angular velocities


   ! Calculate root translational and angular accelerations
   u%RootMotion%TranslationAcc(:,:) = 0.0_BDKi
   u%RootMotion%RotationAcc   (:,:) = 0.0_BDKi
   u%RootMotion%TranslationAcc(:,1) = MATMUL(BD_Tilde(real(u%RootMotion%RotationVel(:,1),BDKi)), &
               MATMUL(BD_Tilde(real(u%RootMotion%RotationVel(:,1),BDKi)),temp_rr))
   ! END Calculate root translational and angular accelerations

   u%PointLoad%Force(:,:)  = 0.0_ReKi
   u%PointLoad%Moment(:,:) = 0.0_ReKi
   u%PointLoad%Force(1:3,p%node_total)  = InitInput%TipLoad(1:3)
   u%PointLoad%Moment(1:3,p%node_total) = InitInput%TipLoad(4:6)
   
   ! LINE2 mesh: DistrLoad
   u%DistrLoad%Force(:,:)  = 0.0_ReKi
   u%DistrLoad%Moment(:,:) = 0.0_ReKi

   IF(p%quadrature .EQ. 1) THEN
       DO i=1,p%ngp*p%elem_total+2
           u%DistrLoad%Force(1:3,i) = InitInput%DistrLoad(1:3)
           u%DistrLoad%Moment(1:3,i)= InitInput%DistrLoad(4:6)
       ENDDO
   ELSEIF(p%quadrature .EQ. 2) THEN
       DO i=1,p%ngp
           u%DistrLoad%Force(1:3,i) = InitInput%DistrLoad(1:3)
           u%DistrLoad%Moment(1:3,i)= InitInput%DistrLoad(4:6)
       ENDDO
   ENDIF

END SUBROUTINE BD_InputSolve

