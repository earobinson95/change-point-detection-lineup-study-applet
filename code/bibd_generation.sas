
/*Finding out the number of blocks to create a balanced incomplete block design.*/
%mktbsize(t=36, k=12, b=20 to 1000)
/**/
%mktbibd(t=36, k=12, b=105)


/* the design implementation is in bibd dataset*/
proc print data=bibd;
run;
