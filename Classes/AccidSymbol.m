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

/** @class AccidSymbol
 * An accidental (accid) symbol represents a sharp, flat, or natural
 * accidental that is displayed at a specific position (note and clef).
 */

#import "AccidSymbol.h"

@implementation AccidSymbol

/**
 * Create a new AccidSymbol with the given accidental, that is
 * displayed at the given note in the given clef.
 */
- (id)initWithAccid:(int)a andNote:(WhiteNote*)note andClef:(int)c {
    accid = a;
    whitenote = [note retain];
    clef = c;
    width = self.minWidth;
    return self;
}

/** Return the white note this accidental is displayed at */
- (WhiteNote*)note {
    return whitenote;
}

/** Get the time (in pulses) this symbol occurs at.
 * Not used.  Instead, the StartTime of the ChordSymbol containing this
 * AccidSymbol is used.
 */
- (int)startTime {
    return -1;
}

/** Get the minimum width (in pixels) needed to draw this symbol */
- (int)minWidth {
    return 3 * NoteHeight/2;
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


/** Get the number of pixels this symbol extends above the staff. Used
 *  to determine the minimum height needed for the staff (Staff:findBounds).
 */
- (int)aboveStaff {
    int dist = [[WhiteNote top:clef] dist:whitenote] * 
               NoteHeight/2;
    if (accid == AccidSharp || accid == AccidNatural)
        dist -= NoteHeight;
    else if (accid == AccidFlat)
        dist -= 3*NoteHeight/2;

    if (dist < 0)
        return -dist;
    else
        return 0;
}

/** Get the number of pixels this symbol extends below the staff. Used
 *  to determine the minimum height needed for the staff (Staff:findBounds).
 */
- (int)belowStaff {
    int dist = [[WhiteNote bottom:clef] dist:whitenote] * 
               NoteHeight/2 + NoteHeight;
    if (accid == AccidSharp || accid == AccidNatural) 
        dist += NoteHeight;

    if (dist > 0)
        return dist;
    else 
        return 0;
}

/** Draw the symbol.
 * @param ytop The ylocation (in pixels) where the top of the staff starts.
 */
- (void) draw:(int)ytop {
    /* Align the symbol to the right */
    NSAffineTransform *trans = [NSAffineTransform transform];
    [trans translateXBy:(width - self.minWidth) yBy:0.0];
    [trans concat];

    /* Store the y-pixel value of the top of the whitenote in ynote. */
    int ynote = ytop + [[WhiteNote top:clef] dist:whitenote] * 
                NoteHeight/2;

    if (accid == AccidSharp)
        [self drawSharp:ynote];
    else if (accid == AccidFlat)
        [self drawFlat:ynote];
    else if (accid == AccidNatural)
        [self drawNatural:ynote];

    trans = [NSAffineTransform transform];
    [trans translateXBy:-(width - self.minWidth) yBy:0.0];
    [trans concat];
}

/** Draw a sharp symbol.
 * @param ynote The pixel location of the top of the accidental's note.
 */
- (void) drawSharp:(int)ynote {
    NSBezierPath *path = [NSBezierPath bezierPath];

    /* Draw the two vertical lines */
    int ystart = ynote - NoteHeight;
    int yend = ynote + 2*NoteHeight;
    int x = NoteHeight/2;
    [path setLineWidth:1];
    [path moveToPoint:NSMakePoint(x, ystart + 2)];
    [path lineToPoint:NSMakePoint(x, yend)];
    [path moveToPoint:NSMakePoint(x + NoteHeight/2, ystart)];
    [path lineToPoint:NSMakePoint(x + NoteHeight/2, yend-2)];
    [path stroke];

    /* Draw the slightly upwards horizontal lines */
    int xstart = NoteHeight/2 - NoteHeight/4;
    int xend = NoteHeight + NoteHeight/4;
    ystart = ynote + LineWidth;
    yend = ystart - LineWidth - LineSpace/4;
   
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(xstart, ystart)];
    [path lineToPoint:NSMakePoint(xend, yend)];
    ystart += LineSpace;
    yend += LineSpace;
    [path moveToPoint:NSMakePoint(xstart, ystart)];
    [path lineToPoint:NSMakePoint(xend, yend)];
    [path setLineWidth:LineSpace/2];
    [path stroke];
}

