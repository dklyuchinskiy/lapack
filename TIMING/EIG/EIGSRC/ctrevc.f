      SUBROUTINE CTREVC( SIDE, HOWMNY, SELECT, N, T, LDT, VL, LDVL, VR,
     $                   LDVR, MM, M, WORK, RWORK, INFO )
*
*  -- LAPACK routine (instrumented to count operations, version 3.0) --
*     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
*     Courant Institute, Argonne National Lab, and Rice University
*     May 7, 2001
*
*     .. Scalar Arguments ..
      CHARACTER          HOWMNY, SIDE
      INTEGER            INFO, LDT, LDVL, LDVR, M, MM, N
*     ..
*     .. Array Arguments ..
      LOGICAL            SELECT( * )
      REAL               RWORK( * )
      COMPLEX            T( LDT, * ), VL( LDVL, * ), VR( LDVR, * ),
     $                   WORK( * )
*     ..
*     Common block to return operation count.
*     OPS is only incremented, OPST is used to accumulate small
*     contributions to OPS to avoid roundoff error
*     .. Common blocks ..
      COMMON             / LATIME / OPS, ITCNT
*     ..
*     .. Scalars in Common ..
      REAL               ITCNT, OPS
*     ..
*
*  Purpose
*  =======
*
*  CTREVC computes some or all of the right and/or left eigenvectors of
*  a complex upper triangular matrix T.
*  Matrices of this type are produced by the Schur factorization of
*  a complex general matrix:  A = Q*T*Q**H, as computed by CHSEQR.
*  
*  The right eigenvector x and the left eigenvector y of T corresponding
*  to an eigenvalue w are defined by:
*  
*               T*x = w*x,     (y**H)*T = w*(y**H)
*  
*  where y**H denotes the conjugate transpose of the vector y.
*  The eigenvalues are not input to this routine, but are read directly
*  from the diagonal of T.
*  
*  This routine returns the matrices X and/or Y of right and left
*  eigenvectors of T, or the products Q*X and/or Q*Y, where Q is an
*  input matrix.  If Q is the unitary factor that reduces a matrix A to
*  Schur form T, then Q*X and Q*Y are the matrices of right and left
*  eigenvectors of A.
*
*  Arguments
*  =========
*
*  SIDE    (input) CHARACTER*1
*          = 'R':  compute right eigenvectors only;
*          = 'L':  compute left eigenvectors only;
*          = 'B':  compute both right and left eigenvectors.
*
*  HOWMNY  (input) CHARACTER*1
*          = 'A':  compute all right and/or left eigenvectors;
*          = 'B':  compute all right and/or left eigenvectors,
*                  backtransformed using the matrices supplied in
*                  VR and/or VL;
*          = 'S':  compute selected right and/or left eigenvectors,
*                  as indicated by the logical array SELECT.
*
*  SELECT  (input) LOGICAL array, dimension (N)
*          If HOWMNY = 'S', SELECT specifies the eigenvectors to be
*          computed.
*          The eigenvector corresponding to the j-th eigenvalue is
*          computed if SELECT(j) = .TRUE..
*          Not referenced if HOWMNY = 'A' or 'B'.
*
*  N       (input) INTEGER
*          The order of the matrix T. N >= 0.
*
*  T       (input/output) COMPLEX array, dimension (LDT,N)
*          The upper triangular matrix T.  T is modified, but restored
*          on exit.
*
*  LDT     (input) INTEGER
*          The leading dimension of the array T. LDT >= max(1,N).
*
*  VL      (input/output) COMPLEX array, dimension (LDVL,MM)
*          On entry, if SIDE = 'L' or 'B' and HOWMNY = 'B', VL must
*          contain an N-by-N matrix Q (usually the unitary matrix Q of
*          Schur vectors returned by CHSEQR).
*          On exit, if SIDE = 'L' or 'B', VL contains:
*          if HOWMNY = 'A', the matrix Y of left eigenvectors of T;
*          if HOWMNY = 'B', the matrix Q*Y;
*          if HOWMNY = 'S', the left eigenvectors of T specified by
*                           SELECT, stored consecutively in the columns
*                           of VL, in the same order as their
*                           eigenvalues.
*          Not referenced if SIDE = 'R'.
*
*  LDVL    (input) INTEGER
*          The leading dimension of the array VL.  LDVL >= 1, and if
*          SIDE = 'L' or 'B', LDVL >= N.
*
*  VR      (input/output) COMPLEX array, dimension (LDVR,MM)
*          On entry, if SIDE = 'R' or 'B' and HOWMNY = 'B', VR must
*          contain an N-by-N matrix Q (usually the unitary matrix Q of
*          Schur vectors returned by CHSEQR).
*          On exit, if SIDE = 'R' or 'B', VR contains:
*          if HOWMNY = 'A', the matrix X of right eigenvectors of T;
*          if HOWMNY = 'B', the matrix Q*X;
*          if HOWMNY = 'S', the right eigenvectors of T specified by
*                           SELECT, stored consecutively in the columns
*                           of VR, in the same order as their
*                           eigenvalues.
*          Not referenced if SIDE = 'L'.
*
*  LDVR    (input) INTEGER
*          The leading dimension of the array VR.  LDVR >= 1, and if
*          SIDE = 'R' or 'B'; LDVR >= N.
*
*  MM      (input) INTEGER
*          The number of columns in the arrays VL and/or VR. MM >= M.
*
*  M       (output) INTEGER
*          The number of columns in the arrays VL and/or VR actually
*          used to store the eigenvectors.  If HOWMNY = 'A' or 'B', M
*          is set to N.  Each selected eigenvector occupies one
*          column.
*
*  WORK    (workspace) COMPLEX array, dimension (2*N)
*
*  RWORK   (workspace) REAL array, dimension (N)
*
*  INFO    (output) INTEGER
*          = 0:  successful exit
*          < 0:  if INFO = -i, the i-th argument had an illegal value
*
*  Further Details
*  ===============
*
*  The algorithm used in this program is basically backward (forward)
*  substitution, with scaling to make the the code robust against
*  possible overflow.
*
*  Each eigenvector is normalized so that the element of largest
*  magnitude has magnitude 1; here the magnitude of a complex number
*  (x,y) is taken to be |x| + |y|.
*
*  =====================================================================
*
*     .. Parameters ..
      REAL               ZERO, ONE
      PARAMETER          ( ZERO = 0.0E+0, ONE = 1.0E+0 )
      COMPLEX            CMZERO, CMONE
      PARAMETER          ( CMZERO = ( 0.0E+0, 0.0E+0 ),
     $                   CMONE = ( 1.0E+0, 0.0E+0 ) )
