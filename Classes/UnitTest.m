/*
 * Copyright (c) 2009-2010 Madhav Vaidyanathan
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License version 2.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 */
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <assert.h>

#import <Foundation/NSAutoreleasePool.h>
#import "MidiFile.h"
#import "KeySignature.h"
#import "TimeSignature.h"
#import "SymbolWidths.h"
#import "AccidSymbol.h"
#import "ClefSymbol.h"
#import "ClefMeasures.h"
#import "ChordSymbol.h"
#import "SheetMusic.h"
#import <SenTestingKit/SenTestingKit.h>

/* Print NSStrings, for debugging */
void prints(NSString *str) {
    const char *cstr = [str cStringUsingEncoding:NSUTF8StringEncoding];
    int fd = open("/tmp/mydebug.txt", O_CREAT|O_APPEND|O_WRONLY, 0644);
    int offset = 0;
    int len = strlen(cstr);
    while (offset < len) {
        int n = write(fd, &cstr[offset], len - offset);
        if (n > 0)
            offset += n;
        if (n == 0)
            break;
        if (n == -1 && errno != EINTR)
            break;
    }
    write(fd, "\n", 1);
    close(fd);
}

/* The filename for storing the temporary midi file */
NSString *testfile = @"test.mid";
const char *ctestfile = "test.mid";

/* Write the given data to the test file "test.mid" */
void writeTestFile(u_char* data, int len) {
    int fd = open(ctestfile, O_CREAT|O_WRONLY, 0644);
    assert(fd >= 0);
    int off = 0;
    int n;
    do {
        n = write(fd, &data[off], len - off);
        if (n > 0) {
            off += n;
        }
    }
    while (off < len);
    close(fd);
}



/* Test cases for the MidiFileReader class */
@interface MidiFileReaderTest :SenTestCase 
{
}
- (void)testByte;
- (void)testShort;
- (void)testInt;
- (void)testVarlen;
- (void)testAscii;
- (void)testSkip;
@end

@implementation MidiFileReaderTest


/* Create a variable-length encoded integer from the given bytes.
 * A varlen integer ends when a byte less than 0x80 (128).
 */
static int varlen(u_char b1, u_char b2, u_char b3, u_char b4) {
    int result = ((b1 & 0x7F) << 21) |
                 ((b2 & 0x7F) << 14) | 
                 ((b3 & 0x7F) << 7)  |
                 (b4 & 0x7F);
    return result;
}


/* Test that MidiFileReader.readByte() returns the correct
 * u_char, and that the file offset is incremented by 1.
 */
- (void)testByte {
    u_char data[] = {10, 20, 30, 40, 50 };
    writeTestFile(data, 5);
    MidiFileReader *reader = [[MidiFileReader alloc] initWithFile:testfile];

    int offset = 0;
    for (int i = 0; i < 5; i++) {
        u_char b = data[i];
        STAssertTrue([reader offset] == offset, @"");
        STAssertTrue([reader peek] == b, @"");
        STAssertTrue([reader readByte] == b, @"");
        offset++;
    }
    [reader release];
    unlink(ctestfile);
}

/* Test that MidiFileReader.readShort() returns the correct
 * unsigned short, and that the file offset is incremented by 2.
 */
- (void)testShort {
    u_short nums[] = { 200, 3000, 10000, 40000 };
    u_char data[4 * 2];
    int index = 0; 
    for (int i = 0; i < 4; i++) {
        data[index]   = (u_char)( (nums[i] >> 8) & 0xFF );
        data[index+1] = (u_char)( nums[i] & 0xFF );
        index += 2;
    }
    writeTestFile(data, 4*2);
    MidiFileReader *reader = [[MidiFileReader alloc] initWithFile:testfile];

    int offset = 0;
    for (int i = 0; i < 4; i++) {
        u_short u = nums[i];
        STAssertTrue([reader offset] == offset, @"");
        STAssertTrue([reader readShort] == u, @"");
        offset += 2;
    }
    [reader release];
    unlink(ctestfile);
}
 
/* Test that MidiFileReader.readInt() returns the correct
 * int, and that the file offset is incremented by 4.
 */
- (void) testInt {
    int nums[] = { 200, 10000, 80000, 999888777 };
    u_char data[4 * 4];
    int index = 0; 
    for (int i = 0; i < 4; i++) {
        data[index]   = (u_char)( (nums[i] >> 24) & 0xFF );
        data[index+1] = (u_char)( (nums[i] >> 16) & 0xFF );
        data[index+2] = (u_char)( (nums[i] >> 8) & 0xFF );
        data[index+3] = (u_char)(  nums[i] & 0xFF );
        index += 4;
    }
    writeTestFile(data, 4*4);
    MidiFileReader *reader = [[MidiFileReader alloc] initWithFile:testfile];

    int offset = 0;
    for (int i = 0; i < 4; i++) {
        int x = nums[i];
        STAssertTrue([reader offset] == offset, @"");
        STAssertTrue([reader readInt] == x, @"");
        offset += 4;
    }
    [reader release];
    unlink(ctestfile);
}

/* Test that MidiFileReader.readVarlen() correctly parses variable
 * length integers.  A variable length int ends when the u_char is
 * less than 0x80 (128). 
 */
- (void) testVarlen {
    u_char data[12];

    data[0] = 0x40;

    data[1] = 0x90; 
    data[2] = 0x30;

    data[3] = 0x81;
    data[4] = 0xA5;
    data[5] = 0x10;

    data[6] = 0x81;
    data[7] = 0x84;
    data[8] = 0xBF;
    data[9] = 0x05;

    writeTestFile(data, 10);
    MidiFileReader *reader = [[MidiFileReader alloc] initWithFile:testfile];

    int len = varlen(0, 0, 0, data[0]);
    STAssertTrue([reader offset] == 0, @"");
    STAssertTrue([reader readVarlen] == len, @"");
    STAssertTrue([reader offset] == 1, @"");

    len = varlen(0, 0, data[1], data[2]);
    STAssertTrue([reader readVarlen] == len, @"");
    STAssertTrue([reader offset] == 3, @"");

    len = varlen(0, data[3], data[4], data[5]);
    STAssertTrue([reader readVarlen] == len, @"");
    STAssertTrue([reader offset] == 6, @"");

    len = varlen(data[6], data[7], data[8], data[9]);
    STAssertTrue([reader readVarlen] == len, @"");
    STAssertTrue([reader offset] == 10, @"");
    
    [reader release];
    unlink(ctestfile);
}

/* Test that MidiFileReader.readASCII() returns the correct
 * ascii chars, and that the file offset is incremented by the
 * length of the chars.
 */
- (void) testAscii {
    u_char data[] = { 65, 66, 67, 68, 69, 70 };
    char *str;
    int cmp;
    writeTestFile(data, 6);

    MidiFileReader *reader = [[MidiFileReader alloc] initWithFile:testfile];
    STAssertTrue([reader offset] == 0, @"");
    str = [reader readAscii:3];
    cmp = strncmp(str, "ABC", 3);
    STAssertTrue(cmp == 0, @"");
    STAssertTrue([reader offset] == 3, @"");
    str = [reader readAscii:3];
    cmp = strncmp(str, "DEF", 3);
    STAssertTrue(cmp == 0, @"");
    STAssertTrue([reader offset] == 6, @"");
    [reader release];
    unlink(ctestfile);
}

/* Test that MidiFileReader.skip() skips the correct amount
 * of bytes, and that the file offset is incremented by the
 * number of bytes skipped.
 */ 
- (void) testSkip {
    u_char data[] = { 65, 66, 67, 68, 69, 70, 71 };
    writeTestFile(data, 7);
    MidiFileReader *reader = [[MidiFileReader alloc] initWithFile:testfile];
    STAssertTrue([reader offset] == 0, @"");
    [reader skip:3];
    STAssertTrue([reader offset] == 3, @"");
    STAssertTrue([reader readByte] == 68, @"");
    [reader skip:2];
    STAssertTrue([reader offset] == 6, @"");
    STAssertTrue([reader readByte] == 71, @"");
    STAssertTrue([reader offset] == 7, @"");
    [reader release];
    unlink(ctestfile);
}

@end  /* MidiFileReaderTest */


/* The test cases for the MidiFile class */
@interface MidiFileTest :SenTestCase {
}
- (void)testSequentialNotes;
- (void)testOverlappingNotes;
- (void)testMissingEventCode;
- (void)testVariousEvents;
- (void)testMetaEvents;
- (void)testMultipleTracks;
- (void)testTruncatedFile;
- (void)testChangeSoundTempo;
- (void)testChangeSoundTranspose;
- (void)testChangeSoundInstruments;
- (void)testChangeSoundTracks;
- (void)testChangeSoundPauseTime;
- (void)testChangeSoundPerChannelTempo;
- (void)testChangeSoundPerChannelTranspose;
- (void)testChangeSoundPerChannelInstruments;
- (void)testChangeSoundPerChannelTracks;
- (void)testChangeSoundPerChannelPauseTime;
- (void)testSplitTrack;
- (void)testCombineToSingleTrack;
- (void)testRoundStartTimes;
- (void)testRoundDurations;

@end

@implementation MidiFileTest

/* Create a Midi File with 3 sequential notes, where each
 * note starts after the previous one ends (timewise).
 *
 * Parse the MidiFile. Verify the following:
 * - The time signature
 * - The number of tracks
 * - The midi note numbers, start time, and duration
 */
- (void) testSequentialNotes {
    u_char notenum = 60;
    u_char quarternote = 240;
    u_char numtracks = 1;
    u_char velocity = 80;

    u_char data[] = {
        77, 84, 104, 100,        /* MThd ascii header */
        0, 0, 0, 6,              /* length of header in bytes */
        0, 1,                    /* one or more simultaneous tracks */
        0, numtracks, 
        0, quarternote,  
        77, 84, 114, 107,        /* MTrk ascii header */
        0, 0, 0, 24,             /* Length of track, in bytes */

        /* time_interval, NoteEvent, note number, velocity */
        0,  EventNoteOn,  notenum,   velocity,
        60, EventNoteOff, notenum,   0,
        0,  EventNoteOn,  notenum+1, velocity,
        30, EventNoteOff, notenum+1, 0,
        0,  EventNoteOn,  notenum+2, velocity,
        90, EventNoteOff, notenum+2, 0
    };

    writeTestFile(data, sizeof(data));
    MidiFile *midifile = [[MidiFile alloc] initWithFile:testfile];
    unlink(ctestfile);

    STAssertTrue([(Array*)midifile.tracks count] == 1, @"");
    TimeSignature *time = midifile.time;
    STAssertTrue(time.numerator == 4, @"");
    STAssertTrue(time.denominator == 4, @"");
    STAssertTrue(time.quarter == quarternote, @"");
    STAssertTrue(time.measure == quarternote * 4, @"");

    MidiTrack *track = [midifile.tracks get:0];
    Array *notes = track.notes;
    STAssertTrue([notes count] == 3, @"");


    STAssertTrue([notes getNote:0].startTime == 0, @"");
    STAssertTrue([notes getNote:0].number == notenum, @"");
    STAssertTrue([notes getNote:0].duration == 60, @"");

    STAssertTrue([notes getNote:1].startTime == 60, @"");
    STAssertTrue([notes getNote:1].number == notenum+1, @"");
    STAssertTrue([notes getNote:1].duration == 30, @"");

    STAssertTrue([notes getNote:2].startTime == 90, @"");
    STAssertTrue([notes getNote:2].number == notenum+2, @"");
    STAssertTrue([notes getNote:2].duration == 90, @"");

    [midifile release];
}


/* Create a Midi File with 3 notes that overlap timewise,
 * where a note starts before the previous note ends.
 *
 * Parse the MidiFile. Verify the following:
 * - The time signature
 * - The number of tracks
 * - The midi note numbers, start time, and duration
 */
- (void) testOverlappingNotes {
    u_char notenum = 60;
    u_char quarternote = 240;
    u_char numtracks = 1;
    u_char velocity = 80;

    u_char data[] = {
        77, 84, 104, 100,        /* MThd ascii header  */
        0, 0, 0, 6,              /* length of header in bytes */
        0, 1,                    /* one or more simultaneous tracks */
        0, numtracks, 
        0, quarternote,  
        77, 84, 114, 107,        /* MTrk ascii header */
        0, 0, 0, 24,             /* Length of track, in bytes */

        /* time_interval, NoteEvent, note number, velocity */
        0,  EventNoteOn,  notenum,   velocity,
        30, EventNoteOn,  notenum+1, velocity,
        30, EventNoteOn,  notenum+2, velocity,
        30, EventNoteOff, notenum+1, 0,
        30, EventNoteOff, notenum,   0,
        30, EventNoteOff, notenum+2, 0
    };

    writeTestFile(data, sizeof(data));
    MidiFile *midifile = [[MidiFile alloc] initWithFile:testfile];
    unlink(ctestfile);

    STAssertTrue([midifile.tracks count] == 1, @"");
    TimeSignature *time = midifile.time;
    STAssertTrue(time.numerator == 4, @"");
    STAssertTrue(time.denominator == 4, @"");
    STAssertTrue(time.quarter == quarternote, @"");
    STAssertTrue(time.measure == quarternote * 4, @"");

    MidiTrack *track = [midifile.tracks get:0];

    Array* notes = track.notes;
    STAssertTrue([notes count] == 3, @"");

    STAssertTrue([notes getNote:0].startTime == 0, @"");
    STAssertTrue([notes getNote:0].number == notenum, @"");
    STAssertTrue([notes getNote:0].duration == 120, @"");
    STAssertTrue([notes getNote:1].startTime == 30, @"");
    STAssertTrue([notes getNote:1].number == notenum+1, @"");
    STAssertTrue([notes getNote:1].duration == 60, @"");

    STAssertTrue([notes getNote:2].startTime == 60, @"");
    STAssertTrue([notes getNote:2].number == notenum+2, @"");
    STAssertTrue([notes getNote:2].duration == 90, @"");

    [midifile release];
}


