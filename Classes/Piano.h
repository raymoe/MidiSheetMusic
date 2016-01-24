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
#import "TimeSignature.h"
#import "MidiFile.h"
#import <AppKit/NSColor.h>

@interface Piano : NSView {
    Array *notes;          /** The midi notes, for shading. */
    int maxShadeDuration;  /** The maximum duration we'll shade a note for */
    BOOL useTwoColors;     /** If true, use two colors for highlighting */
    int showNoteLetters;   /** Display the letter for each piano note */
    NSColor *shadeColor;   /** The color to use for shading */
    NSColor *shade2Color;  /** The color for left-hand shading */
    NSColor *gray1, *gray2, *gray3; /** Gray colors for drawing black/gray lines */
}

-(id)init;
-(void)setMidiFile:(MidiFile*)file withOptions:(MidiOptions*)opt;
-(void)setShade:(NSColor*)s1 andShade2:(NSColor*)s2;
-(void)drawRect:(NSRect) rect;
-(void)shadeNotes:(int)currentPulseTime withPrev:(int)prevPulseTime;
-(void)drawOctaveOutline;
-(void)drawOutline;
-(void)drawBlackKeys;
-(void)drawBlackBorder;
-(void)shadeOneNote:(int)notenumber withColor:(NSColor*) c;
-(int)nextStartTime:(int)index;
-(void)fillRect:(NSRect)rect withColor:(NSColor*)color;
-(void)dealloc;

@end



