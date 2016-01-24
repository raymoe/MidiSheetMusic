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

#import "TimeSigSymbol.h"
#import "WhiteNote.h"

static int images_init = 0;
static NSImage* images[13];     /** The images for each number */

/** @class TimeSigSymbol
 * A TimeSigSymbol represents the time signature at the beginning
 * of the staff. We use pre-made images for the numbers, instead of
 * drawing strings.
 */
@implementation TimeSigSymbol

/** Create a new TimeSigSymbol */
- (id)initWithNumer:(int)numer andDenom:(int)denom {
    numerator = numer;
    denominator = denom;
    [TimeSigSymbol loadImages];
    if (numer >= 0 && numer < 13 && images[numer] != NULL &&
        denom >= 0 && denom < 13 && images[numer] != NULL) {
        candraw = YES;
    }
    else {
        candraw = NO;
    }
    width = self.minWidth;
    return self;
}

/** Load the number images into memory. */
+ (void)loadImages {
    NSString *filename;
    if (images_init == 0) {
        for (int i = 0; i < 13; i++) {
            images[i] = NULL;
        }
        filename = [[NSBundle mainBundle] pathForResource:@"two" ofType:@"png"];
        images[2] = [[NSImage alloc] initWithContentsOfFile:filename];
        [images[2] setFlipped:YES];

        filename = [[NSBundle mainBundle] pathForResource:@"three" ofType:@"png"];
        images[3] = [[NSImage alloc] initWithContentsOfFile:filename];
        [images[3] setFlipped:YES];

        filename = [[NSBundle mainBundle] pathForResource:@"four" ofType:@"png"];
        images[4] = [[NSImage alloc] initWithContentsOfFile:filename];
        [images[4] setFlipped:YES];

        filename = [[NSBundle mainBundle] pathForResource:@"six" ofType:@"png"];
        images[6] = [[NSImage alloc] initWithContentsOfFile:filename];
        [images[6] setFlipped:YES];

        filename = [[NSBundle mainBundle] pathForResource:@"eight" ofType:@"png"];
        images[8] = [[NSImage alloc] initWithContentsOfFile:filename];
        [images[8] setFlipped:YES];

        filename = [[NSBundle mainBundle] pathForResource:@"nine" ofType:@"png"];
        images[9] = [[NSImage alloc] initWithContentsOfFile:filename];
        [images[9] setFlipped:YES];

        filename = [[NSBundle mainBundle] pathForResource:@"twelve" ofType:@"png"];
        images[12] = [[NSImage alloc] initWithContentsOfFile:filename];
        [images[12] setFlipped:YES];
    }
    images_init = 1;
}

/** Get the time (in pulses) this symbol occurs at.
 * This is used to determine the measure this symbol belongs to.
 */
- (int)startTime {
    return -1;
}

/** Get the minimum width (in pixels) needed to draw this symbol */
- (int)minWidth {
    if (candraw) {
        return [images[2] size].width * NoteHeight * 2 / [images[2] size].height;
    }
    else {
        return 0;
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
    if (!candraw)
        return;

    ytop -= LineWidth;
    NSAffineTransform *trans = [NSAffineTransform transform];
    [trans translateXBy:(width - self.minWidth) yBy:0.0];
    [trans concat];

    NSImage *numer = images[numerator];
    NSImage *denom = images[denominator];

    /* Scale the image width to match the height */
    int imgheight = NoteHeight * 2;
    int imgwidth = (int)([numer size].width * 1.0*imgheight / [numer size].height);

    [numer drawInRect:NSMakeRect(0, ytop, imgwidth, imgheight)
           fromRect:NSMakeRect(0, 0, [numer size].width, [numer size].height)
           operation:NSCompositeCopy
           fraction:1.0];

    [denom drawInRect:NSMakeRect(0, ytop + imgheight, imgwidth, imgheight)
           fromRect:NSMakeRect(0, 0, [numer size].width, [numer size].height)
           operation:NSCompositeCopy
           fraction:1.0];

    trans = [NSAffineTransform transform];
    [trans translateXBy:-(width - self.minWidth) yBy:0.0];
    [trans concat];
}

- (NSString*)description {
    NSString *s = [NSString stringWithFormat:
                    @"TimeSigSymbol numerator=%d denominator=%d",
                     numerator, denominator];
    return s;
}

@end


