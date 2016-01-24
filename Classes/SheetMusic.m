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

#import <Foundation/NSString.h>
#import <AppKit/NSPrintInfo.h>
#import <AppKit/NSPrintOperation.h>
#import <AppKit/AppKit.h>
#import <AppKit/NSAttributedString.h>

#import "AccidSymbol.h"
#import "Array.h"
#import "BarSymbol.h"
#import "BlankSymbol.h"
#import "ChordSymbol.h"
#import "ClefMeasures.h"
#import "ClefSymbol.h"
#import "KeySignature.h"
#import "LyricSymbol.h"
#import "MidiFile.h"
#import "MusicSymbol.h"
#import "RestSymbol.h"
#import "Staff.h"
#import "Stem.h"
#import "SymbolWidths.h"
#import "TimeSignature.h"
#import "TimeSigSymbol.h"
#import "WhiteNote.h"
#import "SheetMusic.h"


#define max(x,y) ((x) > (y) ? (x) : (y))


/* Measurements used when drawing.  All measurements are in pixels.
 * The values depend on whether the menu 'Large Notes' or 'Small Notes' is selected.
 */
int LineWidth;    /** The width of a line, in pixels */
int LeftMargin;   /** The left margin, in pixels */
int LineSpace;    /** The space between lines in the staff, in pixels */
int StaffHeight;  /** The height between the 5 horizontal lines of the staff */
int NoteHeight;   /** The height of a whole note */
int NoteWidth;    /** The width of a whole note */
int TitleHeight = 14; /** The height for the title on the first page */


/** A helper function to cast to a MusicSymbol */
id<MusicSymbol> getSymbol(Array *symbols, int index) {
    id<MusicSymbol> result = [symbols get:index];
    return result;
}

/** @class SheetMusic
 * The SheetMusic NSView is the main class for displaying the sheet music.
 * The SheetMusic class has the following public methods:
 *
 * SheetMusic()
 *   Create a new SheetMusic control from the given midi file and options.
 * 
 * SetZoom()
 *   Set the zoom level to display the sheet music at.
 *
 * knownPageRange()
 * rectForPage()
 *   Methods called by NSPrintOperation to print the SheetMusic
 * 
 * drawRect()
 *   Method called by Cocoa to draw the SheetMusic
 *
 * These public methods are called from the MidiSheetMusic Controller.
 *
 */

@implementation SheetMusic

/** Create a new SheetMusic control.
 * MidiFile is the parsed midi file to display.
 * SheetMusic Options are the menu options that were selected.
 *
 * - Apply all the Menu Options to the MidiFile tracks.
 * - Calculate the key signature
 * - For each track, create a list of MusicSymbols (notes, rests, bars, etc)
 * - Vertically align the music symbols in all the tracks
 * - Partition the music notes into horizontal staffs
 */
- (id)initWithFile:(MidiFile*)file andOptions:(MidiOptions*)options {
    NSRect bounds = NSMakeRect(0, 0, PageWidth, PageHeight);
    self = [super initWithFrame:bounds];

    zoom = 1.0f;
    filename = [file.filename retain];
    [self setColors:options.colors andShade:options.shadeColor andShade2:options.shade2Color];
    Array* tracks = [file changeMidiNotes:options];
    [SheetMusic setNoteSize:options.largeNoteSize];
    scrollVert = options.scrollVert;
    showNoteLetters = options.showNoteLetters;
    TimeSignature *time = file.time; 
    if (options.time != nil) {
        time = options.time;
    }
    if (options.key == -1) {
        mainkey = [[self getKeySignature:tracks] retain];
    }
    else {
        mainkey = [[KeySignature alloc] initWithNotescale:options.key];
    }
    numtracks = [tracks count];

    int lastStarttime = file.endTime + options.shifttime;

    /* Create all the music symbols (notes, rests, vertical bars, and
     * clef changes).  The symbols variable contains a list of music 
     * symbols for each track.  The list does not include the left-side 
     * Clef and key signature symbols.  Those can only be calculated 
     * when we create the staffs.
     */

    /* symbols = Array of MusicSymbol[] */
    Array *symbols = [Array new:numtracks];

    for (int tracknum = 0; tracknum < numtracks; tracknum++) {
        MidiTrack *track = [tracks get:tracknum];
        ClefMeasures *clefs = [[ClefMeasures alloc] initWithNotes:track.notes 
                                andMeasure:time.measure];
        /* chords = Array of ChordSymbol */
        Array *chords = [self createChords:track.notes withKey:mainkey 
                              andTime:time andClefs:clefs];
        Array *sym = [self createSymbols:chords withClefs:clefs andTime:time andLastTime:lastStarttime];
        [symbols add:sym];
        [clefs release];
    }

    Array *lyrics = nil; 
    if (options.showLyrics) {
        lyrics = [self getLyrics:tracks];
    }

    /* Vertically align the music symbols */
    SymbolWidths *widths = [[SymbolWidths alloc] initWithSymbols:symbols andLyrics:lyrics];
    [self alignSymbols:symbols withWidths:widths options:options];

    staffs = [[self createStaffs:symbols withKey:mainkey andOptions:options andMeasure:time.measure] retain];

    [self createAllBeamedChords:symbols withTime:time];
    if (lyrics != nil) {
        [self addLyrics:lyrics toStaffs:staffs];
    }

    /* After making chord pairs, the stem directions can change,
     * which affects the staff height.  Re-calculate the staff height.
     */
    for (int i = 0; i < [staffs count]; i++) {
        Staff* staff = [staffs get:i];
        [staff calculateHeight];
    }

    [self setZoom:1.0f];
    [widths release];
    return self;
}



