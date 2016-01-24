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

#import "LyricSymbol.h"

@implementation LyricSymbol

-(id)init {
    return self;
}

-(void)dealloc {
    [text release]; text = nil;
    [super dealloc];
}

-(int)startTime {
    return starttime;
}

-(void)setStartTime:(int)value {
    starttime = value;
}

-(NSString*)text {
    return text;
}

-(void)setText:(NSString*)value {
    [text release];
    text = [value retain];
}

-(int)x {
    return x;
}

-(void)setX:(int)value {
    x = value;
}

/* Return the minimum width in pixels needed to display this lyric.
 * This is an estimation, not exact.
 */
-(int)minWidth {
    float widthPerChar = 10.0f * 2.0f / 3.0f;
    float width = [text length] * widthPerChar;
    NSRange range;
    range = [text rangeOfString:@"i"];
    if (range.location != NSNotFound) {
        width -= widthPerChar/2.0f;
    }
    range = [text rangeOfString:@"j"];
    if (range.location != NSNotFound) {
        width -= widthPerChar/2.0f;
    }
    range = [text rangeOfString:@"l"];
    if (range.location != NSNotFound) {
        width -= widthPerChar/2.0f;
    }
    return (int)width;
}

-(NSString*)description {
    return [NSString stringWithFormat:@"Lyric start=%d x=%d text=%@",
            starttime, x, text];
}

@end

