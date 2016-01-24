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

#import "ClefSymbol.h"
#import "WhiteNote.h"

static NSImage* treble = nil;  /** The treble clef image */
static NSImage* bass = nil;    /** The bass clef image */

/** @class ClefSymbol
 * A ClefSymbol represents either a Treble or Bass Clef image.
 * The clef can be either normal or small size.  Normal size is
 * used at the beginning of a new staff, on the left side.  The
 * small symbols are used to show clef changes within a staff.
 */

@implementation ClefSymbol

/** Create a new ClefSymbol, with the given clef, starttime, and size */
- (id)initWithClef:(int)c andTime:(int)t isSmall:(BOOL)small {
    clef = c;
    starttime = t;
    smallsize = small;
    width = self.minWidth;
    [ClefSymbol loadImages];
    return self;
}

/** Load the Treble/Bass clef images into memory. */
+ (void)loadImages {
    NSString *filename;
    if (treble == NULL) {
        filename = [[NSBundle mainBundle] 
                    pathForResource:@"treble"
                    ofType:@"png"];
        treble = [[NSImage alloc] initWithContentsOfFile:filename];
        [treble setFlipped:YES];
    }
    if (bass == NULL) {
        filename = [[NSBundle mainBundle] 
                    pathForResource:@"bass"
                    ofType:@"png"];
        bass = [[NSImage alloc] initWithContentsOfFile:filename];
        [bass setFlipped:YES];
    }
}

/** Get the time (in pulses) this symbol occurs at.
 * This is used to determine the measure this symbol belongs to.
 */
- (int)startTime {
    return starttime;
}

/** Get the minimum width (in pixels) needed to draw this symbol */
- (int)minWidth {
    if (smallsize) {
        return NoteWidth * 2;
    }
    else {
        return NoteWidth * 3;
    }
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
    if (clef == Clef_Treble && !smallsize)
        return NoteHeight * 2;
    else
        return 0;
}

/** Get the number of pixels this symbol extends below the staff. Used
 *  to determine the minimum height needed for the staff (Staff:findBounds).
 */
- (int)belowStaff {
    if (clef == Clef_Treble && !smallsize)
        return NoteHeight * 2;
    else if (clef == Clef_Treble && smallsize)
        return NoteHeight;
    else
        return 0;
}

/** Draw the symbol.
 * @param ytop The ylocation (in pixels) where the top of the staff starts.
 */
- (void)draw:(int)ytop {
    NSAffineTransform *trans = [NSAffineTransform transform];
    [trans translateXBy:(width - self.minWidth) yBy:0.0];
    [trans concat];

    int y = ytop;
    NSImage *image;
    int height;

    /* Get the image, height, and top y pixel, depending on the clef
     * and the image size.
     */
    if (clef == Clef_Treble) {
        image = treble;
        if (smallsize) {
            height = StaffHeight + StaffHeight/4;
        } else {
            height = 3 * StaffHeight/2 + NoteHeight/2;
            y = ytop - NoteHeight;
        }
    }
    else {
        image = bass;
        if (smallsize) {
            height = StaffHeight - 3*NoteHeight/2;
        } else {
            height = StaffHeight - NoteHeight;
        }
    }

    /* Scale the image width to match the height */
    int imgwidth = (int)([image size].width * 1.0*height / [image size].height);

    [image drawInRect:NSMakeRect(0, y, imgwidth, height)
           fromRect:NSMakeRect(0, 0, [image size].width, [image size].height)
           operation:NSCompositeCopy
           fraction:1.0];

    trans = [NSAffineTransform transform];
    [trans translateXBy:-(width - self.minWidth) yBy:0.0];
    [trans concat];
}

- (NSString*)description {
    NSString *s = [NSString stringWithFormat:
                    @"ClefSymbol clef=%d small=%d width=%d",
                     clef, smallsize, width];
    return s;
}

@end


