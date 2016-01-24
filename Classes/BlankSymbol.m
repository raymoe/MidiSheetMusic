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

#import "BlankSymbol.h"

/** @class BlankSymbol 
 * The Blank symbol is a music symbol that doesn't draw anything.  This
 * symbol is used for alignment purposes, to align notes in different 
 * staffs which occur at the same time.
 */
@implementation BlankSymbol

/** Create a new BlankSymbol with the given starttime and width */
- (id)initWithTime:(int)start andWidth:(int)w {
    starttime = start;
    width = w;
    return self;
}

/** Get the time (in pulses) this symbol occurs at.
 * This is used to determine the measure this symbol belongs to.
 */
- (int)startTime {
    return starttime;
}

/** Get the minimum width (in pixels) needed to draw this symbol */
- (int)minWidth {
    return 0;
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
    return 0;
}

/** Get the number of pixels this symbol extends below the staff. Used
 *  to determine the minimum height needed for the staff (Staff:findBounds).
 */
- (int)belowStaff {
    return 0;
}

/** Draw nothing.
 * @param ytop The ylocation (in pixels) where the top of the staff starts.
 */
- (void)draw:(int)ytop {
}

- (NSString*)description {
    NSString *s = [NSString stringWithFormat:
                    @"BlankSymbol starttime=%d width=%d",
                    starttime, width];
    return s;
}

@end

