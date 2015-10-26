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
module BeamDyn_driver_subs
  
  
  contains
  
  SUBROUTINE BD_ReadDvrFile(DvrInputFile,t_ini,t_f,dt,InitInputData,&
                          ErrStat,ErrMsg)
!------------------------------------------------------------------------------------
! This routine reads in the primary BeamDyn input file and places the values it reads
! in the InputFileData structure.
!   It opens an echo file if requested and returns the (still-open) echo file to the
!     calling routine.
!   It also returns the names of the BldFile, FurlFile, and TrwFile for further
!     reading of inputs.
!------------------------------------------------------------------------------------
   USE BeamDyn
   USE BeamDyn_Subs
   USE BeamDyn_Types
   USE NWTC_Library

   ! Passed variables
   CHARACTER(*),                 INTENT(IN   ) :: DvrInputFile
   INTEGER(IntKi),               INTENT(  OUT) :: ErrStat
   CHARACTER(*),                 INTENT(  OUT) :: ErrMsg
   TYPE(BD_InitInputType),       INTENT(  OUT) :: InitInputData
   REAL(DbKi),                   INTENT(  OUT) :: t_ini
   REAL(DbKi),                   INTENT(  OUT) :: t_f
   REAL(DbKi),                   INTENT(  OUT) :: dt

   ! Local variables:
   INTEGER(IntKi)               :: UnIn                         ! Unit number for reading file
   INTEGER(IntKi)               :: ErrStat2                     ! Temporary Error status
   CHARACTER(ErrMsgLen)         :: ErrMsg2                      ! Temporary Error message
   character(*), parameter      :: RoutineName = 'BD_ReadDvrFile'
   INTEGER(IntKi)               :: UnEc
   
   CHARACTER(1024)              :: FTitle                       ! "File Title": the 2nd line of the input file, which contains a description of its contents

   INTEGER(IntKi)               :: i
