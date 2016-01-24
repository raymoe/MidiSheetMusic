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

#import "TimeSignature.h"
#import "MidiFile.h"

/** @class TimeSignature
 * The TimeSignature class represents
 * - The time signature of the song, such as 4/4, 3/4, or 6/8 time, and
 * - The number of pulses per quarter note
 * - The number of microseconds per quarter note
 *
 * In midi files, all time is measured in "pulses".  Each note has
 * a start time (measured in pulses), and a duration (measured in 
 * pulses).  This class is used mainly to convert pulse durations
 * (like 120, 240, etc) into note durations (half, quarter, eighth, etc).
 */

@implementation TimeSignature

@synthesize numerator;
@synthesize denominator;
@synthesize quarter;
@synthesize measure;
@synthesize tempo;

/** Create a new time signature, with the given numerator,
 * denominator, pulses per quarter note, and tempo.
 */
- (id)initWithNumerator:(int)n andDenominator:(int)d andQuarter:(int)q andTempo:(int)t {
    int beat;

    if (n <= 0 || d <= 0 || q <= 0) {
        MidiFileException *e = [MidiFileException init:@"Invalid Time Signature" offset:0];
        @throw e;
    }

    numerator = n;
    denominator = d;
    quarter = q;
    tempo = t;

    /* Midi File gives wrong time signature sometimes */
    if (numerator == 5) {
        numerator = 4;
    }

    if (denominator < 4)
        beat = quarter * 2;
    else
        beat = quarter / (denominator/4);

    measure = numerator * beat;
    return self;
}

- (void)dealloc {
    [super dealloc];
}

/** Return which measure the given time (in pulses) belongs to. */
- (int)getMeasureForTime:(int)time {
    return time / measure;
}

/** Given a duration in pulses, return the closest note duration. */
- (NoteDuration)getNoteDuration:(int)duration {
    int whole = quarter * 4;

    /**
     1       = 32/32
     3/4     = 24/32
     1/2     = 16/32
     3/8     = 12/32
     1/4     =  8/32
     3/16    =  6/32
     1/8     =  4/32 =    8/64
     triplet         = 5.33/64
     1/16    =  2/32 =    4/64
     1/32    =  1/32 =    2/64
     **/ 

    if      (duration >= 28*whole/32)
        return Whole;
    else if (duration >= 20*whole/32) 
        return DottedHalf;
    else if (duration >= 14*whole/32)
        return Half;
    else if (duration >= 10*whole/32)
        return DottedQuarter;
    else if (duration >=  7*whole/32)
        return Quarter;
    else if (duration >=  5*whole/32)
        return DottedEighth;
    else if (duration >=  6*whole/64)
        return Eighth;
    else if (duration >=  5*whole/64)
        return Triplet;
    else if (duration >=  3*whole/64)
        return Sixteenth;
    else
        return ThirtySecond;
}


/** Return the time period (in pulses) the the given duration spans */
- (int)durationToTime:(NoteDuration)dur {
    int eighth = quarter/2;
    int sixteenth = eighth/2;

    switch (dur) {
        case Whole:         return quarter * 4; 
        case DottedHalf:    return quarter * 3; 
        case Half:          return quarter * 2; 
        case DottedQuarter: return 3*eighth; 
        case Quarter:       return quarter; 
        case DottedEighth:  return 3*sixteenth;
        case Eighth:        return eighth;
        case Triplet:       return quarter/3; 
        case Sixteenth:     return sixteenth;
        case ThirtySecond:  return sixteenth/2; 
        default:            return 0;
    }
}

/* Return a copy of this time signature */
- (id)copyWithZone:(NSZone*)zone {
    TimeSignature *t = [[TimeSignature alloc]
                         initWithNumerator:numerator 
                         andDenominator:denominator 
                         andQuarter:quarter 
                         andTempo:tempo];
    return [t autorelease];
}

- (NSString*) description {
    NSString *s = [NSString stringWithFormat:
                   @"TimeSignature=%d/%d quarter=%d tempo=%d", 
                   numerator, denominator, quarter, tempo ];
    return s;
}

/** Return the given duration as a string */
+ (NSString*) durationString:(int)dur {
    NSString *names[] = { 
        @"ThirtySecond", @"Sixteenth", @"Triplet", @"Eighth",
        @"DottedEighth", @"Quarter", @"DottedQuarter",
        @"Half", @"DottedHalf", @"Whole"
    };
    if (dur < 0 || dur > 9) {
        return @"";
    }
    return names[dur];
}

@end

