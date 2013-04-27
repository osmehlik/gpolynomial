
DC = dmd
DFLAGS = `pkg-config --cflags --libs gtkd-2`
PROG = gPolynomial

$(PROG): main.d plotter.d poly.d
	$(DC) $(DFLAGS) -of$@ -D $^
clean:
	rm $(PROG) *.o

