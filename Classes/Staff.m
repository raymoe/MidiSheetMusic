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

#import "Staff.h"
#import "SheetMusic.h"
#import "ChordSymbol.h"
#import "AccidSymbol.h"
#import "BarSymbol.h"
#import "LyricSymbol.h"

#define max(x,y) ((x) > (y) ? (x) : (y))

/** @class Staff
 * The Staff is used to draw a single Staff (a row of measures) in the 
 * SheetMusic Control. A Staff needs to draw
 * - The Clef
 * - The key signature
 * - The horizontal lines
 * - A list of MusicSymbols
 * - The left and right vertical lines
 *
 * The height of the Staff is determined by the number of pixels each
 * MusicSymbol extends above and below the staff.
 *
 * The vertical lines (left and right sides) of the staff are joined
 * with the staffs above and below it, with one exception.
 * The last track is not joined with the first track.
 */
@implementation Staff


/** Create a new staff with the given list of music symbols,
 * and the given key signature.  The clef is determined by
 * the clef of the first chord symbol. The track number is used
 * to determine whether to join this left/right vertical sides
 * with the staffs above and below. The MidiOptions are used
 * to check whether to display measure numbers or not.
 */
- (id)initWithSymbols:(Array*)musicsymbols andKey:(KeySignature*)key
     andOptions:(MidiOptions*)options
     andTrack:(int)trknum andTotalTracks:(int)total {

    keysigWidth = [SheetMusic keySignatureWidth:key];
    symbols = [musicsymbols retain];
    tracknum = trknum;
    totaltracks = total;
    showMeasures = (options.showMeasures && tracknum == 0);
    measureLength  = options.time.measure;
    int clef = [self findClef];
    clefsym = [[ClefSymbol alloc] initWithClef:clef andTime:0 isSmall:NO];
    keys = [[key getSymbols:clef] retain];
    [self calculateWidth:options.scrollVert];
    [self calculateHeight];
    [self calculateStartEndTime];

    [self fullJustify];
    return self;
}

/** Return the width of the staff */
- (int)width {
    return width;
}

/** Return the height of the staff */
- (int)height {
    return height;
}

/** Return the track number of this staff (starting from 0) */
- (int)track {
    return tracknum;
}

/** Return the starting time of the staff, the start time of
 *  the first symbol.  This is used during playback, to
 *  automatically scroll the music while playing.
 */
- (int)startTime {
    return startTime;
}

/** Return the ending time of the staff, the endTime of
 *  the last symbol.  This is used during playback, to
 *  automatically scroll the music while playing.
 */
- (int)endTime {
    return endTime;
}

- (void)setEndTime:(int)value {
    endTime = value;
}

- (int)tracknum {
    return tracknum;
}

/** Find the initial clef to use for this staff.  Use the clef of
 * the first ChordSymbol.
 */
- (int)findClef {
    int i;
    for (i = 0;  i < [symbols count]; i++) {
        NSObject *m = [symbols get:i];
        if ([m isMemberOfClass:[ChordSymbol class]]) {
        /* if ([m respondsToSelector:@selector(hasTwoStems)]) { */
            ChordSymbol *c = (ChordSymbol*) m;
            return c.clef;
        }
    }
    return Clef_Treble;
}

/** Calculate the height of this staff.  Each MusicSymbol contains the
 * number of pixels it needs above and below the staff.  Get the maximum
 * values above and below the staff.
 */
- (void) calculateHeight {
    int above = 0;
    int below = 0;

    int i;
    for (i = 0; i < [symbols count]; i++) {
        id <MusicSymbol> s = [symbols get:i];
        above = max(above, s.aboveStaff);
        below = max(below, s.belowStaff);
    }
    above = max(above, clefsym.aboveStaff);
    below = max(below, clefsym.belowStaff);
    if (showMeasures) {
        above = max(above, NoteHeight * 3);
    }
    ytop = above + NoteHeight;
    height = NoteHeight*5 + ytop + below;
    if (lyrics != nil) {
        height += 12;
    }

    /* Add some extra vertical space between the last track
     * and first track.
     */
    if (tracknum == totaltracks-1)
        height += NoteHeight * 3;
}

/** Calculate the width of this staff */
-(void)calculateWidth:(BOOL)scrollVert {
    if (scrollVert) {
        width = PageWidth;
        return;
    }
    width = keysigWidth;
    for (int i = 0; i < [symbols count]; i++) {
        id <MusicSymbol> s = [symbols get:i];
        width += s.width;
    }
}