/** Get the best key signature given the midi notes in all the tracks. */
- (KeySignature*)getKeySignature:(Array*)tracks {
    int initsize = 1;
    if ([tracks count] > 0) {
		MidiTrack *track = [tracks get:0];
        initsize = [track.notes count];
        initsize = initsize * [tracks count];
    }
    IntArray* notenums = [IntArray new:initsize];
    int i, j;

    for (i = 0; i < [tracks count]; i++) {
        MidiTrack *track = [tracks get:i];
        for (j = 0; j < [track.notes count]; j++) {
            MidiNote *note = [track.notes get:j];
            [notenums add:note.number];
        }
    }
    KeySignature* result = [KeySignature guess:notenums]; 
    return result;
}


/** Create the chord symbols for a single track.
 * @param midinotes  The Midinotes in the track.
 * @param key        The Key Signature, for determining sharps/flats.
 * @param time       The Time Signature, for determining the measures.
 * @param clefs      The clefs to use for each measure.
 * @ret An array of ChordSymbols
 */
- (Array *)createChords:(Array*)midinotes withKey:(KeySignature*)key
          andTime:(TimeSignature*)time andClefs:(ClefMeasures*)clefs {

    int i = 0;
    int len = [midinotes count]; 
    Array* chords = [Array new:len/4];
    Array* notegroup = [Array new:12];

    while (i < len) {
		MidiNote *note = [midinotes get:i];
        int starttime = note.startTime;
        int clef = [clefs getClef:starttime];

        /* Group all the midi notes with the same start time
         * into the notes list.
         */
        [notegroup clear];
        [notegroup add:[midinotes get:i]];
        i++;
        while (i < len && [(MidiNote*)[midinotes get:i] startTime] == starttime) {
            [notegroup add:[midinotes get:i]];
            i++;
        }

        /* Create a single chord from the group of midi notes with
         * the same start time.
         */
        ChordSymbol *chord = [[ChordSymbol alloc] initWithNotes:notegroup andKey:key
                              andTime:time andClef:clef andSheet:self];
        [chords add:chord];
        [chord release];
    }

    return chords;
}

/* Given the chord symbols for a track, create a new symbol list
 * that contains the chord symbols, vertical bars, rests, and clef changes.
 * Return a list of symbols (ChordSymbol, BarSymbol, RestSymbol, ClefSymbol)
 */
- (Array*) createSymbols:(Array*) chords withClefs:(ClefMeasures*)clefs
          andTime:(TimeSignature*)time andLastTime:(int)lastStartTime {

    Array* symbols;

    symbols = [self addBars:chords withTime:time andLastTime:lastStartTime];
    symbols = [self addRests:symbols withTime:time];
    symbols = [self addClefChanges:symbols withClefs:clefs andTime:time];
    return symbols;
}

/** Add in the vertical bars delimiting measures. 
 *  Also, add the time signature.
 */
- (Array *)addBars:(Array*)chords withTime:(TimeSignature*)time andLastTime:(int)lastStartTime {
    Array* symbols = [Array new:[chords count]];
    BarSymbol *bar;

    TimeSigSymbol* timesymbol = [[TimeSigSymbol alloc]
                                 initWithNumer:time.numerator
                                 andDenom:time.denominator];
    [symbols add:timesymbol];
    [timesymbol release];

    /* The starttime of the beginning of the measure */
    int measuretime = 0;

    int i = 0;
    while (i < [chords count]) {
        if (measuretime <= getSymbol(chords, i).startTime) {
            bar = [[BarSymbol alloc] initWithTime:measuretime];
            [symbols add:bar];
            [bar release];
            measuretime += time.measure;
        }
        else {
            [symbols add:[chords get:i] ];
            i++;
        }
    }

    /* Keep adding bars until the last StartTime (the end of the song) */
    while (measuretime < lastStartTime) {
        bar = [[BarSymbol alloc] initWithTime:measuretime];
        [symbols add:bar];
        [bar release];
        measuretime += time.measure;
    }

    /* Add the final vertical bar to the last measure */
    bar = [[BarSymbol alloc] initWithTime:measuretime];
    [symbols add:bar];
    [bar release];
    return symbols;
}

/** Add rest symbols between notes.  All times below are 
 * measured in pulses.
 */
- (Array *)addRests:(Array*)symbols withTime:(TimeSignature*)time {
    int prevtime = 0;

    Array* result = [Array new:[symbols count]];

    int i;
    for (i = 0; i < [symbols count]; i++) {
        id <MusicSymbol> symbol = [symbols get:i];
        int starttime = symbol.startTime;
        Array* rests = [self getRests:time fromStart:prevtime toEnd:starttime];
        if (rests != nil) {
            for (int j = 0; j < [rests count]; j++) {
                [result add:[rests get:j]];
            }
        }
        [result add:symbol];

        /* Set prevtime to the end time of the last note/symbol. */
        if ([symbol isKindOfClass:[ChordSymbol class]]) {
            ChordSymbol *chord = (ChordSymbol*)symbol;
            prevtime = max( chord.endTime, prevtime );
        }
        else {
            prevtime = max(starttime, prevtime);
        }
    }
    return result;
}

/** Return the rest symbols needed to fill the time interval between
 * start and end.  If no rests are needed, return null.
 */