/* Create a Midi File with 3 notes, where the event code
 * (EventNoteOn, EventNoteOff) is missing for notes 2 and 3.
 *
 * Parse the MidiFile. Verify the following:
 * - The time signature
 * - The number of tracks
 * - The midi note numbers, start time, and duration
 */
- (void) testMissingEventCode {
    u_char notenum = 60;
    u_char quarternote = 240;
    u_char numtracks = 1;
    u_char velocity = 80;

    u_char data[] = {
        77, 84, 104, 100,        /* MThd ascii header  */
        0, 0, 0, 6,              /* length of header in bytes */
        0, 1,                    /* one or more simultaneous tracks */
        0, numtracks, 
        0, quarternote,  
        77, 84, 114, 107,        /* MTrk ascii header */
        0, 0, 0, 20,             /* Length of track, in bytes */

        /* time_interval, NoteEvent, note number, velocity */
        0,  EventNoteOn,  notenum,   velocity,
        30,               notenum+1, velocity,
        30,               notenum+2, velocity,
        30, EventNoteOff, notenum+1, 0,
        30,               notenum,   0,
        30,               notenum+2, 0
    };

    writeTestFile(data, sizeof(data));
    MidiFile *midifile = [[MidiFile alloc] initWithFile:testfile];
    unlink(ctestfile);

    STAssertTrue([midifile.tracks count] == 1, @"");

    TimeSignature *time = midifile.time;
    STAssertTrue(time.numerator == 4, @"");
    STAssertTrue(time.denominator == 4, @"");
    STAssertTrue(time.quarter == quarternote, @"");
    STAssertTrue(time.measure == quarternote * 4, @"");

    MidiTrack *track = [midifile.tracks get:0];

    Array* notes = track.notes;
    STAssertTrue([notes count] == 3, @"");

    STAssertTrue([notes getNote:0].startTime == 0, @"");
    STAssertTrue([notes getNote:0].number == notenum, @"");
    STAssertTrue([notes getNote:0].duration == 120, @"");

    STAssertTrue([notes getNote:1].startTime == 30, @"");
    STAssertTrue([notes getNote:1].number == notenum+1, @"");
    STAssertTrue([notes getNote:1].duration == 60, @"");

    STAssertTrue([notes getNote:2].startTime == 60, @"");
    STAssertTrue([notes getNote:2].number == notenum+2, @"");
    STAssertTrue([notes getNote:2].duration == 90, @"");

    [midifile release];
}


/* Create a Midi File with 3 notes, and many extra events
 * (KeyPressure, ControlChange, ProgramChange, PitchBend).
 *
 * Parse the MidiFile. Verify the following:
 * - The time signature
 * - The number of tracks
 * - The midi note numbers, start time, and duration
 */
- (void) testVariousEvents {
    u_char notenum = 60;
    u_char quarternote = 240;
    u_char numtracks = 1;
    u_char velocity = 80;

    u_char data[] =  {
        77, 84, 104, 100,        /* MThd ascii header  */
        0, 0, 0, 6,              /* length of header in bytes */
        0, 1,                    /* one or more simultaneous tracks */
        0, numtracks, 
        0, quarternote,  
        77, 84, 114, 107,        /* MTrk ascii header */
        0, 0, 0, 39,             /* Length of track, in bytes */

        /* time_interval, NoteEvent, note number, velocity */
        0,  EventNoteOn,  notenum,   velocity,
        60, EventNoteOff, notenum,   0,
        0,  EventKeyPressure, notenum, 10,
        0,  EventControlChange, 10, 10,
        0,  EventNoteOn,  notenum+1, velocity,
        30, EventNoteOff, notenum+1, 0,
        0,  EventProgramChange, 10,
        0,  EventPitchBend, 0, 0,
        0,  EventNoteOn,  notenum+2, velocity,
        90, EventNoteOff, notenum+2, 0
    };

    writeTestFile(data, sizeof(data));
    MidiFile *midifile = [[MidiFile alloc] initWithFile:testfile];
    unlink(ctestfile);

    STAssertTrue([midifile.tracks count] == 1, @"");

    TimeSignature *time = midifile.time;
    STAssertTrue(time.numerator == 4, @"");
    STAssertTrue(time.denominator == 4, @"");
    STAssertTrue(time.quarter == quarternote, @"");
    STAssertTrue(time.measure == quarternote * 4, @"");

    MidiTrack *track = [midifile.tracks get:0];
    Array* notes = track.notes;
    STAssertTrue([notes count] == 3, @"");

    STAssertTrue([notes getNote:0].startTime == 0, @"");
    STAssertTrue([notes getNote:0].number == notenum, @"");
    STAssertTrue([notes getNote:0].duration == 60, @"");

    STAssertTrue([notes getNote:1].startTime == 60, @"");
    STAssertTrue([notes getNote:1].number == notenum+1, @"");
    STAssertTrue([notes getNote:1].duration == 30, @"");

    STAssertTrue([notes getNote:2].startTime == 90, @"");
    STAssertTrue([notes getNote:2].number == notenum+2, @"");
    STAssertTrue([notes getNote:2].duration == 90, @"");

    [midifile release];
}

/* Create a Midi File with 3 notes, and some meta-events
 * (Sequence, Key Signature)
 *
 * Parse the MidiFile. Verify the following:
 * - The time signature
 * - The number of tracks
 * - The midi note numbers, start time, and duration
 */
- (void) testMetaEvents {
    u_char notenum = 60;
    u_char quarternote = 240;
    u_char numtracks = 1;
    u_char velocity = 80;

    u_char data[] = {
        77, 84, 104, 100,        /* MThd ascii header  */
        0, 0, 0, 6,              /* length of header in bytes */
        0, 1,                    /* one or more simultaneous tracks */
        0, numtracks, 
        0, quarternote,  
        77, 84, 114, 107,        /* MTrk ascii header */
        0, 0, 0, 36,             /* Length of track, in bytes */

        /* time_interval, NoteEvent, note number, velocity */
        0,  EventNoteOn,  notenum,   velocity,
        60, EventNoteOff, notenum,   0,
        0,  MetaEvent, MetaEventSequence, 2, 0, 6,
        0,  EventNoteOn,  notenum+1, velocity,
        30, EventNoteOff, notenum+1, 0,
        0,  MetaEvent, MetaEventKeySignature, 2, 3, 0,
        0,  EventNoteOn,  notenum+2, velocity,
        90, EventNoteOff, notenum+2, 0
    };

    writeTestFile(data, sizeof(data));
    MidiFile *midifile = [[MidiFile alloc] initWithFile:testfile];
    unlink(ctestfile);

    STAssertTrue([midifile.tracks count] == 1, @"");
    STAssertTrue(midifile.time.numerator == 4, @"");
    STAssertTrue(midifile.time.denominator == 4, @"");
    STAssertTrue(midifile.time.quarter == quarternote, @"");
    STAssertTrue(midifile.time.measure == quarternote * 4, @"");

    MidiTrack *track = [midifile.tracks get:0];
    Array* notes = track.notes;
    STAssertTrue([notes count] == 3, @"");

    STAssertTrue([notes getNote:0].startTime == 0, @"");
    STAssertTrue([notes getNote:0].number == notenum, @"");
    STAssertTrue([notes getNote:0].duration == 60, @"");

    STAssertTrue([notes getNote:1].startTime == 60, @"");
    STAssertTrue([notes getNote:1].number == notenum+1, @"");
    STAssertTrue([notes getNote:1].duration == 30, @"");

    STAssertTrue([notes getNote:2].startTime == 90, @"");
    STAssertTrue([notes getNote:2].number == notenum+2, @"");
    STAssertTrue([notes getNote:2].duration == 90, @"");

    [midifile release];
}


/* Create a Midi File with 3 tracks, and 3 notes per track.
 *
 * Parse the MidiFile. Verify the following:
 * - The time signature
 * - The number of tracks
 * - The midi note numbers, start time, and duration
 */
- (void) testMultipleTracks {
    u_char notenum = 60;
    u_char quarternote = 240;
    u_char numtracks = 3;
    u_char velocity = 80;

    u_char data[] = {
        77, 84, 104, 100,        /* MThd ascii header  */
        0, 0, 0, 6,              /* length of header in bytes */
        0, 1,                    /* one or more simultaneous tracks */
        0, numtracks, 
        0, quarternote, 
 
        77, 84, 114, 107,        /* MTrk ascii header */
        0, 0, 0, 24,             /* Length of track, in bytes */
        /* time_interval, NoteEvent, note number, velocity */
        0,  EventNoteOn,  notenum,   velocity,
        60, EventNoteOff, notenum,   0,
        0,  EventNoteOn,  notenum+1, velocity,
        30, EventNoteOff, notenum+1, 0,
        0,  EventNoteOn,  notenum+2, velocity,
        90, EventNoteOff, notenum+2, 0,

        77, 84, 114, 107,        /* MTrk ascii header */
        0, 0, 0, 24,             /* Length of track, in bytes */
        /* time_interval, NoteEvent, note number, velocity */
        0,  EventNoteOn,  notenum+1, velocity,
        60, EventNoteOff, notenum+1, 0,
        0,  EventNoteOn,  notenum+2, velocity,
        30, EventNoteOff, notenum+2, 0,
        0,  EventNoteOn,  notenum+3, velocity,
        90, EventNoteOff, notenum+3, 0,

        77, 84, 114, 107,        /* MTrk ascii header */
        0, 0, 0, 24,             /* Length of track, in bytes */
        /* time_interval, NoteEvent, note number, velocity */
        0,  EventNoteOn,  notenum+2, velocity,
        60, EventNoteOff, notenum+2, 0,
        0,  EventNoteOn,  notenum+3, velocity,
        30, EventNoteOff, notenum+3, 0,
        0,  EventNoteOn,  notenum+4, velocity,
        90, EventNoteOff, notenum+4, 0,
    };

    writeTestFile(data, sizeof(data));
    MidiFile *midifile = [[MidiFile alloc] initWithFile:testfile];
    unlink(ctestfile);

    STAssertTrue([midifile.tracks count] == numtracks, @"");
    STAssertTrue(midifile.time.numerator == 4, @"");
    STAssertTrue(midifile.time.denominator == 4, @"");
    STAssertTrue(midifile.time.quarter == quarternote, @"");
    STAssertTrue(midifile.time.measure == quarternote * 4, @"");


    for (int tracknum = 0; tracknum < numtracks; tracknum++) {
        MidiTrack *track = [midifile.tracks get:tracknum];
        Array* notes = track.notes;
        STAssertTrue([notes count] == 3, @"");

        STAssertTrue([notes getNote:0].startTime == 0, @"");
        STAssertTrue([notes getNote:0].number == notenum + tracknum, @"");
        STAssertTrue([notes getNote:0].duration == 60, @"");

        STAssertTrue([notes getNote:1].startTime == 60, @"");
        STAssertTrue([notes getNote:1].number == notenum + tracknum + 1, @"");
        STAssertTrue([notes getNote:1].duration == 30, @"");

        STAssertTrue([notes getNote:2].startTime == 90, @"");
        STAssertTrue([notes getNote:2].number == notenum + tracknum + 2, @"");
        STAssertTrue([notes getNote:2].duration == 90, @"");
    }

    [midifile release];
}


/* Create a Midi File that is truncated, where the
 * track length is 30 bytes, but only 24 bytes of
 * track data are there.
 *
 * Verify that the MidiFile is still parsed successfully.
 */
