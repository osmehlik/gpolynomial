
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

struct PlotArea
{
    double xMin, xMax, yMin, yMax;

    bool isXAxisVisible() { return (yMin < 0) && (0 < yMax); }
    bool isYAxisVisible() { return (xMin < 0) && (0 < xMax); }
}

const double POINT_SELECTION_TOLERANCE = 8;
const int AXIS_MARKER_SIZE = 8;
const int POINT_TEXT_OFFSET = 8;

class Plot : DrawingArea
{
    PlotArea plotArea;
    Vec2D[] points;
    Label *polyLabel;

    bool isDragging = false;
    uint draggedPointIndex = 0;

    this(Label *polyLabel)
    {
        this.polyLabel = polyLabel;

        // connect signal handlers
        addOnDraw(&onExpose);
        addOnButtonPress(&onPress);
        addOnButtonRelease(&onRelease);
        addOnMotionNotify(&onMotionNotify);

        addEvents(GdkEventMask.BUTTON_PRESS_MASK);
        addEvents(GdkEventMask.POINTER_MOTION_MASK);

        // TODO: replace with better defaults assignment
        plotArea.xMin = -10;
        plotArea.xMax =  10;
        plotArea.yMin =  -5;
        plotArea.yMax =   5;
    }

    void addPoint(Vec2D point)
    {
        points ~= point;
        double[] polynomial = polyInterpolate(points);
        polyLabel.setMarkup(polyPrint(polynomial));
        queueDraw();
    }

    bool onPress(Event event, Widget self)
    {
        GtkAllocation a;
        
        Vec2D point = {
            x:    event.button.x,
            y:    event.button.y
        };

        if (event.button.button == 1) {
            for (uint i = 0; i < points.length; ++i) {
                Vec2D v = coordsValueToScreen(points[i]);
                if (dist(point, v) < POINT_SELECTION_TOLERANCE) {
                    isDragging = true;
                    draggedPointIndex = i;
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
        
        Vec2D point = {
            x:    event.button.x,
            y:    event.button.y
        };

        point = coordsScreenToValue(point);

        if (isDragging) {
            points[draggedPointIndex] = point;
            double[] polynomial = polyInterpolate(points);
            polyLabel.setMarkup(polyPrint(polynomial));
            queueDraw();
        }

        return true;
    }
    
    bool onRelease(Event event, Widget self)
    {
        GtkAllocation a;
        
        self.getAllocation(a);
        
        Vec2D point = {
            x:    event.button.x,
            y:    event.button.y
        };

        point = coordsScreenToValue(point);

        // if we are dragging, stop dragging
        if (isDragging) {
            isDragging = false;
        }
        else {

            // which button was released?
            switch (event.button.button) {
                // left button was released
                case 1:
                   points ~= point;
                break;
                // right button was released
                case 3:
                    // remove any points under right button
                    for (uint i = 0; i < points.length; ++i) {
                        if (dist(point, points[i]) < POINT_SELECTION_TOLERANCE) {
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

    void drawPoint(Context context, Vec2D point, Vec2D value)
    {
        // draw cross
        context.moveTo(point.x - POINT_SELECTION_TOLERANCE, point.y);
        context.lineTo(point.x + POINT_SELECTION_TOLERANCE, point.y);
        context.moveTo(point.x, point.y - POINT_SELECTION_TOLERANCE);
        context.lineTo(point.x, point.y + POINT_SELECTION_TOLERANCE);
        
        // draw description
        context.selectFontFace("Sans", cairo_font_slant_t.NORMAL, cairo_font_weight_t.NORMAL);
        context.setFontSize(12);
        context.moveTo(point.x + POINT_TEXT_OFFSET, point.y + POINT_TEXT_OFFSET);
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
                context.moveTo(yAxisX - AXIS_MARKER_SIZE, yScreen);
                context.lineTo(yAxisX + AXIS_MARKER_SIZE, yScreen);
                context.stroke();
            }
 
            // draw axis arrow
            context.setSourceRgb(0, 0, 0);
            context.moveTo(yAxisX, 0);
            context.lineTo(yAxisX - AXIS_MARKER_SIZE, 2 * AXIS_MARKER_SIZE);
            context.lineTo(yAxisX + AXIS_MARKER_SIZE, 2 * AXIS_MARKER_SIZE);
            context.fill();
        }
    
        if (plotArea.isXAxisVisible()) {
            // find x axis position
            double xAxisY = mapRange(plotArea.yMin, 0.0, plotArea.yMax, 0.0, HEIGHT);
            
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
                context.moveTo(xScreen, xAxisY - AXIS_MARKER_SIZE);
                context.lineTo(xScreen, xAxisY + AXIS_MARKER_SIZE);
                context.stroke();
            }

            // draw axis arrow
            context.setSourceRgb(0, 0, 0);
            context.moveTo(WIDTH, xAxisY);
            context.lineTo(WIDTH - 2 * AXIS_MARKER_SIZE, xAxisY - AXIS_MARKER_SIZE);
            context.lineTo(WIDTH - 2 * AXIS_MARKER_SIZE, xAxisY + AXIS_MARKER_SIZE);
            context.fill();
        }

        // draw points
        foreach (Vec2D point; points) {                
            // skip invisible points
            if (point.x < plotArea.xMin
                || point.x > plotArea.xMax 
                || point.y < plotArea.yMin
                || point.y > plotArea.yMax) {
                continue;
            }
                
            Vec2D screen = coordsValueToScreen(point);
                
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

    Vec2D coordsValueToScreen(Vec2D value)
    {
        Vec2D result;

        result.x = mapRange(plotArea.xMin, value.x, plotArea.xMax, 0.0, getWidgetWidth());
        result.y = mapRange(plotArea.yMin, value.y, plotArea.yMax, getWidgetHeight(), 0.0);

        return result;
    }
    
    Vec2D coordsScreenToValue(Vec2D screen)
    {
        Vec2D result;
        
        result.x = mapRange(0.0, screen.x, getWidgetWidth(), plotArea.xMin, plotArea.xMax);
        result.y = mapRange(0.0, screen.y, getWidgetHeight(), plotArea.yMax, plotArea.yMin);
        
        return result;
    }
}
