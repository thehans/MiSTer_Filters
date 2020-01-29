\\ PARI/GP utilities for generating polyphase filter coefficients
\\   For use with MiSTer FPGA retro gaming/computing platform


\\ ****************************
\\ General I/O Utility Functions
\\ ****************************

\\ Create empty file.  (The only available write operation is to append to a file, so use this to make sure we start fresh)
newfile(filename) = system( Strprintf("echo -n '' > \"%s\"", filename) );

\\ Print vector as comma separated integers (evenly spaced for up to 3 digit nums, with optioonal negative sign)
printv(v) = {
  for(i=1, #v-1, printf("%4d,", v[i]) );
  printf("%4d\n", v[#v]);
}

\\ Write vector to file as **floats** (no newline). 
\\ For checking/debugging roundoff errors
write1_fv(filename, v) = {
  for(i=1, #v-1, write1(filename, Strprintf("%7.2f,", v[i]) ) );
  write1(filename, Strprintf("%7.2f", v[#v]) );
}

\\ Write vector to file as integers (no newline). 
\\ For checking/debugging roundoff errors
write1_iv(filename, v) = {
  for(i=1, #v-1, write1(filename, Strprintf("%4d,", v[i]) ) );
  write1(filename, Strprintf("%4d", v[#v]) );
}

\\ Write vector to file as integers (with newline).
\\ Pimary output function when generating filter coefficients.
write_iv(filename, v) = {
  write1_iv(filename, v);
  write1(filename, "\n");
}



\\ *******************************
\\ Interpolation Utility Functions
\\ *******************************


\\ Mix values (or vectors) from x @ t=0 to y @ t=1 (Same as linear interpolate *if t is not otherwise transformed*)
mix(x,y,t) = (1-t)*x + t*y

\\ cosine interpolation
cos_terp(x,y,t) = my(a=1-(1+cos(Pi*t))/2); mix(x, y, a);

\\ generalized smoothstep up to 13th order polynomial ( i=6, polynomial order is always odd, 2*i+1 )
\\   i=-1 shortcut for normal step, NN style
\\   i=0 is plain linear interpolation
\\   i=1 is canonical "smoothstep", very close to "cosine interpolation"
\\   i=2 is "smootherstep", etc.
\\   see: https://en.wikipedia.org/wiki/Smoothstep#Generalization_to_higher-order_equations
smoothstep(x,i=1) = {
  if(i==-1, 
    \\ for "S-1" just "step" like nearest neighbor
    if(x<0.5, 0, 1)
  ,
    my(
      terms = i+1,
      \\ coeffs in order of ascending exponent for convenience,
      \\ when used with sum operation
      coeffs = [
         [  1 ],
         [  3,      -2 ], 
         [  10,    -15,     6 ], 
         [  35,    -84,    70,    -20 ], 
         [  126,  -420,   540,   -315,    70 ],
         [  462, -1980,  3465,  -3080,  1386,  -252 ],
         [ 1716, -9009, 20020, -24024, 16380, -6006, 924 ]
       ][terms]
    );
    sum(e=terms,terms+i, coeffs[e-i]*x^e)
  );
}

\\ Apply smoothstep to mix between x and y
smooth_terp(x, y, t, smooth_i=1) = mix(x, y, smoothstep(t, smooth_i) );


\\ Example for verification of smoothstep correctness, print CSV for all smoothstep polynomials and (manually) chart them in a spreadsheet:
/*
{
  my(filename = "smoothstep.csv");
  newfile(filename);
  forstep(x=0, 1, 0.01,
    for(i=0, 5, write1(filename, Strprintf("%14.12f, ", smoothstep(x,i)) ); ); 
    write1(filename, Strprintf("%14.12f\n", smoothstep(x,6)) );
  ); 
}
*/


\\ Write TxP filter coefficients to file, using function f to interpolate between x and y vectors.
\\   T is derived from length of x (should be 4, with y same length)
\\   "y" is theoretical "full step" (phase = P/P = 1) NOT included in output
\\   eg: print_filter([0,128,0,0],[0,0,128,0], mix)      -- basic linear interpolation
write_filter(filename, x, y, f, P=16) = for(p=0, P-1, write_iv(filename, round( f(x, y, p/P) ) ) );


write_filter_dbg(filename, x, y, f, P=16) = {
  for(p=0, P-1, 
    my(
      T = #x,
      A = f(x,y,p/P), 
      a = round(A)
    ); 
    write1_iv(filename, a);
    write1(filename, Strprintf(" # = %4d\t\t", sum(i=1, T, a[i]) ) );
    write1_fv(filename, A);
    write1(filename, Strprintf(" => %7.2f\n", sum(i=1, T, A[i]) ) );
  );
}


\\ "Bi-smooth" filter generator, using smoothstep interpolation
make_bismooth_filters(Amax=128, P=16) = {
  for(smooth_i=-1, 6,
    my(
      filename = if(smooth_i == -1,
        "Nearest Neighbor(for comparison).txt",
        if(smooth_i == 0,
          Strprintf("BiSmooth%d (bilinear).txt", smooth_i),
          Strprintf("BiSmooth%d.txt", smooth_i)
        )          
      ),
      x = [0, Amax, 0, 0],
      y = [0, 0, Amax, 0],
      f(x, y, t) = smooth_terp(x, y, t, smooth_i)
    );
    newfile(filename);
    write(filename, Strprintf("# %d coefficient => 1x color value (identity output)", Amax));
    write(filename, "# No single term, nor sum of line should exceed 255!\n");
    write(filename, Strprintf("# Bi-smooth interpolation with i=%d (%dth order polynomial)", smooth_i, smooth_i*2+1));
    write(filename, "\n# horizontal coefficients");
    write_filter(filename, x, y, f, P);
    write(filename, "\n# vertical coefficients");
    write_filter(filename, x, y, f, P);
  );
}

\\ "Edge Detect" filter generator, using smoothstep interpolation
\\    Highlights outlines, similar to convolution kernels that approximate Laplace transform
\\    Acts somewhat like a sharpening filter at low levels: E<=32
\\    Or just spaced-out weirdo effects for high E values, (highest E only possible at reduced brightness)

\\    B is additive brightness, since pure edge filter would be zero-sum(on average).  
\\      - B128 is normal brightness
\\    E is the edge factor, 128 being 100% edge (extremely funky looking)
\\    S is the number of smoothstep polynomial used to interpolate
make_edge_filters(smooth_i=1, emin=8, emax=128, estep=8, bmin=0, bmax=128, bstep=8, Amax=128, P=16) = {
  forstep(e=emin, emax, estep,
    forstep(b=bmin, bmax, bstep,
      my(
        epct = 100*e/Amax,
        bpct = 100*b/Amax,
        B0 = b+2*e,
        B = if(B0==256, 255, B0), \\ clamp 256 to 255 to avoid overflow. if > 256 this combo will be skipped
        x = [-e, B, -e, 0],
        y = [0, -e, B, -e],
        filename = if(smooth_i == -1,
          Strprintf("Edge_B%03d_E%03d_NN.txt", b, e),
          if(smooth_i == 0,
            Strprintf("Edge_B%03d_E%03d_S%d (bilinear).txt", b, e, smooth_i),
            Strprintf("Edge_B%03d_E%03d_S%d.txt", b, e, smooth_i)
          )
        ),
        f(x,y,t) = mix(x, y, smoothstep(t, smooth_i) )
      );
      if (B >= Amax && B <= 255,
        newfile(filename);
        write(filename, Strprintf("# %d coefficient => 1x color value (identity output)", Amax));
        write(filename, "# No single term, nor sum of line should exceed 255!\n");
        if(smooth_i == -1,
          write(filename, Strprintf("# Edge detect (%5.2f%% Edge + %5.2f%% Brightness, Nearest Neighbor)", epct, bpct)),
          if(smooth_i == 0, 
            write(filename, Strprintf("# Edge detect (%5.2f%% Edge + %5.2f%% Brightness, Bilinear interpolated)", epct, bpct)),
            write(filename, Strprintf("# Edge detect (%5.2f%% Edge + %5.2f%% Brightness, Smoothstep_%d interpolated)", epct, bpct, smooth_i))
          )
        );
        write(filename, "\n# horizontal coefficients");
        write_filter(filename, x, y, f, P);
        write(filename, "\n# vertical coefficients"); 
        write_filter(filename, x, y, f, P);
      );
    );
  );
}


/************************************************** 


\\ Cubic interpolation function: https://www.paulinternet.nl/?page=bicubic

\\ example formula, not used as code
\\ f(p0,p1,p2,p3,x) = (-1/2*p0  +3/2*p1  -3/2*p2  +1/2*p3)*x^3  + 
\\                    (   1*p0  -5/2*p1    +2*p2  -1/2*p3)*x^2  +
\\                    (-1/2*p0    +0     +1/2*p2    +0   )*x    +
\\                    (    0      +1*p1     +0      +0)

\\ set precision to 7 digits for easier reading:
\p7

\\ Code to print out the coefficients
{
  my(P = 16);
  forstep(x=0, 1, 1/P, 
    my( 
      expr = ( -1/2 * p0  +3/2 * p1  -3/2 * p2  +1/2 * p3) * x^3  + 
             ( +1   * p0  -5/2 * p1  +2   * p2  -1/2 * p3) * x^2  +
             ( -1/2 * p0  +0   * p1  +1/2 * p2  +0   * p3) * x^1  +
             ( +0   * p0  +1   * p1  +0   * p2  +0   * p3) * x^0
    );
    print(128.0*expr);
  );
}

\\ Formatted results:
00                 128.0000*p1
01 -3.515625*p0 + (126.7969*p1 + (4.953125*p2 - 0.234375*p3))
02 -6.125000*p0 + (123.3750*p1 + (11.62500*p2 - 0.875000*p3))
03 -7.921875*p0 + (118.0156*p1 + (19.73438*p2 - 1.828125*p3))
04 -9.000000*p0 + (111.0000*p1 + (29.00000*p2 - 3.000000*p3))
05 -9.453125*p0 + (102.6094*p1 + (39.14063*p2 - 4.296875*p3))
06 -9.375000*p0 + (93.12500*p1 + (49.87500*p2 - 5.625000*p3))
07 -8.859375*p0 + (82.82813*p1 + (60.92188*p2 - 6.890625*p3))
08 -8.000000*p0 + (72.00000*p1 + (72.00000*p2 - 8.000000*p3))
09 -6.890625*p0 + (60.92188*p1 + (82.82813*p2 - 8.859375*p3))
10 -5.625000*p0 + (49.87500*p1 + (93.12500*p2 - 9.375000*p3))
11 -4.296875*p0 + (39.14063*p1 + (102.6094*p2 - 9.453125*p3))
12 -3.000000*p0 + (29.00000*p1 + (111.0000*p2 - 9.000000*p3))
13 -1.828125*p0 + (19.73438*p1 + (118.0156*p2 - 7.921875*p3))
14 -0.875000*p0 + (11.62500*p1 + (123.3750*p2 - 6.125000*p3))
15 -0.234375*p0 + (4.953125*p1 + (126.7969*p2 - 3.515625*p3))
16                                128.0000*p2

Basically same result as existing Bicubic Filter. YAY!!
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

   0,   0, 128,   0  (extra output)

***************************/