*     ..
*     .. Local Scalars ..
      LOGICAL            ALLV, BOTHV, LEFTV, OVER, RIGHTV, SOMEV
      INTEGER            I, II, IS, J, K, KI
      REAL               OPST, OVFL, REMAX, SCALE, SMIN, SMLNUM, ULP,
     $                   UNFL
      COMPLEX            CDUM
*     ..
*     .. External Functions ..
      LOGICAL            LSAME
      INTEGER            ICAMAX
      REAL               SCASUM, SLAMCH
      EXTERNAL           LSAME, ICAMAX, SCASUM, SLAMCH
*     ..
*     .. External Subroutines ..
      EXTERNAL           CCOPY, CGEMV, CLATRS, CSSCAL, SLABAD, XERBLA
*     ..
*     .. Intrinsic Functions ..
      INTRINSIC          ABS, AIMAG, CMPLX, CONJG, MAX, REAL
*     ..
*     .. Statement Functions ..
      REAL               CABS1
*     ..
*     .. Statement Function definitions ..
      CABS1( CDUM ) = ABS( REAL( CDUM ) ) + ABS( AIMAG( CDUM ) )
*     ..
*     .. Executable Statements ..
*
*     Decode and test the input parameters
*
      BOTHV = LSAME( SIDE, 'B' )
      RIGHTV = LSAME( SIDE, 'R' ) .OR. BOTHV
      LEFTV = LSAME( SIDE, 'L' ) .OR. BOTHV
*
      ALLV = LSAME( HOWMNY, 'A' )
      OVER = LSAME( HOWMNY, 'B' )
      SOMEV = LSAME( HOWMNY, 'S' )