!------------------------------------------------------------------------------------

   ! Initialize some variables:
   ErrStat = ErrID_None
   ErrMsg  = ""
   UnEc = -1
   
   CALL GetNewUnit(UnIn,ErrStat2,ErrMsg2)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )
   CALL OpenFInpFile(UnIn,DvrInputFile,ErrStat2,ErrMsg2)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )
      IF (ErrStat >= AbortErrLev) RETURN
      
   !-------------------------- HEADER ---------------------------------------------
   CALL ReadCom(UnIn,DvrInputFile,'File Header: Module Version (line 1)',ErrStat2,ErrMsg2,UnEc)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )
      
   CALL ReadStr(UnIn,DvrInputFile,FTitle,'FTitle','File Header: File Description (line 2)',ErrStat2, ErrMsg2, UnEc)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )
      if (ErrStat >= AbortErrLev) then
         call cleanup()
         return
      end if

   !---------------------- SIMULATION CONTROL --------------------------------------
   CALL ReadCom(UnIn,DvrInputFile,'Section Header: Simulation Control',ErrStat2,ErrMsg2,UnEc)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )
   t_ini = 0.0_DbKi 
   t_f   = 0.0_DbKi 
   dt    = 0.0_DbKi 
   CALL ReadVar(UnIn,DvrInputFile,t_ini,'t_initial','Starting time of simulation',ErrStat2,ErrMsg2,UnEc)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )

   CALL ReadVar(UnIn,DvrInputFile,t_f,"t_final", "Ending time of simulation",ErrStat2,ErrMsg2,UnEc)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )
      
   CALL ReadVar(UnIn,DvrInputFile,dt,"dt", "Time increment size",ErrStat2,ErrMsg2,UnEc)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )
      
   !---------------------- GRAVITY PARAMETER --------------------------------------
   CALL ReadCom(UnIn,DvrInputFile,'Section Header: Gravity Parameter',ErrStat2,ErrMsg2,UnEc)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )
   InitInputData%gravity(:) = 0.0_ReKi
   CALL ReadVar(UnIn,DvrInputFile,InitInputData%gravity(1),"InitInputData%gravity(1)", "gravity vector X",ErrStat2,ErrMsg2,UnEc)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )  
   CALL ReadVar(UnIn,DvrInputFile,InitInputData%gravity(2),"InitInputData%gravity(2)", "gravity vector Y",ErrStat2,ErrMsg2,UnEc)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName ) 
   CALL ReadVar(UnIn,DvrInputFile,InitInputData%gravity(3),"InitInputData%gravity(3)", "gravity vector Z",ErrStat2,ErrMsg2,UnEc)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )
   if (ErrStat >= AbortErrLev) then
       call cleanup()
       return
   end if
   !---------------------- FRAME PARAMETER --------------------------------------
   CALL ReadCom(UnIn,DvrInputFile,'Section Header: Frame Parameter',ErrStat2,ErrMsg2,UnEc)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )
   InitInputData%GlbPos(:)   = 0.0_ReKi
   InitInputData%GlbRot(:,:) = 0.0_R8Ki
   CALL ReadVar(UnIn,DvrInputFile,InitInputData%GlbPos(1),"InitInputData%GlbPos(1)", "position vector X",ErrStat2,ErrMsg2,UnEc)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )  
   CALL ReadVar(UnIn,DvrInputFile,InitInputData%GlbPos(2),"InitInputData%GlbPos(2)", "position vector Y",ErrStat2,ErrMsg2,UnEc)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName ) 
   CALL ReadVar(UnIn,DvrInputFile,InitInputData%GlbPos(3),"InitInputData%GlbPos(3)", "position vector Z",ErrStat2,ErrMsg2,UnEc)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )

   CALL ReadCom(UnIn,DvrInputFile,'Comments on DCM',ErrStat2,ErrMsg2,UnEc)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )
   CALL ReadCom(UnIn,DvrInputFile,'Comments on DCM',ErrStat2,ErrMsg2,UnEc)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )
   DO i=1,3
       CALL ReadAry(UnIn,DvrInputFile,InitInputData%GlbRot(i,:),3,"InitInputData%GlbPos",&
               "Global DCM",ErrStat2,ErrMsg2,UnEc)
          CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )
   ENDDO
   if (ErrStat >= AbortErrLev) then
       call cleanup()
       return
   end if
   !---------------------- INITIAL VELOCITY PARAMETER --------------------------------
   CALL ReadCom(UnIn,DvrInputFile,'Section Header: Initial Velocity Parameter',ErrStat2,ErrMsg2,UnEc)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )
   InitInputData%RootVel(:)   = 0.0_ReKi 
   CALL ReadVar(UnIn,DvrInputFile,InitInputData%RootVel(4),"InitInputData%IniRootVel(1)", "angular velocity vector X",ErrStat2,ErrMsg2,UnEc)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )  
   CALL ReadVar(UnIn,DvrInputFile,InitInputData%RootVel(5),"InitInputData%IniRootVel(2)", "angular velocity vector Y",ErrStat2,ErrMsg2,UnEc)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )
   CALL ReadVar(UnIn,DvrInputFile,InitInputData%RootVel(6),"InitInputData%IniRootVel(3)", "angular velocity vector Z",ErrStat2,ErrMsg2,UnEc)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )
   InitInputData%RootVel(1:3) = MATMUL(BD_Tilde_SP(InitInputData%RootVel(4:6)),InitInputData%GlbPos(:))
   if (ErrStat >= AbortErrLev) then
       call cleanup()
       return
   end if
  
   !---------------------- APPLIED FORCE --------------------------------
   CALL ReadCom(UnIn,DvrInputFile,'Section Header: Applied Force',ErrStat2,ErrMsg2,UnEc)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )
   InitInputData%DistrLoad(:)   = 0.0_ReKi
   InitInputData%TipLoad(:)     = 0.0_ReKi
   CALL ReadVar(UnIn,DvrInputFile,InitInputData%DistrLoad(1),"InitInputData%DistrLoad(1)", "Distributed load vector X",ErrStat2,ErrMsg2,UnEc)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )  
   CALL ReadVar(UnIn,DvrInputFile,InitInputData%DistrLoad(2),"InitInputData%DistrLoad(2)", "Distributed load vector Y",ErrStat2,ErrMsg2,UnEc)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )  
   CALL ReadVar(UnIn,DvrInputFile,InitInputData%DistrLoad(3),"InitInputData%DistrLoad(3)", "Distributed load vector Z",ErrStat2,ErrMsg2,UnEc)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )  
   CALL ReadVar(UnIn,DvrInputFile,InitInputData%DistrLoad(4),"InitInputData%DistrLoad(4)", "Distributed load vector X",ErrStat2,ErrMsg2,UnEc)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )  
   CALL ReadVar(UnIn,DvrInputFile,InitInputData%DistrLoad(5),"InitInputData%DistrLoad(5)", "Distributed load vector Y",ErrStat2,ErrMsg2,UnEc)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )  
   CALL ReadVar(UnIn,DvrInputFile,InitInputData%DistrLoad(6),"InitInputData%DistrLoad(6)", "Distributed load vector Z",ErrStat2,ErrMsg2,UnEc)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )  
   CALL ReadVar(UnIn,DvrInputFile,InitInputData%TipLoad(1),"InitInputData%TipLoad(1)", "Tip load vector X",ErrStat2,ErrMsg2,UnEc)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )  
   CALL ReadVar(UnIn,DvrInputFile,InitInputData%TipLoad(2),"InitInputData%TipLoad(2)", "Tip load vector Y",ErrStat2,ErrMsg2,UnEc)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )  
   CALL ReadVar(UnIn,DvrInputFile,InitInputData%TipLoad(3),"InitInputData%TipLoad(3)", "Tip load vector Z",ErrStat2,ErrMsg2,UnEc)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )  
   CALL ReadVar(UnIn,DvrInputFile,InitInputData%TipLoad(4),"InitInputData%TipLoad(4)", "Tip load vector X",ErrStat2,ErrMsg2,UnEc)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )  
   CALL ReadVar(UnIn,DvrInputFile,InitInputData%TipLoad(5),"InitInputData%TipLoad(5)", "Tip load vector Y",ErrStat2,ErrMsg2,UnEc)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )  
   CALL ReadVar(UnIn,DvrInputFile,InitInputData%TipLoad(6),"InitInputData%TipLoad(6)", "Tip load vector Z",ErrStat2,ErrMsg2,UnEc)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )  
   if (ErrStat >= AbortErrLev) then
       call cleanup()
       return
   end if
   !---------------------- BEAM SECTIONAL PARAMETER ----------------------------------------
   CALL ReadCom(UnIn,DvrInputFile,'Section Header: Primary input file',ErrStat2,ErrMsg2,UnEc)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )
   CALL ReadVar ( UnIn, DvrInputFile, InitInputData%InputFile, 'InputFile', 'Name of the primary input file', ErrStat2,ErrMsg2, UnEc )
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )
   if (ErrStat >= AbortErrLev) then
       call cleanup()
       return
   end if

   call cleanup()
   return
      
