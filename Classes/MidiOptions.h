/*
 * Copyright (c) 2007-2013 Madhav Vaidyanathan
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License version 2.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 */

#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>
#import <Foundation/NSZone.h>
#import <Foundation/NSException.h>
#import <AppKit/NSColor.h>
#import "Array.h"
#import "IntArray.h"
#import "TimeSignature.h"

/* THe possible values for showNoteLetters */
enum { 
     NoteNameNone = 0, 
     NoteNameLetter, 
     NoteNameFixedDoReMi, 
     NoteNameMovableDoReMi, 
     NoteNameFixedNumber, 
     NoteNameMovableNumber
};

@class MidiFile;

/** @class MidiOptions
 *
 * The MidiOptions class contains the available options for
 * modifying the sheet music and sound. These options are
 * collected from the menu/dialog settings, and then are passed
 * to the SheetMusic and MidiPlayer classes.
 */
@interface MidiOptions : NSObject <NSCopying> {
    /* Sheet Music options */
    NSString *filename;      /** The full Midi filename */
    NSString *title;         /** The Midi song title */
    IntArray *tracks;        /** Which tracks to display (true = display) */
    BOOL scrollVert;         /** Whether to scroll vertically or horizontally */
    int numtracks;           /** Total number of tracks */
    BOOL largeNoteSize;      /** Display large or small note sizes */
    BOOL twoStaffs;          /** Combine tracks into two staffs ? */
    int showNoteLetters;     /** Show the name (A, A#, etc) next to the notes */
    BOOL showLyrics;         /** Show the lyrics */
    BOOL showMeasures;       /** Show the measure numbers for each staff */
    int shifttime;           /** Shift note starttimes by the given amount */
    int transpose;           /** Shift note key up/down by given amount */
    int key;                 /** Use the given KeySignature (notescale) */
    TimeSignature *time;     /** Use the given time signature */
    int combineInterval;     /** Combine notes within given time interval (msec) */
    Array* colors;           /** The note colors to use */
    NSColor* shadeColor;     /** The color to use for shading */
    NSColor* shade2Color;    /** The color to use for shading the left hand piano */

    /* Sound options */
    IntArray *mute;          /** Which tracks to mute (true = mute) */
    int  tempo;              /** The tempo, in microseconds per quarter note */
    int  pauseTime;          /** Start the midi music at the given pause time */
    IntArray *instruments;   /** The instruments to use per track */
    BOOL useDefaultInstruments;   /** If true, don't change instruments */
    BOOL playMeasuresInLoop;      /** Play the selected measures in a loop */
    int  playMeasuresInLoopStart; /** Start measure to play in loop */
    int  playMeasuresInLoopEnd;   /** End measure to play in loop */
}

@property (nonatomic, retain) NSString *filename;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) IntArray *tracks;
@property (nonatomic, assign) BOOL scrollVert;
@property (nonatomic, assign) int numtracks;
@property (nonatomic, assign) BOOL largeNoteSize;
@property (nonatomic, assign) BOOL twoStaffs;
@property (nonatomic, assign) int showNoteLetters;
@property (nonatomic, assign) BOOL showLyrics;
@property (nonatomic, assign) BOOL showMeasures;
@property (nonatomic, assign) int shifttime;
@property (nonatomic, assign) int transpose;
@property (nonatomic, assign) int key;
@property (nonatomic, retain) TimeSignature *time;
@property (nonatomic, assign) int combineInterval;
@property (nonatomic, retain) Array* colors;
@property (nonatomic, retain) NSColor* shadeColor;
@property (nonatomic, retain) NSColor* shade2Color;
@property (nonatomic, retain) IntArray *mute;
@property (nonatomic, assign) int tempo;
@property (nonatomic, assign) int pauseTime;
@property (nonatomic, retain) IntArray *instruments;
@property (nonatomic, assign) BOOL useDefaultInstruments;
@property (nonatomic, assign) BOOL playMeasuresInLoop;
@property (nonatomic, assign) int playMeasuresInLoopStart;
@property (nonatomic, assign) int playMeasuresInLoopEnd;

- (MidiOptions *)initFromMidi:(MidiFile *)midifile;
- (NSDictionary *)toDict;
- (MidiOptions *)initFromDict:(NSDictionary *)dict;
- (void)merge:(MidiOptions *)options;

@end

