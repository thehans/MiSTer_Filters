read("utilities.gp");

\\ Another sigmoid function we can use instead of smoothstep is the "Logistic Function":
\\     https://en.wikipedia.org/wiki/Logistic_function

\\   k  is growth rate or steepness of curve
\\   x0 is the x value of the curve's midpoint
\\   L  is the maximum (asymptotic) value
logistic(x,k=12,L=1,x0=0.5) = L / (1 + exp(-k*(x-x0)));



\\ To use it as a step function, we would like for logistic(0, k) == 0 and logistic(1, k) == 1
\\ But the endpoints don't quite reach 0 or 1 (especially for small k), 
\\ so we can scale the oiutput to match. First calculate the actual value at x=1 :
\\     logistic(1,k)
\\   Shift this down by 1/2 so that we are centered vertically about y=0, 
\\   this way applying a scalar will scale the curve symmetrically:
\\     logistic(1,k) - 1/2
\\   We want to scale so that this shifted value at x=1 will equal 1/2,
\\   so our scale factor is:
\\     scale = (1/2) / (logistic(1,k) - 1/2)
\\   After scaling, we can add 1/2 back into the result to center about y=0.5 again.
\\     (value - 1/2)*scale + 1/2
logisticstep(x,k=12) = {
  my(
    val = logistic(x, k),
    scale = (1/2) / (logistic(1, k) - 1/2)
  );
  (val - 1/2)*scale + 1/2
};

\\ Filter generator, using logistic interpolation
make_logistic_filters(kmin=4, kmax=24, kstep=2, Amax=128, P=16) = {
  forstep(k=kmin, kmax, kstep,
    my(
      filename = Strprintf("Logistic_K%02d.txt", k),
      x = [0, Amax, 0, 0],
      y = [0, 0, Amax, 0],
      f(x, y, t) = mix(x, y, logisticstep(t, k))
    );
    newfile(filename);
    write(filename, Strprintf("# %d coefficient => 1x color value (identity output)", Amax));
    write(filename, "# No single term, nor sum of line should exceed 255!\n");
    write(filename, Strprintf("# Logistic function interpolation with k=%d", k));
    write(filename, "\n# horizontal coefficients");
    write_filter(filename, x, y, f, P);
    write(filename, "\n# vertical coefficients");
    write_filter(filename, x, y, f, P);
    printf("Wrote file: %s\n", filename);
  );
};


\\ Example CSV creation command:
\\ create_csv("logistic.csv", logisticstep, Argname="k", Argmin=6, Argmax=36, Argstep=6, Xmin=0, Xmax=1, Xstep=0.01);

