/*
 * Copyright (c) 2009-2012 Madhav Vaidyanathan
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License version 2.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 */

#import "Piano.h"
#import "SheetMusic.h"

static int KeysPerOctave = 7;
static int MaxOctave = 7;

static int WhiteKeyWidth;  /** Width of a single white key */
static int WhiteKeyHeight; /** Height of a single white key */
static int BlackKeyWidth;  /** Width of a single black key */
static int BlackKeyHeight; /** Height of a single black key */
static int margin;         /** Margin at left and top */
static int BlackBorder;    /** The width of the black border around the keys */
static int blackKeyOffsets[10];  /** The x pixles of the black keys */

#define max(x, y) ((x) > (y) ? (x) : (y))
#define min(x, y) ((x) <= (y) ? (x) : (y))

/** @class Piano
 *
 * The Piano NSView is the panel at the top that displays the
 * piano, and highlights the piano notes during playback.
 * The main methods are:
 *
 * setMidiFile() - Set the Midi file to use for shading.  The Midi file
 *                 is needed to determine which notes to shade.
 *
 * shadeNotes() - Shade notes on the piano that occur at a given pulse time.
 *
 */
@implementation Piano

/** Initialize the Piano */
- (id)init {
    int screenwidth = [[NSScreen mainScreen] frame].size.width;
    screenwidth = screenwidth * 95/100;
    WhiteKeyWidth = (int)(screenwidth / (2.0 + KeysPerOctave * MaxOctave));
    if (WhiteKeyWidth % 2 != 0) {
        WhiteKeyWidth--;
    }
    margin = WhiteKeyWidth / 2;
    BlackBorder = WhiteKeyWidth / 2;
    WhiteKeyHeight = WhiteKeyWidth * 5;
    BlackKeyWidth = WhiteKeyWidth / 2;
    BlackKeyHeight = WhiteKeyHeight * 5 / 9;

    NSRect frame = NSMakeRect(0, 0, 
                              margin*2 + BlackBorder*2 + WhiteKeyWidth * KeysPerOctave * MaxOctave,
                              margin*2 + BlackBorder*3 + WhiteKeyHeight);
    self = [super initWithFrame:frame];
    [self setAutoresizingMask:NSViewWidthSizable];
    notes = nil;

    int nums[] = {
        WhiteKeyWidth - BlackKeyWidth/2 - 1,
        WhiteKeyWidth + BlackKeyWidth/2 - 1,
        2*WhiteKeyWidth - BlackKeyWidth/2,
        2*WhiteKeyWidth + BlackKeyWidth/2,
        4*WhiteKeyWidth - BlackKeyWidth/2 - 1,
        4*WhiteKeyWidth + BlackKeyWidth/2 - 1,
        5*WhiteKeyWidth - BlackKeyWidth/2,
        5*WhiteKeyWidth + BlackKeyWidth/2,
        6*WhiteKeyWidth - BlackKeyWidth/2,
        6*WhiteKeyWidth + BlackKeyWidth/2
    };
    for (int i = 0; i < 10; i++) {
        blackKeyOffsets[i] = nums[i];
    }

    gray1 = [NSColor colorWithDeviceRed:16/255.0 green:16/255.0 blue:16/255.0 alpha:1.0];
    gray2 = [NSColor colorWithDeviceRed:90/255.0 green:90/255.0 blue:90/255.0 alpha:1.0];
    gray3 = [NSColor colorWithDeviceRed:200/255.0 green:200/255.0 blue:200/255.0 alpha:1.0];

    gray1 = [gray1 retain];
    gray2 = [gray2 retain];
    gray3 = [gray3 retain];

    shadeColor  = [NSColor colorWithDeviceRed:210/255.0
                   green:205/255.0 blue:220/255.0 alpha:1.0];
    shadeColor = [shadeColor retain];
    shade2Color = [NSColor colorWithDeviceRed:150/255.0
                   green:200/255.0 blue:220/255.0 alpha:1.0];
    shade2Color = [shade2Color retain];

    showNoteLetters = NoteNameNone;
    return self;
}