*
*     Set M to the number of columns required to store the selected
*     eigenvectors.
*
      IF( SOMEV ) THEN
         M = 0
         DO 10 J = 1, N
            IF( SELECT( J ) )
     $         M = M + 1
   10    CONTINUE
      ELSE
         M = N
      END IF
*
      INFO = 0
      IF( .NOT.RIGHTV .AND. .NOT.LEFTV ) THEN
         INFO = -1
      ELSE IF( .NOT.ALLV .AND. .NOT.OVER .AND. .NOT.SOMEV ) THEN
         INFO = -2
      ELSE IF( N.LT.0 ) THEN
         INFO = -4
      ELSE IF( LDT.LT.MAX( 1, N ) ) THEN
         INFO = -6
      ELSE IF( LDVL.LT.1 .OR. ( LEFTV .AND. LDVL.LT.N ) ) THEN
         INFO = -8
      ELSE IF( LDVR.LT.1 .OR. ( RIGHTV .AND. LDVR.LT.N ) ) THEN
         INFO = -10
      ELSE IF( MM.LT.M ) THEN
         INFO = -11
      END IF
      IF( INFO.NE.0 ) THEN
         CALL XERBLA( 'CTREVC', -INFO )
         RETURN
      END IF
*
*     Quick return if possible.
*
      IF( N.EQ.0 )
     $   RETURN
***
*     Initialize
      OPST = 0
***
*
*     Set the constants to control overflow.
*
      UNFL = SLAMCH( 'Safe minimum' )
      OVFL = ONE / UNFL
      CALL SLABAD( UNFL, OVFL )
      ULP = SLAMCH( 'Precision' )
      SMLNUM = UNFL*( N / ULP )
*
*     Store the diagonal elements of T in working array WORK.
*
      DO 20 I = 1, N
         WORK( I+N ) = T( I, I )
   20 CONTINUE
*
*     Compute 1-norm of each column of strictly upper triangular
*     part of T to control overflow in triangular solver.
*
      RWORK( 1 ) = ZERO
      DO 30 J = 2, N
         RWORK( J ) = SCASUM( J-1, T( 1, J ), 1 )
   30 CONTINUE
***
      OPS = OPS + N*( N-1 )
***
*
      IF( RIGHTV ) THEN
*
*        Compute right eigenvectors.
*
         IS = M
         DO 80 KI = N, 1, -1
*
            IF( SOMEV ) THEN
               IF( .NOT.SELECT( KI ) )
     $            GO TO 80
            END IF
            SMIN = MAX( ULP*( CABS1( T( KI, KI ) ) ), SMLNUM )
*
            WORK( 1 ) = CMONE
*
*           Form right-hand side.
*
            DO 40 K = 1, KI - 1
               WORK( K ) = -T( K, KI )
   40       CONTINUE
*
*           Solve the triangular system:
*              (T(1:KI-1,1:KI-1) - T(KI,KI))*X = SCALE*WORK.
*
            DO 50 K = 1, KI - 1
               T( K, K ) = T( K, K ) - T( KI, KI )
               IF( CABS1( T( K, K ) ).LT.SMIN )
     $            T( K, K ) = SMIN
   50       CONTINUE
***
            OPST = OPST + 2*( KI-1 )
***
*
            IF( KI.GT.1 ) THEN
               CALL CLATRS( 'Upper', 'No transpose', 'Non-unit', 'Y',
     $                      KI-1, T, LDT, WORK( 1 ), SCALE, RWORK,
     $                      INFO )
               WORK( KI ) = SCALE
            END IF
***
*           Increment opcount for triangular solver, assuming that
*           ops CLATRS = ops CTRSV, with no scaling in CLATRS.
            OPS = OPS + 4*KI*( KI-1 )
***
*
*           Copy the vector x or Q*x to VR and normalize.
*
            IF( .NOT.OVER ) THEN
               CALL CCOPY( KI, WORK( 1 ), 1, VR( 1, IS ), 1 )
*
               II = ICAMAX( KI, VR( 1, IS ), 1 )
               REMAX = ONE / CABS1( VR( II, IS ) )
               CALL CSSCAL( KI, REMAX, VR( 1, IS ), 1 )
***
               OPST = OPST + ( 4*KI+3 )
