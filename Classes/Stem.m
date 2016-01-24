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


/** @class Stem
 * The Stem class is used by ChordSymbol to draw the stem portion of
 * the chord.  The stem has the following fields:
 *
 * duration  - The duration of the stem.
 * direction - Either StemUp or StemDown
 * side      - Either left or right
 * top       - The topmost note in the chord
 * bottom    - The bottommost note in the chord
 * end       - The note position where the stem ends.  This is usually
 *             six notes past the last note in the chord.  For 8th/16th
 *             notes, the stem must extend even more.
 *
 * The class can change the direction of a stem after it
 * has been created.  The side and end fields may also change due to
 * the direction change.  But other fields will not change.
 */
#import "MusicSymbol.h"
#import "Stem.h"
#import "TimeSignature.h"

@implementation Stem

@synthesize duration;
@synthesize top;
@synthesize bottom;
@synthesize end;
@synthesize pair;
@synthesize direction;
@synthesize receiver;
@synthesize side;
//@synthesize isBeam;
//@synthesize duration;


/** Create a new stem.  The top note, bottom note, and direction are 
 * needed for drawing the vertical line of the stem.  The duration is 
 * needed to draw the tail of the stem.  The overlap boolean is true
 * if the notes in the chord overlap.  If the notes overlap, the
 * stem must be drawn on the right side.
 */
- (id)initWithBottom:(WhiteNote*)b andTop:(WhiteNote*)t
     andDuration:(int)dur andDirection:(int)dir andOverlap:(BOOL)overlap {

    self.top = t;
    self.bottom = b;
    duration = dur;
    direction = dir;
    notesoverlap = overlap;

    if (direction == StemUp || notesoverlap)
        side = RightSide;
    else 
        side = LeftSide;
    self.end = [self calculateEnd];
    self.pair = nil;
    width_to_pair = 0;
    receiver = NO;
    return self;
}

/** Calculate the vertical position (white note key) where 
 * the stem ends 
 */
- (WhiteNote*)calculateEnd {
    if (direction == StemUp) {
        WhiteNote *w = [top add:6];
        if (duration == Sixteenth) {
            w = [w add:2];
        }
        else if (duration == ThirtySecond) {
            w = [w add:4];
        }
        return w;
    }
    else if (direction == StemDown) {
        WhiteNote *w = [bottom add:-6];
        if (duration == Sixteenth) {
            w = [w add:-2];
        }
        else if (duration == ThirtySecond) {
            w = [w add:-4];
        }
        return w;
    }
    else {
        return nil;  /* Shouldn't happen */
    }
}

/** Change the direction of the stem.  This function is called by 
 * ChordSymbol.makePair().  When two chords are joined by a horizontal
 * beam, their stems must point in the same direction (up or down).
 */
- (void)setDirection:(int)newdirection {
    direction = newdirection;
    if (direction == StemUp || notesoverlap)
        side = RightSide;
    else
        side = LeftSide;

    self.end = [self calculateEnd];
}

/** Pair this stem with another Chord.  Instead of drawing a curvy tail,
 * this stem will now have to draw a beam to the given stem pair.  The
 * width (in pixels) to this stem pair is passed as argument.
 */
- (void)setPair:(Stem*)p withWidth:(int)width {
    self.pair = p;
    width_to_pair = width;
}

-(BOOL)isBeam {
    return receiver || (pair != nil);
}

/** Draw this stem.
 * @param ytop The y location (in pixels) where the top of the staff starts.
 * @param topstaff  The note at the top of the staff.
 */
- (void)draw:(int)ytop topStaff:(WhiteNote*)topstaff {
    if (duration == Whole)
        return;

    [self drawVerticalLine:ytop topStaff:topstaff];
    if (duration == Quarter || 
        duration == DottedQuarter ||
        duration == Half ||
        duration == DottedHalf ||
        receiver) {

        return;
    }

    if (pair != nil)
        [self drawBeamStem:ytop topStaff:topstaff];
    else
        [self drawCurvyStem:ytop topStaff:topstaff];
}

/** Draw the vertical line of the stem.
 * @param ytop The y location (in pixels) where the top of the staff starts.
 * @param topstaff  The note at the top of the staff.
 */
