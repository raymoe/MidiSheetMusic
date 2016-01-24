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
#import "Array.h"

/* The Array class is just a convenience class, which has shorter
 * method names than NSMutableArray.
 */
@implementation Array

/* Create a new array with the given capacity */
+ (id)new:(int)capacity {
    Array *a = [[Array alloc] initWithCapacity:capacity];
    return [a autorelease];
}

- (id)initWithCapacity:(int)capacity {
    if (capacity == 0) {
        capacity = 1;
    }
    array = [[NSMutableArray alloc] initWithCapacity:capacity];
    return self;
}

/* free the Array */
- (void)dealloc {
    [array release];
    [super dealloc];
}
    

/* Return the size of the array */
- (int)count {
    return [array count];
}

/* Add an object to the array */
- (void)add:(id)object {
    [array addObject:object];
}

/* Retrieve an object at the given index */
- (id)get:(int)index {
    assert(index >= 0 && index < [array count]);
    return [array objectAtIndex:index];
}

- (MidiNote *)getNote:(int)index {
    return (MidiNote *)[self get:index];
}

/* Set an object at the given index */
- (void)set:(id)obj index:(int)x {
    assert(x >= 0 && x < [array count]);
    [array replaceObjectAtIndex:x withObject:obj];
}

/* Remove the object from the array */
- (void)remove:(id)obj {
    [array removeObject:obj];
}

/* Remove all objects from the array */
- (void)clear {
    [array removeAllObjects];
}

/* Sort the array, using the given comparison function.
 * Use mergesort over quicksort In MidiFile.m, the MidiNote
 * arrays are already mostly sorted, so quicksort won't work
 * well here.
 */
- (void)sort:(int (*)(void *, void*)) compare {
    int count = [array count];
    void** temparray = (void**) malloc(sizeof(void*) * count);
    for (int i = 0; i < count; i++) {
        id obj = [ [array objectAtIndex:i] retain];
        temparray[i] = (void*) obj;
    }
    mergesort(temparray, count, sizeof(void*), compare);
    [self clear];
    for (int i = 0; i < count; i++) {
        id obj = (id) temparray[i];
        [array addObject:obj];
        [obj release];
    }
    free(temparray);
} 


/* Return a sub-range of the Array */
- (Array*)range:(int)start end:(int)n {
    Array *result = [Array new:[array count]/2];
    for (int i = start; i < n; i++) {
        [result add:[array objectAtIndex:i]];
    }
    return result;
}

/* Filter the array using the given function */
- (Array*)filter:(BOOL(*)(id)) func  {
    Array *result = [Array new:[array count]/2];
    for (int i = 0; i < [array count]; i++) {
        id obj = [array objectAtIndex:i];
        if (func(obj)) {
            [result add:obj];
        }
    }
    return result;
}

/* Add the new array to this array */
-(void)addArray:(Array*)newarray {
    for (int i = 0; i < [newarray count]; i++) {
        id obj = [newarray get:i];
        [self add:obj];
    }
}

@end