/** Calculate the start and end time of this staff. */
- (void)calculateStartEndTime {
    startTime = endTime = 0;
    if ([symbols count] == 0) {
        return;
    }
    startTime = [(id <MusicSymbol>)[symbols get:0] startTime];
    for (int i = 0; i < [symbols count]; i++) {
        id <MusicSymbol> m = [symbols get:i];
        if (endTime < m.startTime) {
            endTime = m.startTime;
        }
        if ([m isKindOfClass:[ChordSymbol class]]) {
            ChordSymbol *c = (ChordSymbol*) m;
            if (endTime < c.endTime) {
                endTime = c.endTime;
            }
        }
    }
}


/** Full-Justify the symbols, so that they expand to fill the whole staff. */
- (void)fullJustify {
    if (width != PageWidth)
        return;

    int totalwidth = keysigWidth;
    int totalsymbols = 0;
    int i = 0;

    while (i < [symbols count]) {
        id <MusicSymbol> symbol = [symbols get:i];
        int start = symbol.startTime;
        totalsymbols++;
        totalwidth += symbol.width;
        i++;

        while (i < [symbols count]) {
            symbol = [symbols get:i];
            if (symbol.startTime != start) {
                break;
            }
            totalwidth += symbol.width;
            i++;
        }
    }

    int extrawidth = (PageWidth - totalwidth - 1) / totalsymbols;
    if (extrawidth > NoteHeight*2) {
        extrawidth = NoteHeight*2;
    }
    i = 0;
    while (i < [symbols count]) {
        id <MusicSymbol> symbol = [symbols get:i];
        int start = symbol.startTime;
        symbol.width = symbol.width + extrawidth;
        i++;
        while (i < [symbols count]) {
            id <MusicSymbol> symbol = [symbols get:i];
            if (symbol.startTime != start) {
                break;
            }
            i++;
        }
    }
}


/** Add the lyric symbols that occur within this staff.
 *  Set the x-position of the lyric symbol.
 */
-(void)addLyrics:(Array*)tracklyrics {
    if (tracklyrics == nil || [tracklyrics count] == 0) {
        return;
    }
    lyrics = [[Array new:5] retain];
    int xpos = 0;
    int symbolindex = 0;
    for (int i = 0; i < [tracklyrics count]; i++) {
        LyricSymbol *lyric = (LyricSymbol*)[tracklyrics get:i];
        if (lyric.startTime < startTime) {
            continue;
        }
        if (lyric.startTime > endTime) {
            break;
        }
        /* Get the x-position of this lyric */
        while (symbolindex < [symbols count] &&
               [(id<MusicSymbol>)[symbols get:symbolindex] startTime] < lyric.startTime) {
            xpos += [(id<MusicSymbol>)[symbols get:symbolindex] width];
            symbolindex++;
        }
        [lyric setX:xpos];
        if (symbolindex < [symbols count] &&
            ([[symbols get:symbolindex] isKindOfClass:[BarSymbol class]])) {

            [lyric setX: [lyric x] + NoteWidth];
        }
        [lyrics add:lyric];
    }
    if ([lyrics count] == 0) {
        [lyrics release]; lyrics = nil;
    }
}

/** Draw the lyrics */
-(void)drawLyrics {
    /* Skip the left side Clef symbol and key signature */
    int xpos = keysigWidth;
    int ypos = height - 12;

    for (int i = 0; i < [lyrics count]; i++) {
        LyricSymbol *lyric = [lyrics get:i];
        NSPoint point = NSMakePoint(xpos + [lyric x], ypos);
        [[lyric text] drawAtPoint:point withAttributes:[SheetMusic fontAttributes]];
    }
}



/** Draw the measure numbers for each measure */
-(void)drawMeasureNumbers {
    /* Skip the left side Clef symbol and key signature */
    int xpos = keysigWidth;
    int ypos = ytop - NoteHeight*3;

    for (int i = 0; i < [symbols count]; i++) {
        id<MusicSymbol> s = [symbols get:i];
        if ([s isKindOfClass:[BarSymbol class]]) {
            int measure = 1 + s.startTime / measureLength;
            NSPoint point = NSMakePoint(xpos + NoteWidth/2, ypos);
            NSString *num = [NSString stringWithFormat:@"%d", measure];
            [num drawAtPoint:point withAttributes:[SheetMusic fontAttributes]];
        }
        xpos += s.width;
    }
}


/** Draw the five horizontal lines of the staff */
- (void)drawHorizLines {
    int line = 1;
    int y = ytop - 1;

    NSBezierPath *path = [NSBezierPath bezierPath];
    for (line = 1; line <= 5; line++) {
        [path moveToPoint:NSMakePoint(LeftMargin, y)];
        [path lineToPoint:NSMakePoint(width-1, y)];
        y += LineWidth + LineSpace;
    }
    [path stroke];
    [[NSColor blackColor] setStroke];
}

