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
#import "Array.h"
#import "MidiFile.h"
#import "WhiteNote.h"
#import "ClefMeasures.h"
#import "ClefSymbol.h"

/** @class ClefMeasures
 * The ClefMeasures class is used to report what Clef (Treble or Bass) a
 * given measure uses.
 */
@implementation ClefMeasures
 
/** Given the notes in a track, calculate the appropriate Clef to use
 * for each measure.  Store the result in the clefs list.
 * @param notes  The midi notes
 * @param measurelen The length of a measure, in pulses
 */
- (id)initWithNotes:(Array*)notes andMeasure:(int)measurelen {
    measure = measurelen;
    int mainclef = [self mainClef:notes];
    int nextmeasure = measurelen;
    int pos = 0;
    int clef = mainclef;

    clefs = [[IntArray new:([notes count] / 10) + 1] retain];

    while (pos < [notes count]) {
        /* Sum all the notes in the current measure */
        int sumnotes = 0;
        int notecount = 0;
        while (pos < [notes count] && [(MidiNote*)[notes get:pos] startTime] < nextmeasure) {
            sumnotes += [(MidiNote*)[notes get:pos] number];
            notecount++;
            pos++;
        }
        if (notecount == 0)
            notecount = 1;

        /* Calculate the "average" note in the measure */
        int avgnote = sumnotes / notecount;
        if (avgnote == 0) {
            /* This measure doesn't contain any notes.
             * Keep the previous clef.
             */
        }
        else if (avgnote >= [WhiteNote bottomTreble].number) {
            clef = Clef_Treble;
        }
        else if (avgnote <= [WhiteNote topBass].number) {
            clef = Clef_Bass;
        }
        else {
            /* The average note is between G3 and F4. We can use either
             * the treble or bass clef.  Use the "main" clef, the clef
             * that appears most for this track.
             */
            clef = mainclef;
        }

        [clefs add:clef];
        nextmeasure += measurelen;
    }
    [clefs add:clef];
    return self;
}

- (void)dealloc {
    [clefs release];
    [super dealloc];
}

/** Given a time (in pulses), return the clef used for that measure. */
- (int)getClef:(int)starttime {
    /* If the time exceeds the last measure, return the last measure */
    if (starttime / measure >= [clefs count]) {
        return [clefs get:([clefs count]-1) ];
    }
    else {
        return [clefs get:(starttime / measure) ];
    }
}

/** Calculate the best clef to use for the given notes.  If the
 * average note is below Middle C, use a bass clef.  Else, use a treble
 * clef.
 */
- (int)mainClef:(Array*)notes {
    int middleC = [WhiteNote middleC].number;
    int total = 0;
    for (int i = 0; i < [notes count]; i++) {
        total += [(MidiNote*)[notes get:i] number];
    }
    if ([notes count] == 0) {
        return Clef_Treble;
    }
    else if (total/[notes count] >= middleC) {
        return Clef_Treble;
    }
    else {
        return Clef_Bass;
    }
}

@end