/** Draw a sharp symbol.
 * @param ynote The pixel location of the top of the accidental's note.
 */
- (void)drawFlat:(int)ynote {
    int x = LineSpace/4;
    NSBezierPath* path = [NSBezierPath bezierPath];

    /* Draw the vertical line */
    [path moveToPoint:NSMakePoint(x, ynote - NoteHeight - NoteHeight/2)];
    [path lineToPoint:NSMakePoint(x, ynote + NoteHeight)];

    /* Draw 3 bezier curves.
     * All 3 curves start and stop at the same points.
     * Each subsequent curve bulges more and more towards 
     * the topright corner, making the curve look thicker
     * towards the top-right.
     */

    [path moveToPoint:NSMakePoint(x, ynote + LineSpace/4)];
    [path curveToPoint:NSMakePoint(x, ynote + LineSpace + LineWidth + 1)
          controlPoint1:NSMakePoint(x + LineSpace/2, ynote - LineSpace/2)
          controlPoint2:NSMakePoint(x + LineSpace, ynote + LineSpace/3)
    ];

    [path moveToPoint:NSMakePoint(x, ynote + LineSpace/4)];
    [path curveToPoint:NSMakePoint(x, ynote + LineSpace + LineWidth + 1)
          controlPoint1:NSMakePoint(x + LineSpace/2, ynote - LineSpace/2)
          controlPoint2:NSMakePoint(x + LineSpace + LineSpace/4, 
                                     ynote + LineSpace/3 - LineSpace/4)
    ];


    [path moveToPoint:NSMakePoint(x, ynote + LineSpace/4)];
    [path curveToPoint:NSMakePoint(x, ynote + LineSpace + LineWidth + 1)
          controlPoint1:NSMakePoint(x + LineSpace/2, ynote - LineSpace/2)
          controlPoint2:NSMakePoint(x + LineSpace + LineSpace/2, 
                                     ynote + LineSpace/3 - LineSpace/2)
    ];

    [path setLineWidth:1];
    [path stroke];
}

/** Draw a natural symbol.
 * @param ynote The pixel location of the top of the accidental's note.
 */
- (void)drawNatural:(int)ynote {
    NSBezierPath* path = [NSBezierPath bezierPath];

    /* Draw the two vertical lines */
    int ystart = ynote - LineSpace - LineWidth;
    int yend = ynote + LineSpace + LineWidth;
    int x = LineSpace/2;

    [path moveToPoint:NSMakePoint(x, ystart)];
    [path lineToPoint:NSMakePoint(x, yend)];
    x += LineSpace - LineSpace/4;
    ystart = ynote - LineSpace/4;
    yend = ynote + 2*LineSpace + LineWidth - LineSpace/4;
    [path moveToPoint:NSMakePoint(x, ystart)];
    [path lineToPoint:NSMakePoint(x, yend)];
    [path setLineWidth:1];
    [path stroke];

    /* Draw the slightly upwards horizontal lines */
    path = [NSBezierPath bezierPath];
    int xstart = LineSpace/2;
    int xend = xstart + LineSpace - LineSpace/4;
    ystart = ynote + LineWidth;
    yend = ystart - LineWidth - LineSpace/4;
    [path moveToPoint:NSMakePoint(xstart, ystart)];
    [path lineToPoint:NSMakePoint(xend, yend)];
    ystart += LineSpace;
    yend += LineSpace;
    [path moveToPoint:NSMakePoint(xstart, ystart)];
    [path lineToPoint:NSMakePoint(xend, yend)];

    [path setLineWidth:LineSpace/2];
    [path stroke];
}

- (NSString*)description {
    NSString* names[] = { @"None", @"Sharp", @"Flat", @"Natural" };
    NSString* clefs[] = { @"Treble", @"Bass" };
    NSString *s = [NSString stringWithFormat: 
                     @"AccidSymbol accid=%@ whitenote=%@ clef=%@ width=%d",
                     names[accid], [whitenote description], clefs[clef], width];
    return s;
}

- (void)dealloc {
    [whitenote release];
    [super dealloc];
}

@end


