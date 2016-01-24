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

/** The possible clefs, Treble or Bass */
enum {
    Clef_Treble, Clef_Bass
};

@interface ClefSymbol : NSObject <MusicSymbol> {
    int starttime;       /** Start time of the symbol */
    BOOL smallsize;      /** True if this is a small clef, false otherwise */
    int clef;            /** The clef, Clef_Treble or Clef_Bass */
    int width;
}

-(id)initWithClef:(int)c andTime:(int)t isSmall:(BOOL)small;
+(void)loadImages;

@end