- (void) testTruncatedFile {
    u_char notenum = 60;
    u_char quarternote = 240;
    u_char numtracks = 1;
    u_char velocity = 80;

    u_char data[] = {
        77, 84, 104, 100,        /* MThd ascii header */
        0, 0, 0, 6,              /* length of header in bytes */
        0, 1,                    /* one or more simultaneous tracks */
        0, numtracks, 
        0, quarternote,  
        77, 84, 114, 107,        /* MTrk ascii header */
        0, 0, 0, 30,             /* Length of track, in bytes. Should be 24. */

        /* time_interval, NoteEvent, note number, velocity */
        0,  EventNoteOn,  notenum,   velocity,
        60, EventNoteOff, notenum,   0,
        0,  EventNoteOn,  notenum+1, velocity,
        30, EventNoteOff, notenum+1, 0,
        0,  EventNoteOn,  notenum+2, velocity,
        90, EventNoteOff, notenum+2, 0
    };

    writeTestFile(data, sizeof(data));
    BOOL got_exception = NO;
    @try {
        MidiFile *midifile = [[MidiFile alloc] initWithFile:testfile];
    }
    @catch (MidiFileException* e) {
        got_exception = YES;
    }
    unlink(ctestfile);
    STAssertTrue(got_exception == NO, @"");
}

/* Create the midi file used by the testChangeSound() methods. */
- (MidiFile*) createTestChangeSoundMidiFile {
    u_char notenum = 60;
    u_char quarternote = 240;
    u_char numtracks = 3;
    u_char velocity = 80;

    u_char data[] = {
        77, 84, 104, 100,        /* MThd ascii header  */
        0, 0, 0, 6,              /* length of header in bytes */
        0, 1,                    /* one or more simultaneous tracks */
        0, numtracks, 
        0, quarternote, 
 
        77, 84, 114, 107,        /* MTrk ascii header */
        0, 0, 0, 34,             /* Length of track, in bytes */

        /* tempo event, len=3, tempo = 0x0032ff */
        0,  MetaEvent,    MetaEventTempo, 3, 0x0, 0x32, 0xff,
        /* instrument = 4 (Electric Piano 1) */
        0,  EventProgramChange, 4,

        /* time_interval, NoteEvent, note number, velocity */
        0,  EventNoteOn,  notenum,   velocity,
        60, EventNoteOff, notenum,   0,
        0,  EventNoteOn,  notenum+1, velocity,
        30, EventNoteOff, notenum+1, 0,
        0,  EventNoteOn,  notenum+2, velocity,
        90, EventNoteOff, notenum+2, 0,

        77, 84, 114, 107,        /* MTrk ascii header */
        0, 0, 0, 34,             /* Length of track, in bytes */

        /* tempo event, len=3, tempo = 0xa0b0cc */
        0,  MetaEvent,    MetaEventTempo, 3, 0xa0, 0xb0, 0xcc,
        /* instrument = 5 (Electric Piano 2) */
        0,  EventProgramChange, 5,

        /* time_interval, NoteEvent, note number, velocity */
        0,  EventNoteOn,  notenum+10, velocity,
        60, EventNoteOff, notenum+10, 0,
        0,  EventNoteOn,  notenum+11, velocity,
        30, EventNoteOff, notenum+11, 0,
        0,  EventNoteOn,  notenum+12, velocity,
        90, EventNoteOff, notenum+12, 0,

        77, 84, 114, 107,        /* MTrk ascii header */
        0, 0, 0, 34,             /* Length of track, in bytes */

        /* tempo event, len=3, tempo = 0x121244 */
        0,  MetaEvent,    MetaEventTempo, 3, 0x12, 0x12, 0x44,
        /* instrument = 0 (Acoustic Grand Piano) */
        0,  EventProgramChange, 0,

        /* time_interval, NoteEvent, note number, velocity */
        0,  EventNoteOn,  notenum+20, velocity,
        60, EventNoteOff, notenum+20, 0,
        0,  EventNoteOn,  notenum+21, velocity,
        30, EventNoteOff, notenum+21, 0,
        0,  EventNoteOn,  notenum+22, velocity,
        90, EventNoteOff, notenum+22, 0,
    };

    writeTestFile(data, sizeof(data));

    /* Verify the original Midi File */
    MidiFile *midifile = [[MidiFile alloc] initWithFile:testfile];
    STAssertTrue([midifile.tracks count] == 3, @"");
    STAssertTrue(((MidiTrack*)[midifile.tracks get:0]).instrument == 4, @"");
    STAssertTrue(((MidiTrack*)[midifile.tracks get:1]).instrument == 5, @"");
    STAssertTrue(((MidiTrack*)[midifile.tracks get:2]).instrument == 0, @"");
    for (int tracknum = 0; tracknum < 3; tracknum++) {
        MidiTrack *track = [midifile.tracks get:tracknum];
        Array* notes = track.notes;
        STAssertTrue([notes count] == 3, @"");

        STAssertTrue([notes getNote:0].startTime == 0, @"");
        STAssertTrue([notes getNote:0].number == notenum + 10*tracknum, @"");
        STAssertTrue([notes getNote:0].duration == 60, @"");

        STAssertTrue([notes getNote:1].startTime == 60, @"");
        STAssertTrue([notes getNote:1].number == notenum + 10*tracknum + 1, @"");
        STAssertTrue([notes getNote:1].duration == 30, @"");

        STAssertTrue([notes getNote:2].startTime == 90, @"");
        STAssertTrue([notes getNote:2].number == notenum + 10*tracknum + 2, @"");
        STAssertTrue([notes getNote:2].duration == 90, @"");
    }
    return midifile;
}


/* Test changing the tempo with the  changeSound() method.
 * Create a Midi File and parse it.
 * Call changeSound() with tempo = 0x405060.
 * Parse the new MidiFile, and verify the TimeSignature tempo is 0x405060.
 */
- (void) testChangeSoundTempo {
    MidiFile *midifile = [self createTestChangeSoundMidiFile];

    MidiOptions *options = [[MidiOptions alloc] initFromMidi:midifile];
    MidiFile *newmidi;

    options.tempo = 0x405060;
    int ret = [midifile changeSound:options toFile:testfile];
    STAssertTrue(ret == YES, @"");
    newmidi = [[MidiFile alloc] initWithFile:testfile];

    STAssertTrue([newmidi.tracks count] == 3, @"");
    STAssertTrue(newmidi.time.tempo == 0x405060, @"");
    [newmidi release];
    [midifile release];
    unlink(ctestfile);
}

/* Test transposing the notes with the changeSound() method.
 * Create a Midi File with 3 tracks, and 3 notes per track. Parse the MidiFile.
 * Call changeSound() with transpose = 10.
 * Parse the new MidiFile, and verify the MidiNote numbers are now 10 notes higher.
 */
- (void) testChangeSoundTranspose {
    u_char notenum = 60;

    MidiFile *midifile = [self createTestChangeSoundMidiFile];

    MidiOptions *options = [[MidiOptions alloc] initFromMidi:midifile];
    MidiFile *newmidi;

    options.transpose = 10;
    BOOL ret = [midifile changeSound:options toFile:testfile];
    STAssertTrue(ret == YES, @"");
    newmidi = [[MidiFile alloc] initWithFile:testfile];

    for (int tracknum = 0; tracknum < 3; tracknum++) {
        MidiTrack *track = [newmidi.tracks get:tracknum];
        Array* notes = track.notes;
        STAssertTrue([notes count] == 3, @"");

        STAssertTrue([notes getNote:0].startTime == 0, @"");
        STAssertTrue([notes getNote:0].number == notenum + 10*tracknum + 10, @"");
        STAssertTrue([notes getNote:0].duration == 60, @"");

        STAssertTrue([notes getNote:1].startTime == 60, @"");
        STAssertTrue([notes getNote:1].number == notenum + 10*tracknum + 11, @"");
        STAssertTrue([notes getNote:1].duration == 30, @"");

        STAssertTrue([notes getNote:2].startTime == 90, @"");
        STAssertTrue([notes getNote:2].number == notenum + 10*tracknum + 12, @"");
        STAssertTrue([notes getNote:2].duration == 90, @"");
    }
    [newmidi release];
    [midifile release];
    unlink(ctestfile);
}

/* Test changing the instruments with the changeSound() method.
 * Create a Midi File with 3 tracks.  Parse the MidiFile.
 * Call changeSound() with instruments [40,41,42].
 * Parse the new MidiFile, and verify the instruments are now Violin, Viola, and Cello.
 */
- (void) testChangeSoundInstruments {
    MidiFile *midifile = [self createTestChangeSoundMidiFile];

    MidiOptions *options = [[MidiOptions alloc] initFromMidi:midifile];
    MidiFile *newmidi;
    options.useDefaultInstruments = NO;
    [options.instruments set:40 index:0];
    [options.instruments set:41 index:1];
    [options.instruments set:42 index:2];
    BOOL ret = [midifile changeSound:options toFile:testfile];
    STAssertTrue(ret == YES, @"");
    newmidi = [[MidiFile alloc] initWithFile:testfile];
    STAssertTrue([newmidi.tracks count] == 3, @"");
    STAssertTrue([ [(MidiTrack*)[newmidi.tracks get:0] instrumentName] isEqual:@"Violin"], @"");
    STAssertTrue([ [(MidiTrack*)[newmidi.tracks get:1] instrumentName] isEqual:@"Viola"], @"");
    STAssertTrue([ [(MidiTrack*)[newmidi.tracks get:2] instrumentName] isEqual:@"Cello"], @"");

    [newmidi release];
    [midifile release];
    unlink(ctestfile);
}

/* Test changing the tracks to include using the changeSound() method.
 * Create a Midi File with 3 tracks. Parse the MidiFile.
 * Call changeSound() with tracks = [ NO, YES, NO ]
 * Parse the new MidiFile, and verify that only the second track is included.
 */
- (void) testChangeSoundTracks {
    u_char notenum = 60;

    MidiFile *midifile = [self createTestChangeSoundMidiFile];

    MidiOptions *options = [[MidiOptions alloc] initFromMidi:midifile];
    MidiFile *newmidi;

    options.useDefaultInstruments = NO;
    [options.instruments set:1 index:1];
    STAssertTrue(options.mute != nil, @"");
    STAssertTrue([options.mute count] == 3, @"");
    [options.mute set:YES index:0];
    [options.mute set:NO index:1];
    [options.mute set:YES index:2];
    BOOL ret = [midifile changeSound:options toFile:testfile];
    STAssertTrue(ret == YES, @"");
    newmidi = [[MidiFile alloc] initWithFile:testfile];
    STAssertTrue([newmidi.tracks count] == 1, @"");

    MidiTrack *track = [newmidi.tracks get:0];
    STAssertTrue(track.instrument == 1, @"");
    for (int i = 0; i < 3; i++) {
        MidiNote *note = [track.notes get:i];
        STAssertTrue(note.number == notenum + 10 + i, @"");
    }

    [newmidi release];
    [midifile release];
    unlink(ctestfile);
}

/* Test changing the pauseTime using the changeSound() method.
 * Create a Midi File with 3 tracks, and 3 notes per track. Parse the MidiFile.
 * Call changeSound() with pauseTime = 50.
 * Parse the new MidiFile, and verify the first note is gone, and the 2nd/3rd 
 * notes have their start time 50 pulses earlier.
 */
- (void) testChangeSoundPauseTime {
    u_char notenum = 60;

    MidiFile *midifile = [self createTestChangeSoundMidiFile];

    MidiOptions *options = [[MidiOptions alloc] initFromMidi:midifile];
    options.pauseTime = 50;
    BOOL ret = [midifile changeSound:options toFile:testfile];
    STAssertTrue(ret == YES, @"");
    MidiFile *newmidi;
    newmidi = [[MidiFile alloc] initWithFile:testfile];
    STAssertTrue([newmidi.tracks count] == 3, @"");
    STAssertTrue(((MidiTrack*)[newmidi.tracks get:0]).instrument == 4, @"");
    STAssertTrue(((MidiTrack*)[newmidi.tracks get:1]).instrument == 5, @"");
    STAssertTrue(((MidiTrack*)[newmidi.tracks get:2]).instrument == 0, @"");

    for (int tracknum = 0; tracknum < 3; tracknum++) {
        MidiTrack *track = [newmidi.tracks get:tracknum];
        Array* notes = track.notes;
        STAssertTrue([notes count] == 2, @"");

        STAssertTrue([notes getNote:0].startTime == 60 - options.pauseTime, @"");
        STAssertTrue([notes getNote:0].number == notenum + 10*tracknum + 1, @"");
        STAssertTrue([notes getNote:0].duration == 30, @"");

        STAssertTrue([notes getNote:1].startTime == 90 - options.pauseTime, @"");
        STAssertTrue([notes getNote:1].number == notenum + 10*tracknum + 2, @"");
        STAssertTrue([notes getNote:1].duration == 90, @"");
    }
    [newmidi release];
    [midifile release];
    unlink(ctestfile);
}


