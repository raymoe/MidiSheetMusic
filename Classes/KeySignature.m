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

#include <assert.h>
#import "KeySignature.h"
#import "AccidSymbol.h"
#import "ClefSymbol.h"

/** The number of sharps in each key signature */
enum { C=0, G, D, A, E, B };

/** The number of flats in each key signature */
enum { F=1, Bflat, Eflat, Aflat, Dflat, Gflat };

/** The two arrays below are key maps.  They take a major key
 * (like G major, B-flat major) and a note in the scale, and
 * return the Accidntal required to display that note in the
 * given key.  In a nutshel, the map is
 *
 *   map[Key][NoteScale_ -> Accidntal
 */
static int sharpkeys[8][12];
static int flatkeys[8][12];
static int initmaps = 0;


/** @class KeySignature
 * The KeySignature class represents a key signature, like G Major
 * or B-flat Major.  For sheet music, we only care about the number
 * of sharps or flats in the key signature, not whether it is major
 * or minor.
 *
 * The main operations of this class are:
 * - Guessing the key signature, given the notes in a song.
 * - Generating the accidental symbols for the key signature.
 * - Determining whether a particular note requires an accidental
 *   or not.
 *
 */

@implementation KeySignature;


/** Create new key signature, with the given number of
 * sharps and flats.  One of the two must be 0, you can't
 * have both sharps and flats in the key signature.
 */
- (id)initWithSharps:(int)sharps andFlats:(int)flats {
    assert(sharps == 0 || flats == 0);
    num_sharps = sharps;
    num_flats = flats;

    [KeySignature initAccidentalMaps];
    [self resetKeyMap];
    [self createSymbols];
    return self;
}

/** Create a new key signature, with the given notescale. */
-(id)initWithNotescale:(int)n {
    num_sharps = num_flats = 0;
    switch (n) {
        case NoteScale_A:     num_sharps = 3; break;
        case NoteScale_Bflat: num_flats = 2;  break;
        case NoteScale_B:     num_sharps = 5; break;
        case NoteScale_C:     break;
        case NoteScale_Dflat: num_flats = 5;  break;
        case NoteScale_D:     num_sharps = 2; break;
        case NoteScale_Eflat: num_flats = 3;  break;
        case NoteScale_E:     num_sharps = 4; break;
        case NoteScale_F:     num_flats = 1;  break;
        case NoteScale_Gflat: num_flats = 6;  break;
        case NoteScale_G:     num_sharps = 1; break;
        case NoteScale_Aflat: num_flats = 4;  break;
        default:              break;
    }

    [KeySignature initAccidentalMaps];
    [self resetKeyMap];
    [self createSymbols];
    return self;
}

- (void) dealloc {
    [treble release];
    [bass release];
    [super dealloc];
}

/** Return the number of sharps in the key signature */
- (int)num_sharps {
    return num_sharps;
}
/** Return the number of flats in the key signature */
- (int)num_flats {
    return num_flats;
}


