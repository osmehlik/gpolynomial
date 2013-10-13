
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
import gdk.Event;
import gtk.FileChooserDialog;
import gtk.FileFilter;
import net.smehlik.types;
import net.smehlik.math.polynomial;
import net.smehlik.gui.plotter;
import std.stdio;
import std.conv;

// workaround for this bug in D optlink module:
// http://d.puremagic.com/issues/show_bug.cgi?id=3956
extern(C) export void dummy(){}

extern(C) export void onHelpAboutClicked(Event event, Widget widget)
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

extern(C) export void onOpenClicked(Widget *win)
{
    string[] options = new string[](2);
    GtkResponseType[] responses = new ResponseType[](2);

    options[0] = "Cancel";
    options[1] = "Open";
    responses[0] = GtkResponseType.CANCEL;
    responses[1] = GtkResponseType.OK;

    FileChooserDialog dialog = new FileChooserDialog(
        "Select input file",
        cast(Window)widgets.win,
        GtkFileChooserAction.OPEN,
        options,
        responses
    );

    FileFilter filter = new FileFilter();

    filter.setName("*.csv");
    filter.addPattern("*.csv");

    dialog.setSelectMultiple(false);
    dialog.addFilter(filter);

    GtkResponseType response = cast(GtkResponseType) dialog.run();

    if (response == ResponseType.OK) {
        widgets.polyPlot.importFromFile(dialog.getFilename());
    }
    dialog.hide();

}

extern(C) export void onSaveAsClicked(Widget *win)
{
    string[] options = new string[](2);
    GtkResponseType[] responses = new ResponseType[](2);

    options[0] = "Cancel";
    options[1] = "Save";
    responses[0] = GtkResponseType.CANCEL;
    responses[1] = GtkResponseType.OK;

    FileChooserDialog dialog = new FileChooserDialog(
        "Select output file",
        cast(Window)widgets.win,
        GtkFileChooserAction.SAVE,
        options,
        responses
    );

    FileFilter filter = new FileFilter();

    filter.setName("*.csv");
    filter.addPattern("*.csv");

    dialog.setSelectMultiple(false);
    dialog.addFilter(filter);   

    GtkResponseType response = cast(GtkResponseType) dialog.run();

    if (response == ResponseType.OK) {
        widgets.polyPlot.exportToFile(dialog.getFilename());
    }
    dialog.hide();
}

struct Widgets_t
{
    Widget win;
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

    widgets.win = win;
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