/* Create MidiFile for the testChangeSoundPerChannel tests */
- (MidiFile*) createTestChangeSoundPerChannelMidiFile {
    u_char notenum = 60;
    u_char quarternote = 240;
    u_char numtracks = 1;
    u_char velocity = 80;

    u_char data[] = {
        77, 84, 104, 100,        /* MThd ascii header  */
        0, 0, 0, 6,              /* length of header in bytes */
        0, 1,                    /* one or more simultaneous tracks */
        0, numtracks, 
        0, quarternote, 

        77, 84, 114, 107,        /* MTrk ascii header */
        0, 0, 0, 81,             /* Length of track, in bytes */

        /* Instruments are
         * channel 0 = 0 (Acoustic Piano)
         * channel 1 = 4 (Electric Piano 1)
         * channel 2 = 5 (Electric Piano 2)
         */
        0,  EventProgramChange,   0,
        0,  EventProgramChange+1, 4,
        0,  EventProgramChange+2, 5,

        /* time_interval, NoteEvent, note number, velocity */
        0,  EventNoteOn,    notenum,    velocity,
        0,  EventNoteOn+1,  notenum+10, velocity,
        0,  EventNoteOn+2,  notenum+20, velocity,
        30, EventNoteOff,   notenum,    0,
        0,  EventNoteOff+1, notenum+10,   0,
        0,  EventNoteOff+2, notenum+20,   0,

        30, EventNoteOn,    notenum+1,  velocity,
        0,  EventNoteOn+1,  notenum+11, velocity,
        0,  EventNoteOn+2,  notenum+21, velocity,
        30, EventNoteOff,   notenum+1,    0,
        0,  EventNoteOff+1, notenum+11,   0,
        0,  EventNoteOff+2, notenum+21,   0,

        30, EventNoteOn,    notenum+2,  velocity,
        0,  EventNoteOn+1,  notenum+12, velocity,
        0,  EventNoteOn+2,  notenum+22, velocity,
        30, EventNoteOff,   notenum+2,    0,
        0,  EventNoteOff+1, notenum+12,   0,
        0,  EventNoteOff+2, notenum+22,   0,
    };

    /* Verify that the original midi has 3 tracks, one per channel */
    writeTestFile(data, sizeof(data));
    MidiFile *midifile = [[MidiFile alloc] initWithFile:testfile];
    STAssertTrue([midifile.tracks count] == 3, @"");
    MidiTrack *track;
    track = [midifile.tracks get:0];
    STAssertTrue(track.instrument == 0, @"");
    track = [midifile.tracks get:1];
    STAssertTrue(track.instrument == 4, @"");
    track = [midifile.tracks get:2];
    STAssertTrue(track.instrument == 5, @"");

    for (int tracknum = 0; tracknum < 3; tracknum++) {
        track = [midifile.tracks get:tracknum];
        STAssertTrue([track.notes count] == 3, @"");
        for (int n = 0; n < [track.notes count]; n++) {
            MidiNote *m = [track.notes get:n];
            STAssertTrue(m.number == (notenum + 10*tracknum + n), @"");
        }
    }
    return midifile;
}


/* Test changing the tempo with the changeSoundPerChannel() method.
 * Create a MidiFile with 1 track, and multiple channels. Parse the MidiFile.
 * Call changeSoundPerChannel() with tempo = 0x405060;
 * Parse the new MidiFile, and verify the TimeSignature tempo = 0x405060.
 */
- (void) testChangeSoundPerChannelTempo {
    MidiFile* midifile = [self createTestChangeSoundPerChannelMidiFile];
    MidiOptions *options = [[MidiOptions alloc] initFromMidi:midifile];
    options.tempo = 0x405060;
    int ret = [midifile changeSound:options toFile:testfile];
    STAssertTrue(ret == YES, @"");
    MidiFile *newmidi = [[MidiFile alloc] initWithFile:testfile];
    STAssertTrue(newmidi.time.tempo == 0x405060, @"");

    [newmidi release];
    [midifile release];
    unlink(ctestfile);
}


/* Test transposing the notes using the changeSoundPerChannel() method.
 * Create a Midi File with 1 track, and multiple channels. Parse the MidiFile.
 * Call changeSoundPerChannel() with transpose = 10.
 * Parse the new MidiFile, and verify the notes are transposed 10 values.
 */
- (void) testChangeSoundPerChannelTranspose {
    u_char notenum = 60;

    MidiFile* midifile = [self createTestChangeSoundPerChannelMidiFile];
    MidiOptions *options = [[MidiOptions alloc] initFromMidi:midifile];
    options.transpose = 10;
    int ret = [midifile changeSound:options toFile:testfile];
    STAssertTrue(ret == YES, @"");
    MidiFile* newmidi = [[MidiFile alloc] initWithFile:testfile];

    STAssertTrue([newmidi.tracks count] == 3, @"");
    for (int tracknum = 0; tracknum < 3; tracknum++) {
        MidiTrack *track = [newmidi.tracks get:tracknum];
        for (int i = 0; i < 3; i++) {
            MidiNote *note = [track.notes get:i];
            STAssertTrue(note.number == (notenum + tracknum*10 + i + 10), @"");
        }
    }

    [newmidi release];
    [midifile release];
    unlink(ctestfile);
}

/* Test changing the instruments with the changeSoundPerChannel() method.
 * Create a MidiFile with 1 track, and multiple channels. Parse the MidiFile.
 * Call changeSoundPerChannel() with instruments = [40, 41, 42]
 * Parse the new MidiFile, and verify the new instruments are used.
 */
- (void) testChangeSoundPerChannelInstruments {
    MidiFile* midifile = [self createTestChangeSoundPerChannelMidiFile];
    MidiOptions *options = [[MidiOptions alloc] initFromMidi:midifile];
    for (int tracknum = 0; tracknum < 3; tracknum++) {
        [options.instruments set:(40 + tracknum) index:tracknum];
    }
    options.useDefaultInstruments = NO;
    int ret = [midifile changeSound:options toFile:testfile];
    STAssertTrue(ret == YES, @"");
    MidiFile *newmidi = [[MidiFile alloc] initWithFile:testfile];
    STAssertTrue(((MidiTrack*)[newmidi.tracks get:0]).instrument == 40, @"");
    STAssertTrue(((MidiTrack*)[newmidi.tracks get:1]).instrument == 41, @"");
    STAssertTrue(((MidiTrack*)[newmidi.tracks get:2]).instrument == 42, @"");

    [newmidi release];
    [midifile release];
    unlink(ctestfile);
}

/* Test changing the tracks to include with the changeSoundPerChannel() method.
 * Create a MidiFile with 1 track, and multiple channels. Parse the MidiFile.
 * Call changeSoundPerChannel() with instruments = [NO, YES, NO];
 * Parse the new MidiFile, and verify that only the 2nd track is included.
 */
- (void) testChangeSoundPerChannelTracks {
    u_char notenum = 60;


    MidiFile* midifile = [self createTestChangeSoundPerChannelMidiFile];
    MidiOptions *options = [[MidiOptions alloc] initFromMidi:midifile];
    STAssertTrue(options.mute != nil, @"");
    STAssertTrue([options.mute count] == 3, @"");
    [options.mute set:YES index:0];
    [options.mute set:NO index:1];
    [options.mute set:YES index:2];
    int ret = [midifile changeSound:options toFile:testfile];
    STAssertTrue(ret == YES, @"");
    MidiFile *newmidi = [[MidiFile alloc] initWithFile:testfile];
    STAssertTrue([newmidi.tracks count] == 1, @"");
     
    MidiTrack *track = [newmidi.tracks get:0];
    for (int i = 0; i < 3; i++) {
        MidiNote *note = [track.notes get:i];
        STAssertTrue(note.number == notenum + 10 + i, @"");
    }

    [newmidi release];
    [midifile release];
    unlink(ctestfile);
}

/* Test changing the pauseTime using the changeSoundPerChannel() method.
 * Create a MidiFile with 1 track, and multiple channels. Parse the MidiFile.
 * The original start times for each note are 0, 60, 120.
 * Call changeSoundPerChannel() with pauseTime = 50.
 * Parse the new MidiFile, and verify the first note is gone, and that the
 * start time of the last two notes are 70 pulses less.
 */
- (void) testChangeSoundPerChannelPauseTime {
    u_char notenum = 60;
    MidiFile* midifile = [self createTestChangeSoundPerChannelMidiFile];
    MidiOptions *options = [[MidiOptions alloc] initFromMidi:midifile];
    options.pauseTime = 50;
    int ret = [midifile changeSound:options toFile:testfile];
    STAssertTrue(ret == YES, @"");
    MidiFile *newmidi = [[MidiFile alloc] initWithFile:testfile];
    STAssertTrue([newmidi.tracks count] == 3, @"");
 
    for (int tracknum = 0; tracknum < 3; tracknum++) {
        MidiTrack *track = [newmidi.tracks get:tracknum];
        STAssertTrue([track.notes count] == 2, @"");
        for (int i = 0; i < 2; i++) {
            MidiNote *note = [track.notes get:i];
            STAssertTrue(note.number == notenum + 10*tracknum + i + 1, @"");
            STAssertTrue(note.startTime == 60 * (i+1) - 50, @"");
        }
    }

    [newmidi release];
    [midifile release];
    unlink(ctestfile);
}


/* Create a single track with:
 * - note numbers between 70 and 80
 * - note numbers between 65 and 75
 * - note numbers between 50 and 60
 * - note numbers between 55 and 65
 *
 * Then call SplitTracks().  Verify that
 * - Track 0 has numbers between 65-75, 70-80
 * - Track 1 has numbers between 50-60, 55-65
 */
- (void)testSplitTrack {
    MidiTrack *track = [[MidiTrack alloc] initWithTrack:1];
    int start, number;

    /* Create notes between 70 and 80 */
    for (int i = 0; i < 100; i++) {
        start = i * 10;
        number = 70 + (i % 10);
        MidiNote *note = [MidiNote alloc];
        note.startTime = start;
        note.number = number;
        note.duration = 10;
        [track addNote:note];
        [note release];
    }

    /* Create notes between 65 and 75 */
    for (int i = 0; i < 100; i++) {
        start = i * 10 + 1;
        number = 65 + (i % 10);
        MidiNote *note = [MidiNote alloc];
        note.startTime = start;
        note.number = number;
        note.duration = 10;
        [track addNote:note];
        [note release];
    }

    /* Create notes between 50 and 60 */
    for (int i = 0; i < 100; i++) {
        start = i * 10;
        number = 50 + (i % 10);
        MidiNote *note = [MidiNote alloc];
        note.startTime = start;
        note.number = number;
        note.duration = 10;
        [track addNote:note];
        [note release];
    }

    /* Create notes between 55 and 65 */
    for (int i = 0; i < 100; i++) {
        start = i * 10 + 1;
        number = 55 + (i % 10);
        MidiNote *note = [MidiNote alloc];
        note.startTime = start;
        note.number = number;
        note.duration = 10;
        [track addNote:note];
        [note release];
    }

    [track.notes sort:sortbytime];
    Array *tracks = [MidiFile splitTrack:track withMeasure:40];
    MidiTrack *track0 = [tracks get:0];
    MidiTrack *track1 = [tracks get:1];
    STAssertTrue([track0.notes count] == 200, @"");
    STAssertTrue([track1.notes count] == 200, @"");

    for (int i = 0; i < 100; i++) {
        MidiNote *note1 = [track0.notes get:i*2];
        MidiNote *note2 = [track0.notes get:(i*2 + 1) ];
        STAssertTrue(note1.startTime == i*10, @"");
        STAssertTrue(note2.startTime == i*10 + 1, @"");
        STAssertTrue(note1.number == 70 + (i % 10), @"");
        STAssertTrue(note2.number == 65 + (i % 10), @"");
    }
    for (int i = 0; i < 100; i++) {
        MidiNote *note1 = [track1.notes get:i*2];
        MidiNote *note2 = [track1.notes get:(i*2 + 1) ];
        STAssertTrue(note1.startTime == i*10, @"");
        STAssertTrue(note2.startTime == i*10 + 1, @"");
        STAssertTrue(note1.number == 50 + (i % 10), @"");
        STAssertTrue(note2.number == 55 + (i % 10), @"");
    }
    [track release];
}


/* Create 3 tracks with the following notes:
 * - Start times 1, 3, 5 ... 99
 * - Start times 2, 4, 6 .... 100
 * - Start times 10, 20, .... 100
 * Combine all the tracks to a single track.
 * In the single track, verify that:
 * - The notes are sorted by start time
 * - There are no duplicate notes (same start time and number).
 */
