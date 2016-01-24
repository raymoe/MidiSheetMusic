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
#import "Array.h"
#import "IntArray.h"

@interface ClefMeasures : NSObject {
    IntArray* clefs;  /** The clefs used for each measure (for a single track) */
    int measure;      /** The length of a measure, in pulses */
}

-(id)initWithNotes:(Array*)notes andMeasure:(int)measurelen;
-(int)getClef:(int)starttime;
-(int)mainClef:(Array*)notes;
-(void)dealloc;

@end

