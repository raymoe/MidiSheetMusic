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

#import "ChordSymbol.h"
#import "ClefSymbol.h"
#import "SheetMusic.h"

#define max(x,y) ((x) > (y) ? (x) : (y))

static const char* s2c(id obj) {
    NSString *s = [obj description]; 
    const char *out = [s  cStringUsingEncoding:NSUTF8StringEncoding];
    return out;
}

/** @class ChordSymbol
 * A chord symbol represents a group of notes that are played at the same
 * time.  A chord includes the notes, the accidental symbols for each
 * note, and the stem (or stems) to use.  A single chord may have two 
 * stems if the notes have different durations (e.g. if one note is a
 * quarter note, and another is an eighth note).
 */

@implementation ChordSymbol


/** Create a new Chord Symbol from the given list of midi notes.
 * All the midi notes will have the same start time.  Use the
 * key signature to get the white key and accidental symbol for
 * each note.  Use the time signature to calculate the duration
 * of the notes. Use the clef when drawing the chord.
 */
- (id)initWithNotes:(Array*)midinotes andKey:(KeySignature*)key
     andTime:(TimeSignature*)time andClef:(int)c andSheet:(void*)s {

    int i;

    hasTwoStems = NO;
    clef = c;
    sheetmusic = s;

	MidiNote *midinote = [midinotes get:0];
    starttime = midinote.startTime;
    endtime = midinote.endTime;
    for (i = 0; i < [midinotes count]; i++) {
        if (i > 1) {
            /* notes should already be sorted in increasing order (by number) */
            assert([[midinotes get:i] number] >= [[midinotes get:i-1] number]);
        }
        endtime = max(endtime, [(MidiNote *)[midinotes get:i] endTime]);
    }

    notedata_len = [midinotes count];
    if (notedata_len > 20) {
        notedata_len = 20;
    }
    [self createNoteData:midinotes withKey:key andTime:time];
    [self createAccidSymbols];

    /* Find out how many stems we need (1 or 2) */
    NoteDuration dur1 = notedata[0].duration;
    NoteDuration dur2 = dur1;
    int change = -1;
    for (i = 0; i < notedata_len; i++) {
        dur2 = notedata[i].duration;
        if (dur1 != dur2) {
            change = i;
            break;
        }
    }

    if (dur1 != dur2) {
        /* We have notes with different durations.  So we will need
         * two stems.  The first stem points down, and contains the
         * bottom note up to the note with the different duration.
         *
         * The second stem points up, and contains the note with the
         * different duration up to the top note.
         */
        hasTwoStems = YES;
        stem1 = [[Stem alloc] initWithBottom:notedata[0].whitenote
                              andTop:notedata[change-1].whitenote
                              andDuration:dur1
                              andDirection:StemDown
                              andOverlap:[ChordSymbol notesOverlap:notedata
                                                       withStart:0 
                                                       andEnd:change]
                ];

        stem2 = [[Stem alloc] initWithBottom:notedata[change].whitenote
                              andTop:notedata[notedata_len-1].whitenote
                              andDuration:dur2
                              andDirection:StemUp
                              andOverlap:[ChordSymbol notesOverlap:notedata 
                                                       withStart:change 
                                                       andEnd: notedata_len]
                ];

    }
    else {
        /* All notes have the same duration, so we only need one stem. */
        int direction = [ChordSymbol stemDirection:notedata[0].whitenote
                                     withTop:notedata[notedata_len-1].whitenote
                                     andClef:clef ];

        stem1 = [[Stem alloc] initWithBottom:notedata[0].whitenote
                              andTop:notedata[notedata_len-1].whitenote
                              andDuration:dur1
                              andDirection:direction
                              andOverlap:[ChordSymbol notesOverlap:notedata
                                                       withStart:0 
                                                       andEnd:notedata_len]
                ];

        stem2 = nil;
    }

    /* For whole notes, no stem is drawn. */
    if (dur1 == Whole) {
        [stem1 release];
        stem1 = nil;
    }
    if (dur2 == Whole) {
        [stem2 release];
        stem2 = nil;
    }
    width = self.minWidth;
    assert(width > 0);
    return self;
}


/** Given the raw midi notes (the note number and duration in pulses),
 * calculate the following note data:
 * - The white key
 * - The accidental (if any)
 * - The note duration (half, quarter, eighth, etc)
 * - The side it should be drawn (left or side)
 * By default, notes are drawn on the left side.  However, if two notes
 * overlap (like A and B) you cannot draw the next note directly above it.
 * Instead you must shift one of the notes to the right.
 *
 * The KeySignature is used to determine the white key and accidental.
 * The TimeSignature is used to determine the duration.
 */
