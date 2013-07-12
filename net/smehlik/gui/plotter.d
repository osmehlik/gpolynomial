
module net.smehlik.gui.plotter;

import cairo.Context;
import std.string;
import gdk.Color;
import gtkc.cairotypes;
import gtkc.gdktypes;
import gtk.DragAndDrop;
import gtk.DrawingArea;
import gtk.Label;
import gtk.Widget;
import gtk.Window;
private import gdk.Event;
import net.smehlik.types;
import net.smehlik.math.polynomial;
import net.smehlik.math.percentage;
import net.smehlik.math.geometry;
import std.algorithm;
import std.math;
import std.datetime;

struct PlotArea
{
    double xMin, xMax, yMin, yMax;

    bool isXAxisVisible() { return (yMin < 0) && (0 < yMax); }
    bool isYAxisVisible() { return (xMin < 0) && (0 < xMax); }
}

struct PlotOptions
{
    // maximal distance of click from point location considered as selecting point
    int pointSelectionTolerance;
    int axisMarkerSize;
    // offset between point and its description in both X and Y axis
    int pointDescriptionOffset;
}

enum DraggedObject { POINT, VIEW };

struct DragData
{
    bool mouseWasPressed = false;
    Vec2 mousePressPosition;
    PlotArea mousePressPlotArea;
    SysTime mousePressTime;
    bool isDragging = false;
    DraggedObject draggedObject;
    uint draggedObjectIndex = 0;
}

class Plot : DrawingArea
{
    PlotArea plotArea;
    PlotOptions plotOptions;
    Vec2[] points;
    Label *polyLabel;
    DragData dragData;


    this(Label *polyLabel, PlotArea plotArea, PlotOptions plotOptions)
    {
        this.polyLabel = polyLabel;

        // connect signal handlers
        addOnDraw(&onExpose);
        addOnButtonPress(&onPress);
        addOnButtonRelease(&onRelease);
        addOnMotionNotify(&onMotionNotify);

        addEvents(GdkEventMask.BUTTON_PRESS_MASK);
        addEvents(GdkEventMask.POINTER_MOTION_MASK);

        this.plotArea = plotArea;
        this.plotOptions = plotOptions;
    }

    void addPoint(Vec2 point)
    {
        points ~= point;
        double[] polynomial = polyInterpolate(points);
        polyLabel.setMarkup(polyPrint(polynomial));
        queueDraw();
    }

    bool onPress(Event event, Widget self)
    {
        GtkAllocation a;
        
        Vec2 pointScreen = {
            x: event.button.x,
            y: event.button.y
        };

        if (event.button.button == 1) {

            dragData.mouseWasPressed = true;
            dragData.mousePressPosition = pointScreen;
            dragData.mousePressPlotArea = plotArea;
            dragData.mousePressTime = Clock.currTime();
            dragData.draggedObject = DraggedObject.VIEW;
          
            for (uint i = 0; i < points.length; ++i) {
                Vec2 v = coordsValueToScreen(points[i]);
                if (dist(pointScreen, v) < plotOptions.pointSelectionTolerance) {
                    dragData.isDragging = true;
                    dragData.draggedObject = DraggedObject.POINT;
                    dragData.draggedObjectIndex = i;
                    return true;
                }
            }
        }

        return true;
    }

    bool onMotionNotify(Event event, Widget self)
    {
        GtkAllocation a;
        
        self.getAllocation(a);
        
        Vec2 pointScreen = {
            x: event.button.x,
            y: event.button.y
        };

        Vec2 pointValue = coordsScreenToValue(pointScreen);

        if (dragData.mouseWasPressed) {
            SysTime currentTime = Clock.currTime();
            Duration elapsedTime = currentTime - dragData.mousePressTime;
            Duration trigger = dur!"msecs"(200);

            if ((elapsedTime > trigger) && (!dragData.isDragging)) {
                dragData.isDragging = true;
                dragData.draggedObject = DraggedObject.VIEW;
            }
        }
        
        if (dragData.isDragging) {
            if (dragData.draggedObject == DraggedObject.POINT) {
                points[dragData.draggedObjectIndex] = pointValue;
                double[] polynomial = polyInterpolate(points);
                polyLabel.setMarkup(polyPrint(polynomial));
            }
            else {
                Vec2 pointScreenDelta = pointScreen - dragData.mousePressPosition;

                Vec2 pointValueDelta = {
                    x: mapRange(0.0, pointScreenDelta.x, getWidgetWidth(), 0.0, plotArea.xMax - plotArea.xMin),
                    y: mapRange(0.0, pointScreenDelta.y, getWidgetHeight(), 0.0, plotArea.yMax - plotArea.yMin)
                };

                plotArea.xMin = dragData.mousePressPlotArea.xMin - pointValueDelta.x;
                plotArea.xMax = dragData.mousePressPlotArea.xMax - pointValueDelta.x;
                plotArea.yMin = dragData.mousePressPlotArea.yMin + pointValueDelta.y;
                plotArea.yMax = dragData.mousePressPlotArea.yMax + pointValueDelta.y;


            }
            queueDraw();
        }

        return true;
    }
    