- (void)testCombineToSingleTrack {
    Array* tracks = [Array new:1];
    int start, number;

    MidiTrack *track;

    track = [[MidiTrack alloc] initWithTrack:1];
    [tracks add:track];
    for (int i = 1; i <= 99; i += 2) {
        start = i;
        number = 30 + (i % 10);
        MidiNote *note = [MidiNote alloc];
        note.startTime = start;
        note.channel = 0;
        note.number = number;
        note.duration = 10;
        [track addNote:note];
        [note release];
    }
    [track release];
    track = [[MidiTrack alloc] initWithTrack:2];
    [tracks add:track];
    for (int i = 0; i <= 100; i += 2) {
        start = i;
        number = 50 + (i % 10);
        MidiNote *note = [MidiNote alloc];
        note.startTime = start;
        note.channel = 0;
        note.number = number;
        note.duration = 10;
        [track addNote:note];
        [note release];
    }
    [track release];
    track = [[MidiTrack alloc] initWithTrack:3];
    [tracks add:track];
    for (int i = 0; i <= 100; i += 10) {
        start = i;
        number = 50 + (i % 10);
        MidiNote *note = [MidiNote alloc];
        note.startTime = start;
        note.channel = 0;
        note.number = number;
        note.duration = 20;
        [track addNote:note];
        [note release];
    }
    [track release];

    MidiTrack *result = [MidiFile combineToSingleTrack:tracks];
    STAssertTrue([result.notes count] == 101, @"");
    for (int i = 0; i <= 100; i++) {
        MidiNote *note = [result.notes get:i];
        STAssertTrue(note.startTime == i, @"");
        if (i % 2 == 0) {
            STAssertTrue(note.number == 50 + (i % 10), @"");
        }
        else {
            STAssertTrue(note.number == 30 + (i % 10), @"");
        }
        if (i % 10 == 0) {
            STAssertTrue(note.duration == 20, @"");
        }
        else {
            STAssertTrue(note.duration == 10, @"");
        }
    }
    [result release];
}


/* Create a set of notes with the following start times.
 * 0, 2, 3, 10, 15, 20, 22, 35, 36, 62.
 *
 * After rounding the start times, the start times will be:
 * 0, 0, 0,  0,  0, 20, 20, 20, 36, 62.
 */
- (void) testRoundStartTimes {
    u_char notenum = 20;

    MidiNote *m = [MidiNote alloc];
    m.channel = 0;
    m.duration = 60;

    Array* tracks = [Array new:5];
    MidiTrack *track1 = [[MidiTrack alloc] initWithTrack:0];

    m.startTime = 0; m.number = notenum;
    [track1 addNote:[m copy]];
    m.startTime = 3; m.number = notenum+1;
    [track1 addNote:[m copy]];
    m.startTime = 15; m.number = notenum+2;
    [track1 addNote:[m copy]];
    m.startTime = 22; m.number = notenum+3;
    [track1 addNote:[m copy]];
    m.startTime = 62; m.number = notenum+4;
    [track1 addNote:[m copy]];

    MidiTrack *track2 = [[MidiTrack alloc] initWithTrack:1];

    m.startTime = 2; m.number = notenum+10;
    [track2 addNote:[m copy]];
    m.startTime = 10; m.number = notenum+11;
    [track2 addNote:[m copy]];
    m.startTime = 20; m.number = notenum+12;
    [track2 addNote:[m copy]];
    m.startTime = 35; m.number = notenum+13;
    [track2 addNote:[m copy]];
    m.startTime = 36; m.number = notenum+14;
    [track2 addNote:[m copy]];

    [tracks add:track1];
    [tracks add:track2];

    [track1 release];
    [track2 release];

    int quarter = 130;
    int tempo = 500000;
    TimeSignature *time = [[TimeSignature alloc]
                           initWithNumerator:4
                           andDenominator:4
                           andQuarter:quarter
                           andTempo:tempo];

    /* quarternote * 60,000 / 500,000 = 15 pulses
     * So notes within 15 pulses should be grouped together. 
     * 0, 2, 3, 10, 15 are grouped to starttime 0
     * 20, 22, 35      are grouped to starttime 20
     * 36              is still 36
     * 62              is still 62
     */
    [MidiFile roundStartTimes:tracks toInterval:60 withTime:time];
    Array* notes1 = ((MidiTrack *)[tracks get:0]).notes;
    Array* notes2 = ((MidiTrack *)[tracks get:1]).notes;
    STAssertTrue([notes1 count] == 5, @"");
    STAssertTrue([notes2 count] == 5, @"");

    STAssertTrue([notes1 getNote:0].number == notenum, @"");
    STAssertTrue([notes1 getNote:1].number == notenum+1, @"");
    STAssertTrue([notes1 getNote:2].number == notenum+2, @"");
    STAssertTrue([notes1 getNote:3].number == notenum+3, @"");
    STAssertTrue([notes1 getNote:4].number == notenum+4, @"");

    STAssertTrue([notes2 getNote:0].number == notenum+10, @"");
    STAssertTrue([notes2 getNote:1].number == notenum+11, @"");
    STAssertTrue([notes2 getNote:2].number == notenum+12, @"");
    STAssertTrue([notes2 getNote:3].number == notenum+13, @"");
    STAssertTrue([notes2 getNote:4].number == notenum+14, @"");


    STAssertTrue([notes1 getNote:0].startTime == 0, @"");
    STAssertTrue([notes1 getNote:1].startTime == 0, @"");
    STAssertTrue([notes1 getNote:2].startTime == 0, @"");
    STAssertTrue([notes1 getNote:3].startTime == 20, @"");
    STAssertTrue([notes1 getNote:3].startTime == 20, @"");
    STAssertTrue([notes1 getNote:4].startTime == 62, @"");

    STAssertTrue([notes2 getNote:0].startTime == 0, @"");
    STAssertTrue([notes2 getNote:1].startTime == 0, @"");
    STAssertTrue([notes2 getNote:2].startTime == 20, @"");
    STAssertTrue([notes2 getNote:3].startTime == 20, @"");
    STAssertTrue([notes2 getNote:4].startTime == 36, @"");

    [m release];
    [time release];
}

/* Create a list of notes with start times:
 * 0, 50, 90, 101, 123
 * and duration 1 pulse.
 * Verify that RoundDurations() rounds the
 * durations to the correct value.
 */
- (void) testRoundDurations {
    MidiTrack *track = [[MidiTrack alloc] initWithTrack:1];
    MidiNote *note = [MidiNote alloc];
    note.startTime = 0;
    note.number = 55;
    note.duration = 45;
    [track addNote:note];
    [note release];

    int starttimes[] = { 50, 90, 101, 123 };
    for (int i = 0; i < 4; i++) {
        int start = starttimes[i];
        note = [MidiNote alloc];
        note.startTime = start;
        note.number = 55;
        note.duration = 1;
        [track addNote:note];
        [note release];
    }

    Array* tracks = [Array new:1];
    [tracks add:track];
    int quarternote = 40;
    [MidiFile roundDurations:tracks withQuarter:quarternote];

    STAssertTrue( [track.notes getNote:0].duration == 45, @"");
    STAssertTrue( [track.notes getNote:1].duration == 40, @"");
    STAssertTrue( [track.notes getNote:2].duration == 10, @"");
    STAssertTrue( [track.notes getNote:3].duration == 20, @"");
    STAssertTrue( [track.notes getNote:4].duration == 1, @"");

    [track release];
}

@end  /* MidiFileTest */


/* Test cases for the KeySignature class */
@interface KeySignatureTest :SenTestCase {
}
- (void)testGetSymbols;
- (void)testGetAccidental;
- (void)testGetAccidentalSameMeasure;
- (void)testGuess;
@end

@implementation KeySignatureTest

/* Test that the key signatures return the correct accidentals.
 * C major (0 sharps, 0 flats) should return 0 accidentals.
 * G major through F# major should return F#, C#, G#, D#, A#, E#
 * F major through D-flat major should return B-flat, E-flat, A-flat, D-flat, G-flat
 */
- (void) testGetSymbols {
    KeySignature *k;
    Array *symbols1, *symbols2;

    k = [[KeySignature alloc] initWithSharps:0 andFlats:0];
    symbols1 = [k getSymbols:Clef_Treble];
    symbols2 = [k getSymbols:Clef_Bass];
    STAssertTrue([symbols1 count] == 0, @"");
    STAssertTrue([symbols2 count] == 0, @"");

    int sharps[] = {
        WhiteNote_F, WhiteNote_C, WhiteNote_G, WhiteNote_D,
        WhiteNote_A, WhiteNote_E
    };

    [k release];
    for (int sharp = 1; sharp < 7; sharp++) {
        k = [[KeySignature alloc] initWithSharps:sharp andFlats:0];
        symbols1 = [k getSymbols:Clef_Treble];
        symbols2 = [k getSymbols:Clef_Bass];
        for (int i = 0; i < sharp; i++) {
            STAssertTrue( ((AccidSymbol*)[symbols1 get:i]).note.letter == sharps[i], @"");
            STAssertTrue( ((AccidSymbol*)[symbols2 get:i]).note.letter == sharps[i], @"");
        }
        [k release];
    }

    int flats[] = {
        WhiteNote_B, WhiteNote_E, WhiteNote_A, WhiteNote_D,
        WhiteNote_G
    }; 

    for (int flat = 1; flat < 6; flat++) {
        k = [[KeySignature alloc] initWithSharps:0 andFlats:flat];
        symbols1 = [k getSymbols:Clef_Treble];
        symbols2 = [k getSymbols:Clef_Bass];
        for (int i = 0; i < flat; i++) {
            STAssertTrue( ((AccidSymbol*)[symbols1 get:i]).note.letter == flats[i], @"");
            STAssertTrue( ((AccidSymbol*)[symbols2 get:i]).note.letter == flats[i], @"");
        }
        [k release];
    }
}


/* For each key signature, loop through all the notes, from 1 to 128.
 * Verify that the key signature returns the correct accidental
 * (sharp, flat, natural, none) for the given note.
 */
- (void) testGetAccidental {

    int measure = 1;
    KeySignature *k;
    int expected[12];
    for (int i = 0; i < 12; i++) {
        expected[i] = AccidNone;
    }
    expected[NoteScale_Bflat]  = AccidFlat;
    expected[NoteScale_Csharp] = AccidSharp;
    expected[NoteScale_Dsharp] = AccidSharp;
    expected[NoteScale_Fsharp] = AccidSharp;
    expected[NoteScale_Gsharp] = AccidSharp;

    /* Test C Major */
    k = [[KeySignature alloc] initWithSharps:0 andFlats:0];
    measure = 1;
    for (int note = 1; note < 128; note++) {
        int notescale = notescale_from_number(note);
        STAssertTrue(expected[notescale] == 
                      [k getAccidentalForNote:note andMeasure:measure], @"");
        measure++;
    }
    [k release];

    /* Test G major, F# */
    k = [[KeySignature alloc] initWithSharps:1 andFlats:0];
    measure = 1;
    expected[NoteScale_Fsharp] = AccidNone;
    expected[NoteScale_F] = AccidNatural;
    for (int note = 1; note < 128; note++) {
        int notescale = notescale_from_number(note);
        STAssertTrue(expected[notescale] ==
                      [k getAccidentalForNote:note andMeasure:measure], @"");
        measure++;
    }
    [k release];

    /* Test D major, F#, C# */
    k = [[KeySignature alloc] initWithSharps:2 andFlats:0];
    measure = 1;
    expected[NoteScale_Csharp] = AccidNone;
    expected[NoteScale_C] = AccidNatural;
    for (int note = 1; note < 128; note++) {
        int notescale = notescale_from_number(note);
        STAssertTrue(expected[notescale] ==
                      [k getAccidentalForNote:note andMeasure:measure], @"");
        measure++;
    }
    [k release];

    /* Test A major, F#, C#, G# */
    k = [[KeySignature alloc] initWithSharps:3 andFlats:0];
    measure = 1;
    expected[NoteScale_Gsharp] = AccidNone;
    expected[NoteScale_G] = AccidNatural;
    for (int note = 1; note < 128; note++) {
        int notescale = notescale_from_number(note);
        STAssertTrue(expected[notescale] ==
                      [k getAccidentalForNote:note andMeasure:measure], @"");
        measure++;
    }
    [k release];

    /* Test E major, F#, C#, G#, D# */
    k = [[KeySignature alloc] initWithSharps:4 andFlats:0];
    measure = 1;
    expected[NoteScale_Dsharp] = AccidNone;
    expected[NoteScale_D] = AccidNatural;
    for (int note = 1; note < 128; note++) {
        int notescale = notescale_from_number(note);
        STAssertTrue(expected[notescale] ==
                      [k getAccidentalForNote:note andMeasure:measure], @"");
        measure++;
    }
    [k release];

    /* Test B major, F#, C#, G#, D#, A# */
    k = [[KeySignature alloc] initWithSharps:5 andFlats:0];
    measure = 1;
    expected[NoteScale_Asharp] = AccidNone;
    expected[NoteScale_A] = AccidNatural;
    for (int note = 1; note < 128; note++) {
        int notescale = notescale_from_number(note);
        STAssertTrue(expected[notescale] ==
                      [k getAccidentalForNote:note andMeasure:measure], @"");
        measure++;
    }
    [k release];

    for (int i = 0; i < 12; i++) {
        expected[i] = AccidNone;
    }
    expected[NoteScale_Aflat]  = AccidFlat;
    expected[NoteScale_Bflat]  = AccidFlat;
    expected[NoteScale_Csharp] = AccidSharp;
    expected[NoteScale_Eflat]  = AccidFlat;
    expected[NoteScale_Fsharp] = AccidSharp;

    /* Test F major, Bflat */
    k = [[KeySignature alloc] initWithSharps:0 andFlats:1];
    measure = 1;
    expected[NoteScale_Bflat] = AccidNone;
    expected[NoteScale_B] = AccidNatural;
    for (int note = 1; note < 128; note++) {
        int notescale = notescale_from_number(note);
        STAssertTrue(expected[notescale] ==
                      [k getAccidentalForNote:note andMeasure:measure], @"");
        measure++;
    }
    [k release];

    /* Test Bflat major, Bflat, Eflat */
    k = [[KeySignature alloc] initWithSharps:0 andFlats:2];
    measure = 1;
    expected[NoteScale_Eflat] = AccidNone;
    expected[NoteScale_E] = AccidNatural;
    for (int note = 1; note < 128; note++) {
        int notescale = notescale_from_number(note);
        STAssertTrue(expected[notescale] ==
                      [k getAccidentalForNote:note andMeasure:measure], @"");
        measure++;
    }
    [k release];

    /* Test Eflat major, Bflat, Eflat, Afat */
    k = [[KeySignature alloc] initWithSharps:0 andFlats:3];
    measure = 1;
    expected[NoteScale_Aflat] = AccidNone;
    expected[NoteScale_A] = AccidNatural;
    expected[NoteScale_Dflat] = AccidFlat;
    for (int note = 1; note < 128; note++) {
        int notescale = notescale_from_number(note);
        STAssertTrue(expected[notescale] ==
                      [k getAccidentalForNote:note andMeasure:measure], @"");
        measure++;
    }
    [k release];

    /* Test Aflat major, Bflat, Eflat, Aflat, Dflat */
    k = [[KeySignature alloc] initWithSharps:0 andFlats:4];
    measure = 1;
    expected[NoteScale_Dflat] = AccidNone;
    expected[NoteScale_D] = AccidNatural;
    for (int note = 1; note < 128; note++) {
        int notescale = notescale_from_number(note);
        STAssertTrue(expected[notescale] ==
                      [k getAccidentalForNote:note andMeasure:measure], @"");
        measure++;
    }
    [k release];

    /* Test Dflat major, Bflat, Eflat, Aflat, Dflat, Gflat */
    k = [[KeySignature alloc] initWithSharps:0 andFlats:5];
    measure = 1;
    expected[NoteScale_Gflat] = AccidNone;
    expected[NoteScale_G] = AccidNatural;
    for (int note = 1; note < 128; note++) {
        int notescale = notescale_from_number(note);
        STAssertTrue(expected[notescale] ==
                      [k getAccidentalForNote:note andMeasure:measure], @"");
        measure++;
    }
    [k release];
}