/** Iniitalize the sharpkeys and flatkeys maps */
+ (void)initAccidentalMaps {
    if (initmaps == 1)
        return;

    initmaps = 1;

    int* map;
    map = &sharpkeys[C][0];
    map[ NoteScale_A ]      = AccidNone;
    map[ NoteScale_Asharp ] = AccidFlat;
    map[ NoteScale_B ]      = AccidNone;
    map[ NoteScale_C ]      = AccidNone;
    map[ NoteScale_Csharp ] = AccidSharp;
    map[ NoteScale_D ]      = AccidNone;
    map[ NoteScale_Dsharp ] = AccidSharp;
    map[ NoteScale_E ]      = AccidNone;
    map[ NoteScale_F ]      = AccidNone;
    map[ NoteScale_Fsharp ] = AccidSharp;
    map[ NoteScale_G ]      = AccidNone;
    map[ NoteScale_Gsharp ] = AccidSharp;

    map = &sharpkeys[G][0];
    map[ NoteScale_A ]      = AccidNone;
    map[ NoteScale_Asharp ] = AccidFlat;
    map[ NoteScale_B ]      = AccidNone;
    map[ NoteScale_C ]      = AccidNone;
    map[ NoteScale_Csharp ] = AccidSharp;
    map[ NoteScale_D ]      = AccidNone;
    map[ NoteScale_Dsharp ] = AccidSharp;
    map[ NoteScale_E ]      = AccidNone;
    map[ NoteScale_F ]      = AccidNatural;
    map[ NoteScale_Fsharp ] = AccidNone;
    map[ NoteScale_G ]      = AccidNone;
    map[ NoteScale_Gsharp ] = AccidSharp;

    map = &sharpkeys[D][0];
    map[ NoteScale_A ]      = AccidNone;
    map[ NoteScale_Asharp ] = AccidFlat;
    map[ NoteScale_B ]      = AccidNone;
    map[ NoteScale_C ]      = AccidNatural;
    map[ NoteScale_Csharp ] = AccidNone;
    map[ NoteScale_D ]      = AccidNone;
    map[ NoteScale_Dsharp ] = AccidSharp;
    map[ NoteScale_E ]      = AccidNone;
    map[ NoteScale_F ]      = AccidNatural;
    map[ NoteScale_Fsharp ] = AccidNone;
    map[ NoteScale_G ]      = AccidNone;
    map[ NoteScale_Gsharp ] = AccidSharp;

    map = &sharpkeys[A][0];
    map[ NoteScale_A ]      = AccidNone;
    map[ NoteScale_Asharp ] = AccidFlat;
    map[ NoteScale_B ]      = AccidNone;
    map[ NoteScale_C ]      = AccidNatural;
    map[ NoteScale_Csharp ] = AccidNone;
    map[ NoteScale_D ]      = AccidNone;
    map[ NoteScale_Dsharp ] = AccidSharp;
    map[ NoteScale_E ]      = AccidNone;
    map[ NoteScale_F ]      = AccidNatural;
    map[ NoteScale_Fsharp ] = AccidNone;
    map[ NoteScale_G ]      = AccidNatural;
    map[ NoteScale_Gsharp ] = AccidNone;

    map = &sharpkeys[E][0];
    map[ NoteScale_A ]      = AccidNone;
    map[ NoteScale_Asharp ] = AccidFlat;
    map[ NoteScale_B ]      = AccidNone;
    map[ NoteScale_C ]      = AccidNatural;
    map[ NoteScale_Csharp ] = AccidNone;
    map[ NoteScale_D ]      = AccidNatural;
    map[ NoteScale_Dsharp ] = AccidNone;
    map[ NoteScale_E ]      = AccidNone;
    map[ NoteScale_F ]      = AccidNatural;
    map[ NoteScale_Fsharp ] = AccidNone;
    map[ NoteScale_G ]      = AccidNatural;
    map[ NoteScale_Gsharp ] = AccidNone;

    map = &sharpkeys[B][0];
    map[ NoteScale_A ]      = AccidNatural;
    map[ NoteScale_Asharp ] = AccidNone;
    map[ NoteScale_B ]      = AccidNone;
    map[ NoteScale_C ]      = AccidNatural;
    map[ NoteScale_Csharp ] = AccidNone;
    map[ NoteScale_D ]      = AccidNatural;
    map[ NoteScale_Dsharp ] = AccidNone;
    map[ NoteScale_E ]      = AccidNone;
    map[ NoteScale_F ]      = AccidNatural;
    map[ NoteScale_Fsharp ] = AccidNone;
    map[ NoteScale_G ]      = AccidNatural;
    map[ NoteScale_Gsharp ] = AccidNone;

        /* Flat keys */

    map = &flatkeys[C][0];
    map[ NoteScale_A ]      = AccidNone;
    map[ NoteScale_Asharp ] = AccidFlat;
    map[ NoteScale_B ]      = AccidNone;
    map[ NoteScale_C ]      = AccidNone;
    map[ NoteScale_Csharp ] = AccidSharp;
    map[ NoteScale_D ]      = AccidNone;
    map[ NoteScale_Dsharp ] = AccidSharp;
    map[ NoteScale_E ]      = AccidNone;
    map[ NoteScale_F ]      = AccidNone;
    map[ NoteScale_Fsharp ] = AccidSharp;
    map[ NoteScale_G ]      = AccidNone;
    map[ NoteScale_Gsharp ] = AccidSharp;

    map = &flatkeys[F][0];
    map[ NoteScale_A ]      = AccidNone;
    map[ NoteScale_Bflat ]  = AccidNone;
    map[ NoteScale_B ]      = AccidNatural;
    map[ NoteScale_C ]      = AccidNone;
    map[ NoteScale_Csharp ] = AccidSharp;
    map[ NoteScale_D ]      = AccidNone;
    map[ NoteScale_Eflat ]  = AccidFlat;
    map[ NoteScale_E ]      = AccidNone;
    map[ NoteScale_F ]      = AccidNone;
    map[ NoteScale_Fsharp ] = AccidSharp;
    map[ NoteScale_G ]      = AccidNone;
    map[ NoteScale_Aflat ]  = AccidFlat;

    map = &flatkeys[Bflat][0];
    map[ NoteScale_A ]      = AccidNone;
    map[ NoteScale_Bflat ]  = AccidNone;
    map[ NoteScale_B ]      = AccidNatural;
    map[ NoteScale_C ]      = AccidNone;
    map[ NoteScale_Csharp ] = AccidSharp;
    map[ NoteScale_D ]      = AccidNone;
    map[ NoteScale_Eflat ]  = AccidNone;
    map[ NoteScale_E ]      = AccidNatural;
    map[ NoteScale_F ]      = AccidNone;
    map[ NoteScale_Fsharp ] = AccidSharp;
    map[ NoteScale_G ]      = AccidNone;
    map[ NoteScale_Aflat ]  = AccidFlat;

    map = &flatkeys[Eflat][0];
    map[ NoteScale_A ]      = AccidNatural;
    map[ NoteScale_Bflat ]  = AccidNone;
    map[ NoteScale_B ]      = AccidNatural;
    map[ NoteScale_C ]      = AccidNone;
    map[ NoteScale_Dflat ]  = AccidFlat;
    map[ NoteScale_D ]      = AccidNone;
    map[ NoteScale_Eflat ]  = AccidNone;
    map[ NoteScale_E ]      = AccidNatural;
    map[ NoteScale_F ]      = AccidNone;
    map[ NoteScale_Fsharp ] = AccidSharp;
    map[ NoteScale_G ]      = AccidNone;
    map[ NoteScale_Aflat ]  = AccidNone;

    map = &flatkeys[Aflat][0];
    map[ NoteScale_A ]      = AccidNatural;
    map[ NoteScale_Bflat ]  = AccidNone;
    map[ NoteScale_B ]      = AccidNatural;
    map[ NoteScale_C ]      = AccidNone;
    map[ NoteScale_Dflat ]  = AccidNone;
    map[ NoteScale_D ]      = AccidNatural;
    map[ NoteScale_Eflat ]  = AccidNone;
    map[ NoteScale_E ]      = AccidNatural;
    map[ NoteScale_F ]      = AccidNone;
    map[ NoteScale_Fsharp ] = AccidSharp;
    map[ NoteScale_G ]      = AccidNone;
    map[ NoteScale_Aflat ]  = AccidNone;

    map = &flatkeys[Dflat][0];
    map[ NoteScale_A ]      = AccidNatural;
    map[ NoteScale_Bflat ]  = AccidNone;
    map[ NoteScale_B ]      = AccidNatural;
    map[ NoteScale_C ]      = AccidNone;
    map[ NoteScale_Dflat ]  = AccidNone;
    map[ NoteScale_D ]      = AccidNatural;
    map[ NoteScale_Eflat ]  = AccidNone;
    map[ NoteScale_E ]      = AccidNatural;
    map[ NoteScale_F ]      = AccidNone;
    map[ NoteScale_Gflat ]  = AccidNone;
    map[ NoteScale_G ]      = AccidNatural;
    map[ NoteScale_Aflat ]  = AccidNone;

    map = &flatkeys[Gflat][0];
    map[ NoteScale_A ]      = AccidNatural;
    map[ NoteScale_Bflat ]  = AccidNone;
    map[ NoteScale_B ]      = AccidNone;
    map[ NoteScale_C ]      = AccidNatural;
    map[ NoteScale_Dflat ]  = AccidNone;
    map[ NoteScale_D ]      = AccidNatural;
    map[ NoteScale_Eflat ]  = AccidNone;
    map[ NoteScale_E ]      = AccidNatural;
    map[ NoteScale_F ]      = AccidNone;
    map[ NoteScale_Gflat ]  = AccidNone;
    map[ NoteScale_G ]      = AccidNatural;
    map[ NoteScale_Aflat ]  = AccidNone;
}