/** Draw the vertical lines at the far left and far right sides. */
- (void)drawEndLines {
    /* Draw the vertical lines from 0 to the height of this staff,
     * including the space above and below the staff, with two exceptions:
     * - If this is the first track, don't start above the staff.
     *   Start exactly at the top of the staff (ytop - LineWidth)
     * - If this is the last track, don't end below the staff.
     *   End exactly at the bottom of the staff.
     */
    int ystart, yend;
    if (tracknum == 0)
        ystart = ytop - LineWidth;
    else
        ystart = 0;

    if (tracknum == (totaltracks-1))
        yend = ytop + 4 * NoteHeight;
    else
        yend = height;

    NSBezierPath *path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(LeftMargin, ystart)];
    [path lineToPoint:NSMakePoint(LeftMargin, yend)];
    [path moveToPoint:NSMakePoint(width-1, ystart)];
    [path lineToPoint:NSMakePoint(width-1, yend)];
    [path stroke];
}

/** Draw this staff. Only draw the symbols inside the clip area. */
- (void)drawRect:(NSRect)clip {
    int xpos = LeftMargin + 5;

    NSAffineTransform *trans;

    /* Draw the left side Clef symbol */
    trans = [NSAffineTransform transform];
    [trans translateXBy:xpos yBy:0.0];
    [trans concat];
    [clefsym draw:ytop];
    trans = [NSAffineTransform transform];
    [trans translateXBy:-xpos yBy:0.0];
    [trans concat];

    xpos += clefsym.width;

    /* Draw the key signature */
    int i;

    for (i = 0; i < [keys count]; i++) {
        AccidSymbol *a = [keys get:i];
        trans = [NSAffineTransform transform];
        [trans translateXBy:xpos yBy:0.0];
        [trans concat];
        [a draw:ytop];
        trans = [NSAffineTransform transform];
        [trans translateXBy:-xpos yBy:0.0];
        [trans concat];
        xpos += a.width;
    }


    /* Draw the actual notes, rests, bars.  Draw the symbols one 
     * after another, using the symbol width to determine the
     * x position of the next symbol.
     *
     * For fast performance, only draw symbols that are in the clip area.
     */
    for (i = 0; i < [symbols count]; i++) {
        id <MusicSymbol> s = [symbols get:i];
        if ((xpos <= clip.origin.x + clip.size.width + 50) &&
            (xpos + s.width + 50 >= clip.origin.x)) {

            trans = [NSAffineTransform transform];
            [trans translateXBy:xpos yBy:0.0];
            [trans concat];
            [s draw:ytop];
            trans = [NSAffineTransform transform];
            [trans translateXBy:-xpos yBy:0.0];
            [trans concat];
        }
        xpos += s.width;
    }
    [self drawHorizLines];
    [self drawEndLines];

    if (showMeasures) {
        [self drawMeasureNumbers];
    }
    if (lyrics != nil) {
        [self drawLyrics];
    }
}


/** Shade all the chords played in the given time.
 *  Un-shade any chords shaded in the previous pulse time.
 *  Store the x coordinate location where the shade was drawn.
 */