- (void)drawVerticalLine:(int)ytop topStaff:(WhiteNote*)topstaff {
    int xstart;
    if (side == LeftSide)
        xstart = LineSpace/4 + 1;
    else
        xstart = LineSpace/4 + NoteWidth;

    if (direction == StemUp) {
        int y1 = ytop + [topstaff dist:bottom] * NoteHeight/2 
                   + NoteHeight/4;

        int ystem = ytop + [topstaff dist:end] * NoteHeight/2;

        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(xstart, y1)];
        [path lineToPoint:NSMakePoint(xstart, ystem)];
        [path stroke];
    }
    else if (direction == StemDown) {
        int y1 = ytop + [topstaff dist:top] * NoteHeight/2 
                   + NoteHeight;

        if (side == LeftSide)
            y1 = y1 - NoteHeight/4;
        else
            y1 = y1 - NoteHeight/2;

        int ystem = ytop + [topstaff dist:end] * NoteHeight/2 
                      + NoteHeight;

        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(xstart, y1)];
        [path lineToPoint:NSMakePoint(xstart, ystem)];
        [path stroke];
    }
}

/** Draw a curvy stem tail.  This is only used for single chords, not chord pairs.
 * @param ytop The y location (in pixels) where the top of the staff starts.
 * @param topstaff  The note at the top of the staff.
 */
- (void)drawCurvyStem:(int)ytop topStaff:(WhiteNote*)topstaff {

    NSBezierPath *path = [NSBezierPath bezierPath];
    [path setLineWidth:2];

    int xstart = 0;
    if (side == LeftSide)
        xstart = LineSpace/4 + 1;
    else
        xstart = LineSpace/4 + NoteWidth;

    if (direction == StemUp) {
        int ystem = ytop + [topstaff dist:end] * NoteHeight/2;

        if (duration == Eighth ||
            duration == DottedEighth ||
            duration == Triplet ||
            duration == Sixteenth ||
            duration == ThirtySecond) {

            [path moveToPoint:NSMakePoint(xstart, ystem)];
            [path curveToPoint:NSMakePoint(xstart + LineSpace/2, 
                                            ystem + NoteHeight*3)
                  controlPoint1:NSMakePoint(xstart,
                                             ystem + 3*LineSpace/2)
                  controlPoint2:NSMakePoint(xstart + LineSpace*2, 
                                             ystem + NoteHeight*2)
            ];
        }
        ystem += NoteHeight;

        if (duration == Sixteenth ||
            duration == ThirtySecond) {

            [path moveToPoint:NSMakePoint(xstart, ystem)];
            [path curveToPoint:NSMakePoint(xstart + LineSpace/2, 
                                            ystem + NoteHeight*3)
                  controlPoint1:NSMakePoint(xstart,
                                             ystem + 3*LineSpace/2)
                  controlPoint2:NSMakePoint(xstart + LineSpace*2, 
                                             ystem + NoteHeight*2)
            ];
        }

        ystem += NoteHeight;
        if (duration == ThirtySecond) {
            [path moveToPoint:NSMakePoint(xstart, ystem)];
            [path curveToPoint:NSMakePoint(xstart + LineSpace/2, 
                                            ystem + NoteHeight*3)
                  controlPoint1:NSMakePoint(xstart,
                                             ystem + 3*LineSpace/2)
                  controlPoint2:NSMakePoint(xstart + LineSpace*2, 
                                             ystem + NoteHeight*2)
            ];
        }
    }

    else if (direction == StemDown) {
        int ystem = ytop + [topstaff dist:end]*NoteHeight/2 +
                    NoteHeight;

        if (duration == Eighth ||
            duration == DottedEighth ||
            duration == Triplet ||
            duration == Sixteenth ||
            duration == ThirtySecond) {

            [path moveToPoint:NSMakePoint(xstart, ystem)];
            [path curveToPoint:NSMakePoint(xstart + LineSpace, 
                                            ystem - NoteHeight*2 - LineSpace/2)
                  controlPoint1:NSMakePoint(xstart,
                                             ystem - LineSpace)
                  controlPoint2:NSMakePoint(xstart + LineSpace*2, 
                                             ystem - NoteHeight*2)
            ];
        }
        ystem -= NoteHeight;

        if (duration == Sixteenth ||
            duration == ThirtySecond) {

            [path moveToPoint:NSMakePoint(xstart, ystem)];
            [path curveToPoint:NSMakePoint(xstart + LineSpace, 
                                            ystem - NoteHeight*2 - LineSpace/2)
                  controlPoint1:NSMakePoint(xstart,
                                             ystem - LineSpace)
                  controlPoint2:NSMakePoint(xstart + LineSpace*2, 
                                             ystem - NoteHeight*2)
            ];
        }

        ystem -= NoteHeight;
        if (duration == ThirtySecond) {
            [path moveToPoint:NSMakePoint(xstart, ystem)];
            [path curveToPoint:NSMakePoint(xstart + LineSpace, 
                                            ystem - NoteHeight*2 - LineSpace/2)
                  controlPoint1:NSMakePoint(xstart,
                                             ystem - LineSpace)
                  controlPoint2:NSMakePoint(xstart + LineSpace*2, 
                                             ystem - NoteHeight*2)
            ];
        }
    }
    [path stroke];
}

