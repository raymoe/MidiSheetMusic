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

@interface MidiFileReader : NSObject {
    u_char *data;      /** The entire midi file data */
    int datalen;       /** The data length */
    int parse_offset;  /** The current offset while parsing */
}
-(id)initWithFile:(NSString*)filename;
-(void)checkRead:(int)amount;
-(u_char)peek;
-(u_char)readByte;
-(u_short)readShort;
-(int)readInt;
-(u_char*)readBytes:(int)len;
-(char*)readAscii:(int)len;
-(int)readVarlen;
-(void)skip:(int)amount;
-(int)offset;
-(void)dealloc;
@end

