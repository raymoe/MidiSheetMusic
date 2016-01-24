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

#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>

/** The possible note durations */
typedef enum {
  ThirtySecond, Sixteenth, Triplet, Eighth,
  DottedEighth, Quarter, DottedQuarter,
  Half, DottedHalf, Whole
} NoteDuration;


@interface TimeSignature : NSObject {
    int numerator;      /** Numerator of the time signature */
    int denominator;    /** Denominator of the time signature */
    int quarter;        /** Number of pulses per quarter note */
    int measure;        /** Number of pulses per measure */
    int tempo;          /** Number of microseconds per quarter note */
}

@property (nonatomic, readonly) int numerator;
@property (nonatomic, readonly) int denominator;
@property (nonatomic, readonly) int quarter;
@property (nonatomic, readonly) int measure;
@property (nonatomic, readonly) int tempo;

-(id)initWithNumerator:(int)num andDenominator:(int)d andQuarter:(int)q andTempo:(int)t;
-(int)getMeasureForTime:(int)time;
-(NoteDuration)getNoteDuration:(int)pulses;
-(int)durationToTime:(NoteDuration)duration;
-(id)copyWithZone:(NSZone*)zone;
+(NSString*)durationString:(int)dur;

@end