/* Draw a horizontal beam stem, connecting this stem with the Stem pair.
 * @param ytop The y location (in pixels) where the top of the staff starts.
 * @param topstaff  The note at the top of the staff.
 */
- (void)drawBeamStem:(int)ytop topStaff:(WhiteNote*)topstaff {
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path setLineWidth:NoteHeight/2];

    int xstart = 0;
    int xstart2 = 0;

    if (side == LeftSide)
        xstart = LineSpace/4 + 1;
    else if (side == RightSide)
        xstart = LineSpace/4 + NoteWidth;

    if ([pair side] == LeftSide)
        xstart2 = LineSpace/4 + 1;
    else if ([pair side] == RightSide)
        xstart2 = LineSpace/4 + NoteWidth;


    if (direction == StemUp) {
        int xend = width_to_pair + xstart2;
        int ystart = ytop + [topstaff dist:end] * NoteHeight/2;
        int yend = ytop + [topstaff dist:[pair end]] * NoteHeight/2;

        if (duration == Eighth ||
            duration == DottedEighth || 
            duration == Triplet || 
            duration == Sixteenth ||
            duration == ThirtySecond) {

            [path moveToPoint:NSMakePoint(xstart, ystart)];
            [path lineToPoint:NSMakePoint(xend, yend)];
        }
        ystart += NoteHeight;
        yend += NoteHeight;

        /* A dotted eighth will connect to a 16th note. */
        if (duration == DottedEighth) {
            int x = xend - NoteHeight;
            double slope = (yend - ystart) * 1.0 / (xend - xstart);
            int y = (int)(slope * (x - xend) + yend);

            [path moveToPoint:NSMakePoint(x, y)];
            [path lineToPoint:NSMakePoint(xend, yend)];
        }

        if (duration == Sixteenth ||
            duration == ThirtySecond) {

            [path moveToPoint:NSMakePoint(xstart, ystart)];
            [path lineToPoint:NSMakePoint(xend, yend)];
        }
        ystart += NoteHeight;
        yend += NoteHeight;
        
        if (duration == ThirtySecond) {
            [path moveToPoint:NSMakePoint(xstart, ystart)];
            [path lineToPoint:NSMakePoint(xend, yend)];
        }
    }

    else {
        int xend = width_to_pair + xstart2;
        int ystart = ytop + [topstaff dist:end] * NoteHeight/2 + 
                     NoteHeight;
        int yend = ytop + [topstaff dist:[pair end]] * NoteHeight/2 
                     + NoteHeight;

        if (duration == Eighth ||
            duration == DottedEighth ||
            duration == Triplet ||
            duration == Sixteenth ||
            duration == ThirtySecond) {

            [path moveToPoint:NSMakePoint(xstart, ystart)];
            [path lineToPoint:NSMakePoint(xend, yend)];
        }
        ystart -= NoteHeight;
        yend -= NoteHeight;

        /* A dotted eighth will connect to a 16th note. */
        if (duration == DottedEighth) {
            int x = xend - NoteHeight;
            double slope = (yend - ystart) * 1.0 / (xend - xstart);
            int y = (int)(slope * (x - xend) + yend);

            [path moveToPoint:NSMakePoint(x, y)];
            [path lineToPoint:NSMakePoint(xend, yend)];
        }

        if (duration == Sixteenth ||
            duration == ThirtySecond) {

            [path moveToPoint:NSMakePoint(xstart, ystart)];
            [path lineToPoint:NSMakePoint(xend, yend)];
        }
        ystart -= NoteHeight;
        yend -= NoteHeight;
        
        if (duration == ThirtySecond) {
            [path moveToPoint:NSMakePoint(xstart, ystart)];
            [path lineToPoint:NSMakePoint(xend, yend)];
        }
    }
    [path stroke];
}

- (void)dealloc {
    self.top = nil;
    self.bottom = nil;
    self.end = nil;
    self.pair = nil;
    [super dealloc];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"Stem duration=%@ direction=%d top=%@ bottom=%@ end=%@ overlap=%d side=%d width_to_pair=%d receiver=%d",
               [TimeSignature durationString:duration], 
               direction, 
               [top description], [bottom description], [end description], 
               notesoverlap, side, width_to_pair, receiver ];
}


@end