/** The keymap tells what accidental symbol is needed for each
 *  note in the scale.  Reset the keymap to the values of the
 *  key signature.
 */
- (void)resetKeyMap {
    int* key;
    if (num_flats > 0)
        key = &flatkeys[num_flats][0];
    else
        key = &sharpkeys[num_sharps][0];

    for (int notenumber = 0; notenumber < 160; notenumber++) {
        int notescale = notescale_from_number(notenumber);
        keymap[notenumber] = key[notescale];
    }
}


/** Create the Accidental symbols for this key, for
 * the treble and bass clefs.
 */
- (void)createSymbols {
    int count = (num_sharps > num_flats ? num_sharps : num_flats);
    int arrsize = count;
    if (arrsize == 0) {
        arrsize = 1;
    }
    treble = [[Array new:arrsize] retain];
    bass = [[Array new:arrsize] retain];

    if (count == 0) {
        return;
    }

    WhiteNote* treblenotes[6];
    WhiteNote* bassnotes[6];

    if (num_sharps > 0)  {
        treblenotes[0] = [WhiteNote allocWithLetter:WhiteNote_F andOctave:5];
        treblenotes[1] = [WhiteNote allocWithLetter:WhiteNote_C andOctave:5];
        treblenotes[2] = [WhiteNote allocWithLetter:WhiteNote_G andOctave:5];
        treblenotes[3] = [WhiteNote allocWithLetter:WhiteNote_D andOctave:5];
        treblenotes[4] = [WhiteNote allocWithLetter:WhiteNote_A andOctave:6];
        treblenotes[5] = [WhiteNote allocWithLetter:WhiteNote_E andOctave:5];

        bassnotes[0] = [WhiteNote allocWithLetter:WhiteNote_F andOctave:3];
        bassnotes[1] = [WhiteNote allocWithLetter:WhiteNote_C andOctave:3];
        bassnotes[2] = [WhiteNote allocWithLetter:WhiteNote_G andOctave:3];
        bassnotes[3] = [WhiteNote allocWithLetter:WhiteNote_D andOctave:3];
        bassnotes[4] = [WhiteNote allocWithLetter:WhiteNote_A andOctave:4];
        bassnotes[5] = [WhiteNote allocWithLetter:WhiteNote_E andOctave:3];

    }
    else if (num_flats > 0) {
        treblenotes[0] = [WhiteNote allocWithLetter:WhiteNote_B andOctave:5];
        treblenotes[1] = [WhiteNote allocWithLetter:WhiteNote_E andOctave:5];
        treblenotes[2] = [WhiteNote allocWithLetter:WhiteNote_A andOctave:5];
        treblenotes[3] = [WhiteNote allocWithLetter:WhiteNote_D andOctave:5];
        treblenotes[4] = [WhiteNote allocWithLetter:WhiteNote_G andOctave:4];
        treblenotes[5] = [WhiteNote allocWithLetter:WhiteNote_C andOctave:5];

        bassnotes[0] = [WhiteNote allocWithLetter:WhiteNote_B andOctave:3];
        bassnotes[1] = [WhiteNote allocWithLetter:WhiteNote_E andOctave:3];
        bassnotes[2] = [WhiteNote allocWithLetter:WhiteNote_A andOctave:3];
        bassnotes[3] = [WhiteNote allocWithLetter:WhiteNote_D andOctave:3];
        bassnotes[4] = [WhiteNote allocWithLetter:WhiteNote_G andOctave:2];
        bassnotes[5] = [WhiteNote allocWithLetter:WhiteNote_C andOctave:3];

    }

    int a = AccidNone;
    if (num_sharps > 0)
        a = AccidSharp;
    else
        a = AccidFlat;

    for (int i = 0; i < count; i++) {
        AccidSymbol *s = [[AccidSymbol alloc] 
                          initWithAccid:a andNote:treblenotes[i] 
                          andClef:Clef_Treble];
        [treble add:s];
        [s release];
        AccidSymbol *s2 = [[AccidSymbol alloc] 
                          initWithAccid:a andNote:bassnotes[i] 
                          andClef:Clef_Bass];
        [bass add:s2];
        [s2 release];
    }
}