/** Set the MidiFile to use.
 *  Save the list of midi notes. Each midi note includes the note Number
 *  and StartTime (in pulses), so we know which notes to shade given the
 *  current pulse time.
 */
- (void)setMidiFile:(MidiFile*)midifile withOptions:(MidiOptions*)options {
    [notes release]; notes = nil;
    useTwoColors = NO;
    if (midifile == nil) {
        return;
    }

    maxShadeDuration = midifile.time.quarter * 2;
    Array *tracks = [midifile changeMidiNotes:options];
    MidiTrack *track = [MidiFile combineToSingleTrack:tracks];
    notes = [track.notes retain];

    /* We want to know which track the note came from.
     * Use the 'channel' field to store the track.
     */
    for (int tracknum = 0; tracknum < [tracks count]; tracknum++) {
        MidiTrack *t = [tracks get:tracknum];
        for (int i = 0; i < [t.notes count]; i++) {
            MidiNote *note = [t.notes get:i];
            note.channel = tracknum;
        }
    }

    /* When we have exactly two tracks, we assume this is a piano song,
     * and we use different colors for highlighting the left hand and
     * right hand notes.
     */
    useTwoColors = NO;
    if ([tracks count] == 2) {
        useTwoColors = YES;
    }

    showNoteLetters = options.showNoteLetters;
    [self display];
}

/** Set the colors to use for shading */
- (void)setShade:(NSColor*)s1 andShade2:(NSColor*)s2 {
    [shadeColor release];
    [shade2Color release];
    shadeColor = [s1 retain];
    shade2Color = [s2 retain];
}

/** Draw a line with the given color */
static void drawLine(NSColor *color, int x1, int y1, int x2, int y2) {
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path setLineWidth:1];
    [path moveToPoint:NSMakePoint(x1, y1)];
    [path lineToPoint:NSMakePoint(x2, y2)];
    [color setStroke];
    [path stroke];
    [[NSColor blackColor] setStroke];
}

/** Draw the outline of a 12-note (7 white note) piano octave */
- (void)drawOctaveOutline {
    int right = WhiteKeyWidth * KeysPerOctave;

    /* Draw the bounding rectangle, from C to B */
    drawLine(gray1, 0, 0, 0, WhiteKeyHeight);
    drawLine(gray1, right, 0, right, WhiteKeyHeight);
    // drawLine(gray1, 0, WhiteKeyHeight, right, WhiteKeyHeight);

    drawLine(gray3, right-1, 0, right-1, WhiteKeyHeight);
    drawLine(gray3, 1, 0, 1, WhiteKeyHeight);

    /* Draw the line between E and F */
    drawLine(gray1, 3*WhiteKeyWidth, 0, 3*WhiteKeyWidth, WhiteKeyHeight);
    drawLine(gray3, 3*WhiteKeyWidth - 1, 0, 3*WhiteKeyWidth - 1, WhiteKeyHeight);
    drawLine(gray3, 3*WhiteKeyWidth + 1, 0, 3*WhiteKeyWidth + 1, WhiteKeyHeight);

    /* Draw the sides/bottom of the black keys */
    for (int i = 0; i < 10; i += 2) {
        int x1 = blackKeyOffsets[i];
        int x2 = blackKeyOffsets[i+1];

        drawLine(gray1, x1, 0, x1, BlackKeyHeight);
        drawLine(gray1, x2, 0, x2, BlackKeyHeight);
        drawLine(gray1, x1, BlackKeyHeight, x2, BlackKeyHeight);

        drawLine(gray2, x1-1, 0, x1-1, BlackKeyHeight+1);
        drawLine(gray2, x2+1, 0, x2+1, BlackKeyHeight+1);
        drawLine(gray2, x1-1, BlackKeyHeight+1, x2+1, BlackKeyHeight+1);

        drawLine(gray3, x1-2, 0, x1-2, BlackKeyHeight+2);
        drawLine(gray3, x2+2, 0, x2+2, BlackKeyHeight+2);
        drawLine(gray3, x1-2, BlackKeyHeight+2, x2+2, BlackKeyHeight+2);
    }

    /* Draw the bottom-half of the white keys */
    for (int i = 1; i < KeysPerOctave; i++) {
        if (i == 3) {
            continue;  /* We draw the line between E and F above */
        }
        drawLine(gray1, i*WhiteKeyWidth, BlackKeyHeight, i*WhiteKeyWidth, WhiteKeyHeight);
        drawLine(gray2, i*WhiteKeyWidth - 1, BlackKeyHeight+1, i*WhiteKeyWidth - 1, WhiteKeyHeight);
        drawLine(gray3, i*WhiteKeyWidth + 1, BlackKeyHeight+1, i*WhiteKeyWidth + 1, WhiteKeyHeight);

    }
}

