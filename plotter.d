
module net.smehlik.plotter;

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
import net.smehlik.poly;
import std.algorithm;
import std.math;
import std.stdio;

/**
 * Calculates distance between two points.
 * Params:
 *     p1 = the first point
 *     p2 = the second point
 * Returns:
 *     the distance between p1 and p2
 */
pure T dist(T = double)(ref Vec2D p1, ref Vec2D p2)
{
    T a = abs(p2.x - p1.x);
    T b = abs(p2.y - p1.y);

    return sqrt(a*a + b*b);
}

const double POINT_SELECTION_TOLERANCE = 8;
const int CELL_SIZE = 32;
const int AXIS_MARKER_SIZE = 8;


class Plot : DrawingArea
{
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
        
        self.getAllocation(a);
	Vec2D point = {
            x:    event.button.x - a.width / 2,
            y: - (event.button.y - a.height / 2)
	};

        if (event.button.button == 1) {
            for (uint i = 0; i < points.length; ++i) {
	        if (dist(point, points[i]) < POINT_SELECTION_TOLERANCE) {
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
            x:    event.motion.x - a.width / 2,
            y: - (event.motion.y - a.height / 2)
        };

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
            x:    event.button.x - a.width / 2,
            y: - (event.button.y - a.height / 2)
        };

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

    bool onExpose(Context context, Widget self)
    {
        GtkAllocation a;
        
        self.getAllocation(a);
        
            auto drawable = self.getWindow();

            const int WIDTH       = cast(int) a.width;
            const int HEIGHT      = cast(int) a.height;
            const int HALF_WIDTH  = WIDTH / 2;
	    const int HALF_HEIGHT = HEIGHT / 2;

            // draw white background
	    context.setLineWidth(1);
            context.setSourceRgb(1, 1, 1);
            context.rectangle(0, 0, WIDTH, HEIGHT);
	    context.fill();

            // set pen color to black
            context.setSourceRgb(0, 0, 0);

            // move to middle of screen
            context.translate(HALF_WIDTH, HALF_HEIGHT);
            // invert y axis
            context.scale(1, -1);

            const int xMax  = HALF_WIDTH / CELL_SIZE * CELL_SIZE;
            const int xMin  = -xMax;
            const int xStep = CELL_SIZE;
            const int yMax  = HALF_HEIGHT / CELL_SIZE * CELL_SIZE;
            const int yMin  = -yMax;
	    const int yStep = CELL_SIZE;

            for (int y = yMin; y < yMax; y += yStep) {

                // draw background grid line

                if (y == 0) context.setSourceRgb(0, 0, 0);
		else        context.setSourceRgb(0.95, 0.95, 0.95);

                context.moveTo(-HALF_WIDTH, y);
		context.lineTo(+HALF_WIDTH, y);
		context.stroke();

                // draw axis mark
                context.setSourceRgb(0, 0, 0);
		context.moveTo(-AXIS_MARKER_SIZE, y);
		context.lineTo(+AXIS_MARKER_SIZE, y);
		context.stroke();
            }

            for (int x = xMin; x < xMax; x += xStep) {

                // draw background grid line

                if (x == 0) context.setSourceRgb(0, 0, 0);
		else        context.setSourceRgb(0.9, 0.9, 0.9);

                context.moveTo(x, -HALF_HEIGHT);
		context.lineTo(x, +HALF_HEIGHT);
		context.stroke();

                // draw axis mark
                context.setSourceRgb(0, 0, 0);
		context.moveTo(x, -AXIS_MARKER_SIZE);
		context.lineTo(x, +AXIS_MARKER_SIZE);
		context.stroke();
            }

            const int ARROW_LENGTH = 16;
	    const int ARROW_WIDTH = 16;

            // up arrow
            context.moveTo(0, HALF_HEIGHT);
	    context.lineTo(ARROW_WIDTH / 2, HALF_HEIGHT - ARROW_LENGTH);
	    context.lineTo(- ARROW_WIDTH / 2, HALF_HEIGHT - ARROW_LENGTH);
	    context.lineTo(0, HALF_HEIGHT);
            context.fillPreserve();

            // right arrow
	    context.moveTo(HALF_WIDTH, 0);
	    context.lineTo(HALF_WIDTH - ARROW_LENGTH, - ARROW_WIDTH/2);
	    context.lineTo(HALF_WIDTH - ARROW_LENGTH,   ARROW_WIDTH/2);
	    context.lineTo(HALF_WIDTH, 0);
	    context.fillPreserve();

            const int POINT_TEXT_OFFSET = 12;

            // draw points
            foreach (Vec2D point; points) {
                context.moveTo(point.x - POINT_SELECTION_TOLERANCE, point.y);
                context.lineTo(point.x + POINT_SELECTION_TOLERANCE, point.y);
                context.moveTo(point.x, point.y - POINT_SELECTION_TOLERANCE);
                context.lineTo(point.x, point.y + POINT_SELECTION_TOLERANCE);

		context.selectFontFace("Sans",
		    cairo_font_slant_t.NORMAL,
		    cairo_font_weight_t.NORMAL);
		context.setFontSize(12);

                context.moveTo(point.x + POINT_TEXT_OFFSET, point.y -
		POINT_TEXT_OFFSET);
                context.scale(1, -1);
		string text = format("[%.2f,%.2f]", point.x, point.y);
		context.showText(text);
                context.scale(1, -1);
            }

            // draw curve

            double[] polynomial = polyInterpolate(points);

            for (double x = -HALF_WIDTH; x < HALF_WIDTH; ++x) {

                if (x == -HALF_WIDTH) {
                    context.moveTo(x, polyEval(polynomial, x));
                }
                else {
                    context.lineTo(x, polyEval(polynomial, x));
                }
            }

            context.stroke();

            return true;
    }
}