/** Return the Accidntal symbols for displaying this key signature
 * for the given clef.
 */
- (Array*)getSymbols:(int)clef {
    if (clef == Clef_Treble) {
        return treble;
    }
    else {
        return bass;
    }
}

/** Given a midi note number, return the accidental (if any)
 * that should be used when displaying the note in this key 
 * signature.
 *
 * The current measure is also required.  Once we return an
 * accidental for a measure, the accidental remains for the
 * rest of the measure. So we must update the current keymap
 * with any new accidentals that we return.  When we move to another
 * measure, we reset the keymap back to the key signature.
 */
- (int)getAccidentalForNote:(int)notenumber andMeasure:(int)measure {
    if (measure != prevmeasure) {
        [self resetKeyMap];
        prevmeasure = measure;
    }

    int result = keymap[notenumber];
    if (result == AccidSharp) {
        keymap[notenumber] = AccidNone;
        keymap[notenumber-1] = AccidNatural;
    }
    else if (result == AccidFlat) {
        keymap[notenumber] = AccidNone;
        keymap[notenumber+1] = AccidNatural;
    }
    else if (result == AccidNatural) {
        keymap[notenumber] = AccidNone;
        int nextkey = notescale_from_number(notenumber+1);
        int prevkey = notescale_from_number(notenumber-1);

        /* If we insert a natural, then either:
         * - the next key must go back to sharp,
         * - the previous key must go back to flat.
         */
        if (keymap[notenumber-1] == AccidNone && keymap[notenumber+1] == AccidNone &&
            notescale_is_black_key(nextkey) && notescale_is_black_key(prevkey) ) {

            if (num_flats == 0) {
                keymap[notenumber+1] = AccidSharp;
            }
            else {
                keymap[notenumber-1] = AccidFlat;
            }
        }
        else if (keymap[notenumber-1] == AccidNone && notescale_is_black_key(prevkey)) {
            keymap[notenumber-1] = AccidFlat;
        }
        else if (keymap[notenumber+1] == AccidNone && notescale_is_black_key(nextkey)) {
            keymap[notenumber+1] = AccidSharp;
        }
        else {
            /* Shouldn't get here */
        }
    }
    return result;
}