/** Draw an outline of the piano for 7 octaves */
- (void)drawOutline {
    NSAffineTransform *trans;

    for (int octave = 0; octave < MaxOctave; octave++) {
        trans = [NSAffineTransform transform];
        [trans translateXBy:(octave * WhiteKeyWidth * KeysPerOctave) yBy:0];
        [trans concat];
        [self drawOctaveOutline];
        trans = [NSAffineTransform transform];
        [trans translateXBy:-(octave * WhiteKeyWidth * KeysPerOctave) yBy:0];
        [trans concat];
    }
}

/* Draw the Black keys */
- (void)drawBlackKeys {
    NSAffineTransform *trans;
    NSRect rect;
    for (int octave = 0; octave < MaxOctave; octave++) {
        trans = [NSAffineTransform transform];
        [trans translateXBy:(octave * WhiteKeyWidth * KeysPerOctave) yBy:0];
        [trans concat];
        for (int i = 0; i < 10; i += 2) {
            int x1 = blackKeyOffsets[i];
            int x2 = blackKeyOffsets[i+1];
            rect = NSMakeRect(x1, 0, BlackKeyWidth, BlackKeyHeight);
            [self fillRect:rect withColor:gray1];
            rect = NSMakeRect(x1+1, BlackKeyHeight - BlackKeyHeight/8,
                              BlackKeyWidth-2, BlackKeyHeight/8);
            [self fillRect:rect withColor:gray2];
        }

        trans = [NSAffineTransform transform];
        [trans translateXBy:-(octave * WhiteKeyWidth * KeysPerOctave) yBy:0];
        [trans concat];
    }
}


/* Draw the black border area surrounding the piano keys.
 * Also, draw gray outlines at the bottom of the white keys.
 */
- (void)drawBlackBorder {
    NSAffineTransform *trans;
    NSRect rect;

    int PianoWidth = WhiteKeyWidth * KeysPerOctave * MaxOctave;
    rect = NSMakeRect(margin, margin, PianoWidth + BlackBorder*2, BlackBorder-2);
    [self fillRect:rect withColor:gray1];
    rect = NSMakeRect(margin, margin, BlackBorder, WhiteKeyHeight + BlackBorder*3);
    [self fillRect:rect withColor:gray1];
    rect = NSMakeRect(margin, margin + BlackBorder + WhiteKeyHeight,
                      BlackBorder*2 + PianoWidth, BlackBorder*2);
    [self fillRect:rect withColor:gray1];
    rect = NSMakeRect(margin + BlackBorder + PianoWidth, margin,
                      BlackBorder, WhiteKeyHeight + BlackBorder*3);
    [self fillRect:rect withColor:gray1];

    drawLine(gray2, margin + BlackBorder, margin + BlackBorder - 1,
                    margin + BlackBorder + PianoWidth, margin + BlackBorder - 1);

    /* Draw the gray bottoms of the white keys */
    trans = [NSAffineTransform transform];
    [trans translateXBy:(margin + BlackBorder) yBy:(margin + BlackBorder)];
    [trans concat];
    for (int i = 0; i < KeysPerOctave * MaxOctave; i++) {
        rect = NSMakeRect(i*WhiteKeyWidth + 1, WhiteKeyHeight + 2,
                          WhiteKeyWidth - 2, BlackBorder/2);
        [self fillRect:rect withColor:gray2];
    }
    trans = [NSAffineTransform transform];
    [trans translateXBy:-(margin + BlackBorder) yBy:-(margin + BlackBorder)];
    [trans concat];
}


