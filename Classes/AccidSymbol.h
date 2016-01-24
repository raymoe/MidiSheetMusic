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
#import <Foundation/NSString.h>
#import "MusicSymbol.h"
#import "WhiteNote.h"

/** Accidentals */
enum {
    AccidNone, AccidSharp, AccidFlat, AccidNatural
};

@interface AccidSymbol : NSObject <MusicSymbol> {
    int accid;             /** The accidental (sharp, flat, natural) */
    WhiteNote* whitenote;  /** The white note where the symbol occurs */
    int clef;              /** Which clef the symbols is in */
    int width;             /** Width of symbol */
}

@property (nonatomic, readonly) WhiteNote *note;

-(id)initWithAccid:(int)a andNote:(WhiteNote*)note andClef:(int)clef;
-(WhiteNote*)note;
-(void)drawSharp:(int)ynote;
-(void)drawFlat:(int)ynote;
-(void)drawNatural:(int)ynote;

@end