- (void)createNoteData:(Array*)midinotes withKey:(KeySignature*)key
       andTime:(TimeSignature*)time {

    memset(notedata, 0, sizeof(NoteData) * 20);
    notedata_len = [midinotes count];
    if (notedata_len > 20) {
        notedata_len = 20;
    }
    NoteData *prev = NULL;

    for (int i = 0; i < notedata_len; i++) {
        MidiNote *midi = [midinotes get:i];
        NoteData *note = &(notedata[i]);
        note->number = midi.number;
        note->leftside = YES;
        note->whitenote = [[key getWhiteNote:midi.number] retain];
        note->duration = [time getNoteDuration:(midi.endTime - midi.startTime)];
        note->accid = [key getAccidentalForNote:midi.number 
                                 andMeasure:(midi.startTime / time.measure)];

        if (i > 0 && ( ( [note->whitenote dist:prev->whitenote]) == 1)) {
            /* This note overlaps with the previous note.
             * Change the side of this note.
             */
            if (prev->leftside) {
                note->leftside = NO;
            } else {
                note->leftside = YES;
            }
        } else {
            note->leftside = YES;
        }
        prev = note;
    }
}


/** Given the note data (the white keys and accidentals), create 
 * the Accidental Symbols and return them.
 */
- (void)createAccidSymbols {
    int count = 0;
    int i, n;
    for (i = 0; i < notedata_len; i++) {
        if (notedata[i].accid != AccidNone) {
            count++;
        }
    }
    accidsymbols = [[Array new:count] retain];
    for (n = 0; n < notedata_len; n++) {
        if (notedata[n].accid != AccidNone) {
            AccidSymbol *a = [[AccidSymbol alloc] initWithAccid:notedata[n].accid 
                              andNote:(notedata[n].whitenote) andClef:clef ];
            [accidsymbols add:a];
            [a release];
        }
    }
}

/** Calculate the stem direction (Up or down) based on the top and
 * bottom note in the chord.  If the average of the notes is above
 * the middle of the staff, the direction is down.  Else, the
 * direction is up.
 */
+(int)stemDirection:(WhiteNote*)bottom withTop:(WhiteNote*)top andClef:(int)clef {
    WhiteNote* middle;
    if (clef == Clef_Treble)
        middle = [WhiteNote allocWithLetter:WhiteNote_B andOctave:5];
    else
        middle = [WhiteNote allocWithLetter:WhiteNote_D andOctave:3];

    int dist = [middle dist:bottom] + [middle dist:top];
    if (dist >= 0)
        return StemUp;
    else 
        return StemDown;
}

/** Return whether any of the notes in notedata (between start and
 * end indexes) overlap. This is needed by the Stem class to
 * determine the position of the stem (left or right of notes).
 */
+(BOOL)notesOverlap:(NoteData*)notedata withStart:(int)start andEnd:(int)end {
    for (int i = start; i < end; i++) {
        if (!notedata[i].leftside) {
            return YES;
        }
    }
    return NO;
}


/** Get the time (in pulses) this symbol occurs at.
 * This is used to determine the measure this symbol belongs to.
 */
- (int)startTime {
    return starttime;
}

/** Get the end time (in pulses) of the longest note in the chord.
 * Used to determine whether two adjacent chords can be joined
 * by a stem.
 */
- (int)endTime {
    return endtime;
}

/** Return the clef this chord is drawn in. */
- (int)clef {
    return clef;
}

/** Return true if this chord has two stems */
- (BOOL)hasTwoStems {
    return hasTwoStems;
}

/* Return the stem will the smallest duration.  This property
 * is used when making chord pairs (chords joined by a horizontal
 * beam stem). The stem durations must match in order to make
 * a chord pair.  If a chord has two stems, we always return
 * the one with a smaller duration, because it has a better 
 * chance of making a pair.
 */