- (Array *)getRests:(TimeSignature*)time fromStart:(int)start toEnd:(int)end {
    Array* result = [Array new:2];
    RestSymbol *r1, *r2;

    if (end - start < 0) {
        return nil;
    }

    NoteDuration dur = [time getNoteDuration:(end - start)];
    switch (dur) {
        case Whole:
        case Half:
        case Quarter:
        case Eighth:
            r1 = [[RestSymbol alloc] initWithTime:start andDuration:dur];
            [result add:r1];
            [r1 release];
            return result;

        case DottedHalf:
            r1 = [[RestSymbol alloc] initWithTime:start andDuration:Half];
            r2 = [[RestSymbol alloc] initWithTime:(start + time.quarter*2)
                                      andDuration:Quarter];
            [result add:r1]; [result add:r2];
            [r1 release]; [r2 release];
            return result;

        case DottedQuarter:
            r1 = [[RestSymbol alloc] initWithTime:start andDuration:Quarter];
            r2 = [[RestSymbol alloc] initWithTime:(start + time.quarter)
                                      andDuration:Eighth];
            [result add:r1]; [result add:r2];
            [r1 release]; [r2 release];
            return result; 

        case DottedEighth:
            r1 = [[RestSymbol alloc] initWithTime:start andDuration:Eighth];
            r2 = [[RestSymbol alloc] initWithTime:(start + time.quarter/2)
                                      andDuration:Sixteenth];
            [result add:r1]; [result add:r2];
            [r1 release]; [r2 release];
            return result;

        default:
            return nil;
    }
}

/** The current clef is always shown at the beginning of the staff, on
 * the left side.  However, the clef can also change from measure to 
 * measure. When it does, a Clef symbol must be shown to indicate the 
 * change in clef.  This function adds these Clef change symbols.
 * This function does not add the main Clef Symbol that begins each
 * staff.  That is done in the Staff() contructor.
 */
- (Array *)addClefChanges:(Array*)symbols withClefs:(ClefMeasures*)clefs
          andTime:(TimeSignature*)time {

    Array* result = [Array new:[symbols count]];
    int prevclef = [clefs getClef:0];
    int i;
    for (i = 0; i < [symbols count]; i++) {
        id <MusicSymbol> symbol = [symbols get:i];
        /* A BarSymbol indicates a new measure */
        if ([symbol isKindOfClass:[BarSymbol class]]) {
            int clef = [clefs getClef:symbol.startTime];
            if (clef != prevclef) {
                ClefSymbol *clefsym = [[ClefSymbol alloc] 
                                 initWithClef:clef andTime:symbol.startTime-1 isSmall:YES];
                [result add:clefsym];
                [clefsym release];
            }
            prevclef = clef;
        }
        [result add:symbol];
    }
    return result;
}


/** Notes with the same start times in different staffs should be
 * vertically aligned.  The SymbolWidths class is used to help 
 * vertically align symbols.
 *
 * First, each track should have a symbol for every starttime that
 * appears in the Midi File.  If a track doesn't have a symbol for a
 * particular starttime, then add a "blank" symbol for that time.
 *
 * Next, make sure the symbols for each start time all have the same
 * width, across all tracks.  The SymbolWidths class stores
 * - The symbol width for each starttime, for each track
 * - The maximum symbol width for a given starttime, across all tracks.
 *
 * The method SymbolWidths.GetExtraWidth() returns the extra width
 * needed for a track to match the maximum symbol width for a given
 * starttime.
 */
- (void)alignSymbols:(Array*)allsymbols withWidths:(SymbolWidths*)widths options:(MidiOptions *)options {

    // if we show measure numbers, increase bar symbol width
	if (options.showMeasures) {
        for (int track = 0; track < [allsymbols count]; track++) {
            Array *symbols = [allsymbols get:track];
            for (int i = 0; i < [symbols count]; i++) {
                id<MusicSymbol> sym = [symbols get:i];
                if ([sym isKindOfClass:[BarSymbol class]]) {
			        sym.width = sym.width + NoteWidth;
	            }
            }
        }
    }
    
    for (int track = 0; track < [allsymbols count]; track++) {
        Array *symbols = [allsymbols get:track];
        Array *result = [[Array alloc] initWithCapacity:[symbols count]];

        int i = 0;

        /* If a track doesn't have a symbol for a starttime,
         * add a blank symbol.
         */
        IntArray *starttimes = [widths startTimes];
        int startTimesCount = [starttimes count];
        for (int w = 0; w < startTimesCount; w++) {
            int start = [starttimes get:w];

            /* BarSymbols are not included in the SymbolWidths calculations */
            while (i < [symbols count] && 
                   ([getSymbol(symbols, i) isKindOfClass:[BarSymbol class]]) &&
                   (getSymbol(symbols, i).startTime <= start)) {

                [result add:[symbols get:i]];
                i++;
            }

            if (i < [symbols count] && getSymbol(symbols,i).startTime == start) {

                while (i < [symbols count] && 
                       getSymbol(symbols,i).startTime == start) {

                    [result add:[symbols get:i]];
                    i++;
                }
            }
            else {
                BlankSymbol *blank = [[BlankSymbol alloc] initWithTime:start andWidth:0];
                [result add:blank];
                [blank release];
            }
        }

        /* For each starttime, increase the symbol width by
         * SymbolWidths.GetExtraWidth().
         */
        i = 0;
        while (i < [result count]) {
            id <MusicSymbol> symbol = [result get:i];
            if ([symbol isKindOfClass:[BarSymbol class]]) {
                i++;
                continue;
            }
            int start = symbol.startTime;
            int extra = [widths getExtraWidth:track  forTime:start];
            int orig_width = symbol.width;
            assert(orig_width >= 0);
            symbol.width = (orig_width + extra);

            /* Skip all remaining symbols with the same starttime. */
            while (i < [result count] && getSymbol(result, i).startTime == start) {
                i++;
            }
        }
        symbols = nil;
        [allsymbols set:result index:track];
        [result release];
    }
}


static BOOL isChord(id x) {
    return [x isKindOfClass:[ChordSymbol class]];
}

static BOOL isBlank(id x) {
    return [x isKindOfClass:[BlankSymbol class]];
}

/** Find 2, 3, 4, or 6 chord symbols that occur consecutively (without any
 *  rests or bars in between).  There can be BlankSymbols in between.
 *
 *  The startIndex is the index in the symbols to start looking from.
 *
 *  Store the indexes of the consecutive chords in chordIndexes.
 *  Store the horizontal distance (pixels) between the first and last chord.
 *  If we failed to find consecutive chords, return false.
 */
