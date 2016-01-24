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

#import <Foundation/NSObject.h>
#import "MusicSymbol.h"

@interface TimeSigSymbol : NSObject <MusicSymbol> {
    int  numerator;         /** The numerator */
    int  denominator;       /** The denominator */
    int  width;             /** The width in pixels */
    BOOL candraw;           /** True if we can draw the time signature */
}

-(id)initWithNumer:(int)n andDenom:(int)d;
+(void)loadImages;

@end

