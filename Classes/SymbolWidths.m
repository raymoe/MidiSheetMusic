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

#import "SymbolWidths.h"
#import "MusicSymbol.h"
#import "LyricSymbol.h"
#import "BarSymbol.h"

/**@class IntDict
 *  The IntDict class is a dictionary mapping integers to integers. 
 */
@implementation IntDict 

/** Create a new IntDict instance with the given capacity.  
 * Initialize two int arrays,  one to store the keys and one 
 * to store the values.
 */
- (id)initWithCapacity:(int)amount {
    size = 0;
    if (amount == 0)
        amount = 10;
    capacity = amount;
    lastpos = 0;
    keys = (int*) calloc(capacity, sizeof(int));
    values = (int*) calloc(capacity, sizeof(int));
    return self;
}

- (void)dealloc {
    free(keys);
    free(values);
    [super dealloc];
}

/** Increase the capacity of the key/value arrays  */
- (void)resize
{
    int newcapacity = capacity * 2;
    int* newkeys = (int*)calloc(newcapacity, sizeof(int));
    int *newvalues = (int*)calloc(newcapacity, sizeof(int));
    for (int i = 0; i < capacity; i++) {
        newkeys[i] = keys[i];
        newvalues[i] = values[i];
    }
    free(keys);
    free(values);
    keys = newkeys;
    values = newvalues;
    capacity = newcapacity;
}

/** Add the given key/value pair to this dictionary.
 * This assumes the key is not already in the dictionary.
 * If the keys/values arrays are full, then resize them.
 * The keys array must be kept in sorted order, so insert
 * the new key/value in the correct sorted position.
 */
- (void)addKey:(int)key withValue:(int)value {
    if (size == capacity) {
        [self resize];
    }

    int pos = size-1;
    while (pos >= 0 && key < keys[pos]) {
        keys[pos+1] = keys[pos];
        values[pos+1] = values[pos];
        pos--;
    }
    keys[pos+1] = key;
    values[pos+1] = value;
    size++;
}

/** Set the given key to the given value */
- (void)setKey:(int)key withValue:(int)value {
    if ([self contains:key] ) {
        keys[lastpos] = key;
        values[lastpos] = value;
    }
    else {
        [self addKey:key withValue:value];
    }
}
 

/** Return TRUE if this dictionary contains the given key.
 * If true, set lastpos = the index position of the key.
 */
- (BOOL)contains:(int)key {
    if (size == 0)
        return FALSE;

    /* The SymbolWidths class below calls this method many times,
     * passing the keys in sorted order.  To speed up performance,
     * we start searching at the position of the last key (lastpos),
     * instead of starting at the beginning of the array.
     */
    if (lastpos < 0 || lastpos >= size || key < keys[lastpos])
        lastpos = 0;

    while (lastpos < size && key > keys[lastpos]) {
        lastpos++;
    }
    if (lastpos < size && key == keys[lastpos]) {
        return TRUE;
    }
    else {
        return FALSE;
    }
}

/** Get the value for the given key. */
- (int)get:(int)key {
    if ([self contains:key]) {
        return values[lastpos];
    }
    else {
        assert(0);
        return 0;
    }
}

/** Return the number of key/value pairs */
- (int)count {
    return size;
}

/** Return the key at the given index */
- (int)getkey:(int)index {
    return keys[index];
}

/** Return the capacity of the dictionary */
- (int)capacity {
    return capacity;
}

@end

/** @class SymbolWidths
 * The SymbolWidths class is used to vertically align notes in different
 * tracks that occur at the same time (that have the same starttime).
 * This is done by the following:
 * - Store a list of all the start times.
 * - Store the width of symbols for each start time, for each track.
 * - Store the maximum width for each start time, across all tracks.
 * - Get the extra width needed for each track to match the maximum
 *   width for that start time.
 *
 * See method SheetMusic.AlignSymbols(), which uses this class.
 */

@implementation SymbolWidths

/** Initialize the symbol width maps, given all the symbols in
 * all the tracks.
 */
- (id)initWithSymbols:(Array*)tracks andLyrics:(Array*)tracklyrics {
    int i, tracknum;
    IntDict *dict;

    /* Get the symbol widths for all the tracks */
    widths = [[Array new:[tracks count]] retain];
    for (tracknum = 0; tracknum < [tracks count]; tracknum++) {
        dict = [SymbolWidths getTrackWidths:[tracks get:tracknum]];
        [widths add:dict];
    }

    maxwidths = [[IntDict alloc] initWithCapacity:[tracks count]];

    /* Calculate the maximum symbol widths */
    for (i = 0; i < [widths count]; i++) {
        dict = [widths get:i];
        int time;

        for (int k = 0; k < [dict count]; k++) {
            time = [dict getkey:k];
            if (!([maxwidths contains:time])  ||
                ([maxwidths get:time] < [dict get:time])) {

                [maxwidths setKey:time withValue:[dict get:time]];
            }
        }
    }

    if (tracklyrics != nil) {
        for (int tracknum = 0; tracknum < [tracklyrics count]; tracknum++) {
            Array *lyrics = [tracklyrics get:tracknum];
            if (lyrics == nil || [lyrics count] == 0) {
                continue;
            }
            for (int i = 0; i < [lyrics count]; i++) {
                LyricSymbol *lyric = [lyrics get:i];
                int width = lyric.minWidth;
                int time = lyric.startTime;

                if (!([maxwidths contains:time])  ||
                    ([maxwidths get:time] < width)) {

                    [maxwidths setKey:time withValue:width];
                }
            }
        }
    }

    /* Store all the start times to the starttime array.
     * Since the IntDict keys are sorted, the starttimes array
     * will also be sorted.
     */
    starttimes = [[IntArray new:[maxwidths count]] retain];
    for (int i = 0; i < [maxwidths count]; i++) {
        [starttimes add:[maxwidths getkey:i]];
    }
    return self;
}


- (void)dealloc {
    [widths release];
    [maxwidths release];
    [starttimes release];
    [super dealloc];
}

/** Create a table of the symbol widths for each starttime in the track. */
+(IntDict*) getTrackWidths:(Array*) symbols {
    IntDict *widths = [[IntDict alloc] initWithCapacity:23];

    for (int i = 0; i < [symbols count]; i++) {
        id <MusicSymbol> m = [symbols get:i];
        int start = m.startTime;
        int w = m.minWidth;

        if ([m isKindOfClass:[BarSymbol class]]) {
            continue;
        }
        else if ([widths contains:start]) {
            [widths setKey:start withValue:([widths get:start] + w) ];
        }
        else {
            [widths addKey:start withValue:w];
        }
    }
    return [widths autorelease];
}

/** Given a track and a start time, return the extra width needed so that
 * the symbols for that start time align with the other tracks.
 */
- (int) getExtraWidth:(int)track forTime:(int)start {
    IntDict *trackwidths = [widths get:track];

    if (![trackwidths contains:start]) {
        return [maxwidths get:start];
    }
    else {
        return [maxwidths get:start] - [trackwidths get:start];
    }
}

/** Return an array of all the start times in all the tracks */
- (IntArray*)startTimes {
    return starttimes;
}


@end

