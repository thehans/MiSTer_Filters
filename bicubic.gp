\\ Standard bicubic filter (already exists in main MiSTer filter repo)

\\ Only implemented here to verify that I understand how its generated and that I get same results.

\\ Very nice explanation for reference: https://www.paulinternet.nl/?page=bicubic

\\ Example of formula, not used directly as code
\\ f(p0,p1,p2,p3,x) = (-1/2*p0  +3/2*p1  -3/2*p2  +1/2*p3)*x^3  + 
\\                    (   1*p0  -5/2*p1    +2*p2  -1/2*p3)*x^2  +
\\                    (-1/2*p0    +0     +1/2*p2    +0   )*x    +
\\                    (    0      +1*p1     +0      +0)

\\ Code to print out the coefficients
{
  my(
    Amax = 128,
    P = 16
  );
  forstep(x=0, (P-1)/P, 1/P, 
    my( 
      A = round(Amax*[
        -1/2*x^3  +1  *x^2  -1/2*x^1  +0*x^0,
        +3/2*x^3  -5/2*x^2  +0  *x^1  +1*x^0,
        -3/2*x^3  +2  *x^2  +1/2*x^1  +0*x^0,
        +1/2*x^3  -1/2*x^2  +0  *x^1  +0*x^0
      ])
    );
    printf("%4d,%4d,%4d,%4d\n", A[1], A[2], A[3], A[4]);
  );
}


/************************************************** 

Results:
   0, 128,   0,   0
  -4, 127,   5,   0
  -6, 123,  12,  -1
  -8, 118,  20,  -2
  -9, 111,  29,  -3
  -9, 103,  39,  -4
  -9,  93,  50,  -6
  -9,  83,  61,  -7
  -8,  72,  72,  -8
  -7,  61,  83,  -9
  -6,  50,  93,  -9
  -4,  39, 103,  -9
  -3,  29, 111,  -9
  -2,  20, 118,  -8
  -1,  12, 123,  -6
   0,   5, 127,  -4

Basically same* result as existing Bicubic Filter. YAY!!

*just an off-by-one rounding difference where a row sums to 129, pretty sure that was manually edited for MiSTer repo anyways.

**************************************************/