+(BOOL)findConsecutiveChords:(Array*)symbols andTime:(TimeSignature*) time
                     andStart:(int)startIndex andIndexes:(int*) chordIndexes
                     andNumChords:(int)numChords andHorizDistance:(int*)dist {
    int i = startIndex;
    while (true) {
        int horizDistance = 0;

        /* Find the starting chord */
        while (i < [symbols count] - numChords) {
            if (isChord([symbols get:i])) {
                ChordSymbol* c = (ChordSymbol*) [symbols get:i];
                if (c.stem != nil) {
                    break;
                }
            }
            i++;
        }
        if (i >= [symbols count] - numChords) {
            return NO;
        }
        chordIndexes[0] = i;
        BOOL foundChords = YES;
        for (int chordIndex = 1; chordIndex < numChords; chordIndex++) {
            i++;
            int remaining = numChords - 1 - chordIndex;
            while ((i < [symbols count] - remaining) && (isBlank([symbols get:i])) ) {
                horizDistance += getSymbol(symbols, i).width;
                i++;
            }
            if (i >= [symbols count] - remaining) {
                return NO;
            }
            if (!isChord([symbols get:i])) {
                foundChords = NO;
                break;
            }
            chordIndexes[chordIndex] = i;
            horizDistance += getSymbol(symbols, i).width;
        }
        if (foundChords) {
            *dist = horizDistance;
            return YES;
        }

        /* Else, start searching again from index i */
    }
}


/** Connect chords of the same duration with a horizontal beam.
 *  numChords is the number of chords per beam (2, 3, 4, or 6).
 *  if startBeat is true, the first chord must start on a quarter note beat.
 */
-(void)createBeamedChords:(Array*)allsymbols withTime:(TimeSignature*)time
                   andNumChords:(int)numChords onBeat:(BOOL)startBeat {
    int chordIndexes[6];
    Array* chords = [[Array alloc] initWithCapacity:numChords];

    for (int track = 0; track < [allsymbols count]; track++) {
        Array* symbols = [allsymbols get:track];
        int startIndex = 0;
        while (1) {
            int horizDistance = 0;
            BOOL found = [SheetMusic findConsecutiveChords:symbols
                               andTime:time
                               andStart:startIndex
                               andIndexes:chordIndexes
                               andNumChords:numChords
                               andHorizDistance: &horizDistance];

            if (!found) {
                break;
            }
            [chords clear];
            for (int i = 0; i < numChords; i++) {
                [chords add: [symbols get:(chordIndexes[i])] ];
            }

            if ([ChordSymbol canCreateBeams:chords withTime:time onBeat:startBeat]) {
                [ChordSymbol createBeam:chords withSpacing:horizDistance];
                startIndex = chordIndexes[numChords-1] + 1;
            }
            else {
                startIndex = chordIndexes[0] + 1;
            }

            /* What is the value of startIndex here?
             * If we created a beam, we start after the last chord.
             * If we failed to create a beam, we start after the first chord.
             */
        }
    }
    [chords clear];
    [chords release];
}


/** Connect chords of the same duration with a horizontal beam.
 *
 *  We create beams in the following order:
 *  - 6 connected 8th note chords, in 3/4, 6/8, or 6/4 time
 *  - Triplets that start on quarter note beats
 *  - 3 connected chords that start on quarter note beats (12/8 time only)
 *  - 4 connected chords that start on quarter note beats (4/4 or 2/4 time only)
 *  - 2 connected chords that start on quarter note beats
 *  - 2 connected chords that start on any beat
 */ 
-(void)createAllBeamedChords:(Array*)allsymbols withTime:(TimeSignature*)time {
    if ((time.numerator == 3 && time.denominator == 4) ||
        (time.numerator == 6 && time.denominator == 8) ||
        (time.numerator == 6 && time.denominator == 4) ) {

        [self createBeamedChords:allsymbols withTime:time
              andNumChords:6 onBeat:YES];
    }
    [self createBeamedChords:allsymbols withTime:time
          andNumChords:3 onBeat:YES];
    [self createBeamedChords:allsymbols withTime:time
          andNumChords:4 onBeat:YES];
    [self createBeamedChords:allsymbols withTime:time
          andNumChords:2 onBeat:YES];
    [self createBeamedChords:allsymbols withTime:time
          andNumChords:2 onBeat:NO];
}


/** Get the width (in pixels) needed to display the key signature */
+(int)keySignatureWidth:(KeySignature*)key {
    ClefSymbol *clefsym = [[ClefSymbol alloc] initWithClef:Clef_Treble andTime:0 isSmall:NO];
    int result = clefsym.minWidth;
    [clefsym release];
    Array *keys = [key getSymbols:Clef_Treble];
    for (int i = 0; i < [keys count]; i++) {
        AccidSymbol *symbol = [keys get:i];
        result += symbol.minWidth;
    }
    return result + LeftMargin + 5;
}

/** Given MusicSymbols for a track, create the staffs for that track.
 *  Each Staff has a maxmimum width of PageWidth (800 pixels).
 *  Also, measures should not span multiple Staffs.
 */
