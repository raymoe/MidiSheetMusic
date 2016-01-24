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
#import "TimeSignature.h"
#import "KeySignature.h"
#import "ClefMeasures.h"
#import "MidiFile.h"
#import "SymbolWidths.h"
#import "MusicSymbol.h"

#define PageWidth   800   /* The width of each page */
#define PageHeight 1050   /* The height of each page (when printing) */

id<MusicSymbol> getSymbol(Array *symbols, int index);

@interface SheetMusic : NSView {
    Array* staffs;            /** The array of Staffs to display (from top to bottom) */
    KeySignature *mainkey;    /** The main key signature */
    int numtracks;            /** The number of tracks */
    float zoom;               /** The zoom level to draw at (1.0 == 100%) */
    BOOL scrollVert;          /** Whether to scroll vertically or horizontally */
    int showNoteLetters;      /** Show the note letters */
    NSString *filename;       /** The MIDI file name */
    NSColor* NoteColors[12];  /** The colors to use for drawing each note */
    NSColor *shadeColor;      /** The color for shading */
    NSColor *shade2Color;     /** The color for shading left-hand piano */
    NSObject *mouseTarget;    /** The target/action to call for a mouse click */
    SEL mouseAction;
}

-(id)initWithFile:(MidiFile*)file andOptions:(MidiOptions*)options;
-(KeySignature*) getKeySignature:(Array*)tracks;
-(Array*) createChords:(Array*)midinotes withKey:(KeySignature*)key
          andTime:(TimeSignature*)time andClefs:(ClefMeasures*) clefs;
-(Array*) createSymbols:(Array*)chords withClefs:(ClefMeasures*)clefs
          andTime:(TimeSignature*)time andLastTime:(int)lastStartTime;
-(Array*) addBars:(Array*)chords withTime:(TimeSignature*)time
          andLastTime:(int)lastStartTime;
-(Array*) addRests:(Array*)chords withTime:(TimeSignature*)time;
-(Array*) getRests:(TimeSignature*)time fromStart:(int)start toEnd:(int)end;
-(Array*) addClefChanges:(Array*)symbols withClefs:(ClefMeasures*)clefs 
          andTime:(TimeSignature*) time;
-(void) alignSymbols:(Array*)allsymbols withWidths:(SymbolWidths *)widths options:(MidiOptions *)options;
+(int) keySignatureWidth:(KeySignature*)key;
-(Array*) createStaffsForTrack:(Array*)symbols withKey:(KeySignature*)key
          andMeasure:(int) measurelen andOptions:(MidiOptions*)options
          andTrack:(int)track andTotalTracks:(int)totaltracks;
-(Array*) createStaffs:(Array*)allsymbols withKey:(KeySignature*)key 
          andOptions:(MidiOptions*)options andMeasure:(int)measurelen;
+(BOOL)findConsecutiveChords:(Array*)symbols andTime:(TimeSignature*) time
                     andStart:(int)startIndex andIndexes:(int*) chordIndexes
                     andNumChords:(int)numChords andHorizDistance:(int*)dist;
-(void)createBeamedChords:(Array*)allsymbols withTime:(TimeSignature*)time
                   andNumChords:(int)numChords onBeat:(BOOL)startBeat;
-(void)createAllBeamedChords:(Array*)allsymbols withTime:(TimeSignature*)time;
-(void) setZoom:(float)value;
-(int) showNoteLetters;
-(void)drawTitle;
-(void) drawRect:(NSRect) rect;
-(BOOL) knowsPageRange:(NSRange*)range;
-(NSRect)rectForPage:(int)pagenum;
-(NSSize) printerPageSize;
-(NSAttributedString*)pageHeader;
-(NSAttributedString*)pageFooter;
-(void) shadeNotes:(int)currentPulseTime withPrev:(int)prevPulseTime gradualScroll:(BOOL)value;
-(void) scrollToShadedNotes:(NSPoint)shadePos gradualScroll:(BOOL)value;
-(void) setColors:(Array*)newcolors andShade:(NSColor*)c andShade2:(NSColor*)c2;
-(NSColor*)noteColor:(int) notescale;
-(NSColor*) shadeColor;
-(NSColor*) shade2Color;
-(KeySignature*)mainkey;
-(Array*)getLyrics:(Array*)tracks;
-(void)addLyrics:(Array*)lyrics toStaffs:(Array*)staffs;
-(void)setMouseClickTarget:(NSObject *)obj action:(SEL)action;
-(int)pulseTimeForPoint:(NSPoint)point;
-(void) dealloc;

+(void) setNoteSize:(BOOL) largenotes;
+(NSDictionary*)fontAttributes;
@end



