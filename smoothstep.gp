read("utilities.gp")

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
};

\\ Apply smoothstep to mix between x and y
smooth_terp(x, y, t, smooth_i=1) = mix(x, y, smoothstep(t, smooth_i) );


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
    printf("Wrote file: %s\n", filename);
  );
};

\\ Example CSV creation command:
\\ create_csv("smoothstep.csv", smoothstep, Argname="S", Argmin=0, Argmax=6, Argstep=1, Xmin=0, Xmax=1, Xstep=0.01);