- (Array*) createStaffsForTrack:(Array*)symbols withKey:(KeySignature*)key
          andMeasure:(int) measurelen andOptions:(MidiOptions*)options
          andTrack:(int)track andTotalTracks:(int)totaltracks {

    Array *thestaffs = [Array new:10];
    int startindex = 0;
    int keysigWidth = [SheetMusic keySignatureWidth:key];

    while (startindex < [symbols count]) {
        /* startindex is the index of the first symbol in the staff.
         * endindex is the index of the last symbol in the staff.
         */
        int endindex = startindex;
        int width = keysigWidth;
        int maxwidth;

        /* If we're scrolling vertically, the maximum width is PageWidth. */
        if (scrollVert) {
            maxwidth = PageWidth;
        }
        else {
            maxwidth = 2000000;
        }

        while (endindex < [symbols count] &&
               width + getSymbol(symbols, endindex).width < maxwidth) {

            width += getSymbol(symbols, endindex).width;

            endindex++;
        }
        endindex--;

        /* There's 3 possibilities at this point:
         * 1. We have all the symbols in the track.
         *    The endindex stays the same.
         *
         * 2. We have symbols for less than one measure.
         *    The endindex stays the same.
         *
         * 3. We have symbols for 1 or more measures.
         *    Since measures cannot span multiple staffs, we must
         *    make sure endindex does not occur in the middle of a
         *    measure.  We count backwards until we come to the end
         *    of a measure.
         */

        if (endindex == [symbols count] - 1) {
            /* endindex stays the same */
        }
        else if (getSymbol(symbols, startindex).startTime / measurelen ==
                 getSymbol(symbols, endindex).startTime / measurelen) {
            /* endindex stays the same */
        }
        else {
            int endmeasure = getSymbol(symbols, endindex+1).startTime/measurelen;
            while (getSymbol(symbols, endindex).startTime / measurelen == endmeasure) {
                endindex--;
            }
        }
        Array *staffsymbols = [symbols range:startindex end:endindex+1];
        if (scrollVert) {
            width = PageWidth;
        }
        Staff *staff = [[Staff alloc] initWithSymbols:staffsymbols 
                          andKey:key andOptions:options
                          andTrack:track andTotalTracks:totaltracks];
        [thestaffs add:staff];
        [staff release];
        startindex = endindex + 1;
    }
    return thestaffs;
}



/** Given all the MusicSymbols for every track, create the staffs
 * for the sheet music.  There are two parts to this:
 *
 * - Get the list of staffs for each track.
 *   The staffs will be stored in trackstaffs as:
 *
 *   trackstaffs[0] = { Staff0, Staff1, Staff2, ... } for track 0
 *   trackstaffs[1] = { Staff0, Staff1, Staff2, ... } for track 1
 *   trackstaffs[2] = { Staff0, Staff1, Staff2, ... } for track 2
 *
 * - Store the Staffs in the staffs list, but interleave the
 *   tracks as follows:
 *
 *   staffs = { Staff0 for track 0, Staff0 for track1, Staff0 for track2,
 *              Staff1 for track 0, Staff1 for track1, Staff1 for track2,
 *              Staff2 for track 0, Staff2 for track1, Staff2 for track2,
 *              ... } 
 */ 
- (Array*) createStaffs:(Array*) allsymbols withKey:(KeySignature*)key
     andOptions:(MidiOptions*)options andMeasure:(int)measurelen  {

    Array *trackstaffs = [Array new:[allsymbols count]];
    int totaltracks = [allsymbols count];

    for (int track = 0; track < totaltracks; track++) {
        Array* symbols = [allsymbols get:track];
        Array *trackstaff = [self createStaffsForTrack:symbols withKey:key 
                                   andMeasure:measurelen andOptions:options
                                  andTrack:track andTotalTracks:totaltracks];
        [trackstaffs add:trackstaff];
    }

    /* Update the endTime of each Staff. The endTime is used during shading */
    for (int track = 0; track < [trackstaffs count]; track++) {
        Array *thestaffs = (Array*)[trackstaffs get:track];
        for (int i = 0; i < [thestaffs count]-1; i++) {
            Staff *staff = [thestaffs get:i];
            Staff *nextstaff = [thestaffs get:i+1];
            [staff setEndTime: nextstaff.startTime];
        }
    }

    /* Interleave the staffs of each track into the result array */
    int maxstaffs = 0;
    for (int i = 0; i < [trackstaffs count]; i++) {
        if (maxstaffs < [(Array*)[trackstaffs get:i] count]) {
            maxstaffs = [(Array*)[trackstaffs get:i] count];
        }
    }
    Array *result = [Array new:(maxstaffs * [trackstaffs count]) ];
    for (int i = 0; i < maxstaffs; i++) {
        for (int track = 0; track < [trackstaffs count]; track++) {
            Array *list = [trackstaffs get:track];
            if (i < [list count]) {
                Staff *s = [list get:i];
                [result add:s];
            }
        }
    }

    return result;
}

/** Set the note colors to use */
- (void)setColors:(Array*)newcolors andShade:(NSColor*)s andShade2:(NSColor*)s2  {
    if (newcolors != nil) {
        for (int i = 0; i < 12; i++) {
            NoteColors[i] = [newcolors get:i];
        }
    }
    else {
        for (int i = 0; i < 12; i++) {
            NoteColors[i] = [NSColor blackColor];
        }
    }

    shadeColor = s;
    shade2Color = s2;
}

/** Retrieve the color for a given note number */
- (NSColor*)noteColor:(int)number {
    return NoteColors[ notescale_from_number(number) ];
}

/** Retrieve the shade color */
- (NSColor*)shadeColor {
    return shadeColor;
}

/** Retrieve the shade2 color */
- (NSColor*)shade2Color {
    return shade2Color;
}

/** Get the lyrics for each track */
-(Array *)getLyrics:(Array *)tracks {
    BOOL hasLyrics = NO;
    Array *result = [Array new:[tracks count]];
    for (int tracknum = 0; tracknum < [tracks count]; tracknum++) {
        Array *lyrics = [[Array alloc] initWithCapacity:5];
        [result add:lyrics];
        MidiTrack *track = [tracks get:tracknum];
        if (track.lyrics == nil) {
            [lyrics release];
            continue;
        }
        hasLyrics = YES;
        for (int i = 0; i < [track.lyrics count]; i++) {
            MidiEvent *ev = [track.lyrics get:i];
            NSString *text = [[NSString alloc] initWithBytes:ev.metavalue length:ev.metalength encoding:NSUTF8StringEncoding];
            LyricSymbol *sym = [[LyricSymbol alloc] init];
            [sym setStartTime:ev.startTime];
            [sym setText:text];
            [text release];
            [lyrics add:sym];
            [sym release];
        }
        [lyrics release];
    }
    if (!hasLyrics) {
        return nil;
    }
    else {
        return result;
    }
}

