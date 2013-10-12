
PROG = gPolynomial
SOURCES = \
  main.d \
  net/smehlik/math/polynomial.d \
  net/smehlik/types.d \
  net/smehlik/math/percentage.d \
  net/smehlik/gui/plotter.d \
  net/smehlik/math/geometry.d

DC = dmd

ifdef WIN
DFLAGS =
DLIBS = -L+gtkd.lib -L/SUBSYSTEM:WINDOWS
else
DFLAGS = `pkg-config --cflags gtkd-2`
DLIBS = `pkg-config --libs gtkd-2`
endif

$(PROG): $(SOURCES)
	$(DC) $(DFLAGS) -of$@ $^ $(DLIBS)
clean:
	rm $(PROG) *.o
wininst: $(PROG)
	"C:\Program Files (x86)\Inno Setup 5\ISCC.exe" platforms/win/installer.iss

