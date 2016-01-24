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
#import "Array.h"
#import "ClefSymbol.h"
#import "AccidSymbol.h"
#import "KeySignature.h"
#import "TimeSignature.h"
#import "MidiFile.h"

@interface Staff : NSObject {
    Array* symbols;             /** The list of music symbols in this staff */
    Array* lyrics;              /** The lyrics to display (can be null) */
    int ytop;                   /** The y pixel of the top of the staff */
    ClefSymbol *clefsym;        /** The left-side Clef symbol */
    Array* keys;                /** The key signature accidental symbols */
    BOOL showMeasures;          /** If true, show the measure numbers */
    int keysigWidth;            /** The width of the clef and key signature */
    int width;                  /** The width of the staff in pixels */
    int height;                 /** The height of the staff in pixels */
    int tracknum;               /** The track this staff represents */
    int totaltracks;            /** The total number of tracks */
    int startTime;              /** The time (in pulses) of first symbol */
    int endTime;                /** The time (in pulses) of last symbol */
    int measureLength;          /** The time (in pulses) of a measure */
}

@property (nonatomic, readonly) int tracknum;
@property (nonatomic, readonly) int width;
@property (nonatomic, readonly) int height;
@property (nonatomic, readonly) int startTime;
@property (nonatomic, assign) int endTime;

-(id)initWithSymbols:(Array*)symbols andKey:(KeySignature*)key 
     andOptions:(MidiOptions*)options 
     andTrack:(int)t andTotalTracks:(int)total;
-(int)findClef;
-(void)calculateHeight;
-(void)calculateWidth:(BOOL)scrollVert;
-(void)calculateStartEndTime;
-(void)fullJustify;
-(void)addLyrics:(Array*)lyrics;
-(void)drawHorizLines;
-(void)drawEndLines;
-(void)drawRect:(NSRect)clip;
-(void)drawMeasureNumbers;
-(void)drawLyrics;
-(int)tracknum;
-(void)shadeNotes:(int)currentPulseTime withPrev:(int)prevPulseTime 
       andX:(int*)x_shade andColor:(NSColor*)color ;
-(int)pulseTimeForPoint:(NSPoint)point;
-(void)dealloc;
-(NSString*)description;
@end