    bool onRelease(Event event, Widget self)
    {
        GtkAllocation a;
        
        self.getAllocation(a);
        
        Vec2 pointScreen = {
            x: event.button.x,
            y: event.button.y
        };

        Vec2 pointValue = coordsScreenToValue(pointScreen);

        dragData.mouseWasPressed = false;
        // if we are dragging, stop dragging
        if (dragData.isDragging) {
            dragData.isDragging = false;
        }
        else {

            // which button was released?
            switch (event.button.button) {
                // left button was released
                case 1:
                   points ~= pointValue;
                break;
                // right button was released
                case 3:
                    // remove any points under right button
                    for (uint i = 0; i < points.length; ++i) {
		        Vec2 iPointScreen = coordsValueToScreen(points[i]);
                        if (dist(pointScreen, iPointScreen) < plotOptions.pointSelectionTolerance) {
                            remove(points, i);
                            points.length = points.length -1;
                            break;
                        }
                }
                break;
                default:
                break;
            }
        }

        double[] polynomial = polyInterpolate(points);
        polyLabel.setMarkup(polyPrint(polynomial));
        queueDraw();

        return true;
    }

    void drawPoint(Context context, Vec2 point, Vec2 value)
    {
        // draw cross
        context.moveTo(point.x - plotOptions.pointSelectionTolerance, point.y);
        context.lineTo(point.x + plotOptions.pointSelectionTolerance, point.y);
        context.moveTo(point.x, point.y - plotOptions.pointSelectionTolerance);
        context.lineTo(point.x, point.y + plotOptions.pointSelectionTolerance);
        
        // draw description
        context.selectFontFace("Sans", cairo_font_slant_t.NORMAL, cairo_font_weight_t.NORMAL);
        context.setFontSize(12);
        context.moveTo(point.x + plotOptions.pointDescriptionOffset, point.y + plotOptions.pointDescriptionOffset);
        string text = format("[%.2f,%.2f]", value.x, value.y);
        context.showText(text); 
    }
    