***
*
               DO 60 K = KI + 1, N
                  VR( K, IS ) = CMZERO
   60          CONTINUE
            ELSE
               IF( KI.GT.1 )
     $            CALL CGEMV( 'N', N, KI-1, CMONE, VR, LDVR, WORK( 1 ),
     $                        1, CMPLX( SCALE ), VR( 1, KI ), 1 )
*
               II = ICAMAX( N, VR( 1, KI ), 1 )
               REMAX = ONE / CABS1( VR( II, KI ) )
               CALL CSSCAL( N, REMAX, VR( 1, KI ), 1 )
***
               OPS = OPS + ( 8*N*( KI-1 )+10*N+3 )
***
            END IF
*
*           Set back the original diagonal elements of T.
*
            DO 70 K = 1, KI - 1
               T( K, K ) = WORK( K+N )
   70       CONTINUE
*
            IS = IS - 1
   80    CONTINUE
      END IF
*
      IF( LEFTV ) THEN
*
*        Compute left eigenvectors.
*
         IS = 1
         DO 130 KI = 1, N
*
            IF( SOMEV ) THEN
               IF( .NOT.SELECT( KI ) )
     $            GO TO 130
            END IF
            SMIN = MAX( ULP*( CABS1( T( KI, KI ) ) ), SMLNUM )
*
            WORK( N ) = CMONE
*
*           Form right-hand side.
*
            DO 90 K = KI + 1, N
               WORK( K ) = -CONJG( T( KI, K ) )
   90       CONTINUE
*
*           Solve the triangular system:
*              (T(KI+1:N,KI+1:N) - T(KI,KI))'*X = SCALE*WORK.
*
            DO 100 K = KI + 1, N
               T( K, K ) = T( K, K ) - T( KI, KI )
               IF( CABS1( T( K, K ) ).LT.SMIN )
     $            T( K, K ) = SMIN
  100       CONTINUE
***
            OPST = OPST + 2*( N-KI )
***
*
            IF( KI.LT.N ) THEN
               CALL CLATRS( 'Upper', 'Conjugate transpose', 'Non-unit',
     $                      'Y', N-KI, T( KI+1, KI+1 ), LDT,
     $                      WORK( KI+1 ), SCALE, RWORK, INFO )
               WORK( KI ) = SCALE
            END IF
***
*           Increment opcount for triangular solver, assuming that
*           ops CLATRS = ops CTRSV, with no scaling in CLATRS.
            OPS = OPS + 4*( N-KI )*( N-KI+1 )
***
*
*           Copy the vector x or Q*x to VL and normalize.
*
            IF( .NOT.OVER ) THEN
               CALL CCOPY( N-KI+1, WORK( KI ), 1, VL( KI, IS ), 1 )
*
               II = ICAMAX( N-KI+1, VL( KI, IS ), 1 ) + KI - 1
               REMAX = ONE / CABS1( VL( II, IS ) )
               CALL CSSCAL( N-KI+1, REMAX, VL( KI, IS ), 1 )
***
               OPST = OPST + ( 4*( N-KI+1 )+3 )
***
*
               DO 110 K = 1, KI - 1
                  VL( K, IS ) = CMZERO
  110          CONTINUE
            ELSE
               IF( KI.LT.N )
     $            CALL CGEMV( 'N', N, N-KI, CMONE, VL( 1, KI+1 ), LDVL,
     $                        WORK( KI+1 ), 1, CMPLX( SCALE ),
     $                        VL( 1, KI ), 1 )
*
               II = ICAMAX( N, VL( 1, KI ), 1 )
               REMAX = ONE / CABS1( VL( II, KI ) )
               CALL CSSCAL( N, REMAX, VL( 1, KI ), 1 )
***
               OPS = OPS + ( 8*N*( N-KI )+10*N+3 )
***
            END IF
*
*           Set back the original diagonal elements of T.
*
            DO 120 K = KI + 1, N
               T( K, K ) = WORK( K+N )
  120       CONTINUE
*
            IS = IS + 1
  130    CONTINUE
      END IF
***
*     Compute final op count
      OPS = OPS + OPST
***
*
      RETURN
*
*     End of CTREVC
*
      END