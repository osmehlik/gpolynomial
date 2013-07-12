
import gtk.Entry;
import gtk.AboutDialog;
import gtk.Widget;
import gtk.Builder;
import gtk.Widget;
import gtk.Window;
import gtk.Dialog;
import gtk.Main;
import gtk.VBox;
import gtk.Label;
import gtk.MainWindow;
import net.smehlik.types;
import net.smehlik.math.polynomial;
import net.smehlik.gui.plotter;
import std.stdio;
import std.conv;

extern(C) export void onAboutClicked(GtkMenuItem *item)
{
    int response = widgets.about.run();
    if ((response == GtkResponseType.DELETE_EVENT)
        || (response == GtkResponseType.CLOSE)
	|| (response == GtkResponseType.CANCEL)) {
        widgets.about.hide();
    }
}

extern(C) export void onPointAddClicked(GtkToolButton *btn)
{
    widgets.pointAdd.showAll();
    widgets.pointAddXEntry.setText("");
    widgets.pointAddYEntry.setText("");
}


extern(C) export void onZoomInClicked(GtkToolButton *btn)
{
    widgets.polyPlot.zoomBy(0.5);
}

extern(C) export void onZoomOutClicked(GtkToolButton *btn)
{
    widgets.polyPlot.zoomBy(2);
}

extern(C) export void onPointAddCancelButtonClicked(GtkButton *button)
{
    widgets.pointAdd.hide();
}

extern(C) export void onPointAddOkButtonClicked(GtkButton *button)
{
    string xText = widgets.pointAddXEntry.getText();
    string yText = widgets.pointAddYEntry.getText();

    double x, y;

    try {
        x = parse!double(xText);
        y = parse!double(yText);
    }
    catch {
	    // user entered nonsense, nothing to add
        return;
    }

    Vec2 point = { x: x, y: y };

    widgets.polyPlot.addPoint(point);

    widgets.pointAdd.hide();
}

struct Widgets_t
{
    AboutDialog about;
    Label polyLabel;
    Plot polyPlot;

    Dialog pointAdd;
    Entry pointAddXEntry;
    Entry pointAddYEntry;
};

Widgets_t widgets;

void main(string[] args)
{
    PlotArea defaultPlotArea = {
        xMin: -10,
        xMax: 10,
        yMin: -5,
        yMax: 5
    };

    PlotOptions defaultPlotOptions = {
        pointSelectionTolerance: 8,
        axisMarkerSize: 8,
        pointDescriptionOffset: 8
    };

    Main.init(args);

    Builder b = new Builder();

    if (!b.addFromFile("gui.glade")) {
        writeln("Cannot load gui.");
	    return;
    }

    Widget win = cast(Widget) b.getObject("window");
    VBox vBox = cast(VBox) b.getObject("vbox");

    widgets.polyLabel      = new Label("Add some points, polynomial will be shown here.");
    widgets.polyPlot       = new Plot(&widgets.polyLabel, defaultPlotArea, defaultPlotOptions);
    widgets.about          = cast(AboutDialog) b.getObject("about");
    widgets.pointAdd       = cast(Dialog) b.getObject("pointAddDialog");
    widgets.pointAddXEntry = cast(Entry) b.getObject("pointAddXEntry");
    widgets.pointAddYEntry = cast(Entry) b.getObject("pointAddYEntry");

    vBox.add(widgets.polyPlot);
    vBox.packStart(widgets.polyLabel, false, false, 4);

    b.connectSignals(null);

    win.showAll();

    Main.run();
}

