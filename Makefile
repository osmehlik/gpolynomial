
DC = dmd
PROG = gPolynomial

$(PROG): main.d plotter.d poly.d
	$(DC) -of$@ -D $^ `pkg-config --cflags --libs gtkd` -unittest -debug -Dddoc
clean:
	rm $(PROG) *.o

