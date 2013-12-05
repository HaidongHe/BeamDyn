	SUBROUTINE lubksb(a,n,indx,b,ui)
    
    INTEGER(IntKi),INTENT(IN):: indx(:),n
    REAL(ReKi),INTENT(IN):: a(:,:)
    REAL(ReKi),INTENT(INOUT):: b(:)
    REAL(ReKi),INTENT(OUT):: ui(:)
    
    INTEGER(IntKi):: i,ii,j,ll
    REAL(ReKi):: summ
            
    ii = 0
    DO i = 1 , n
    	ll = indx(i)
        summ = b(ll)
        b(ll) = b(i)
        IF (ii .ne. 0) THEN
        	DO j = ii , i-1
            	summ = summ - a(i,j) * b(j)
			ENDDO
        ELSE IF (summ .ne. 0.0) THEN
        	ii = i
        ENDIF
        b(i) = summ
	ENDDO
      
    DO i = n,1,-1
    	summ = b(i)
        DO j = i+1 , n
			summ = summ - a(i,j) * b(j)
        ENDDO
        b(i) = summ / a(i,i)
    ENDDO
    
    do i=1,n
    	ui(i)=b(i)
    enddo
    	
	END subroutine