/** Add the lyric symbols to the corresponding staffs */
-(void)addLyrics:(Array*)tracklyrics toStaffs:(Array*)thestaffs {
    for (int i = 0; i < [thestaffs count]; i++) {
        Staff *staff = [thestaffs get:i];
        Array *lyrics = [tracklyrics get:[staff tracknum]];
        [staff addLyrics:lyrics];
    }
}


/* Set the zoom level to display at (1.0 == 100%).
 * Recalculate the SheetMusic width and height based on the
 * zoom level.  Then redraw the SheetMusic. 
 */
- (void)setZoom:(float)value {
    zoom = value;
    NSRect rect = [self frame];
    NSSize size = rect.size;
    float width = 0;
    float height = 0;
    for (int i = 0; i < [staffs count]; i++) {
        Staff *staff = [staffs get:i];
        width = max(width, staff.width * zoom);
        height += ([staff height] * zoom);
    }
    size.width = (int)width + 2;
    size.height = ((int)height) + LeftMargin;
    rect.size.width = size.width;
    rect.size.height = size.height;

    [self setFrame:rect];
    rect = [self frame];
    [self display];
}

/** Return true if the sheet music should display the note letters */
- (int)showNoteLetters {
    return showNoteLetters;
}

/** Get the main key signature */
-(KeySignature*)mainkey {
    return mainkey;
}


/** Set the size of the notes, large or small.  Smaller notes means
 * more notes per staff.
 */
+(void)setNoteSize:(BOOL)largenotes {
    LineWidth = 1;
    LeftMargin = 4;
    if (largenotes)
        LineSpace = 7;
    else
        LineSpace = 5;

    StaffHeight = LineSpace*4 + LineWidth*5;
    NoteHeight = LineSpace + LineWidth;
    NoteWidth = (3 * LineSpace) / 2;
}

/** Write the MIDI file title at the top of the page */
- (void)drawTitle {
    /* Set the font attribute */
    NSFont *font = [NSFont boldSystemFontOfSize:12.0];
    NSArray *keys = [NSArray arrayWithObjects:NSFontAttributeName, nil];
    NSArray *values = [NSArray arrayWithObjects:font, nil];
    NSDictionary *dict = [NSDictionary dictionaryWithObjects:values forKeys:keys];

    NSArray *parts = [filename pathComponents];
    NSString *name = [parts lastObject];
    NSString *title = [MidiFile titleName:name];

    NSPoint point = NSMakePoint(LeftMargin, 0);
    [title drawAtPoint:point withAttributes:dict];
}


- (NSAttributedString*)pageHeader {
    NSAttributedString *attr = [[NSAttributedString alloc]
                                 initWithString:@""];
    return [attr autorelease];
}


- (NSAttributedString*)pageFooter {
    NSPrintOperation *op = [NSPrintOperation currentOperation];
    int num = [op currentPage];
    NSString *pagenum = [NSString stringWithFormat:@"%d", num];
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc]
                                       initWithString:pagenum];
    [attr setAlignment:NSRightTextAlignment range:NSMakeRange(0, [pagenum length])];
    return [attr autorelease];
}


/** Draw the SheetMusic.
 * If drawing to the screen, scale the graphics by the current zoom factor.
 * If printing, scale the graphics by the paper page size.
 * Get the vertical start and end points of the clip area.
 * Only draw Staffs which lie inside the clip area.
 */
- (void)drawRect:(NSRect)rect {
    NSGraphicsContext *gc = [NSGraphicsContext currentContext];
    [gc setShouldAntialias:YES];

    NSBezierPath *path = [NSBezierPath bezierPathWithRect:rect];
    [[NSColor whiteColor] setFill];
    [path fill];
    [[NSColor blackColor] setFill];

    NSAffineTransform *trans;
    NSRect clip;

    if ([NSGraphicsContext currentContextDrawingToScreen]) {
        trans = [NSAffineTransform transform];
        [trans scaleXBy:zoom yBy:zoom];
        [trans concat];
        clip = NSMakeRect((int)(rect.origin.x / zoom),
                          (int)(rect.origin.y / zoom),
                          (int)(rect.size.width / zoom),
                          (int)(rect.size.height / zoom) );
    }
    else {
        NSSize pagesize = [self printerPageSize];
        float scale = pagesize.width / (1.0 * PageWidth);
        trans = [NSAffineTransform transform];
        [trans scaleXBy:scale yBy:scale];
        [trans concat];
        clip = NSMakeRect(0,
                          (int)(rect.origin.y / scale),
                          (int)(rect.size.width / scale),
                          (int)(rect.size.height / scale) );
        [self drawTitle];
    }

    int ypos = TitleHeight;

    for (int i =0; i < [staffs count]; i++) {
        Staff *staff = [staffs get:i];
        if ((ypos + [staff height] < clip.origin.y) || (ypos > clip.origin.y + clip.size.height)) {
            /* Staff is not in the clip, don't need to draw it */
        }
        else {
            trans = [NSAffineTransform transform];
            [trans translateXBy:0 yBy:ypos];
            [trans concat];
            [staff drawRect:clip];
            trans = [NSAffineTransform transform];
            [trans translateXBy:0 yBy:-ypos];
            [trans concat];
        }

        ypos += [staff height];
    }

    if ([NSGraphicsContext currentContextDrawingToScreen]) {
        trans = [NSAffineTransform transform];
        [trans scaleXBy:(1.0/zoom) yBy:(1.0/zoom)];
        [trans concat];
    }
    else {
        NSSize pagesize = [self printerPageSize];
        float scale = pagesize.width / (1.0 * PageWidth);
        trans = [NSAffineTransform transform];
        [trans scaleXBy:(1.0/scale) yBy:(1.0/scale)];
        [trans concat];
    }
}


