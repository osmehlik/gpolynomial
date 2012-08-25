
import gtk.Main;
import gtk.VBox;
import gtk.Label;
import gtk.MainWindow;
import net.smehlik.poly;
import net.smehlik.plotter;

import std.stdio;
void main(string[] args)
{
    Main.init(args);

    MainWindow win = new MainWindow("gPolynomial");
    VBox vBox      = new VBox(false, 0);
    Label label    = new Label("Add some points, polynomial will be shown here.");
    Plot p         = new Plot(&label);

    win.setDefaultSize(640, 480);

    vBox.add(p);
    vBox.packStart(label, false, false, 4);
    win.add(vBox);

    win.showAll();

    Main.run();
}