- (Stem*)stem {
    if (stem1 == nil) { return stem2; }
    else if (stem2 == nil) { return stem1; }
    else if (stem1.duration < stem2.duration) { return stem1; }
    else { return stem2; }
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

/** Get the minimum width (in pixels) needed to draw this symbol.
 *
 * The accidental symbols can be drawn above one another as long
 * as they don't overlap (they must be at least 6 notes apart).
 * If two accidental symbols do overlap, the accidental symbol
 * on top must be shifted to the right.  So the width needed for
 * accidental symbols depends on whether they overlap or not.
 *
 * If we are also displaying the letters, include extra width.
 */
- (int)minWidth {
    /* The width needed for the note circles */
    int result = 2 * NoteHeight + NoteHeight * 3/4;

    if ([accidsymbols count] > 0) {
        AccidSymbol *first = [accidsymbols get:0];
        result += first.minWidth;
        for (int i = 1; i < [accidsymbols count]; i++) {
            AccidSymbol *accid = [accidsymbols get:i];
            AccidSymbol *prev = [accidsymbols get:(i-1)];
            if ([accid.note dist:prev.note] < 6) {
                result += accid.minWidth;
            }
        }
    }
    SheetMusic *sheet = (SheetMusic*)sheetmusic;
    if (sheet != nil && [sheet showNoteLetters] != NoteNameNone) {
        result += 8;
    }
    return result;
}


/** Get the number of pixels this symbol extends above the staff. Used
 *  to determine the minimum height needed for the staff (Staff:findBounds).
 */
- (int)aboveStaff {
    /* Find the topmost note in the chord */
    WhiteNote *topnote = notedata[ notedata_len-1 ].whitenote;

   /* The stem.End is the note position where the stem ends.
    * Check if the stem end is higher than the top note.
    */
    if (stem1 != nil)
        topnote = [WhiteNote max:topnote and:[stem1 end]];
    if (stem2 != nil)
        topnote = [WhiteNote max:topnote and:[stem2 end]];

    int dist = [topnote dist:[WhiteNote top:clef]] * NoteHeight/2;
    int result = 0;
    if (dist > 0)
        result = dist;

    /* Check if any accidental symbols extend above the staff */
    int i;
    for (i = 0; i < [accidsymbols count]; i++) {
        AccidSymbol* symbol = [accidsymbols get:i];
        if (symbol.aboveStaff > result) {
            result = symbol.aboveStaff;
        }
    }
    return result;
}

/** Get the number of pixels this symbol extends below the staff. Used
 *  to determine the minimum height needed for the staff (Staff:findBounds).
 */
- (int) belowStaff {
    /* Find the bottom note in the chord */
    WhiteNote* bottomnote = notedata[0].whitenote;

    /* The stem.End is the note position where the stem ends.
     * Check if the stem end is lower than the bottom note.
     */
    if (stem1 != nil)
        bottomnote = [WhiteNote min:bottomnote and:[stem1 end]];
    if (stem2 != nil)
        bottomnote = [WhiteNote min:bottomnote and:[stem2 end]];

    int dist = [[WhiteNote bottom:clef] dist:bottomnote] * NoteHeight/2;

    int result = 0;
    if (dist > 0)
        result = dist;

    /* Check if any accidental symbols extend below the staff */
    int i;
    for (i = 0; i < [accidsymbols count]; i++) {
        AccidSymbol *symbol = [accidsymbols get:i]; 
        if (symbol.belowStaff > result) {
            result = symbol.belowStaff;
        }
    }
    return result;
}


/** Get the name for this note */
-(NSString*)noteNameFromNumber:(int)notenumber andWhiteNote:(WhiteNote*)whitenote {
    SheetMusic *sheet = (SheetMusic*)sheetmusic;
    int notename = [sheet showNoteLetters];
    if (notename == NoteNameLetter) {
        return [self letterFromNumber:notenumber andWhiteNote:whitenote];
    }
    else if (notename == NoteNameFixedDoReMi) {
        NSArray *fixedDoReMi = [NSArray arrayWithObjects:
            @"La", @"Li", @"Ti", @"Do", @"Di", @"Re", @"Ri", @"Mi", @"Fa", @"Fi", @"So", @"Si", nil
        ];
        int notescale = notescale_from_number(notenumber);
        return [fixedDoReMi objectAtIndex:notescale];
    }
    else if (notename == NoteNameMovableDoReMi) {
        NSArray *fixedDoReMi = [NSArray arrayWithObjects:
            @"La", @"Li", @"Ti", @"Do", @"Di", @"Re", @"Ri", @"Mi", @"Fa", @"Fi", @"So", @"Si", nil
        ];
        int mainscale = [[sheet mainkey] notescale];
        int diff = NoteScale_C - mainscale;
        notenumber += diff;
        if (notenumber < 0) {
            notenumber += 12;
        }
        int notescale = notescale_from_number(notenumber);
        return [fixedDoReMi objectAtIndex:notescale];
    }
    else if (notename == NoteNameFixedNumber) {
        NSArray *num = [NSArray arrayWithObjects:
            @"10", @"11", @"12", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", nil
        ];
        int notescale = notescale_from_number(notenumber);
        return [num objectAtIndex:notescale];
    }
    else if (notename == NoteNameMovableNumber) {
        NSArray *num = [NSArray arrayWithObjects:
            @"10", @"11", @"12", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", nil
        ];
        int mainscale = [[sheet mainkey] notescale];
        int diff = NoteScale_C - mainscale;
        notenumber += diff;
        if (notenumber < 0) {
            notenumber += 12;
        }
        int notescale = notescale_from_number(notenumber);
        return [num objectAtIndex:notescale];
    }
    else {
        return @"";
    }
}


/** Get the letter (A, A#, Bb) representing this note */
-(NSString*)letterFromNumber:(int)notenumber andWhiteNote:(WhiteNote*)whitenote {
    int notescale = notescale_from_number(notenumber);
    switch(notescale) {
        case NoteScale_A: return @"A";
        case NoteScale_B: return @"B";
        case NoteScale_C: return @"C";
        case NoteScale_D: return @"D";
        case NoteScale_E: return @"E";
        case NoteScale_F: return @"F";
        case NoteScale_G: return @"G";
        case NoteScale_Asharp:
            if (whitenote.letter == WhiteNote_A)
                return @"A#";
            else
                return @"Bb";
        case NoteScale_Csharp:
            if (whitenote.letter == WhiteNote_C)
                return @"C#";
            else
                return @"Db";
        case NoteScale_Dsharp:
            if (whitenote.letter == WhiteNote_D)
                return @"D#";
            else
                return @"Eb";
        case NoteScale_Fsharp:
            if (whitenote.letter == WhiteNote_F)
                return @"F#";
            else
                return @"Gb";
        case NoteScale_Gsharp:
            if (whitenote.letter == WhiteNote_G)
                return @"G#";
            else
                return @"Ab";
        default:
            return @"";
    }
}


/** Draw the Chord Symbol:
 * - Draw the accidental symbols.
 * - Draw the black circle notes.
 * - Draw the stems.
 * @param ytop The ylocation (in pixels) where the top of the staff starts.
 */
- (void)draw:(int)ytop {
    NSAffineTransform *trans;

    /* Align the chord to the right */
    trans = [NSAffineTransform transform];
    [trans translateXBy:(width - self.minWidth) yBy:0.0];
    [trans concat];

    /* Draw the accidentals */
    WhiteNote *topstaff = [WhiteNote top:clef];
    int xpos = [self drawAccid:ytop];

    /* Draw the notes */
    trans = [NSAffineTransform transform];
    [trans translateXBy:xpos yBy:0.0];
    [trans concat];
    [self drawNotes:ytop topStaff:topstaff];
    SheetMusic *sheet = (SheetMusic*)sheetmusic;
    if (sheet != nil && [sheet showNoteLetters] != 0) {
        [self drawNoteLetters:ytop topStaff:topstaff];
    }

    /* Draw the stems */
    if (stem1 != nil)
        [stem1 draw:ytop topStaff:topstaff];
    if (stem2 != nil)
        [stem2 draw:ytop topStaff:topstaff];

    trans = [NSAffineTransform transform];
    [trans translateXBy:-xpos yBy:0.0];
    [trans concat];
    trans = [NSAffineTransform transform];
    [trans translateXBy:-(width - self.minWidth) yBy:0.0];
    [trans concat];
}

/** Draw the accidental symbols.  If two symbols overlap (if they
 * are less than 6 notes apart), we cannot draw the symbol directly
 * above the previous one.  Instead, we must shift it to the right.
 * @param ytop The ylocation (in pixels) where the top of the staff starts.
 * @return The x pixel width used by all the accidentals.
 */
- (int)drawAccid:(int)ytop {
    int xpos = 0;

    AccidSymbol *prev = nil;
    int i;
    for (i = 0; i < [accidsymbols count]; i++) {
        AccidSymbol *symbol = [accidsymbols get:i];
        if (prev != nil && [symbol.note dist:prev.note] < 6) {
            xpos += symbol.width;
        }
        NSAffineTransform *trans = [NSAffineTransform transform];
        [trans translateXBy:xpos yBy:0.0];
        [trans concat];
        [symbol draw:ytop];
        trans = [NSAffineTransform transform];
        [trans translateXBy:-xpos yBy:0.0];
        [trans concat];
        prev = symbol;
    }
    if (prev != nil) {
        xpos += prev.width;
    }
    return xpos;
}

/** Draw the black circle notes.
 * @param ytop The ylocation (in pixels) where the top of the staff starts.
 * @param topstaff The white note of the top of the staff.
 */
- (void)drawNotes:(int)ytop topStaff:(WhiteNote*)topstaff {
    NSBezierPath *path;
    NSColor *color;
    int noteindex, i;

    for (noteindex = 0; noteindex < notedata_len; noteindex++) {
        NoteData *note = &notedata[noteindex];

        /* Get the x,y position to draw the note */
        int ynote = ytop + [topstaff dist:(note->whitenote)] * NoteHeight/2;

        int xnote = LineSpace/4;
        if (!note->leftside)
            xnote += NoteWidth;

        /* Draw rotated ellipse.  You must first translate (0,0)
         * to the center of the ellipse.
         */
        NSAffineTransform *trans;
        trans = [NSAffineTransform transform];
        [trans translateXBy:(xnote + NoteWidth/2 + 1) yBy:(ynote - LineWidth + NoteHeight/2)];
        [trans concat];
        trans = [NSAffineTransform transform];
        [trans rotateByDegrees:-45.0];
        [trans concat];

        SheetMusic *sheet = (SheetMusic*)sheetmusic;
        if (sheet != nil) {
            color = [sheet noteColor:note->number];
        }
        else {
            color = [NSColor blackColor];
        }
        if (note->duration == Whole || 
            note->duration == Half ||
            note->duration == DottedHalf) {

            path = [NSBezierPath bezierPath];
            [path setLineWidth:1];
            [color setStroke];
            [path appendBezierPathWithOvalInRect:
                NSMakeRect(-NoteWidth/2, -NoteHeight/2, NoteWidth, NoteHeight-1)];
            [path appendBezierPathWithOvalInRect:
                NSMakeRect(-NoteWidth/2, -NoteHeight/2 + 1, NoteWidth, NoteHeight-2)];
            [path appendBezierPathWithOvalInRect:
                NSMakeRect(-NoteWidth/2, -NoteHeight/2 + 1, NoteWidth, NoteHeight-3)];

            [path stroke];
        }
        else {
            path = [NSBezierPath bezierPath];
            [path setLineWidth:LineWidth];
            [color setFill];
            [path appendBezierPathWithOvalInRect:
                NSMakeRect(-NoteWidth/2, -NoteHeight/2, NoteWidth, NoteHeight-1)];
            [path fill];
        }

        path = [NSBezierPath bezierPath];
        [path setLineWidth:LineWidth];
        [[NSColor blackColor] setStroke];
        [path appendBezierPathWithOvalInRect:
            NSMakeRect(-NoteWidth/2, -NoteHeight/2, NoteWidth, NoteHeight-1)];
        [path stroke];

        trans = [NSAffineTransform transform];
        [trans rotateByDegrees:45.0];
        [trans concat];
        trans = [NSAffineTransform transform];
        [trans translateXBy:-(xnote + NoteWidth/2 + 1) yBy:-(ynote - LineWidth + NoteHeight/2)];
        [trans concat];

        /* Draw a dot if this is a dotted duration. */
        if (note->duration == DottedHalf ||
            note->duration == DottedQuarter ||
            note->duration == DottedEighth) {

            NSBezierPath *path = [NSBezierPath bezierPath];
            [path setLineWidth:LineWidth];
            [[NSColor blackColor] setFill];
            [[NSColor blackColor] setStroke];
            [path appendBezierPathWithOvalInRect:
                NSMakeRect(xnote + NoteWidth + LineSpace/3, ynote + LineSpace/3, 4, 4) ];
            [path fill];
        }

        /* Draw horizontal lines if note is above/below the staff */
        path = [NSBezierPath bezierPath];
        [path setLineWidth:LineWidth];
        [[NSColor blackColor] setStroke];

        WhiteNote *top = [topstaff add:1];
        int dist = [note->whitenote dist:top];
        int y = ytop - LineWidth;

        if (dist >= 2) {
            for (i = 2; i <= dist; i += 2) {
                y -= NoteHeight;
                [path moveToPoint:NSMakePoint(xnote - LineSpace/4, y)];
                [path lineToPoint:NSMakePoint(xnote + NoteWidth + LineSpace/4, y) ];
            }
        }

        WhiteNote *bottom = [top add:(-8)];
        y = ytop + (LineSpace + LineWidth) * 4 - 1;
        dist = [bottom dist:(note->whitenote)];
        if (dist >= 2) {
            for (i = 2; i <= dist; i+= 2) {
                y += NoteHeight;
                [path moveToPoint:NSMakePoint(xnote - LineSpace/4, y) ];
                [path lineToPoint:NSMakePoint(xnote + NoteWidth + LineSpace/4, y) ];
            }
        }
        [path stroke];

        /* End drawing horizontal lines */
    }
}


/** Draw the note letters (A, A#, Bb, etc) next to the note circles.
 * @param ytop The ylocation (in pixels) where the top of the staff starts.
 * @param topstaff The white note of the top of the staff.
 */
- (void)drawNoteLetters:(int)ytop topStaff:(WhiteNote*)topstaff {
    int noteindex;

    BOOL overlap = [ChordSymbol notesOverlap:notedata withStart:0 andEnd:notedata_len];
    for (noteindex = 0; noteindex < notedata_len; noteindex++) {
        NoteData *note = &notedata[noteindex];
        if (!note->leftside) {
            /* There's not enought pixel room to show the letter */
            continue;
        }

        /* Get the x,y position to draw the note */
        int ynote = ytop + [topstaff dist:(note->whitenote)] * NoteHeight/2;

        /* Draw the letter to the right side of the note */ 
        int xnote = LineSpace/2 + NoteWidth;

        if (note->duration == DottedHalf ||
            note->duration == DottedQuarter ||
            note->duration == DottedEighth || overlap) {

            xnote += NoteWidth*2/3;
        }
        NSPoint point = NSMakePoint(xnote, ynote - NoteHeight*2/3);
        NSString *letter = [self noteNameFromNumber:note->number 
                            andWhiteNote:note->whitenote];
        [letter drawAtPoint:point withAttributes:[SheetMusic fontAttributes]];
    }
}


/** Return true if the chords can be connected, where their stems are
 * joined by a horizontal beam. In order to create the beam:
 *
 * - The chords must be in the same measure.
 * - The chord stems should not be a dotted duration.
 * - The chord stems must be the same duration, with one exception
 *   (Dotted Eighth to Sixteenth).
 * - The stems must all point in the same direction (up or down).
 * - The chord cannot already be part of a beam.
 *
 * - 6-chord beams must be 8th notes in 3/4, 6/8, or 6/4 time
 * - 3-chord beams must be either triplets, or 8th notes (12/8 time signature)
 * - 4-chord beams are ok for 2/2, 2/4 or 4/4 time, any duration
 * - 4-chord beams are ok for other times if the duration is 16th
 * - 2-chord beams are ok for any duration
 *
 * If startQuarter is true, the first note should start on a quarter note
 * (only applies to 2-chord beams).
 */
+(BOOL)canCreateBeams:(Array*)chords withTime:(TimeSignature*)time onBeat:(BOOL)startQuarter {

    int numChords = [chords count];
    ChordSymbol *chord0 = [chords get:0];
    Stem* firstStem = chord0.stem;
    Stem* lastStem = [[chords get:(numChords-1)] stem];
    if (firstStem == nil || lastStem == nil) {
        return NO;
    }
    int measure = chord0.startTime / time.measure;
    NoteDuration dur = firstStem.duration;
    NoteDuration dur2 = lastStem.duration;

    BOOL dotted8_to_16 = NO;
    if (numChords == 2 && dur == DottedEighth && dur2 == Sixteenth) {
        dotted8_to_16 = YES;
    } 

    if (dur == Whole || dur == Half || dur == DottedHalf || dur == Quarter ||
        dur == DottedQuarter ||
        (dur == DottedEighth && !dotted8_to_16)) {

        return NO;
    }

    if (numChords == 6) {
        if (dur != Eighth) {
            return NO;
        }
        BOOL correctTime = 
           ((time.numerator == 3 && time.denominator == 4) ||
            (time.numerator == 6 && time.denominator == 8) ||
            (time.numerator == 6 && time.denominator == 4) );
        if (!correctTime) {
            return NO;
        }

        if (time.numerator == 6 && time.denominator == 4) {
            /* first chord must start at 1st or 4th quarter note */
            int beat = time.quarter * 3;
            if (( chord0.startTime % beat) > time.quarter/6) {
                return NO;
            }
        }
    }
    else if (numChords == 4) {
        if (time.numerator == 3 && time.denominator == 8) {
            return NO;
        }
        BOOL correctTime = 
           (time.numerator == 2 || time.numerator == 4 || time.numerator == 8);
        if (!correctTime && dur != Sixteenth) {
            return NO;
        }

        /* chord must start on quarter note */
        int beat = time.quarter;
        if (dur == Eighth) {
            /* 8th note chord must start on 1st or 3rd quarter note */
            beat = time.quarter * 2;
        }
        else if (dur == ThirtySecond) {
            /* 32nd note must start on an 8th beat */
            beat = time.quarter / 2;
        }

        if ((chord0.startTime % beat) > time.quarter/6) {
            return NO;
        }
    }
    else if (numChords == 3) {
        BOOL valid = (dur == Triplet) || 
                      (dur == Eighth && 
                      time.numerator == 12 && time.denominator == 8);
        if (!valid) {
            return NO;
        }

        /* chord must start on quarter note */
        int beat = time.quarter;
        if (time.numerator == 12 && time.denominator == 8) {
            /* In 12/8 time, chord must start on 3*8th beat */
            beat = time.quarter/2 * 3;
        }
        if ((chord0.startTime % beat) > time.quarter/6) {
            return NO;
        }
    }
    else if (numChords == 2) {
        if (startQuarter) {
            int beat = time.quarter;
            if ((chord0.startTime % beat) > time.quarter/6) {
                return NO;
            }
        }
    }

    for (int i = 0; i < numChords; i++) {
        ChordSymbol *chord = [chords get:i];
        if ((chord.startTime / time.measure) != measure) {
            return NO;
        }
        if (chord.stem == nil) {
            return NO;
        }
        if (chord.stem.duration != dur && !dotted8_to_16) {
            return NO;
        }
        if ([chord.stem isBeam]) {
            return NO;
        }
    }

    /* Check that all stems can point in same direction */
    BOOL hasTwoStems = NO;
    int direction = StemUp; 
    for (int i = 0; i < numChords; i++) {
        ChordSymbol *chord = [chords get:i];
        if (chord.hasTwoStems) {
            if (hasTwoStems && [chord.stem direction] != direction) {
                return NO;
            }
            hasTwoStems = YES;
            direction = [chord.stem direction];
        }
    }

    /* Get the final stem direction */
    if (!hasTwoStems) {
        WhiteNote *note1;
        WhiteNote *note2;
        note1 = ([firstStem direction] == StemUp ? [firstStem top] : [firstStem bottom]);
        note2 = ([lastStem direction] == StemUp ? [lastStem top] : [lastStem bottom]);
        direction = [ChordSymbol stemDirection:note1 withTop:note2 andClef: chord0.clef];
    }

    /* If the notes are too far apart, don't use a beam */
    if (direction == StemUp) {
        if (abs([[firstStem top] dist:[lastStem top]]) >= 11) {
            return NO;
        }
    }
    else {
        if (abs([[firstStem bottom] dist:[lastStem bottom]]) >= 11) {
            return NO;
        }
    }
    return YES;
}


/** Connect the chords using a horizontal beam. 
 *
 * spacing is the horizontal distance (in pixels) between the right side 
 * of the first chord, and the right side of the last chord.
 *
 * To make the beam:
 * - Change the stem directions for each chord, so they match.
 * - In the first chord, pass the stem location of the last chord, and
 *   the horizontal spacing to that last stem.
 * - Mark all chords (except the first) as "receiver" pairs, so that 
 *   they don't draw a curvy stem.
 */
+(void)createBeam:(Array*)chords withSpacing:(int)spacing {
    Stem* firstStem = [[chords get:0] stem];
    Stem* lastStem = [[chords get:([chords count]-1)] stem];

    /* Calculate the new stem direction */
    int newdirection = -1;
    for (int i = 0; i < [chords count]; i++) {
        ChordSymbol *chord = [chords get:i];
        if (chord.hasTwoStems) {
            newdirection = [chord.stem direction];
            break;
        }
    }

    if (newdirection == -1) {
        WhiteNote *note1;
        WhiteNote *note2;
        note1 = ([firstStem direction] == StemUp ? [firstStem top] : [firstStem bottom]);
        note2 = ([lastStem direction] == StemUp ? [lastStem top] : [lastStem bottom]);
        newdirection = [ChordSymbol stemDirection:note1 withTop:note2 andClef:[[chords get:0] clef]];
    }
    for (int i = 0; i < [chords count]; i++) {
        ChordSymbol *chord = [chords get:i];
        chord.stem.direction = newdirection;
    }

    if ([chords count] == 2) {
        [ChordSymbol bringStemsCloser:chords];
    }
    else {
        [ChordSymbol lineUpStemEnds:chords];
    }

    [firstStem setPair:lastStem withWidth:spacing];
    for (int i = 1; i < [chords count]; i++) {
        ChordSymbol *chord = [chords get:i];
        chord.stem.receiver = YES;
    }
}


/** We're connecting the stems of two chords using a horizontal beam.
 *  Adjust the vertical endpoint of the stems, so that they're closer
 *  together.  For a dotted 8th to 16th beam, increase the stem of the
 *  dotted eighth, so that it's as long as a 16th stem.
 */
+(void)bringStemsCloser:(Array*)chords {
    Stem* firstStem = [[chords get:0] stem];
    Stem* lastStem = [[chords get:1] stem];
    WhiteNote *newend = nil;

    /* If we're connecting a dotted 8th to a 16th, increase
     * the stem end of the dotted eighth.
     */
    if (firstStem.duration == DottedEighth &&
        lastStem.duration == Sixteenth) {
        if ([firstStem direction] == StemUp) {
            newend = [[firstStem end] add:2];
            [firstStem setEnd:newend];
        }
        else {
            newend = [[firstStem end] add:-2];
            [firstStem setEnd:newend];
        }
    }

    /* Bring the stem ends closer together */
    int distance = abs([[firstStem end] dist: [lastStem end]]);
    if ([firstStem direction] == StemUp) {
        if ([WhiteNote max:[firstStem end] and:[lastStem end]] == [firstStem end]) {
            newend = [[lastStem end] add:(distance/2)]; 
            [lastStem setEnd:newend];
        }
        else {
            newend = [[firstStem end] add:(distance/2)];
            [firstStem setEnd:newend];
        }
    }
    else {
        if ([WhiteNote min:[firstStem end] and:[lastStem end]] == [firstStem end]) {
            newend = [[lastStem end] add:(-distance/2)];
            [lastStem setEnd:newend];
        }
        else {
            newend = [[firstStem end] add:(-distance/2)];
            [firstStem setEnd:newend];
        }
    }
}

/** We're connecting the stems of three or more chords using a horizontal beam.
 *  Adjust the vertical endpoint of the stems, so that the middle chord stems
 *  are vertically in between the first and last stem.
 */
+(void)lineUpStemEnds:(Array*)chords {
    Stem* firstStem = [[chords get:0] stem];
    Stem* lastStem = [[chords get:([chords count]-1)] stem];
    Stem* middleStem = [[chords get:1] stem];
    WhiteNote *newend = nil;

    if ([firstStem direction] == StemUp) {
        /* Find the highest stem. The beam will either:
         * - Slant downwards (first stem is highest)
         * - Slant upwards (last stem is highest)
         * - Be straight (middle stem is highest)
         */
        WhiteNote* top = [firstStem end];
        for (int i = 0; i < [chords count]; i++) {
            ChordSymbol *chord = [chords get:i];
            top = [WhiteNote max:top and:[chord.stem end]];
        }
        if (top == [firstStem end] && [top dist:[lastStem end]] >= 2) {
            [firstStem setEnd:top];
            newend = [top add:-1];
            [middleStem setEnd:newend];
            newend = [top add:-2];
            [lastStem setEnd:newend];
        }
        else if (top == [lastStem end] && [top dist:[firstStem end]] >= 2) {
            newend = [top add:-2];
            [firstStem setEnd:newend];
            newend = [top add:-1];
            [middleStem setEnd:newend];
            [lastStem setEnd:top];
        }
        else {
            [firstStem setEnd:top];
            [middleStem setEnd:top];
            [lastStem setEnd:top];
        }
    }
    else {
        /* Find the bottommost stem. The beam will either:
         * - Slant upwards (first stem is lowest)
         * - Slant downwards (last stem is lowest)
         * - Be straight (middle stem is highest)
         */
        WhiteNote* bottom = [firstStem end];
        for (int i = 0; i < [chords count]; i++) {
            ChordSymbol *chord = [chords get:i];
            bottom = [WhiteNote min:bottom and:[chord.stem end]];
        }

        if (bottom == [firstStem end] && [[lastStem end] dist:bottom] >= 2) {
            [firstStem setEnd:bottom];
            newend = [bottom add:1];
            [middleStem setEnd:newend];
            newend = [bottom add:2];
            [lastStem setEnd:newend];
        }
        else if (bottom == [lastStem end] && [[firstStem end] dist:bottom] >= 2) {
            newend = [bottom add:2];
            [firstStem setEnd:newend];
            newend = [bottom add:1];
            [middleStem setEnd:newend];
            [lastStem setEnd:bottom];
        }
        else {
            [firstStem setEnd:bottom];
            [middleStem setEnd:bottom];
            [lastStem setEnd:bottom];
        }
    }

    /* All middle stems have the same end */
    for (int i = 1; i < [chords count]-1; i++) {
        Stem *stem = [[chords get:i] stem];
        [stem setEnd: [middleStem end]];
    }
}

-(NSString*)description {
    NSString *clefs[] = { @"Treble", @"Bass" };
    NSString *s = [NSString stringWithFormat:
                    @"ChordSymbol clef=%@ start=%d end=%d width=%d hasTwoStems=%d ",
                    clefs[clef], starttime, endtime, width, hasTwoStems];
    for (int i = 0; i < [accidsymbols count]; i++) {
        AccidSymbol *symbol = [accidsymbols get:i];
        s = [s stringByAppendingString:[symbol description]];
        s = [s stringByAppendingString:@" "];
    }
    for (int i = 0; i < notedata_len; i++) {
        NSString *notestr = [NSString stringWithFormat:
                              @"Note whitenote=%@ duration=%@ leftside=%d ",
                              [notedata[i].whitenote description],
                              [TimeSignature durationString:notedata[i].duration ],
                              notedata[i].leftside];
        s = [s stringByAppendingString:notestr];
    }
    if (stem1 != nil) {
        s = [s stringByAppendingString:[stem1 description]];
        s = [s stringByAppendingString:@" "];
    }
    if (stem2 != nil) {
        s = [s stringByAppendingString:[stem2 description]];
        s = [s stringByAppendingString:@" "];
    }
    return s;
}

- (void)dealloc {
    for (int i = 0; i < notedata_len; i++) {
        [notedata[i].whitenote release];
    }
    notedata_len = 0;
    [accidsymbols release];  accidsymbols = nil;
    [stem1 release]; stem1 = nil;
    [stem2 release]; stem2 = nil;
    [super dealloc];
}


@end

/** Comparison function for sorting Chords by start time */
int sortChordSymbol(id chord1, id chord2, void* unused) {
    ChordSymbol *c1 = (ChordSymbol*) chord1;
    ChordSymbol *c2 = (ChordSymbol*) chord2;
    return c1.startTime - c2.startTime;
}

