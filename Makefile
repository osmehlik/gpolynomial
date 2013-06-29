
PROG = gPolynomial
SOURCES = \
  main.d \
  net/smehlik/math/polynomial.d \
  net/smehlik/types.d \
  net/smehlik/math/percentage.d \
  net/smehlik/gui/plotter.d \
  net/smehlik/math/geometry.d

DC = dmd
DFLAGS = `pkg-config --cflags --libs gtkd-2`

$(PROG): $(SOURCES)
	$(DC) $(DFLAGS) -of$@ $^ -unittest
clean:
	rm $(PROG) *.o