/** Draw the note letters (A, A#, Bb, etc) underneath each white note */
- (void)drawNoteLetters {
    NSArray *letters;
    if (showNoteLetters == NoteNameLetter) {
        letters = [NSArray arrayWithObjects:
          @"C", @"D", @"E", @"F", @"G", @"A", @"B", nil
        ];
    }
    else if (showNoteLetters == NoteNameFixedNumber) {
        letters = [NSArray arrayWithObjects:
          @"1", @"3", @"5", @"6", @"8", @"10", @"12", nil
        ];
    }
    else {
        return;
    }
    NSGraphicsContext *gc = [NSGraphicsContext currentContext];
    [gc setShouldAntialias:YES];
 
    /* Set the font attribute */
    NSFont *font = [NSFont boldSystemFontOfSize:12.0];
    NSArray *keys = [NSArray arrayWithObjects:
                     NSFontAttributeName, NSForegroundColorAttributeName, nil];
    NSArray *values = [NSArray arrayWithObjects:font, [NSColor whiteColor], nil];
    NSDictionary *dict = [NSDictionary dictionaryWithObjects:values forKeys:keys];

    NSAffineTransform *trans;
    
    trans = [NSAffineTransform transform];
    [trans translateXBy:(margin + BlackBorder) yBy:(margin + BlackBorder)];
    [trans concat];
    for (int octave = 0; octave < MaxOctave; octave++) {
        for (int i = 0; i < KeysPerOctave; i++) {
            NSPoint point = NSMakePoint((octave*KeysPerOctave + i) * WhiteKeyWidth + WhiteKeyWidth/3,
                                        WhiteKeyHeight + BlackBorder * 3/4);
            NSString *letter = [letters objectAtIndex:i];
            [letter drawAtPoint:point withAttributes:dict];
        }
    }
    trans = [NSAffineTransform transform];
    [trans translateXBy:-(margin + BlackBorder) yBy:-(margin + BlackBorder)];
    [trans concat];
    [[NSColor blackColor] set];
    [gc setShouldAntialias:NO];
}


/** Draw the Piano */
- (void)drawRect:(NSRect)rect {
    NSGraphicsContext *gc = [NSGraphicsContext currentContext];
    [gc setShouldAntialias:NO];

    /* Draw a border line at the top */
    drawLine(gray1, 0, 0, [self frame].size.width, 0);

    NSAffineTransform *trans;
    trans = [NSAffineTransform transform];
    [trans translateXBy:(margin + BlackBorder) yBy:(margin + BlackBorder)];
    [trans concat];

    NSRect backrect = NSMakeRect(0, 0, 
                                 WhiteKeyWidth * KeysPerOctave * MaxOctave, 
                                 WhiteKeyHeight);
    [self fillRect:backrect withColor:[NSColor whiteColor]];
    [[NSColor blackColor] setFill];
    [self drawBlackKeys];
    [self drawOutline];

    trans = [NSAffineTransform transform];
    [trans translateXBy:-(margin + BlackBorder) yBy:-(margin + BlackBorder)];
    [trans concat];

    [self drawBlackBorder];
    if (showNoteLetters != NoteNameNone) {
        [self drawNoteLetters];
    }
    [gc setShouldAntialias:YES];
}


/** Fill in a rectangle with the given color */
- (void)fillRect:(NSRect)rect withColor:(NSColor*)color {
    [color setFill];
    NSBezierPath *path = [NSBezierPath bezierPathWithRect:rect];
    [path fill];
}