contains
   subroutine cleanup() 
      close(UnIn)
      return
   end subroutine cleanup         
END SUBROUTINE BD_ReadDvrFile

SUBROUTINE Dvr_InitializeOutputFile(OutUnit,IntOutput,RootName,ErrStat,ErrMsg)

   USE BeamDyn
   USE BeamDyn_Types
   USE NWTC_Library

   INTEGER(IntKi),              INTENT(  OUT):: OutUnit
   TYPE(BD_InitOutputType),     INTENT(IN   ):: IntOutput     ! Output for initialization routine
   INTEGER(IntKi),              INTENT(  OUT):: ErrStat     ! Error status of the operation
   CHARACTER(*),                INTENT(  OUT):: ErrMsg      ! Error message if ErrStat /= ErrID_None
   CHARACTER(*),                INTENT(IN   ):: RootName

   integer(IntKi)                            :: i      
   integer(IntKi)                            :: numOuts
   INTEGER(IntKi)                            :: ErrStat2                     ! Temporary Error status
   CHARACTER(ErrMsgLen)                      :: ErrMsg2                      ! Temporary Error message
   character(*), parameter                   :: RoutineName = 'Dvr_InitializeOutputFile'

   ErrStat = ErrID_none
   ErrMsg  = ""
   
   CALL GetNewUnit(OutUnit,ErrStat2,ErrMsg2)
   CALL OpenFOutFile ( OutUnit, trim(RootName)//'.out', ErrStat2, ErrMsg2 )
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )
      if (ErrStat >= AbortErrLev) return

   write (OutUnit,'(/,A)')  'Predictions were generated on '//CurDate()//' at '//CurTime()//' using '//trim(GetNVD(IntOutput%Ver))
   write (OutUnit,'()' )    !print a blank line
   
   numOuts = size(IntOutput%WriteOutputHdr)
   !......................................................
   ! Write the names of the output parameters on one line:
   !......................................................

   write (OutUnit,'()')
   write (OutUnit,'()')
   write (OutUnit,'()')

   call WrFileNR ( OutUnit, 'Time        ' )

   do i=1,NumOuts
      call WrFileNR ( OutUnit, tab//IntOutput%WriteOutputHdr(i) )
   end do ! i

   write (OutUnit,'()')

      !......................................................
      ! Write the units of the output parameters on one line:
      !......................................................

   call WrFileNR ( OutUnit, ' (s)            ' )

   do i=1,NumOuts
      call WrFileNR ( Outunit, tab//IntOutput%WriteOutputUnt(i) )
   end do ! i

   write (OutUnit,'()')  


END SUBROUTINE Dvr_InitializeOutputFile


SUBROUTINE Dvr_WriteOutputLine(t,OutUnit, OutFmt, Output, errStat, errMsg)

   USE BeamDyn_Types
   USE NWTC_Library

   real(DbKi)             ,  intent(in   )   :: t                    ! simulation time (s)
   INTEGER(IntKi)         ,  intent(in   )   :: OutUnit              ! Status of error message
   CHARACTER(*)           ,  intent(in   )   :: OutFmt
!   real(ReKi)             ,  intent(in   )   :: output(:)            ! Rootname for the output file
   TYPE(BD_OutputType),      INTENT(IN   )   :: Output
   integer(IntKi)         ,  intent(inout)   :: errStat              ! Status of error message
   character(*)           ,  intent(inout)   :: errMsg               ! Error message if ErrStat /= ErrID_None
      
   ! Local variables.

   character(200)                            :: frmt                 ! A string to hold a format specifier
   character(15)                             :: tmpStr               ! temporary string to print the time output as text

   integer :: numOuts
   
   errStat = ErrID_None
   errMsg  = ''

   numOuts = size(Output%WriteOutput,1)
   frmt = '"'//tab//'"'//trim(OutFmt)      ! format for array elements from individual modules
   
      ! time
   write( tmpStr, '(F15.6)' ) t
   call WrFileNR( OutUnit, tmpStr )
   call WrNumAryFileNR ( OutUnit, Output%WriteOutput,  frmt, errStat, errMsg )
   if ( errStat >= AbortErrLev ) return
   
     ! write a new line (advance to the next line)
   write (OutUnit,'()')
      
end subroutine Dvr_WriteOutputLine
  
end module BeamDyn_driver_subs