/* Test that getAccidental() and getWhiteNote() return the correct values.
 * - The WhiteNote should be one below for flats, and one above for sharps.
 * - The accidental should only be returned the first time the note is passed.
 *   On the second time, getAccidental() should return none.
 * - When a sharp/flat accidental is returned, calling getAccidental() on
 *   the white key just below/above should now return a natural accidental.
 */
- (void) testGetAccidentalSameMeasure {
    KeySignature *k;

    /* G Major, F# */
    k = [[KeySignature alloc] initWithSharps:1 andFlats:0];

    int note = notescale_to_number(NoteScale_C, 1);
    STAssertTrue([k getWhiteNote:note].letter == WhiteNote_C, @"");
    STAssertTrue([k getAccidentalForNote:note andMeasure:1] == AccidNone, @"");
    STAssertTrue([k getWhiteNote:note].letter == WhiteNote_C, @"");
    STAssertTrue([k getAccidentalForNote:note andMeasure:1] == AccidNone, @"");

    note = notescale_to_number(NoteScale_Fsharp, 1);
    STAssertTrue([k getWhiteNote:note].letter == WhiteNote_F, @"");
    STAssertTrue([k getAccidentalForNote:note andMeasure:1] == AccidNone, @"");
    STAssertTrue([k getWhiteNote:note].letter == WhiteNote_F, @"");
    STAssertTrue([k getAccidentalForNote:note andMeasure:1] == AccidNone, @"");

    note = notescale_to_number(NoteScale_F, 1);
    STAssertTrue([k getWhiteNote:note].letter == WhiteNote_F, @"");
    STAssertTrue([k getAccidentalForNote:note andMeasure:1] == AccidNatural, @"");
    STAssertTrue([k getWhiteNote:note].letter == WhiteNote_F, @"");
    STAssertTrue([k getAccidentalForNote:note andMeasure:1] == AccidNone, @"");

    note = notescale_to_number(NoteScale_Fsharp, 1);
    STAssertTrue([k getWhiteNote:note].letter == WhiteNote_F, @"");
    STAssertTrue([k getAccidentalForNote:note andMeasure:1] == AccidSharp, @"");
    STAssertTrue([k getWhiteNote:note].letter == WhiteNote_F, @"");
    STAssertTrue([k getAccidentalForNote:note andMeasure:1] == AccidNone, @"");

    note = notescale_to_number(NoteScale_Bflat, 1);
    STAssertTrue([k getWhiteNote:note].letter == WhiteNote_B, @"");
    STAssertTrue([k getAccidentalForNote:note andMeasure:1] == AccidFlat, @"");
    STAssertTrue([k getWhiteNote:note].letter == WhiteNote_B, @"");
    STAssertTrue([k getAccidentalForNote:note andMeasure:1] == AccidNone, @"");

    note = notescale_to_number(NoteScale_A, 1);
    STAssertTrue([k getWhiteNote:note].letter == WhiteNote_A, @"");
    STAssertTrue([k getAccidentalForNote:note andMeasure:1] == AccidNone, @"");

    note = notescale_to_number(NoteScale_B, 1);
    STAssertTrue([k getWhiteNote:note].letter == WhiteNote_B, @"");
    STAssertTrue([k getAccidentalForNote:note andMeasure:1] == AccidNatural, @"");
    STAssertTrue([k getWhiteNote:note].letter == WhiteNote_B, @"");
    STAssertTrue([k getAccidentalForNote:note andMeasure:1] == AccidNone, @"");

    note = notescale_to_number(NoteScale_Bflat, 1);
    STAssertTrue([k getWhiteNote:note].letter == WhiteNote_B, @"");
    STAssertTrue([k getAccidentalForNote:note andMeasure:1] == AccidFlat, @"");

    [k release];

    /* F Major, Bflat */
    k = [[KeySignature alloc] initWithSharps:0 andFlats:1];

    note = notescale_to_number(NoteScale_G, 1);
    STAssertTrue([k getWhiteNote:note].letter == WhiteNote_G, @"");
    STAssertTrue([k getAccidentalForNote:note andMeasure:1] == AccidNone, @"");
    STAssertTrue([k getWhiteNote:note].letter == WhiteNote_G, @"");
    STAssertTrue([k getAccidentalForNote:note andMeasure:1] == AccidNone, @"");

    note = notescale_to_number(NoteScale_Bflat, 1);
    STAssertTrue([k getWhiteNote:note].letter == WhiteNote_B, @"");
    STAssertTrue([k getAccidentalForNote:note andMeasure:1] == AccidNone, @"");
    STAssertTrue([k getWhiteNote:note].letter == WhiteNote_B, @"");
    STAssertTrue([k getAccidentalForNote:note andMeasure:1] == AccidNone, @"");

    note = notescale_to_number(NoteScale_B, 1);
    STAssertTrue([k getWhiteNote:note].letter == WhiteNote_B, @"");
    STAssertTrue([k getAccidentalForNote:note andMeasure:1] == AccidNatural, @"");
    STAssertTrue([k getWhiteNote:note].letter == WhiteNote_B, @"");
    STAssertTrue([k getAccidentalForNote:note andMeasure:1] == AccidNone, @"");

    note = notescale_to_number(NoteScale_Bflat, 1);
    STAssertTrue([k getWhiteNote:note].letter == WhiteNote_B, @"");
    STAssertTrue([k getAccidentalForNote:note andMeasure:1] == AccidFlat, @"");
    STAssertTrue([k getWhiteNote:note].letter == WhiteNote_B, @"");
    STAssertTrue([k getAccidentalForNote:note andMeasure:1] == AccidNone, @"");

    note = notescale_to_number(NoteScale_Fsharp, 1);
    STAssertTrue([k getWhiteNote:note].letter == WhiteNote_F, @"");
    STAssertTrue([k getAccidentalForNote:note andMeasure:1] == AccidSharp, @"");
    STAssertTrue([k getWhiteNote:note].letter == WhiteNote_F, @"");
    STAssertTrue([k getAccidentalForNote:note andMeasure:1] == AccidNone, @"");

    note = notescale_to_number(NoteScale_G, 1);
    STAssertTrue([k getWhiteNote:note].letter == WhiteNote_G, @"");
    STAssertTrue([k getAccidentalForNote:note andMeasure:1] == AccidNone, @"");

    note = notescale_to_number(NoteScale_F, 1);
    STAssertTrue([k getWhiteNote:note].letter == WhiteNote_F, @"");
    STAssertTrue([k getAccidentalForNote:note andMeasure:1] == AccidNatural, @"");
    STAssertTrue([k getWhiteNote:note].letter == WhiteNote_F, @"");
    STAssertTrue([k getAccidentalForNote:note andMeasure:1] == AccidNone, @"");

    note = notescale_to_number(NoteScale_Fsharp, 1);
    STAssertTrue([k getWhiteNote:note].letter == WhiteNote_F, @"");
    STAssertTrue([k getAccidentalForNote:note andMeasure:1] == AccidSharp, @"");

    [k release];
}

/* Create an array of note numbers (from 1 to 128), and verify that
 * the correct KeySignature is guessed.
 */
- (void) testGuess {
    KeySignature *k;
    IntArray *notes = [IntArray new:1000];

    /* C major */
    int octave = 0;
    for (int i = 0; i < 100; i++) {
        [notes add:notescale_to_number(NoteScale_A, octave)];
        [notes add:notescale_to_number(NoteScale_B, octave)];
        [notes add:notescale_to_number(NoteScale_C, octave)];
        [notes add:notescale_to_number(NoteScale_D, octave)];
        [notes add:notescale_to_number(NoteScale_E, octave)];
        [notes add:notescale_to_number(NoteScale_F, octave)];
        [notes add:notescale_to_number(NoteScale_G, octave)];
        octave = (octave + 1) % 7;
    }
    for (int i = 0; i < 10; i++) {
        [notes add:notescale_to_number(NoteScale_Fsharp, octave)];
        [notes add:notescale_to_number(NoteScale_Dsharp, octave)];
    }
    k = [KeySignature guess:notes];
    STAssertTrue([k num_sharps] == 0, @"");
    STAssertTrue([k num_flats] == 0, @"");

    /* A Major, F#, C#, G# */
    notes = [IntArray new:1000];
    octave = 0;
    for (int i = 0; i < 100; i++) {
        [notes add:notescale_to_number(NoteScale_A, octave)];
        [notes add:notescale_to_number(NoteScale_B, octave)];
        [notes add:notescale_to_number(NoteScale_Csharp, octave)];
        [notes add:notescale_to_number(NoteScale_D, octave)];
        [notes add:notescale_to_number(NoteScale_E, octave)];
        [notes add:notescale_to_number(NoteScale_Fsharp, octave)];
        [notes add:notescale_to_number(NoteScale_Gsharp, octave)];
        octave = (octave + 1) % 7;
    }
    for (int i = 0; i < 10; i++) {
        [notes add:notescale_to_number(NoteScale_F, octave)];
        [notes add:notescale_to_number(NoteScale_Dsharp, octave)];
    }
    k = [KeySignature guess:notes];
    STAssertTrue([k num_sharps] == 3, @"");
    STAssertTrue([k num_flats] == 0, @"");

    /* Eflat Major, Bflat, Eflat, Aflat */
    notes = [IntArray new:1000];
    octave = 0;
    for (int i = 0; i < 100; i++) {
        [notes add:notescale_to_number(NoteScale_Aflat, octave)];
        [notes add:notescale_to_number(NoteScale_Bflat, octave)];
        [notes add:notescale_to_number(NoteScale_C, octave)];
        [notes add:notescale_to_number(NoteScale_D, octave)];
        [notes add:notescale_to_number(NoteScale_Eflat, octave)];
        [notes add:notescale_to_number(NoteScale_F, octave)];
        [notes add:notescale_to_number(NoteScale_G, octave)];
        octave = (octave + 1) % 7;
    }
    for (int i = 0; i < 10; i++) {
        [notes add:notescale_to_number(NoteScale_Dflat, octave)];
        [notes add:notescale_to_number(NoteScale_B, octave)];
    }
    k = [KeySignature guess:notes];
    STAssertTrue([k num_sharps] == 0, @"");
    STAssertTrue([k num_flats] == 3, @"");
}

@end  /* KeySignature test */


/* The TestSymbol is used for the SymbolWidths test cases */
@interface TestSymbol :NSObject <MusicSymbol> {
    int starttime;
    int width;
}
- (id)initWithTime:(int)start andWidth:(int) w;
- (int)startTime;
- (int)minWidth;
- (int)width;
- (void)setWidth:(int)w;
- (int)aboveStaff;
- (int)belowStaff;
- (void)draw:(int)ytop;

