\\ Miscellaneous functions that don't have their own file, not really used by other scripts (yet, anyways).


\\ cosine interpolation
\\   Just another example of possible interpolation function, 
\\   but probably not different enough from smoothstep (BiSmooth1.txt) to tell a difference
cos_terp(x,y,t) = my(a=1-(1+cos(Pi*t))/2); mix(x, y, a);


\\ The "Error function" https://en.wikipedia.org/wiki/Error_function
\\ Yet another "sigmoid function" which maybe useful for interpolation, 
\\ though again I'm not sure there would be any advantage or perceptable difference to try this in addition to smoothstep and logistic function based filters

\\ PARI has the "complementary error function": erfc(x) = 1 - erf(x), so define the "non-complementary" one:
erf(x) = 1-erfc(x);


