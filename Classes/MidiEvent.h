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

#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>
#import <Foundation/NSZone.h>
#import <Foundation/NSException.h>

#import "Array.h"
#import "TimeSignature.h"

int sortMidiEvent(void* v1, void* v2);

@interface MidiEvent : NSObject <NSCopying> {
    int     deltaTime;     /** The time between the previous event and this on */
    int     startTime;     /** The absolute time this event occurs */
    bool    hasEventflag;  /** False if this is using the previous eventflag */
    u_char  eventFlag;     /** NoteOn, NoteOff, etc.  Full list is in class MidiFile */
    u_char  channel;       /** The channel this event occurs on */

    u_char  notenumber;    /** The note number  */
    u_char  velocity;      /** The volume of the note */
    u_char  instrument;    /** The instrument */
    u_char  keyPressure;   /** The key pressure */
    u_char  chanPressure;  /** The channel pressure */
    u_char  controlNum;    /** The controller number */
    u_char  controlValue;  /** The controller value */
    u_short pitchBend;     /** The pitch bend value */
    u_char  numerator;     /** The numerator, for TimeSignature meta events */
    u_char  denominator;   /** The denominator, for TimeSignature meta events */
    int     tempo;         /** The tempo, for Tempo meta events */
    u_char  metaevent;     /** The metaevent, used if eventflag is MetaEvent */
    int     metalength;    /** The metaevent length  */
    u_char* metavalue;     /** The raw byte value, for Sysex and meta events */
}

@property (nonatomic, assign) int deltaTime;
@property (nonatomic, assign) int startTime;
@property (nonatomic, assign) bool hasEventflag;
@property (nonatomic, assign) u_char eventFlag;
@property (nonatomic, assign) u_char channel;
@property (nonatomic, assign) u_char notenumber;
@property (nonatomic, assign) u_char velocity;
@property (nonatomic, assign) u_char instrument;
@property (nonatomic, assign) u_char keyPressure;
@property (nonatomic, assign) u_char chanPressure;
@property (nonatomic, assign) u_char controlNum;
@property (nonatomic, assign) u_char controlValue;
@property (nonatomic, assign) u_short pitchBend;
@property (nonatomic, assign) u_char numerator;
@property (nonatomic, assign) u_char denominator;
@property (nonatomic, assign) int tempo;
@property (nonatomic, assign) u_char metaevent;
@property (nonatomic, assign) int metalength;
@property (nonatomic, assign) u_char* metavalue;

-(id)init;
-(id)copyWithZone:(NSZone*)zone;

@end


