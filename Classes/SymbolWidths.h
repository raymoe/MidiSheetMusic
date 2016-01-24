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
#import "Array.h"
#import "IntArray.h"

@interface IntDict : NSObject {
    int *keys;     /** Sorted array of integer keys */
    int *values;   /** Array of integer values */
    int size;      /** Number of keys */
    int capacity;  /** capacity of arrays */
    int lastpos;   /** The index from the last "get" method */
}
-(id)initWithCapacity:(int)amount;
-(void)resize;
-(void)addKey:(int)key withValue:(int)value;
-(void)setKey:(int)key withValue:(int)value;
-(int)get:(int)key;
-(BOOL)contains:(int)key;
-(int)getkey:(int)index;
-(int)count;
-(int)capacity;
-(void)dealloc;
@end

@interface SymbolWidths : NSObject {
    /** Array of IntDict maps (starttime -> symbol width), one per track */
    Array *widths;

    /** Map of starttime -> maximum symbol width */
    IntDict *maxwidths;

    /** An array of all the starttimes, in all tracks */
    IntArray *starttimes;
}

-(id)initWithSymbols:(Array*)tracks andLyrics:(Array*)lyrics;
-(void)dealloc;
+(IntDict*)getTrackWidths:(Array*)symbols;
-(int)getExtraWidth:(int)track forTime:(int)starttime;
-(IntArray*)startTimes;

@end

