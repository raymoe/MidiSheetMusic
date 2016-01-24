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

#import <Foundation/NSArray.h>

@interface IntArray : NSObject {
    int *values;  /* The array of integers */
    int size;     /* The size of the array */
    int capacity; /* The capacity of the array */
}
+(id)new:(int)capacity;
-(id)initWithCapacity:(int)capacity;
-(void)dealloc;
-(void)add:(int)x;
-(int)get:(int)index;
-(void)set:(int)x index:(int) x;
-(int)indexOf:(int)x;
-(BOOL)contains:(int)x;
-(int)count;
-(void)sort;
-(IntArray *)clone;
-(NSArray *)toArray;
-(IntArray *)initFromArray:(NSArray *)array;

@end