/* Shade the given note with the given brush.
 * We only draw notes from notenumber 24 to 96.
 * (Middle-C is 60).
 */
- (void)shadeOneNote:(int)notenumber withColor:(NSColor*)color {
    int octave = notenumber / 12;
    int notescale = notenumber % 12;

    octave -= 2;
    if (octave < 0 || octave >= MaxOctave)
        return;

    NSAffineTransform *trans;
    trans = [NSAffineTransform transform];
    [trans translateXBy:(octave * WhiteKeyWidth * KeysPerOctave) yBy:0];
    [trans concat];

    int x1, x2, x3;

    int bottomHalfHeight = WhiteKeyHeight - (BlackKeyHeight+3) - 1;

    /* notescale goes from 0 to 11, from C to B. */
    switch (notescale) {
    case 0: /* C */
        x1 = 2;
        x2 = blackKeyOffsets[0] - 2;
        [self fillRect:NSMakeRect(x1, 0, x2 - x1, BlackKeyHeight+3) withColor:color];
        [self fillRect:NSMakeRect(x1, BlackKeyHeight+3, WhiteKeyWidth-3, bottomHalfHeight) withColor:color];
        break;
    case 1: /* C# */
        x1 = blackKeyOffsets[0];
        x2 = blackKeyOffsets[1];
        [self fillRect:NSMakeRect(x1, 0, x2 - x1, BlackKeyHeight) withColor:color];
        if (color == gray1) {
            [self fillRect:NSMakeRect(x1+1, BlackKeyHeight - BlackKeyHeight/8,
                            BlackKeyWidth-2, BlackKeyHeight/8) 
                            withColor:gray2];
        }
        break;
    case 2: /* D */
        x1 = WhiteKeyWidth + 2;
        x2 = blackKeyOffsets[1] + 3;
        x3 = blackKeyOffsets[2] - 2;
        [self fillRect:NSMakeRect(x2, 0, x3 - x2, BlackKeyHeight+3) withColor:color];
        [self fillRect:NSMakeRect(x1, BlackKeyHeight+3, WhiteKeyWidth-3, bottomHalfHeight) withColor:color];
        break;
    case 3: /* D# */
        x1 = blackKeyOffsets[2];
        x2 = blackKeyOffsets[3];
        [self fillRect:NSMakeRect(x1, 0, BlackKeyWidth, BlackKeyHeight) withColor:color];
        if (color == gray1) {
            [self fillRect:NSMakeRect(x1+1, BlackKeyHeight - BlackKeyHeight/8,
                                       BlackKeyWidth-2, BlackKeyHeight/8) 
                                       withColor:gray2];
        }
        break;
    case 4: /* E */
        x1 = WhiteKeyWidth * 2 + 2;
        x2 = blackKeyOffsets[3] + 3;
        x3 = WhiteKeyWidth * 3 - 1;
        [self fillRect:NSMakeRect(x2, 0, x3 - x2, BlackKeyHeight+3) withColor:color];
        [self fillRect:NSMakeRect(x1, BlackKeyHeight+3, WhiteKeyWidth-3, bottomHalfHeight) withColor:color];
        break;
    case 5: /* F */
        x1 = WhiteKeyWidth * 3 + 2;
        x2 = blackKeyOffsets[4] - 2;
        x3 = WhiteKeyWidth * 4 - 2;
        [self fillRect:NSMakeRect(x1, 0, x2 - x1, BlackKeyHeight+3) withColor:color];
        [self fillRect:NSMakeRect(x1, BlackKeyHeight+3, WhiteKeyWidth-3, bottomHalfHeight) withColor:color];
        break;
    case 6: /* F# */
        x1 = blackKeyOffsets[4];
        x2 = blackKeyOffsets[5];
        [self fillRect:NSMakeRect(x1, 0, BlackKeyWidth, BlackKeyHeight) withColor:color];
        if (color == gray1) {
            [self fillRect:NSMakeRect(x1+1, BlackKeyHeight - BlackKeyHeight/8,
                                       BlackKeyWidth-2, BlackKeyHeight/8) 
                                       withColor:gray2];
        }
        break;
    case 7: /* G */
        x1 = WhiteKeyWidth * 4 + 2;
        x2 = blackKeyOffsets[5] + 3;
        x3 = blackKeyOffsets[6] - 2;
        [self fillRect:NSMakeRect(x2, 0, x3 - x2, BlackKeyHeight+3) withColor:color];
        [self fillRect:NSMakeRect(x1, BlackKeyHeight+3, WhiteKeyWidth-3, bottomHalfHeight) withColor:color];
        break;
    case 8: /* G# */
        x1 = blackKeyOffsets[6];
        x2 = blackKeyOffsets[7];
        [self fillRect:NSMakeRect(x1, 0, BlackKeyWidth, BlackKeyHeight) withColor:color];
        if (color == gray1) {
            [self fillRect:NSMakeRect(x1+1, BlackKeyHeight - BlackKeyHeight/8,
                                       BlackKeyWidth-2, BlackKeyHeight/8) 
                                       withColor:gray2];
        }
        break;
    case 9: /* A */
        x1 = WhiteKeyWidth * 5 + 2;
        x2 = blackKeyOffsets[7] + 3;
        x3 = blackKeyOffsets[8] - 2;
        [self fillRect:NSMakeRect(x2, 0, x3 - x2, BlackKeyHeight+3) withColor:color];
        [self fillRect:NSMakeRect(x1, BlackKeyHeight+3, WhiteKeyWidth-3, bottomHalfHeight) withColor:color];
        break;
    case 10: /* A# */
        x1 = blackKeyOffsets[8];
        x2 = blackKeyOffsets[9];
        [self fillRect:NSMakeRect(x1, 0, BlackKeyWidth, BlackKeyHeight) withColor:color];
        if (color == gray1) {
            [self fillRect:NSMakeRect(x1+1, BlackKeyHeight - BlackKeyHeight/8,
                                       BlackKeyWidth-2, BlackKeyHeight/8) 
                                       withColor:gray2];
        }
        break;
    case 11: /* B */
        x1 = WhiteKeyWidth * 6 + 2;
        x2 = blackKeyOffsets[9] + 3;
        x3 = WhiteKeyWidth * KeysPerOctave - 1;
        [self fillRect:NSMakeRect(x2, 0, x3 - x2, BlackKeyHeight+3) withColor:color];
        [self fillRect:NSMakeRect(x1, BlackKeyHeight+3, WhiteKeyWidth-3, bottomHalfHeight) withColor:color];
        break;
    default:
        break;
    }
    trans = [NSAffineTransform transform];
    [trans translateXBy:-(octave * WhiteKeyWidth * KeysPerOctave) yBy:0];
    [trans concat];

}