/**
 * Return the number of pages needed to print this sheet music.
 * This method is called by NSPrintOperation to 
 * determine the number of pages this view has.
 *
 * A staff should fit within a single page, not be split across two pages.
 * If the sheet music has exactly 2 tracks, then two staffs should
 * fit within a single page, and not be split across two pages.
 */
- (BOOL)knowsPageRange:(NSRange*)range {
    int num = 1;
    int currheight = TitleHeight;
    NSSize pagesize = [self printerPageSize];
    float scale = pagesize.width / (1.0 * PageWidth);
    int viewPageHeight = (int)(pagesize.height / scale);

    if (numtracks == 2 && ([staffs count] % 2) == 0) {
        for (int i = 0; i < [staffs count]; i += 2) {
            int heights = [(Staff*)[staffs get:i] height] +
                          [(Staff*)[staffs get:i+1] height];
            if (currheight + heights > viewPageHeight) {
                num++;
                currheight = heights;
            }
            else {
                currheight += heights;
            }
        }
    }
    else {
        for (int i = 0; i < [staffs count]; i++) {
            Staff *staff = [staffs get:i];
            if (currheight + [staff height] > viewPageHeight) {
                num++;
                currheight = [staff height];
            }
            else {
                currheight += [staff height];
            }
        }
    }
    range->location = 1;
    range->length = num;
    return YES;
}


/** Given a page number (for printing), return the drawing
 * rectangle that corresponds to that page number. This method
 * is used to print to a printer, and to save as a PDF file.
 */
- (NSRect)rectForPage:(int)pagenumber {
    NSSize pagesize = [self printerPageSize];
    float scale = pagesize.width / (1.0 * PageWidth);
    int viewPageHeight = (int)(pagesize.height / scale);

    NSRect rect = NSMakeRect(0, 0, pagesize.width, 0);

    int pagenum = 1;
    int staffnum = 0;
    int ypos = 0;

    if (numtracks == 2 && ([staffs count] % 2) == 0) {
        /* Determine the "y" (vertical) start of the rectangle.
         * Skip the staffs until we reach the given page number 
         */
        int ypos = TitleHeight;
        if (pagenumber > 1) {
            rect.origin.y = TitleHeight;
        }
        while (pagenum < pagenumber && staffnum + 1 < [staffs count]) {
            int staffheights = [(Staff*)[staffs get:staffnum] height] +
                               [(Staff*)[staffs get:staffnum+1] height];

            if (ypos + staffheights >= viewPageHeight) {
                pagenum++;
                ypos = 0;
            }
            else {
                ypos += staffheights;
                rect.origin.y += staffheights;
                staffnum += 2;
            }
        }
        if (staffnum >= [staffs count]) {
            rect.size.height = 0;   /* Return an empty rectangle */
            return rect;
        }

        /* Determine the height of the rectangle to draw. */
        rect.size.height = 0;
        if (pagenumber == 1) {
            rect.size.height += TitleHeight;
        }
        for (; staffnum+1 < [staffs count]; staffnum += 2) {
            int staffheights = [(Staff*)[staffs get:staffnum] height] +
                               [(Staff*)[staffs get:staffnum+1] height];
            if (rect.size.height + staffheights >= viewPageHeight) {
                break;
            }
            rect.size.height += staffheights;
        }
    }

    else {
        /* Determine the "y" (vertical) start of the rectangle.
         * Skip the staffs until we reach the given page number 
         */
        int ypos = TitleHeight;
        if (pagenumber > 1) {
            rect.origin.y = TitleHeight;
        }
        while (pagenum < pagenumber && staffnum < [staffs count]) {
            int staffheight = [(Staff*)[staffs get:staffnum] height]; 

            if (ypos + staffheight >= viewPageHeight) {
                pagenum++;
                ypos = 0;
            }
            else {
                ypos += staffheight;
                rect.origin.y += staffheight;
                staffnum++;
            }
        }
        if (staffnum >= [staffs count]) {
            rect.size.height = 0;   /* Return an empty rectangle */
            return rect;
        }

        /* Determine the height of the rectangle to draw. */
        rect.size.height = 0;
        if (pagenumber == 1) {
            rect.size.height = TitleHeight;
        }
        for (; staffnum < [staffs count]; staffnum++) {
            int staffheight = [(Staff*)[staffs get:staffnum] height];
            if (rect.size.height + staffheight >= viewPageHeight) {
                break;
            }
            rect.size.height += staffheight;
        }
    }

    /* Convert the y location and height from view coordinates to printer coordinates */
    rect.origin.x = 0;
    rect.origin.y = rect.origin.y * scale;
    rect.size.width = pagesize.width;
    rect.size.height = rect.size.height * scale;

    return rect;
} 

/** Get the height of the printer page */
- (NSSize)printerPageSize {
    NSPrintInfo *info = [[NSPrintOperation currentOperation] printInfo];
    NSSize size = [info paperSize];
    size.height = size.height - [info topMargin] - [info bottomMargin];
    size.width = size.width - [info leftMargin] - [info rightMargin];
    return size;
}

/** Shade all the chords played at the given pulse time.
 *  Loop through all the staffs and call staff.shadeNotes().
 *  If scrollGradually is true, scroll gradually (smooth scrolling)
 *  to the shaded notes.
 */
