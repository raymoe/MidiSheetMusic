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
#import "MidiFileReader.h"
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

/** @class MidiFileReader
 * The MidiFileReader is used to read low-level binary data from a file.
 * This class can do the following:
 *
 * - Peek at the next byte in the file.
 * - Read a byte
 * - Read a 16-bit big endian short
 * - Read a 32-bit big endian int
 * - Read a fixed length ascii string (not null terminated)
 * - Read a "variable length" integer.  The format of the variable length
 *   int is described at the top of this file.
 * - Skip ahead a given number of bytes
 * - Return the current offset.
 */
@implementation MidiFileReader

/** Create a new MidiFileReader for the given filename */
- (id)initWithFile:(NSString*)filename {
    const char *name = [filename cStringUsingEncoding:NSUTF8StringEncoding];
    int fd = open(name, O_RDONLY);
    if (fd == -1) {
        const char *err = strerror(errno);
        NSString *reason = @"Unable to open file ";
        reason = [reason stringByAppendingString:filename];
        reason = [reason stringByAppendingString:@":"];
        reason = [reason stringByAppendingString:
           [NSString stringWithCString:err encoding:NSUTF8StringEncoding]];
        MidiFileException *e = [MidiFileException init:reason offset:0];
        @throw e;
    }
    struct stat info;
    int ret = stat(name, &info);
    if (info.st_size == 0) {
        NSString *reason = @"File is empty:";
        reason = [reason stringByAppendingString:filename];
        MidiFileException *e = [MidiFileException init:reason offset:0];
        @throw e;
    }
    datalen = info.st_size;
    data = (u_char*)malloc(datalen);
    int offset = 0;
    while (1) {
        if (offset == datalen)
            break;
        int n = read(fd, &data[offset], datalen - offset);
        if (n <= 0)
            break;
        offset += n;
    }
    close(fd);
    parse_offset = 0;
    return self;
}

/** Check that the given number of bytes doesn't exceed the file size */
- (void)checkRead:(int)amount {
    if (parse_offset + amount > datalen) {
        NSString *reason = @"File is truncated";
        MidiFileException *e = [MidiFileException init:reason offset:parse_offset];
        @throw e;
    }
} 

/** Return the next byte in the file, but don't increment the parse offset */
- (u_char)peek {
    [self checkRead:1];
    return data[parse_offset];
}


/** Read a byte from the file */
- (u_char)readByte {
    [self checkRead:1];
    u_char x = data[parse_offset];
    parse_offset++;
    return x;
}

/** Read the given number of bytes from the file */
- (u_char*)readBytes:(int) amount {
    [self checkRead:amount];
    u_char* result = malloc(sizeof(u_char) * amount);
    memcpy(result, &data[parse_offset], amount);
    parse_offset += amount;
    return result;
}

/** Read a 16-bit short from the file */
- (u_short)readShort {
    [self checkRead:2];
    u_short x = (u_short) ( (data[parse_offset] << 8) | data[parse_offset+1] );
    parse_offset += 2;
    return x;
}

/** Read a 32-bit int from the file */
- (int)readInt {
    [self checkRead:4];
    int x = (int)( (data[parse_offset] << 24) | (data[parse_offset+1] << 16) | 
                   (data[parse_offset+2] << 8) | data[parse_offset+3] );
    parse_offset += 4;
    return x;
}

/** Read an ascii string with the given length */
- (char*)readAscii:(int)len {
    [self checkRead:len];
    char* s = (char*) &data[parse_offset];
    parse_offset += len;
    return s;
}

/** Read a variable-length integer (1 to 4 bytes). The integer ends
 * when you encounter a byte that doesn't have the 8th bit set
 * (a byte less than 0x80).
 */
- (int)readVarlen {
    unsigned int result = 0;
    u_char b;
    int i;

    b = [self readByte];
    result = (unsigned int)(b & 0x7f);

    for (i = 0; i < 3; i++) {
        if ((b & 0x80) != 0) {
            b = [self readByte];
            result = (unsigned int)( (result << 7) + (b & 0x7f) );
        }
        else {
            break;
        }
    }
    return (int)result;
}

/** Skip over the given number of bytes */
- (void)skip:(int)amount {
    [self checkRead:amount];
    parse_offset += amount;
}

/** Return the current parse offset */
- (int)offset {
    return parse_offset;
}


- (void)dealloc {
    free(data);
    [super dealloc];
}

@end