/** Given a midi note number, return the white note (the
 * non-sharp/non-flat note) that should be used when displaying
 * this note in this key signature. This should be called
 * before calling getAccidental.
 */
- (WhiteNote*)getWhiteNote:(int)notenumber {
    int notescale = notescale_from_number(notenumber);
    int octave = (notenumber + 3) / 12 - 1;
    int letter = 0;

    int whole_sharps[] = { 
        WhiteNote_A, WhiteNote_A, 
        WhiteNote_B, 
        WhiteNote_C, WhiteNote_C,
        WhiteNote_D, WhiteNote_D,
        WhiteNote_E,
        WhiteNote_F, WhiteNote_F,
        WhiteNote_G, WhiteNote_G
    };

    int whole_flats[] = {
        WhiteNote_A, 
        WhiteNote_B, WhiteNote_B,
        WhiteNote_C,
        WhiteNote_D, WhiteNote_D,
        WhiteNote_E, WhiteNote_E,
        WhiteNote_F,
        WhiteNote_G, WhiteNote_G,
        WhiteNote_A
    };

    int accid = keymap[notenumber];
    if (accid == AccidFlat) {
        letter = whole_flats[notescale];
    }
    else if (accid == AccidSharp) {
        letter = whole_sharps[notescale];
    }
    else if (accid == AccidNatural) {
        letter = whole_sharps[notescale];
    }
    else if (accid == AccidNone) {
        letter = whole_sharps[notescale];

        /* If the note number is a sharp/flat, and there's no accidental,
         * determine the white note by seeing whether the previous or next note
         * is a natural.
         */

        if (notescale_is_black_key(notescale)) {
            if (keymap[notenumber-1] == AccidNatural &&
                keymap[notenumber+1] == AccidNatural) {

                if (num_flats > 0) {
                    letter = whole_flats[notescale];
                }
                else {
                    letter = whole_sharps[notescale];
                }
            }
            else if (keymap[notenumber-1] == AccidNatural) {
                letter = whole_sharps[notescale];
            }
            else if (keymap[notenumber+1] == AccidNatural) {
               letter = whole_flats[notescale];
            }
        }
    }

    /* The above algorithm doesn't quite work for G-flat major.
     * Handle it here.
     */
    if (num_flats == Gflat && notescale == NoteScale_B) {
        letter = WhiteNote_C;
    }
    if (num_flats == Gflat && notescale == NoteScale_Bflat) {
        letter = WhiteNote_B;
    }
    if (num_flats > 0 && notescale == NoteScale_Aflat) {
        octave++;
    }
    return [WhiteNote allocWithLetter:letter andOctave:octave];
}


