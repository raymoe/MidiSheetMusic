/*
 * Copyright (c) 2007-2009 Madhav Vaidyanathan
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
#include <stdlib.h>
#include <assert.h>
#include <fcntl.h>
#import "IntArray.h"

/* The IntArray class stores an array int */
@implementation IntArray

/* Allocate a new integer array, with the given capacity */
+ (id)new:(int)capacity {
    IntArray *arr = [[IntArray alloc] initWithCapacity:capacity];
    return [arr autorelease];
}

- (id)initWithCapacity:(int)newcapacity {
    assert(newcapacity >= 0);
    if (newcapacity == 0)
        newcapacity = 1;
    capacity = newcapacity;
    size = 0;
    values = (int*)calloc(capacity, sizeof(int));
    return self;
}

/* Free the integer array */
- (void)dealloc {
    free(values);
    [super dealloc];
}

/* Append integer x to the end of the array.
 * If needed, increase the capacity of the array.
 */
- (void)add:(int)x {
    if (size == capacity) {
        int newcapacity = 2*capacity;
        int* newvalues = (int*)calloc(newcapacity, sizeof(int));
        for (int i = 0; i < size; i++) {
            newvalues[i] = values[i];
        }
        free(values);
        values = newvalues;
        capacity = newcapacity;
    }
    values[size] = x;
    size++;
}

/* Return the integer at the given index */
- (int)get:(int)index {
	assert(index >= 0 && index < size);
    return values[index];
}

/* Set the integer at index i to the value x */
- (void)set:(int)x index:(int)i {
	assert(i >= 0 && i < size);
    values[i] = x;
}

/* Return YES if this array contains the given integer x.
 * Else, return NO.
 */
- (BOOL)contains:(int)x {
    for (int i = 0; i < size; i++) {
        if (values[i] == x) {
            return YES;
        }
    }
    return NO;
}

/* Return the index of the given integer x in the array.
 * This method assumes that x is definitely in the array.
 */
- (int)indexOf:(int)x {
    int startindex = 0;
    int endindex = size;
    int pos = startindex + (endindex - startindex)/2;
    while (values[pos] != x) {
        if (values[pos] < x) {
            startindex = pos;
            pos = startindex + (endindex - startindex)/2;
        }
        else {
            endindex = pos;
            pos = startindex + (endindex - startindex)/2;
        }
    }
    return pos;
}

/* Return the number of items in the array */
- (int)count {
    return size;
}

/* Comparison function for sorting the integer array. */
static int intcmp(const void *v1, const void* v2) {
    int *x1 = (int*) v1;
    int *x2 = (int*) v2;
    return (*x1) - (*x2);
}

/** Sort the int array using mergesort.
 *  Don't use quicksort. In MidiFile.m, we're sorting lots of 
 *  MidiNotes that are already mostly sorted, and quicksort
 *  performs badly on those.
 */
- (void)sort {
    mergesort(values, size, sizeof(int), intcmp);
}

/** Convert this IntArray to an NSArray of NSNumber */
- (NSArray *)toArray {
    NSMutableArray *nsarray = [[NSMutableArray alloc] init];
    for (int i = 0; i < [self count]; i++) {
        NSNumber *num = [NSNumber numberWithInt:[self get:i]];
        [nsarray addObject:num];
    }
    return [nsarray autorelease];
}

/** Initialize this IntArray from an NSArray of NSNumber */
- (IntArray *)initFromArray:(NSArray *)nsarray
{
    [self initWithCapacity:[nsarray count]];
    for (int i = 0; i < [nsarray count]; i++) {
        NSNumber *num = [nsarray objectAtIndex:i];
        [self add: [num intValue]];
    }
    return self;
}

/** Clone this IntArray */
- (IntArray *)clone
{
    IntArray *result = [[IntArray alloc] initWithCapacity:[self count]];
    for (int i = 0; i < [self count]; i++) {
        [result add:[self get:i]];
    }
    return [result autorelease];
}

@end