- (void)shadeNotes:(int)currentPulseTime withPrev:(int)prevPulseTime 
                   gradualScroll:(BOOL)gradualScroll {
    if (![self canDraw]) {
        return;
    }
    [self lockFocus];
    NSGraphicsContext *gc = [NSGraphicsContext currentContext];
    [gc setShouldAntialias:YES];

    NSAffineTransform *trans = [NSAffineTransform transform];
    [trans scaleXBy:zoom yBy:zoom];
    [trans concat];

    int ypos = TitleHeight;
    int x_shade = 0;
    int y_shade = 0;

    for (int i = 0; i < [staffs count]; i++) {
        Staff *staff = [staffs get:i];
        trans = [NSAffineTransform transform];
        [trans translateXBy:0 yBy:ypos];
        [trans concat];
        [staff shadeNotes:currentPulseTime withPrev:prevPulseTime andX:&x_shade andColor:shadeColor];
        trans = [NSAffineTransform transform];
        [trans translateXBy:0 yBy:-ypos];
        [trans concat];

        ypos += [staff height];
        if (currentPulseTime >= staff.endTime) {
            y_shade += [staff height];
        }
    }

    trans = [NSAffineTransform transform];
    [trans scaleXBy:(1.0/zoom) yBy:(1.0/zoom)];
    [trans concat];

    x_shade = (int)(x_shade * zoom);
    y_shade -= NoteHeight;
    y_shade = (int)(y_shade * zoom);

    NSPoint shadePos;
    shadePos.x = x_shade;
    shadePos.y = y_shade;
    if (currentPulseTime >= 0) {
        [self scrollToShadedNotes:shadePos gradualScroll:gradualScroll];
    }
    [[NSGraphicsContext currentContext] flushGraphics];
    [self unlockFocus];

}

/** Scroll the sheet music so that the shaded notes are visible.
  * If scrollGradually is true, scroll gradually (smooth scrolling)
  * to the shaded notes.
  */
- (void)scrollToShadedNotes:(NSPoint)shadePos gradualScroll:(BOOL)gradualScroll {
    int x_shade = shadePos.x;
    int y_shade = shadePos.y;

    NSClipView *clipview = (NSClipView*) [self superview];
    NSScrollView *scrollView = (NSScrollView*) [clipview superview];
    NSRect scrollRect = [clipview documentVisibleRect];
    NSPoint newPos;
    newPos.x = scrollRect.origin.x; newPos.y = scrollRect.origin.y;

    if (scrollVert) {
        int scrollDist = (int)(y_shade - scrollRect.origin.y);

        if (gradualScroll) {
            if (scrollDist > (zoom * StaffHeight * 8))
                scrollDist = scrollDist / 2;
            else if (scrollDist > (NoteHeight * 3 * zoom))
                scrollDist = (int)(NoteHeight * 3 * zoom);
        }
        newPos.y += scrollDist;
    }
    else {
        int x_view = (int)(scrollRect.origin.x + 40 * scrollRect.size.width/100);
        int xmax   = (int)(scrollRect.origin.x + 65 * scrollRect.size.width/100);
        int scrollDist = x_shade - x_view;

        if (gradualScroll) {
            if (x_shade > xmax)
                scrollDist = (x_shade - x_view)/3;
            else if (x_shade > x_view)
                scrollDist = (x_shade - x_view)/6;
        }

        newPos.x += scrollDist;
        if (newPos.x < 0) {
            newPos.x = 0;
        }
    }
    [clipview scrollToPoint:newPos]; 
    [scrollView reflectScrolledClipView:clipview];
}


/** Return the font attributes for drawing note letters
 *  and measure numbers.
 */
static NSDictionary *fontAttr = NULL;
+(NSDictionary*)fontAttributes {
    if (fontAttr == NULL) {
        NSFont *font = [NSFont systemFontOfSize:10.0];
        NSArray *keys = [NSArray arrayWithObjects:NSFontAttributeName, nil];
        NSArray *values = [NSArray arrayWithObjects:font, nil];
        fontAttr = [NSDictionary dictionaryWithObjects:values forKeys:keys];
        fontAttr = [fontAttr retain];
    }
    return fontAttr;
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (BOOL)isFlipped {
    return YES;
}

/** Set the callback target/action to invoke when a mouse is clicked. */
- (void)setMouseClickTarget:(NSObject*)obj action:(SEL)action {
    [mouseTarget release];
    mouseTarget = [obj retain];
    mouseAction = action;
}

- (void)mouseDown:(NSEvent *)event {
    if (mouseTarget != nil) {
        [mouseTarget performSelector:mouseAction withObject:event];
    }
}

/** Return the pulseTime corresponding to the given point on the SheetMusic.
 *  First, find the staff corresponding to the point.
 *  Then, within the staff, find the notes/symbols corresponding to the point,
 *  and return the StartTime (pulseTime) of the symbols.
 */
-(int)pulseTimeForPoint:(NSPoint)point {
    NSPoint scaledPoint = NSMakePoint((int)(point.x / zoom), (int)(point.y / zoom));
    int y = 0;
    for (int i = 0; i < [staffs count]; i++) {
        Staff *staff = [staffs get:i];
        if (scaledPoint.y >= y && scaledPoint.y <= y + [staff height]) {
            return [staff pulseTimeForPoint:scaledPoint];
        }
        y += [staff height];
    }
    return -1;
}


- (void)dealloc {
    [staffs release];
    [super dealloc];
}


- (NSString*) description {
    NSString *result = [NSString stringWithFormat:@"SheetMusic staffs=%d\n", [staffs count]];
    for (int i = 0; i < [staffs count]; i++) {
        Staff *staff = [staffs get:i];
        result = [result stringByAppendingString:[staff description]];
    }
    result = [result stringByAppendingString:@"End SheetMusic\n"];
    return result;
}


@end