- (void) shadeNotes:(int)currentPulseTime withPrev:(int)prevPulseTime 
              andX:(int*)x_shade andColor:(NSColor*)color {
    NSAffineTransform *trans;

    /* If there's nothing to unshade, or shade, return */
    if ((startTime > prevPulseTime || endTime < prevPulseTime) &&
        (startTime > currentPulseTime || endTime < currentPulseTime)) {
        return;
    }

    /* Skip the left side Clef symbol and key signature */
    int xpos = keysigWidth;

    id <MusicSymbol> curr = nil;
    ChordSymbol* prevChord = nil;
    int prev_xpos = 0;

    /* Loop through the symbols.
     * Unshade symbols where startTime <= prevPulseTime < end
     * Shade symbols where startTime <= currentPulseTime < end
     */
    for (int i = 0; i < [symbols count]; i++) {
        curr = [symbols get:i];
        if ([curr isKindOfClass:[BarSymbol class]]) {
            xpos += curr.width;
            continue;
        }

        int start = curr.startTime;
        int end = 0;
        if (i+2 < [symbols count] && [[symbols get:i+1] isKindOfClass:[BarSymbol class]]) {
            end = [(id <MusicSymbol>)[symbols get:i+2] startTime];
        }
        else if (i+1 < [symbols count]) {
            end = [(id <MusicSymbol>)[symbols get:i+1] startTime];
        }
        else {
            end = endTime;
        }

        /* If we've past the previous and current times, we're done. */
        if ((start > prevPulseTime) && (start > currentPulseTime)) {
            if (*x_shade == 0) {
                *x_shade = xpos;
            }
            return;
        }
        /* If shaded notes are the same, we're done */
        if ((start <= currentPulseTime) && (currentPulseTime < end) &&
            (start <= prevPulseTime) && (prevPulseTime < end)) {

            *x_shade = xpos;
            return;
        }

        BOOL redrawLines = FALSE;

        /* If symbol is in the previous time, draw a white background */
        if ((start <= prevPulseTime) && (prevPulseTime < end)) {
            trans = [NSAffineTransform transform];
            [trans translateXBy:xpos-2 yBy:-2];
            [trans concat];
            [[NSColor whiteColor] setFill];
            NSBezierPath *path = [NSBezierPath bezierPathWithRect:
                NSMakeRect(0, 0, curr.width+4, [self height] + 4) ];
            [path fill];
            trans = [NSAffineTransform transform];
            [trans translateXBy:-(xpos-2) yBy:2];
            [trans concat];
            trans = [NSAffineTransform transform];
            [trans translateXBy:xpos yBy:0.0];
            [trans concat];
            [curr draw:ytop];
            trans = [NSAffineTransform transform];
            [trans translateXBy:-xpos yBy:0.0];
            [trans concat];

            redrawLines = YES;
        }

        /* If symbol is in the current time, draw a shaded background */
        if ((start <= currentPulseTime) && (currentPulseTime < end)) {
            *x_shade = xpos;

            trans = [NSAffineTransform transform];
            [trans translateXBy:xpos yBy:0.0];
            [trans concat];
            [color setFill];
            NSBezierPath *path = [NSBezierPath bezierPathWithRect:
                 NSMakeRect(0, 0, curr.width, [self height]) ];
            [path fill];
            [curr draw:ytop];
            trans = [NSAffineTransform transform];
            [trans translateXBy:-xpos yBy:0.0];
            [trans concat];

            redrawLines = YES;
        }

        /* If either a gray or white background was drawn, we need to redraw
         * the horizontal staff lines, and redraw the stem of the previous chord.
         */
        if (redrawLines) {
            int line = 1;
            int y = ytop - LineWidth;

            trans = [NSAffineTransform transform];
            [trans translateXBy:xpos-2  yBy:0.0];
            [trans concat];

            NSBezierPath *path = [NSBezierPath bezierPath];
            [path setLineWidth:1];
            for (line = 1; line <= 5; line++) {
                [path moveToPoint:NSMakePoint(0, y)];
                [path lineToPoint:NSMakePoint(curr.width+4, y)];
                y += LineWidth + LineSpace;
            }
            [path stroke];
            trans = [NSAffineTransform transform];
            [trans translateXBy:-(xpos-2) yBy:0.0];
            [trans concat];

            if (prevChord != nil) {
                trans = [NSAffineTransform transform];
                [trans translateXBy:prev_xpos yBy:0.0];
                [trans concat];
                [prevChord draw:ytop];
                trans = [NSAffineTransform transform];
                [trans translateXBy:-prev_xpos yBy:0.0];
                [trans concat];
                if (showMeasures) {
                    [self drawMeasureNumbers];
                }
                if (lyrics != nil) {
                    [self drawLyrics];
                }
            }
        }

        if ([curr isKindOfClass:[ChordSymbol class]]) {
            ChordSymbol *chord = (ChordSymbol*)curr;
            if (chord.stem != nil && ![chord.stem receiver]) {
                prevChord = (ChordSymbol*) curr;
                prev_xpos = xpos;
            }
        }
        xpos += curr.width;
    }
}


/** Return the pulse time corresponding to the given point.
 *  Find the notes/symbols corresponding to the x position,
 *  and return the startTime (pulseTime) of the symbol.
 */
- (int)pulseTimeForPoint:(NSPoint)point {
    int xpos = keysigWidth;
    int pulseTime = startTime;
    for (int i = 0; i < [symbols count]; i++) {
        id<MusicSymbol> sym = [symbols get:i];
        pulseTime = sym.startTime;
        if (point.x <= xpos + sym.width) {
            return pulseTime;
        }
        xpos += sym.width;
    }
    return pulseTime;
}


- (void)dealloc {
    [symbols release];
    [clefsym release];
    [keys release];
    [lyrics release];
    [super dealloc];
}

- (NSString*)description {
    NSString *s = [NSString stringWithFormat:@"Staff clef=%@\n", [clefsym description]];
    s = [s stringByAppendingString:@"  Keys:\n"];
    for (int i = 0; i < [keys count]; i++) {
        AccidSymbol *a = [keys get:i];
        s = [s stringByAppendingString:@"    "];
        s = [s stringByAppendingString:[a description]];
        s = [s stringByAppendingString:@"\n"]; 
    }
    s = [s stringByAppendingString:@"  Symbols:\n"];
    for (int i = 0; i < [symbols count]; i++) {
        id sym = [symbols get:i];
        s = [s stringByAppendingString:@"    "];
        s = [s stringByAppendingString:[sym description]];
        s = [s stringByAppendingString:@"\n"];
    }
    s = [s stringByAppendingString:@"End Staff\n"];
    return s;
}

@end