@end

@implementation TestSymbol

- (id)initWithTime:(int)start andWidth:(int) w {
    starttime = start;
    width = w;
    return self;
}

- (int) startTime { 
    return starttime;
}

- (int) minWidth {
    return width;
}

- (int) width {
    return width;
}

- (void)setWidth:(int)w {
    width = w;
}

- (int)aboveStaff {
    return 0;
}

- (int)belowStaff {
    return 0;
}

- (void)draw:(int)ytop {
}

@end  /* TestSymbol */


/* Test cases for the SymbolWidths class */
@interface SymbolWidthsTest :SenTestCase {
}
- (void)testStartTimes;
- (void)testGetExtraWidth;
@end

@implementation SymbolWidthsTest

/* Given multiple tracks of symbols, test that the SymbolWidths.startTimes
 * returns all the unique start times of all the symbols, in sorted order.
 */
- (void) testStartTimes {
    Array* tracks = [Array new:3];
    for (int i = 0; i < 3; i++) {
        Array *symbols = [Array new:5];
        for (int j = 0; j < 5; j++) {
            TestSymbol *t = [[TestSymbol alloc] initWithTime:(i*10 + j) andWidth:10];
            [symbols add:t];
            [t release];
        }
        [tracks add:symbols];
    }
    SymbolWidths *s = [[SymbolWidths alloc] initWithSymbols:tracks andLyrics:nil];
    IntArray* starttimes = [s startTimes];
    int index = 0;
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 5; j++) {
            STAssertTrue([starttimes get:index] == i*10 + j, @"");
            index++;
        }
    }
    [s release];
}


/* Create 3 tracks with 1 symbol each. The widths of each symbol
 * are 0, 4, and 8 respectively.  Verify that getExtraWidth() 
 * returns the correct value.
 *
 * Add 1 symbol to each track, with the same start time as the
 * previous symbols, so that the total widths for each track is
 * 0, 5, and 10 respectively.  Verify that getExtraWidth() returns 
 * the correct value.
 *
 * Create a symbol with width 6, but only add it to the first track.
 * Verify that getExtraWidth() returns the correct value.
 */
- (void) testGetExtraWidth {
    SymbolWidths *s;
    Array* tracks = [Array new:3];
    for (int i = 0; i < 3; i++) {
        Array* symbols =  [Array new:1];
        TestSymbol *t = [[TestSymbol alloc] initWithTime:100 andWidth:(i*4)];
        [symbols add:t];
        [t release];
        [tracks add:symbols];
    }
    s = [[SymbolWidths alloc] initWithSymbols:tracks andLyrics:nil];
    int extra = [s getExtraWidth:0 forTime:100];
    STAssertTrue(extra == 8, @"");
    extra = [s getExtraWidth:1 forTime:100];
    STAssertTrue(extra == 4, @"");
    extra = [s getExtraWidth:2 forTime:100];
    STAssertTrue(extra == 0, @"");
    [s release];

    for (int i = 0; i < 3; i++) {
        TestSymbol *t = [[TestSymbol alloc] initWithTime:100 andWidth:i];
        Array *track = [tracks get:i];
        [track add:t];
        [t release];
    }
    s = [[SymbolWidths alloc] initWithSymbols:tracks andLyrics:nil];
    extra = [s getExtraWidth:0 forTime:100];
    STAssertTrue(extra == 10, @"");
    extra = [s getExtraWidth:1 forTime:100];
    STAssertTrue(extra == 5, @"");
    extra = [s getExtraWidth:2 forTime:100];
    STAssertTrue(extra == 0, @"");
    [s release];

    TestSymbol *t = [[TestSymbol alloc] initWithTime:200 andWidth:6];
    [(Array*) [tracks get:0] add:t];
    [t release];
    s = [[SymbolWidths alloc] initWithSymbols:tracks andLyrics:nil];
    extra = [s getExtraWidth:0 forTime:200];
    STAssertTrue(extra == 0, @"");
    extra = [s getExtraWidth:1 forTime:200];
    STAssertTrue(extra == 6, @"");
    extra = [s getExtraWidth:2 forTime:200];
    STAssertTrue(extra == 6, @"");
    [s release];

}

@end  /* SymbolWidthsTest */


/* Test cases for the ClefMeasures class */
@interface ClefMeasuresTest :SenTestCase {
}
- (void)testAllTreble;
- (void)testAllBass;
- (void)testMainClefTreble;
- (void)testMainClefBass;
@end

@implementation ClefMeasuresTest

static int middleC = 60;
static int G3 = 55;
static int F4 = 65;

/* Create a list of notes all above middle C.
 * Verify that all the clefs are treble clefs.
 */
- (void) testAllTreble {
    Array* notes = [Array new:100];
    for (int i = 0; i < 100; i++) {
        MidiNote *note = [MidiNote alloc];
        note.startTime = i*10;
        note.number = middleC + (i % 5);
        [notes add:note];
        [note release];
    }
    ClefMeasures *clefs = [[ClefMeasures alloc] initWithNotes:notes andMeasure:40 ];
    for (int i = 0; i < 100; i++) {
        int clef = [clefs getClef:i*10];
        STAssertTrue(clef == Clef_Treble, @"");
    }
    [clefs release];
}

/* Create a list of notes all below middle C.
 * Verify that all the clefs are bass clefs.
 */
- (void) testAllBass {
    Array* notes = [Array new:100];
    for (int i = 0; i < 100; i++) {
        MidiNote *note = [MidiNote alloc];
        note.startTime = i*10;
        note.number = middleC - (i % 5);
        [notes add:note];
        [note release];
    }
    ClefMeasures *clefs = [[ClefMeasures alloc] initWithNotes:notes andMeasure:40 ];
    for (int i = 0; i < 100; i++) {
        int clef = [clefs getClef:i*10];
        STAssertTrue(clef == Clef_Bass, @"");
    }
    [clefs release];
}

/* Create a list of notes where the average note is above middle-C.
 * Verify that
 * - notes above F4 are treble clef
 * - notes below G3 are bass clef
 * - notes in between G3 and F4 are treble clef.
 */
- (void) testMainClefTreble {
    Array* notes = [Array new:100];
    for (int i = 0; i < 100; i++) {
        MidiNote *note = [MidiNote alloc];
        note.startTime = i*10;
        note.number = F4 + (i % 20);
        [notes add:note];
        [note release];
    }
    for (int i = 100; i < 200; i++) {
        MidiNote *note = [MidiNote alloc];
        note.startTime = i*10;
        note.number = G3 - (i % 2);
        [notes add:note];
        [note release];
    }
    for (int i = 200; i < 300; i++) {
        MidiNote *note = [MidiNote alloc];
        note.startTime = i*10;
        note.number = middleC - (i % 2);
        [notes add:note];
        [note release];
    }
    ClefMeasures *clefs = [[ClefMeasures alloc] initWithNotes:notes andMeasure:50 ];
    for (int i = 0; i < 100; i++) {
        int clef = [clefs getClef:i*10];
        STAssertTrue(clef == Clef_Treble, @"");
    }
    for (int i = 100; i < 200; i++) {
        int clef = [clefs getClef:i*10];
        STAssertTrue(clef == Clef_Bass, @"");
    }
    for (int i = 200; i < 300; i++) {
        int clef = [clefs getClef:i*10];
        STAssertTrue(clef == Clef_Treble, @"");
    }
    [clefs release];
}

/* Create a list of notes where the average note is below middle-C.
 * Verify that
 * - notes above F4 are treble clef
 * - notes below G3 are bass clef
 * - notes in between G3 and F4 are bass clef.
 */
- (void) testMainClefBass {
    Array* notes = [Array new:100];
    for (int i = 0; i < 100; i++) {
        MidiNote *note = [MidiNote alloc];
        note.startTime = i*10;
        note.number = F4 + (i % 2);
        [notes add:note];
        [note release];
    }
    for (int i = 100; i < 200; i++) {
        MidiNote *note = [MidiNote alloc];
        note.startTime = i*10;
        note.number = G3 - (i % 20);
        [notes add:note];
        [note release];
    }
    for (int i = 200; i < 300; i++) {
        MidiNote *note = [MidiNote alloc];
        note.startTime = i*10;
        note.number = middleC + (i % 2);
        [notes add:note];
        [note release];
    }
    ClefMeasures *clefs = [[ClefMeasures alloc] initWithNotes:notes andMeasure:50 ];
    for (int i = 0; i < 100; i++) {
        int clef = [clefs getClef:i*10];
        STAssertTrue(clef == Clef_Treble, @"");
    }
    for (int i = 100; i < 200; i++) {
        int clef = [clefs getClef:i*10];
        STAssertTrue(clef == Clef_Bass, @"");
    }
    for (int i = 200; i < 300; i++) {
        int clef = [clefs getClef:i*10];
        STAssertTrue(clef == Clef_Bass, @"");
    }
    [clefs release];
}
@end  /* ClefMeasuresTest */



/* Test cases for the ChordSymbol class */
@interface ChordSymbolTest :SenTestCase {
}
- (void)testStemUpTreble;
- (void)testStemUpBass;
- (void)testStemDownTreble;
- (void)testStemDownBass;
- (void)testSixteenthDuration;
- (void)testWholeDuration;
- (void)testNotesOverlap;
- (void)testNotesOverlapStemDown;
- (void)testTwoStems;
- (void)testAccidentals;

@end

@implementation ChordSymbolTest

/* Test a chord with
 * - 2 notes at bottom of treble clef.
 * - No accidentals
 * - Quarter duration
 * - Stem facing up.
 */
- (void)testStemUpTreble {
    [SheetMusic setNoteSize:NO];
    KeySignature *key = [[KeySignature alloc] initWithSharps:0 andFlats:0];
    int quarter = 400;
    TimeSignature *time = [[TimeSignature alloc]
                             initWithNumerator:4 andDenominator:4
                             andQuarter:quarter  andTempo:60000];

    int num1 = [WhiteNote bottomTreble].number;
    int num2 = num1 + 2;
    MidiNote *note1 = [MidiNote alloc];
    note1.startTime = 0; 
    note1.number = num1;
    note1.duration = quarter;
    MidiNote *note2 = [MidiNote alloc];
    note2.startTime = 0; 
    note2.number = num2;
    note2.duration = quarter;

    Array *notes = [Array new:2];
    [notes add:note1];
    [notes add:note2];
    [note1 release];
    [note2 release];

    ChordSymbol *chord = [[ChordSymbol alloc]
                          initWithNotes:notes andKey:key
                          andTime:time  andClef:Clef_Treble andSheet:nil];
    STAssertEqualObjects([chord description], 
                    @"ChordSymbol clef=Treble start=0 end=400 width=16 hasTwoStems=0 Note whitenote=F4 duration=Quarter leftside=1 Note whitenote=G4 duration=Quarter leftside=0 Stem duration=Quarter direction=1 top=G4 bottom=F4 end=F5 overlap=1 side=2 width_to_pair=0 receiver=0 ", @"");

    [key release];
    [time release];
    [chord release];
}


/* Test a chord with
 * - 2 notes at top of treble clef.
 * - No accidentals
 * - Quarter duration
 * - Stem facing down.
 */
- (void)testStemDownTreble {
    [SheetMusic setNoteSize:NO];
    KeySignature *key = [[KeySignature alloc] initWithSharps:0 andFlats:0];
    int quarter = 400;
    TimeSignature *time = [[TimeSignature alloc]
                             initWithNumerator:4 andDenominator:4
                             andQuarter:quarter  andTempo:60000];
    int num2 = [WhiteNote topTreble].number;
    int num1 = num2 - 2;
    MidiNote *note1 = [MidiNote alloc];
    note1.startTime = 0; 
    note1.number = num1;
    note1.duration = quarter;
    MidiNote *note2 = [MidiNote alloc];
    note2.startTime = 0; 
    note2.number = num2;
    note2.duration = quarter;

    Array *notes = [Array new:2];
    [notes add:note1];
    [notes add:note2];
    [note1 release];
    [note2 release];

    ChordSymbol *chord = [[ChordSymbol alloc]
                          initWithNotes:notes andKey:key
                          andTime:time  andClef:Clef_Treble andSheet:nil];
    STAssertEqualObjects([chord description],
                    @"ChordSymbol clef=Treble start=0 end=400 width=16 hasTwoStems=0 Note whitenote=D5 duration=Quarter leftside=1 Note whitenote=E5 duration=Quarter leftside=0 Stem duration=Quarter direction=2 top=E5 bottom=D5 end=E4 overlap=1 side=2 width_to_pair=0 receiver=0 ", @"");

    [key release];
    [time release];
    [chord release];
}


/* Test a chord with
 * - 2 notes at bottom of bass clef.
 * - No accidentals
 * - Quarter duration
 * - Stem facing up.
 */
