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


/** Enumeration of the notes in a scale (A, A#, ... G#) */
enum {
    NoteScale_A       = 0,
    NoteScale_Asharp  = 1,
    NoteScale_Bflat   = 1,
    NoteScale_B       = 2,
    NoteScale_C       = 3,
    NoteScale_Csharp  = 4,
    NoteScale_Dflat   = 4,
    NoteScale_D       = 5,
    NoteScale_Dsharp  = 6,
    NoteScale_Eflat   = 6,
    NoteScale_E       = 7,
    NoteScale_F       = 8,
    NoteScale_Fsharp  = 9,
    NoteScale_Gflat   = 9,
    NoteScale_G       = 10,
    NoteScale_Gsharp  = 11,
    NoteScale_Aflat   = 11
};


/* White notes in the scale */
enum {
    WhiteNote_A = 0,
    WhiteNote_B = 1,
    WhiteNote_C = 2,
    WhiteNote_D = 3,
    WhiteNote_E = 4,
    WhiteNote_F = 5,
    WhiteNote_G = 6
};


int  notescale_to_number(int notescale, int octave);
int  notescale_from_number(int number);
BOOL notescale_is_black_key(int notescale);

@interface WhiteNote : NSObject {
    int letter;   /* The letter of the note, A thru G */
    int octave;   /* The octave, 0 thru 10. */
}

@property (nonatomic, readonly) int letter;
@property (nonatomic, readonly) int octave;
@property (nonatomic, readonly) int number;

+(id)allocWithLetter:(int)a andOctave:(int)o;
+(WhiteNote*)topTreble;
+(WhiteNote*)bottomTreble;
+(WhiteNote*)topBass;
+(WhiteNote*)bottomBass;
+(WhiteNote*)middleC;
+(WhiteNote*)top:(int)c;
+(WhiteNote*)bottom:(int)c;
+(WhiteNote*)max:(WhiteNote*)x and:(WhiteNote*)y;
+(WhiteNote*)min:(WhiteNote*)x and:(WhiteNote*)y;
-(id)initWithLetter:(int)a andOctave:(int)o;
-(int)dist:(WhiteNote*)w;
-(WhiteNote*)add:(int)amount;
+(int)compare:(WhiteNote*)x and:(WhiteNote*)y;

@end

