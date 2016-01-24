/*
 * Copyright (c) 2009-2011 Madhav Vaidyanathan
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License version 2.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 */


/* @class RestSymbol
 * A Rest symbol represents a rest - whole, half, quarter, or eighth.
 * The Rest symbol has a starttime and a duration, just like a regular
 * note.
 */
#import "RestSymbol.h"

@implementation RestSymbol

/** Create a new rest symbol with the given start time and duration */
- (id)initWithTime:(int)t andDuration:(int)dur {
    starttime = t;
    duration = dur;
    width = self.minWidth;
    return self;
}

/** Get the time (in pulses) this symbol occurs at.
 * This is used to determine the measure this symbol belongs to.
 */
- (int)startTime {
    return starttime;
}

/** Get the width (in pixels) of this symbol. The width is set
 * in SheetMusic:alignSymbols to vertically align symbols.
 */
- (int)width {
    return width;
}

/** Set the width (in pixels) of this symbol. The width is set
 * in SheetMusic:alignSymbols to vertically align symbols.
 */
- (void)setWidth:(int)w {
    width = w;
}

/** Get the minimum width (in pixels) needed to draw this symbol */
- (int)minWidth {
    return 2 * NoteHeight + NoteHeight/2;
}

/** Get the number of pixels this symbol extends above the staff. Used
 *  to determine the minimum height needed for the staff (Staff:findBounds).
 */
- (int)aboveStaff {
    return 0;
}

/** Get the number of pixels this symbol extends below the staff. Used
 *  to determine the minimum height needed for the staff (Staff:findBounds).
 */
- (int)belowStaff {
    return 0;
}

/** Draw the symbol.
 * @param ytop The ylocation (in pixels) where the top of the staff starts.
 */
- (void)draw:(int)ytop {
    NSAffineTransform *trans;

    /* Align the rest symbol to the right */
    trans = [NSAffineTransform transform];
    [trans translateXBy:(width - self.minWidth) yBy:0.0];
    [trans concat];
    trans = [NSAffineTransform transform];
    [trans translateXBy:NoteHeight/2 yBy:0.0];
    [trans concat];

    [[NSColor blackColor] setFill];

    if (duration == Whole) {
        [self drawWhole:ytop];
    }
    else if (duration == Half) {
        [self drawHalf:ytop];
    }
    else if (duration == Quarter) {
        [self drawQuarter:ytop];
    }
    else if (duration == Eighth) {
        [self drawEighth:ytop];
    }
    trans = [NSAffineTransform transform];
    [trans translateXBy:-NoteHeight/2 yBy:0.0];
    [trans concat];
    trans = [NSAffineTransform transform];
    [trans translateXBy:-(width - self.minWidth) yBy:0.0];
    [trans concat];
}


/** Draw a whole rest symbol, a rectangle below a staff line. 
 * @param ytop The ylocation (in pixels) where the top of the staff starts.
 */
- (void)drawWhole:(int)ytop {
    int y = ytop + NoteHeight;

    NSBezierPath *path = [NSBezierPath bezierPathWithRect:
        NSMakeRect(0, y, NoteWidth, NoteHeight/2)];
    [path fill];
}

/** Draw a half rest symbol, a rectangle above a staff line.
 * @param ytop The ylocation (in pixels) where the top of the staff starts.
 */
- (void)drawHalf:(int)ytop {
    int y = ytop + NoteHeight + NoteHeight/2;

    NSBezierPath *path = [NSBezierPath bezierPathWithRect:
        NSMakeRect(0, y, NoteWidth, NoteHeight/2)];
    [path fill];
}

/** Draw a quarter rest symbol. 
 * @param ytop The ylocation (in pixels) where the top of the staff starts.
 */
- (void)drawQuarter:(int)ytop {

    NSBezierPath *path;

    path = [NSBezierPath bezierPath];
    [path setLineCapStyle:NSButtLineCapStyle];

    int y = ytop + NoteHeight/2;
    int x = 2;
    int xend = x + 2*NoteHeight/3;
    [path moveToPoint:NSMakePoint(x, y)];
    [path lineToPoint:NSMakePoint(xend-1, y + NoteHeight - 1)];
    [path setLineWidth:1];
    [path stroke];

    path = [NSBezierPath bezierPath];
    [path setLineCapStyle:NSButtLineCapStyle];
    y  = ytop + NoteHeight + 1;
    [path moveToPoint:NSMakePoint(xend-2, y)];
    [path lineToPoint:NSMakePoint(x, y + NoteHeight)];
    [path setLineWidth:LineSpace/2];
    [path stroke];

    path = [NSBezierPath bezierPath];
    [path setLineCapStyle:NSButtLineCapStyle];
    y = ytop + NoteHeight*2 - 1;
    [path moveToPoint:NSMakePoint(0, y)];
    [path lineToPoint:NSMakePoint(xend+2, y + NoteHeight)];
    [path setLineWidth:1];
    [path stroke];

    path = [NSBezierPath bezierPath];
    [path setLineCapStyle:NSButtLineCapStyle];
    if (NoteHeight == 6) {
        [path moveToPoint:NSMakePoint(xend, y + 1 + 3*NoteHeight/4)];
        [path lineToPoint:NSMakePoint(x/2, y + 1 + 3*NoteHeight/4)];
    }
    else { /* NoteHeight == 8 */
        [path moveToPoint:NSMakePoint(xend, y + 3*NoteHeight/4)];
        [path lineToPoint:NSMakePoint(x/2, y + 3*NoteHeight/4)];
    }
    [path setLineWidth:LineSpace/2];
    [path stroke];

    path = [NSBezierPath bezierPath];
    [path setLineCapStyle:NSButtLineCapStyle];
    [path moveToPoint:NSMakePoint(0, y + 2*NoteHeight/3 + 1)];
    [path lineToPoint:NSMakePoint(xend - 1, y + 3*NoteHeight/2)];
    [path setLineWidth:1];
    [path stroke];
}

/** Draw an eighth rest symbol
 * @param ytop The ylocation (in pixels) where the top of the staff starts.
 */
- (void)drawEighth:(int)ytop {

    NSBezierPath *path;
    path = [NSBezierPath bezierPath];
    int y = ytop + NoteHeight - 1;
    [path appendBezierPathWithOvalInRect:
          NSMakeRect(0, y+1, LineSpace-1, LineSpace-1)];

    [path fill];

    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint((LineSpace-2)/2, y + LineSpace - 1)];
    [path lineToPoint:NSMakePoint(3*LineSpace/2,   y + LineSpace/2)];
    [path moveToPoint:NSMakePoint(3*LineSpace/2,   y + LineSpace/2)];
    [path lineToPoint:NSMakePoint(3*LineSpace/4,   y + NoteHeight*2)];
    [path setLineWidth:1];
    [path stroke];
}

- (NSString*)description {
    NSString *s = [NSString stringWithFormat:
                   @"RestSymbol starttime=%d duration=%d width=%d",
                   starttime, duration, width];
    return s;
}


@end