- (void)testStemUpBass {
    [SheetMusic setNoteSize:NO];
    KeySignature *key = [[KeySignature alloc] initWithSharps:0 andFlats:0];
    int quarter = 400;
    TimeSignature *time = [[TimeSignature alloc]
                             initWithNumerator:4 andDenominator:4
                             andQuarter:quarter  andTempo:60000];
    int num1 = [WhiteNote bottomBass].number;
    int num2 = num1 + 2;
    MidiNote *note1 = [MidiNote alloc];
    note1.startTime = 0; 
    note1.number = num1;
    note1.duration = quarter;
    MidiNote *note2 = [MidiNote alloc];
    note2.startTime = 0; 
    note2.number = num2;
    note2.duration = quarter;

    Array *notes = [Array new:2];
    [notes add:note1];
    [notes add:note2];
    [note1 release];
    [note2 release];

    ChordSymbol *chord = [[ChordSymbol alloc]
                          initWithNotes:notes andKey:key
                          andTime:time  andClef:Clef_Bass andSheet:nil];
    STAssertEqualObjects([chord description],
                    @"ChordSymbol clef=Bass start=0 end=400 width=16 hasTwoStems=0 Note whitenote=A3 duration=Quarter leftside=1 Note whitenote=B3 duration=Quarter leftside=0 Stem duration=Quarter direction=1 top=B3 bottom=A3 end=A4 overlap=1 side=2 width_to_pair=0 receiver=0 ", @"");

    [key release];
    [time release];
    [chord release];
}


/* Test a chord with
 * - 2 notes at top of treble clef.
 * - No accidentals
 * - Quarter duration
 * - Stem facing down.
 */
- (void)testStemDownBass {
    [SheetMusic setNoteSize:NO];
    KeySignature *key = [[KeySignature alloc] initWithSharps:0 andFlats:0];
    int quarter = 400;
    TimeSignature *time = [[TimeSignature alloc]
                             initWithNumerator:4 andDenominator:4
                             andQuarter:quarter  andTempo:60000];
    int num2 = [WhiteNote topBass].number;
    int num1 = num2 - 2;
    MidiNote *note1 = [MidiNote alloc];
    note1.startTime = 0; 
    note1.number = num1;
    note1.duration = quarter;
    MidiNote *note2 = [MidiNote alloc];
    note2.startTime = 0; 
    note2.number = num2;
    note2.duration = quarter;

    Array *notes = [Array new:2];
    [notes add:note1];
    [notes add:note2];
    [note1 release];
    [note2 release];


    ChordSymbol *chord = [[ChordSymbol alloc]
                          initWithNotes:notes andKey:key
                          andTime:time  andClef:Clef_Bass andSheet:nil];

    STAssertEqualObjects([chord description],
                    @"ChordSymbol clef=Bass start=0 end=400 width=16 hasTwoStems=0 Note whitenote=F3 duration=Quarter leftside=1 Note whitenote=G3 duration=Quarter leftside=0 Stem duration=Quarter direction=2 top=G3 bottom=F3 end=G2 overlap=1 side=2 width_to_pair=0 receiver=0 ", @"");

    [key release];
    [time release];
    [chord release];
}


/* Test a chord with
 * - 1 notes at bottom of treble clef.
 * - No accidentals
 * - Sixteenth duration
 * - Stem facing up.
 * Test that GetAboveWidth returns 1 note above the staff.
 */
- (void)testSixteenthDuration {
    [SheetMusic setNoteSize:NO];
    KeySignature *key = [[KeySignature alloc] initWithSharps:0 andFlats:0];
    int quarter = 400;
    TimeSignature *time = [[TimeSignature alloc]
                             initWithNumerator:4 andDenominator:4
                             andQuarter:quarter  andTempo:60000];
    int num1 = [WhiteNote bottomTreble].number;
    MidiNote *note1 = [MidiNote alloc];
    note1.startTime = 0; 
    note1.number = num1;
    note1.duration = quarter/4;

    Array *notes = [Array new:1];
    [notes add:note1];
    [note1 release];

    ChordSymbol *chord = [[ChordSymbol alloc]
                          initWithNotes:notes andKey:key
                          andTime:time  andClef:Clef_Treble andSheet:nil];
    STAssertEqualObjects([chord description],
                    @"ChordSymbol clef=Treble start=0 end=100 width=16 hasTwoStems=0 Note whitenote=F4 duration=Sixteenth leftside=1 Stem duration=Sixteenth direction=1 top=F4 bottom=F4 end=G5 overlap=0 side=2 width_to_pair=0 receiver=0 ", @"");
    STAssertTrue(chord.aboveStaff == NoteHeight, @"");

    [key release];
    [time release];
    [chord release];
}

/* Test a chord with
 * - 1 notes at bottom of treble clef.
 * - No accidentals
 * - whole duration
 * - no stem
 */

- (void)testWholeDuration {
    [SheetMusic setNoteSize:NO];
    KeySignature *key = [[KeySignature alloc] initWithSharps:0 andFlats:0];
    int quarter = 400;
    TimeSignature *time = [[TimeSignature alloc]
                             initWithNumerator:4 andDenominator:4
                             andQuarter:quarter  andTempo:60000];
    int num1 = [WhiteNote bottomTreble].number;
    MidiNote *note1 = [MidiNote alloc];
    note1.startTime = 0; 
    note1.number = num1;
    note1.duration = quarter*4;

    Array *notes = [Array new:1];
    [notes add:note1];
    [note1 release];

    ChordSymbol *chord = [[ChordSymbol alloc]
                          initWithNotes:notes andKey:key
                          andTime:time  andClef:Clef_Treble andSheet:nil];
    STAssertEqualObjects([chord description],
                    @"ChordSymbol clef=Treble start=0 end=1600 width=16 hasTwoStems=0 Note whitenote=F4 duration=Whole leftside=1 ", @"");

    [key release];
    [time release];
    [chord release];
}

/* Test a chord with
 * - 2 notes at bottom of treble clef
 * - The notes overlap when drawn.
 * - No accidentals
 * - Quarter duration
 * - Stem facing up.
 */
- (void)testNotesOverlap {
    [SheetMusic setNoteSize:NO];
    KeySignature *key = [[KeySignature alloc] initWithSharps:0 andFlats:0];
    int quarter = 400;
    TimeSignature *time = [[TimeSignature alloc]
                             initWithNumerator:4 andDenominator:4
                             andQuarter:quarter  andTempo:60000];
    int num1 = [WhiteNote bottomTreble].number;
    int num2 = num1 + 1;
    MidiNote *note1 = [MidiNote alloc];
    note1.startTime = 0; 
    note1.number = num1;
    note1.duration = quarter;
    MidiNote *note2 = [MidiNote alloc];
    note2.startTime = 0; 
    note2.number = num2;
    note2.duration = quarter;

    Array *notes = [Array new:2];
    [notes add:note1];
    [notes add:note2];
    [note1 release];
    [note2 release];

    ChordSymbol *chord = [[ChordSymbol alloc]
                          initWithNotes:notes andKey:key
                          andTime:time  andClef:Clef_Treble andSheet:nil];
    STAssertEqualObjects([chord description],
                    @"ChordSymbol clef=Treble start=0 end=400 width=25 hasTwoStems=0 AccidSymbol accid=Sharp whitenote=F4 clef=Treble width=9 Note whitenote=F4 duration=Quarter leftside=1 Note whitenote=F4 duration=Quarter leftside=1 Stem duration=Quarter direction=1 top=F4 bottom=F4 end=E5 overlap=0 side=2 width_to_pair=0 receiver=0 ", @"");

    [key release];
    [time release];
    [chord release];
}

/* Test a chord with
 * - 2 notes at top of treble clef
 * - The notes overlap when drawn.
 * - No accidentals
 * - Quarter duration
 * - Stem facing down.
 * - Stem is on the right side of the first note.
 */
- (void)testNotesOverlapStemDown {
    [SheetMusic setNoteSize:NO];
    KeySignature *key = [[KeySignature alloc] initWithSharps:0 andFlats:0];
    int quarter = 400;
    TimeSignature *time = [[TimeSignature alloc]
                             initWithNumerator:4 andDenominator:4
                             andQuarter:quarter  andTempo:60000];
    int num1 = [WhiteNote topTreble].number;
    int num2 = num1 + 1;
    MidiNote *note1 = [MidiNote alloc];
    note1.startTime = 0; 
    note1.number = num1;
    note1.duration = quarter;
    MidiNote *note2 = [MidiNote alloc];
    note2.startTime = 0; 
    note2.number = num2;
    note2.duration = quarter;

    Array *notes = [Array new:2];
    [notes add:note1];
    [notes add:note2];
    [note1 release];
    [note2 release];

    ChordSymbol *chord = [[ChordSymbol alloc]
                          initWithNotes:notes andKey:key
                          andTime:time  andClef:Clef_Treble andSheet:nil];
    STAssertEqualObjects([chord description],
                    @"ChordSymbol clef=Treble start=0 end=400 width=16 hasTwoStems=0 Note whitenote=E5 duration=Quarter leftside=1 Note whitenote=F5 duration=Quarter leftside=0 Stem duration=Quarter direction=2 top=F5 bottom=E5 end=F4 overlap=1 side=2 width_to_pair=0 receiver=0 ", @"");

    [key release];
    [time release];
    [chord release];
}


/* Test a chord with
 * - 2 notes at bottom of treble clef
 * - The notes have different durations (quarter, eighth)
 * - No accidentals
 * - Two stems:one facing up, one facing down.
 */

- (void)testTwoStems {
    [SheetMusic setNoteSize:NO];
    KeySignature *key = [[KeySignature alloc] initWithSharps:0 andFlats:0];
    int quarter = 400;
    TimeSignature *time = [[TimeSignature alloc]
                             initWithNumerator:4 andDenominator:4
                             andQuarter:quarter  andTempo:60000];
    int num1 = [WhiteNote bottomTreble].number;
    int num2 = num1 + 2;
    MidiNote *note1 = [MidiNote alloc];
    note1.startTime = 0; 
    note1.number = num1;
    note1.duration = quarter;
    MidiNote *note2 = [MidiNote alloc];
    note2.startTime = 0; 
    note2.number = num2;
    note2.duration = quarter/2;

    Array *notes = [Array new:2];
    [notes add:note1];
    [notes add:note2];
    [note1 release];
    [note2 release];

    ChordSymbol *chord = [[ChordSymbol alloc]
                          initWithNotes:notes andKey:key
                          andTime:time  andClef:Clef_Treble andSheet:nil];
    STAssertEqualObjects([chord description],
                    @"ChordSymbol clef=Treble start=0 end=400 width=16 hasTwoStems=1 Note whitenote=F4 duration=Quarter leftside=1 Note whitenote=G4 duration=Eighth leftside=0 Stem duration=Quarter direction=2 top=F4 bottom=F4 end=G3 overlap=0 side=1 width_to_pair=0 receiver=0 Stem duration=Eighth direction=1 top=G4 bottom=G4 end=F5 overlap=1 side=2 width_to_pair=0 receiver=0 ", @"");

    [key release];
    [time release];
    [chord release];
}


/* Test a chord with
 * - 2 notes at bottom of treble clef.
 * - Both notes have sharp accidentals.
 * - Quarter duration
 * - Stem facing up.
 * Test that Width returns extra space for accidentals.
 */
- (void)testAccidentals {
    [SheetMusic setNoteSize:NO];
    KeySignature *key = [[KeySignature alloc] initWithSharps:0 andFlats:0];
    int quarter = 400;
    TimeSignature *time = [[TimeSignature alloc]
                             initWithNumerator:4 andDenominator:4
                             andQuarter:quarter  andTempo:60000];
    int num1 = [WhiteNote bottomTreble].number + 1;
    int num2 = num1 + 2;
    MidiNote *note1 = [MidiNote alloc];
    note1.startTime = 0; 
    note1.number = num1;
    note1.duration = quarter;
    MidiNote *note2 = [MidiNote alloc];
    note2.startTime = 0; 
    note2.number = num2;
    note2.duration = quarter;

    Array *notes = [Array new:2];
    [notes add:note1];
    [notes add:note2];
    [note1 release];
    [note2 release];

    ChordSymbol *chord = [[ChordSymbol alloc]
                          initWithNotes:notes andKey:key
                          andTime:time  andClef:Clef_Treble andSheet:nil];
    STAssertEqualObjects([chord description],
                   @"ChordSymbol clef=Treble start=0 end=400 width=34 hasTwoStems=0 AccidSymbol accid=Sharp whitenote=F4 clef=Treble width=9 AccidSymbol accid=Sharp whitenote=G4 clef=Treble width=9 Note whitenote=F4 duration=Quarter leftside=1 Note whitenote=G4 duration=Quarter leftside=0 Stem duration=Quarter direction=1 top=G4 bottom=F4 end=F5 overlap=1 side=2 width_to_pair=0 receiver=0 ", @"");

    int notewidth = 2*NoteHeight + NoteHeight*3/4;
    int accidwidth = 3*NoteHeight;
    STAssertTrue(chord.minWidth == notewidth + accidwidth, @"");

    [key release];
    [time release];
    [chord release];
}

@end

