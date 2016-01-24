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

#import "MidiFile.h"
#import "MidiFileException.h"
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

/** @class MidiFileException
 * A MidiFileException is thrown when an error occurs
 * while parsing the Midi File.  The constructore takes
 * the file offset (in bytes) where the error occurred,
 * and a string describing the error.
 */
@implementation MidiFileException
+(id)init:(NSString*)reason offset:(int)off {
    NSString *s = [NSString stringWithFormat:@"%@ at offset %d", reason, off];
    MidiFileException *e =
        [[MidiFileException alloc] initWithName:@"MidiFileException"
          reason:s userInfo:nil];
    return [e autorelease];
}
@end

