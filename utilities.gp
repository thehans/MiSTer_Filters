
/*****************************
 General I/O Utility Functions
 ****************************/

\\ Create empty file.  (The only available write operation is to append to a file, so use this to make sure we start fresh)
newfile(filename) = system( Strprintf("echo -n '' > \"%s\"", filename) );

\\ Print vector as comma separated integers (evenly spaced for up to 3 digit nums, with optioonal negative sign)
printv(v) = {
  for(i=1, #v-1, printf("%4d,", v[i]) );
  printf("%4d\n", v[#v]);
};

\\ Write vector to file as **floats** (no newline). 
\\ For checking/debugging roundoff errors
write1_fv(filename, v) = {
  for(i=1, #v-1, write1(filename, Strprintf("%7.2f,", v[i]) ) );
  write1(filename, Strprintf("%7.2f", v[#v]) );
};

\\ Write vector to file as integers (no newline). 
\\ For checking/debugging roundoff errors
write1_iv(filename, v) = {
  for(i=1, #v-1, write1(filename, Strprintf("%4d,", v[i]) ) );
  write1(filename, Strprintf("%4d", v[#v]) );
};

\\ Write vector to file as integers (with newline).
\\ Pimary output function when generating filter coefficients.
write_iv(filename, v) = {
  write1_iv(filename, v);
  write1(filename, "\n");
};


/*******************************
 Interpolation Utility Functions
 *******************************/

\\ Mix values (or vectors) from x @ t=0 to y @ t=1 (Same as linear interpolate *if t is not otherwise transformed*)
mix(x,y,t) = (1-t)*x + t*y;

\\ Write T*P filter coefficients to file, using function f(x, y, t) to interpolate between x and y vectors.
\\   T is derived from length of x (should be 4, with y same length)
\\   "y" is theoretical "full step" (phase = P/P = 1) NOT included in output
\\   eg: print_filter([0,128,0,0],[0,0,128,0], mix)      -- basic linear interpolation
write_filter(filename, x, y, f, P=16) = for(p=0, P-1, write_iv(filename, round( f(x, y, p/P) ) ) );

\\ Same as write_filter but with added info to verify sum of each line, rounding issues etc.
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
};


\\ Create CSV file based on the provided function for charting in spreadheet or verifying equation correctness:
\\  - Generalized for any function f(X,Arg) 
\\  - "X" is the main variable input (default from [0,1] in 0.01 increments, for "*step" style of functions)
\\  - "Arg" represents some generic additional function argument used to compare multiple columns of data
\\      (eg. smooth_i for smoothstep function, or "k" for logistic function)
\\  - "Argname" should be a string used for labeling each column in CSV header row.

\\ First column of csv output is just X value, 
\\ Works well with LibreOffice, Chart Type: "XY (Scatter)" - "Lines only" 

create_csv(filename, f, Argname, Argmin, Argmax, Argstep, Xmin=0, Xmax=1, Xstep=0.01) = {
  newfile(filename);
  \\ Output header row
  write1(filename, "X,");
  forstep(Arg=Argmin, Argmax-Argstep, Argstep, write1(filename, Strprintf("%s=%d,", Argname, Arg)) );
  write1(filename, Strprintf("%s=%d\n", Argname, Argmax) );

  \\ Output function results
  forstep(X=Xmin, Xmax, Xstep,
    write1(filename, Strprintf("%14.12f, ", X) );
    forstep(Arg=Argmin, Argmax-Argstep, Argstep, write1(filename, Strprintf("%14.12f, ", f(X,Arg)) ); ); 
    write1(filename, Strprintf("%14.12f\n", f(X,Argmax)) );
  ); 
  printf("Generated file \"%s\"\n", filename);
};