/** Find the symbol with the startTime closest to the given time.
 *  Return the index of the symbol.  Use a binary search method.
 */
- (int)findClosestStartTime:(int)pulseTime {
    int left = 0;
    int right = [notes count] - 1;

    while (right - left > 1) {
        int i = (right + left)/2;
        if ([[notes get:left] startTime] == pulseTime)
            break;
        else if ([[notes get:i] startTime] <= pulseTime)
            left = i;
        else
            right = i;
    }
    while (left >= 1 && ([[notes get:left-1] startTime] == [[notes get:left] startTime])) {
        left--;
    }
    return left;
}


/** Return the next startTime that occurs after the MidiNote
 *  at offset i.  If all the subsequent notes have the same
 *  startTime, then return the largest endTime.
 */
- (int)nextStartTime:(int)i {
	MidiNote *note = [notes get:i];
    int start = note.startTime;
    int end = note.endTime;

    while (i < [notes count]) {
		note = [notes get:i];
        if (note.startTime > start) {
            return note.startTime;
        }
        int end2 = note.endTime;
        end = max(end, end2);
        i++;
    }
    return end;
}


/** Return the next startTime that occurs after the MidiNote
 *  at offset i, that is also in the same track/channel.
 */
- (int)nextStartTimeSameTrack:(int)i {
	MidiNote *note = [notes get:i];
    int start = note.startTime;
    int end = note.endTime;
    int track = note.channel;

    while (i < [notes count]) {
		note = [notes get:i];
        if (note.channel != track) {
            i++;
            continue;
        }
        if (note.startTime > start) {
            return note.startTime;
        }
        int end2 = note.endTime;
        end = max(end, end2);
        i++;
    }
    return end;
}


