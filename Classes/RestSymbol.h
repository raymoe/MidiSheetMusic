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

#import "MusicSymbol.h"
#import "TimeSignature.h"

@interface RestSymbol : NSObject <MusicSymbol> {
    int starttime;          /** The starttime of the rest */
    NoteDuration duration;  /** The rest duration (eighth, quarter, half, whole) */
    int width;              /** The width in pixels */
}

-(id)initWithTime:(int)t andDuration:(int)dur;
-(void)drawWhole:(int)ytop;
-(void)drawHalf:(int)ytop;
-(void)drawQuarter:(int)ytop;
-(void)drawEighth:(int)ytop;

@end