/** Guess the key signature, given the midi note numbers used in
 * the song.
 */
+ (id)guess:(IntArray*) notes {
    [KeySignature initAccidentalMaps];

    int notecount[12];
    int i;

    /* Get the frequency count of each note in the 12-note scale */
    for (i = 0; i < 12; i++) {
        notecount[i] = 0;
    } 
    for (i = 0; i < [notes count]; i++) {
        int notenumber = [notes get:i];
        int notescale = (notenumber + 3) % 12;
        notecount[notescale] += 1;
    }

    /* For each key signature, count the total number of accidentals
     * needed to display all the notes.  Choose the key signature
     * with the fewest accidentals.
     */
    int bestkey = 0;
    BOOL is_best_sharp = YES;
    int smallest_accid_count = [notes count];
    int key;

    for (key = 0; key < 6; key++) {
        int accid_count = 0;
        for (int n = 0; n < 12; n++) {
            if (sharpkeys[key][n] != AccidNone) {
                accid_count += notecount[n];
            }
        }
        if (accid_count < smallest_accid_count) {
            smallest_accid_count = accid_count;
            bestkey = key;
            is_best_sharp = YES;
        }
    }

    for (key = 0; key < 7; key++) {
        int accid_count = 0;
        for (int n = 0; n < 12; n++) {
            if (flatkeys[key][n] != AccidNone) {
                accid_count += notecount[n];
            }
        }
        if (accid_count < smallest_accid_count) {
            smallest_accid_count = accid_count;
            bestkey = key;
            is_best_sharp = NO;
        }
    }
    if (is_best_sharp) {
        return [[[KeySignature alloc] initWithSharps:bestkey andFlats:0] autorelease];
    }
    else {
        return [[[KeySignature alloc] initWithSharps:0 andFlats:bestkey] autorelease];
    }
}

/** Return true if this key signature is equal to key signature k */
- (BOOL)equals:(KeySignature*)k{
    if ([k num_sharps] == num_sharps && [k num_flats] == num_flats)
        return YES;
    else
        return NO;
}


/* Return the Major Key of this Key Signature */
- (int)notescale {
    int flatmajor[] = {
        NoteScale_C, NoteScale_F, NoteScale_Bflat, NoteScale_Eflat,
        NoteScale_Aflat, NoteScale_Dflat, NoteScale_Gflat, NoteScale_B 
    };

    int sharpmajor[] = {
        NoteScale_C, NoteScale_G, NoteScale_D, NoteScale_A, NoteScale_E,
        NoteScale_B, NoteScale_Fsharp, NoteScale_Csharp, NoteScale_Gsharp,
        NoteScale_Dsharp
    };
    if (num_flats > 0)
        return flatmajor[num_flats];
    else 
        return sharpmajor[num_sharps];
}

/* Convert a Major Key into a string */
+ (NSString*) keyToString:(int) notescale {
    switch (notescale) {
        case NoteScale_A:     return @"A major, F# minor" ;
        case NoteScale_Bflat: return @"B-flat major, G minor";
        case NoteScale_B:     return @"B major, A-flat minor";
        case NoteScale_C:     return @"C major, A minor";
        case NoteScale_Dflat: return @"D-flat major, B-flat minor";
        case NoteScale_D:     return @"D major, B minor";
        case NoteScale_Eflat: return @"E-flat major, C minor";
        case NoteScale_E:     return @"E major, C# minor";
        case NoteScale_F:     return @"F major, D minor";
        case NoteScale_Gflat: return @"G-flat major, E-flat minor";
        case NoteScale_G:     return @"G major, E minor";
        case NoteScale_Aflat: return @"A-flat major, F minor";
        default:              return @"";
    }
}

/* Return a string representation of this key signature.
 * We only return the major key signature, not the minor one.
 */
- (NSString*)description {
    return [KeySignature keyToString:[self notescale]];
}

@end


