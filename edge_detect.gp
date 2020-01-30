read("smoothstep.gp")

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
        B = if(B0==256, 255, B0), \\ clamp 256 to 255 to avoid overflow. if > 256 this combo will be skipped in the main loop body
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
      \\ Don't write filters for B<Amax (too dark) or B > 255 (will cause overflow artifacts, black grid lines in output)
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
        printf("Wrote file: %s\n", filename);
      );
    );
  );
};