    bool onExpose(Context context, Widget self)
    {
        // redraw viewport

        // find out canvas size
    
        GtkAllocation a;
        
        self.getAllocation(a);
        
        auto drawable = self.getWindow();
    
        double WIDTH  = cast(double) a.width;
        double HEIGHT = cast(double) a.height;    
    
        // draw white background
        context.setLineWidth(1);
        context.setSourceRgb(1, 1, 1);
        context.rectangle(0, 0, WIDTH, HEIGHT);
        context.fill();

        // set pen color to black
        context.setSourceRgb(0, 0, 0);

        if (plotArea.isYAxisVisible()) {
            // find y axis position
            double yAxisX = mapRange(plotArea.xMin, 0.0, plotArea.xMax, 0.0, WIDTH);

            context.moveTo(yAxisX, 0); 
            context.lineTo(yAxisX, HEIGHT);
            context.stroke();

            for (double y = plotArea.yMin + 1; y <= plotArea.yMax - 1; y += 1) {

                if (y == 0) continue;

                double yScreen = mapRange(plotArea.yMin, y, plotArea.yMax, 0.0, HEIGHT);

                // draw axis line
                context.setSourceRgb(0.95, 0.95, 0.95);
                context.moveTo(0, yScreen);
                context.lineTo(WIDTH, yScreen);
                context.stroke();		

                // draw axis mark
                context.setSourceRgb(0, 0, 0);
                context.moveTo(yAxisX - plotOptions.axisMarkerSize, yScreen);
                context.lineTo(yAxisX + plotOptions.axisMarkerSize, yScreen);
                context.stroke();
            }
 
            // draw axis arrow
            context.setSourceRgb(0, 0, 0);
            context.moveTo(yAxisX, 0);
            context.lineTo(yAxisX - plotOptions.axisMarkerSize, 2 * plotOptions.axisMarkerSize);
            context.lineTo(yAxisX + plotOptions.axisMarkerSize, 2 * plotOptions.axisMarkerSize);
            context.fill();
        }
    
        if (plotArea.isXAxisVisible()) {
            // find x axis position
            double xAxisY = mapRange(plotArea.yMin, 0.0, plotArea.yMax, HEIGHT, 0.0);
            
            context.moveTo(0, xAxisY);
            context.lineTo(WIDTH, xAxisY);
            context.stroke();

            for (double x = plotArea.xMin + 1; x <= plotArea.xMax - 1; x += 1) {
                double xScreen = mapRange(plotArea.xMin, x, plotArea.xMax, 0.0, WIDTH);

                if (x == 0) continue;

                // draw axis line
                context.setSourceRgb(0.95, 0.95, 0.95);
                context.moveTo(xScreen, 0);
                context.lineTo(xScreen, HEIGHT);
                context.stroke();		

                // draw axis mark
                context.setSourceRgb(0, 0, 0);
                context.moveTo(xScreen, xAxisY - plotOptions.axisMarkerSize);
                context.lineTo(xScreen, xAxisY + plotOptions.axisMarkerSize);
                context.stroke();
            }

            // draw axis arrow
            context.setSourceRgb(0, 0, 0);
            context.moveTo(WIDTH, xAxisY);
            context.lineTo(WIDTH - 2 * plotOptions.axisMarkerSize, xAxisY - plotOptions.axisMarkerSize);
            context.lineTo(WIDTH - 2 * plotOptions.axisMarkerSize, xAxisY + plotOptions.axisMarkerSize);
            context.fill();
        }

        // draw points
        foreach (Vec2 point; points) {                
            // skip invisible points
            if (point.x < plotArea.xMin
                || point.x > plotArea.xMax 
                || point.y < plotArea.yMin
                || point.y > plotArea.yMax) {
                continue;
            }
                
            Vec2 screen = coordsValueToScreen(point);
                
            drawPoint(context, screen, point);
        }

        // draw curve
        double[] polynomial = polyInterpolate(points);
        for (double xScreen = 0; xScreen < WIDTH; ++xScreen) {
            double xValue = mapRange(0.0, xScreen, WIDTH, plotArea.xMin, plotArea.xMax);
            double yValue = polyEval(polynomial, xValue);
            double yScreen = mapRange(plotArea.yMin, yValue, plotArea.yMax, HEIGHT, 0.0);
    
            if (xScreen == 0) {
                context.moveTo(xScreen, yScreen);
            }
            else {
                context.lineTo(xScreen, yScreen);
            }
        }
        context.stroke();

        return true;
    }
    
    void zoomBy(double factor)
    {
        double width = plotArea.xMax - plotArea.xMin;
        double height = plotArea.yMax - plotArea.yMin;
        double xCenter = (plotArea.xMin + plotArea.xMax) / 2;
        double yCenter = (plotArea.yMin + plotArea.yMax) / 2;

        width *= factor;
        height *= factor;

        plotArea.xMin = xCenter - width/2;
        plotArea.xMax = xCenter + width/2;
        plotArea.yMin = yCenter - height/2;
        plotArea.yMax = yCenter + height/2;

        queueDraw();
    }
    
    // TODO: find out if this can be removed in favor of Gtk.widget.width
    double getWidgetWidth() {
        GtkAllocation a;
        
        getAllocation(a);
        
        return cast(double) a.width;
    }

    // TODO: find out if this can be removed in favor of Gtk.widget.height
    double getWidgetHeight() {
        GtkAllocation a;
        
        getAllocation(a);
        
        return cast(double) a.height;
    }   
    
    Vec2 coordsValueToScreen(Vec2 value)
    {
        Vec2 result;

        result.x = mapRange(plotArea.xMin, value.x, plotArea.xMax, 0.0, getWidgetWidth());
        result.y = mapRange(plotArea.yMin, value.y, plotArea.yMax, getWidgetHeight(), 0.0);

        return result;
    }
    
    Vec2 coordsScreenToValue(Vec2 screen)
    {
        Vec2 result;
        
        result.x = mapRange(0.0, screen.x, getWidgetWidth(), plotArea.xMin, plotArea.xMax);
        result.y = mapRange(0.0, screen.y, getWidgetHeight(), plotArea.yMax, plotArea.yMin);
        
        return result;
    }
}
