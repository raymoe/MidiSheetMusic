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

#import "Array.h"
#import "IntArray.h"
#import "WhiteNote.h"


@interface KeySignature : NSObject {
    int num_flats;   /** The number of sharps in the key, 0 thru 6 */
    int num_sharps;  /** The number of flats in the key, 0 thru 6 */

    /** The accidental symbols (AccidSymbols) that denote this key, in a treble clef */
    Array* treble;

    /** The accidental symbols (AccidSymbols) that denote this key, in a bass clef */
    Array* bass;

    /** The key map for this key signature:
     *   keymap[notenumber] -> Accidental
     */
    int keymap[160];

    /** The measure used in the previous call to GetAccidental() */
    int prevmeasure; 
}
+(void)initAccidentalMaps;
+(id)guess:(IntArray*)notes;
-(id)initWithSharps:(int)s andFlats:(int)f;
-(id)initWithNotescale:(int)n;
-(void)dealloc;
-(int)num_sharps;
-(int)num_flats;
-(void)resetKeyMap;
-(void)createSymbols;
-(Array*)getSymbols:(int)clef;
-(int)getAccidentalForNote:(int)notenumber andMeasure:(int)measure;
-(WhiteNote*)getWhiteNote:(int)notenumber;
-(BOOL)equals:(KeySignature*)k;
-(NSString*)description;
-(int)notescale;
+(NSString*)keyToString:(int)notescale;

@end