/** Find the Midi notes that occur in the current time.
 *  Shade those notes on the piano displayed.
 *  Un-shade the those notes played in the previous time.
 */
- (void)shadeNotes:(int)currentPulseTime withPrev:(int)prevPulseTime {
    if (notes == nil || [notes count] == 0) {
        return;
    }
    if (![self canDraw]) {
        return;
    }
    [self lockFocus];

    NSGraphicsContext *gc = [NSGraphicsContext currentContext];
    [gc setShouldAntialias:NO];

    NSAffineTransform *trans = [NSAffineTransform transform];
    [trans translateXBy:(margin + BlackBorder) yBy:(margin + BlackBorder)];
    [trans concat];

    /* Loop through the Midi notes.
     * Unshade notes where startTime <= prevPulseTime < next startTime
     * Shade notes where startTime <= currentPulseTime < next startTime
     */
    int lastShadedIndex = [self findClosestStartTime:(prevPulseTime - maxShadeDuration*2)];
    for (int i = lastShadedIndex; i < [notes count]; i++) {
		MidiNote *note = [notes get:i];
        int start = note.startTime;
        int end = note.endTime;
        int notenumber = note.number;

        int nextStart = [self nextStartTime:i];
        int nextStartTrack = [self nextStartTimeSameTrack:i];
        end = max(end, nextStartTrack);
        end = min(end, start + maxShadeDuration-1);

        /* If we've past the previous and current times, we're done. */
        if ((start > prevPulseTime) && (start > currentPulseTime)) {
            break;
        }

        /* If shaded notes are the same, we're done */
        if ((start <= currentPulseTime) && (currentPulseTime < nextStart) && 
            (currentPulseTime < end) && 
            (start <= prevPulseTime) && (prevPulseTime < nextStart) &&
            (prevPulseTime < end)) {
            break;
        }

        /* If the note is in the current time, shade it */
        if ((start <= currentPulseTime) && (currentPulseTime < end)) {
            if (useTwoColors) {
                if (note.channel == 1) {
                    [self shadeOneNote:notenumber withColor:shade2Color];
                }
                else {
                    [self shadeOneNote:notenumber withColor:shadeColor];
                }
            }
            else {
                [self shadeOneNote:notenumber withColor:shadeColor];
            }
        }

        /* If the note is in the previous time, un-shade it, draw it white. */
        else if ((start <= prevPulseTime) && (prevPulseTime < end)) {
            int num = notenumber % 12;
            if (num == 1 || num == 3 || num == 6 || num == 8 || num == 10) {
                [self shadeOneNote:notenumber withColor:gray1] ;
            }
            else {
                [self shadeOneNote:notenumber withColor:[NSColor whiteColor]];
            }
        }
    }
    trans = [NSAffineTransform transform];
    [trans translateXBy:-(margin + BlackBorder) yBy:-(margin + BlackBorder)];
    [trans concat];
    [[NSGraphicsContext currentContext] flushGraphics];
    [[NSGraphicsContext currentContext] setShouldAntialias:NO];
    [self unlockFocus];
}

/** Use flipped coordinates */
- (BOOL)isFlipped {
    return YES;
}

- (void)dealloc {
    [notes release]; notes = nil;
    [gray1 release]; gray1 = nil;
    [gray2 release]; gray2 = nil;
    [gray3 release]; gray3 = nil;
    [shadeColor release]; shadeColor = nil;
    [shade2Color release]; shade2Color = nil;
    [super dealloc];
}

@end


