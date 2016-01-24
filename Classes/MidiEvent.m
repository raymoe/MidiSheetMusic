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

#import "MidiEvent.h"
#import "MidiFile.h"
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

/** Compare two MidiEvents based on their start times. 
 *  Used by the C mergesort function.
 */
int sortMidiEvent(void* v1, void* v2) {
    MidiEvent **ev1 = (MidiEvent**)v1;
    MidiEvent **ev2 = (MidiEvent**)v2;
    MidiEvent *event1 = *ev1;
    MidiEvent *event2 = *ev2;

    if (event1.startTime == event2.startTime) {
        return event1.eventFlag - event2.eventFlag;
    }
    else {
        return event1.startTime - event2.startTime;
    }
}


/** @class MidiEvent
 * A MidiEvent represents a single event (such as EventNoteOn) in the
 * Midi file. It includes the delta time of the event.
 */
@implementation MidiEvent

@synthesize deltaTime;
@synthesize startTime;
@synthesize hasEventflag;
@synthesize eventFlag;
@synthesize channel;
@synthesize notenumber;
@synthesize velocity;
@synthesize instrument;
@synthesize keyPressure;
@synthesize chanPressure;
@synthesize controlNum;
@synthesize controlValue;
@synthesize pitchBend;
@synthesize numerator;
@synthesize denominator;
@synthesize tempo;
@synthesize metaevent;
@synthesize metalength;
@synthesize metavalue;

/** Initialize all the MidiEvent fields to 0 */
- (id)init {
    deltaTime = 0;
    startTime = 0;
    hasEventflag = 0;
    eventFlag = 0;
    channel = 0;
    notenumber = 0;
    velocity = 0;
    instrument = 0;
    keyPressure = 0;
    chanPressure = 0;
    controlNum = 0;
    controlValue = 0;
    pitchBend = 0;
    numerator = 0;
    denominator = 0;
    tempo = 0;
    metaevent = 0;
    metalength = 0;
    metavalue = NULL;
    return self;
}


- (id)copyWithZone:(NSZone*)zone {
    MidiEvent *mevent = [[MidiEvent alloc] init];
    mevent.deltaTime = deltaTime;
    mevent.startTime = startTime;
    mevent.hasEventflag = hasEventflag;
    mevent.eventFlag = eventFlag;
    mevent.channel = channel;
    mevent.notenumber = notenumber;
    mevent.velocity = velocity;
    mevent.instrument = instrument;
    mevent.keyPressure = keyPressure;
    mevent.chanPressure = chanPressure;
    mevent.controlNum = controlNum;
    mevent.controlValue = controlValue;
    mevent.pitchBend = pitchBend;
    mevent.numerator = numerator;
    mevent.denominator = denominator;
    mevent.tempo = tempo;
    mevent.metaevent = metaevent;
    mevent.metalength = metalength;
    mevent.metavalue = metavalue;
    return [mevent autorelease];
}

- (void)dealloc {
    if (eventFlag == MetaEvent || eventFlag == SysexEvent1 ||
        eventFlag == SysexEvent2) {
        /* free(metavalue); */
        metavalue = NULL;
    }
    [super dealloc];
}

@end

