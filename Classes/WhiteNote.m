/*
 * Copyright (c) 2007-2011 Madhav Vaidyanathan
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License version 2.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 */

#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>
#import "WhiteNote.h"
#import "ClefSymbol.h"
#import "KeySignature.h"
#include <assert.h>


/** Convert a note (A, A#, B, etc) and octave into a 
 * Midi Note number.
 */
int notescale_to_number(int notescale, int octave) {
    return 9 + notescale + octave * 12;
}

/** Convert a Midi note number into a notescale (A, A#, B) */
int notescale_from_number(int number) {
    return (number + 3) % 12;
}

/** Return true if this notescale number is a black key */
BOOL notescale_is_black_key(int notescale) {
    if (notescale == NoteScale_Asharp ||
        notescale == NoteScale_Csharp ||
        notescale == NoteScale_Dsharp ||
        notescale == NoteScale_Fsharp ||
        notescale == NoteScale_Gsharp) {

        return YES;
    }
    else {
        return NO;
    }
} 


static WhiteNote* _topTreble = nil;
static WhiteNote* _topBass = nil;
static WhiteNote* _bottomTreble = nil;
static WhiteNote* _bottomBass = nil;
static WhiteNote* _middleC = nil;

/** @class WhiteNote
 * The WhiteNote class represents a white key note, a non-sharp,
 * non-flat note.  To display midi notes as sheet music, the notes
 * must be converted to white notes and accidentals.
 *
 * White notes consist of a letter (A thru G) and an octave (0 thru 10).
 * The octave changes from G to A.  After G2 comes A3.  Middle-C is C4.
 *
 * The main operations are calculating distances between notes, and comparing notes.
 */

@implementation WhiteNote

/** Create a new note with the given letter and octave. */
+(id)allocWithLetter:(int)a andOctave:(int)o {
    WhiteNote *w = [WhiteNote alloc];
    [w initWithLetter:a andOctave:o];
    return [w autorelease];
}

/* Common white notes used in calculations */

+(WhiteNote*) topTreble {
    if (_topTreble == nil) {
        _topTreble = [[WhiteNote allocWithLetter:WhiteNote_E andOctave:5] retain];
    }
    return _topTreble;
}

+(WhiteNote*) bottomTreble {
    if (_bottomTreble == nil) {
        _bottomTreble = [[WhiteNote allocWithLetter:WhiteNote_F andOctave:4] retain];
    }
    return _bottomTreble;
}

+(WhiteNote*) topBass {
    if (_topBass == nil) {
        _topBass = [[WhiteNote allocWithLetter:WhiteNote_G andOctave:3] retain];
    }
    return _topBass;
}

+(WhiteNote*) bottomBass {
    if (_bottomBass == nil) {
        _bottomBass = [[WhiteNote allocWithLetter:WhiteNote_A andOctave:3] retain];
    }
    return _bottomBass;
}

+(WhiteNote*) middleC {
    if (_middleC == nil) {
        _middleC = [[WhiteNote allocWithLetter:WhiteNote_C andOctave:4] retain];
    }
    return _middleC;
}

/** Return the top note in the staff of the given clef */
+(WhiteNote*) top:(int)clef {
    if (clef == Clef_Treble)
        return [WhiteNote topTreble];
    else
        return [WhiteNote topBass];
}

/** Return the bottom note in the staff of the given clef */
+(WhiteNote*) bottom:(int)clef {
    if (clef == Clef_Treble)
        return [WhiteNote bottomTreble];
    else
        return [WhiteNote bottomBass];
}

/** Get the letter */
- (int)letter {
    return letter;
}

/** Get the octave. */
- (int)octave {
    return octave;
}

/** Create a new note with the given letter and octave. */
- (id)initWithLetter:(int)a andOctave:(int)o {
    letter = a;
    octave = o;
    assert(letter >= 0 && letter <= 6);
    return self;
}

/** Return the distance (in white notes) between this note
 * and note w, i.e.  this - w.  For example, C4 - A4 = 2,
 */
- (int)dist:(WhiteNote*)w {
    return (octave - w.octave) * 7 + (letter - w.letter);
}

/** Return this note plus the given amount (in white notes).
 * The amount may be positive or negative.  For example,
 * A4 + 2 = C4, and C4 + (-2) = A4.
 */
- (WhiteNote*)add:(int)amount {
    int num = octave * 7 + letter;
    num += amount;
    if (num < 0) {
        num = 0;
    }
    return [WhiteNote allocWithLetter:(num % 7) andOctave:(num / 7)];
}

/** Return the midi note number corresponding to this white note.
 * The midi note numbers cover all keys, including sharps/flats,
 * so each octave is 12 notes.  Middle C (C4) is 60.  Some example
 * numbers for various notes:
 *
 *  A 2 = 33
 *  A#2 = 34
 *  G 2 = 43
 *  G#2 = 44 
 *  A 3 = 45
 *  A 4 = 57
 *  A#4 = 58
 *  B 4 = 59
 *  C 4 = 60
 */

- (int)number {
    int offset = 0;
    switch (letter) {
        case WhiteNote_A: offset = NoteScale_A; break;
        case WhiteNote_B: offset = NoteScale_B; break;
        case WhiteNote_C: offset = NoteScale_C; break;
        case WhiteNote_D: offset = NoteScale_D; break;
        case WhiteNote_E: offset = NoteScale_E; break;
        case WhiteNote_F: offset = NoteScale_F; break;
        case WhiteNote_G: offset = NoteScale_G; break;
        default: offset = 0; break;
    }
    return notescale_to_number(offset, octave);
}

/** Compare the two notes.  Return
 *  < 0  if x is less (lower) than y
 *    0  if x is equal to y
 *  > 0  if x is greater (higher) than y
 */
+(int) compare:(WhiteNote*)x and:(WhiteNote*) y {
    return [x dist:y];
}

/** Return the higher note, x or y */
+(WhiteNote*)max:(WhiteNote*)x and:(WhiteNote*)y {
    if ([x dist:y] > 0)
        return x;
    else
        return y;
}

/** Return the lower note, x or y */
+(WhiteNote*) min:(WhiteNote*)x and:(WhiteNote*) y {
    if ([x dist:y] < 0)
        return x;
    else
        return y;
}

/** Return the string <letter><octave> for this note. */
- (NSString*) description {
    NSArray* letters = [NSArray arrayWithObjects:
        @"A", @"B", @"C", @"D", @"E", @"F", @"G", nil];

    NSString *s = [NSString stringWithFormat:@"%@%d", 
           [letters objectAtIndex:letter], octave ];
    return s; 
}


@end

