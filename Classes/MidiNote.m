/*
 * Copyright (c) 2007-2012 Madhav Vaidyanathan
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License version 2.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 */

#import "MidiFile.h"
#import "MidiNote.h"
#import <Foundation/NSAutoreleasePool.h>
#include <stdlib.h>
#include <fcntl.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <assert.h>
#include <stdio.h>
#include <sys/stat.h>
#include <math.h>

/** @class MidiNote
 * A MidiNote contains
 *
 * starttime - The time (measured in pulses) when the note is pressed.
 * channel   - The channel the note is from.  This is used when matching
 *             NoteOff events with the corresponding NoteOn event.
 *             The channels for the NoteOn and NoteOff events must be
 *             the same.
 * number    - The note number, from 0 to 127.  Middle C is 60.
 * duration  - The time duration (measured in pulses) after which the 
 *             note is released.
 *
 * A MidiNote is created when we encounter a NoteOff event.  The duration
 * is initially unknown (set to 0).  When the corresponding NoteOff event
 * is found, the duration is set by the method NoteOff().
 */

@implementation MidiNote

@synthesize startTime;
@synthesize channel;
@synthesize number;
@synthesize duration;

- (id)init {
    startTime = 0;
    channel = 0;
    duration = 0;
    number = 0;
    return self;
} 

- (int)endTime
{
    return startTime + duration;
}

/* A NoteOff event occurs for this note at the given time.
 * Calculate the note duration based on the noteoff event.
 */
- (void)noteOff:(int)endtime {
    duration = endtime - startTime;
}

- (id)copyWithZone:(NSZone*)zone {
    MidiNote *m = [[MidiNote alloc] init];
    m.startTime = startTime;
    m.channel = channel;
    m.number = number;
    m.duration = duration;
    return [m autorelease];
}

- (NSString*)description {
    NSString *s = [NSString stringWithFormat:
                      @"MidiNote channel=%d number=%d start=%d duration=%d",
                      channel, number, startTime, duration ];
    return s;
}

- (void)dealloc {
    [super dealloc];
}

@end


