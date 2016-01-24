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

#import "WhiteNote.h"
#import "TimeSignature.h"

#define StemUp     1  /* The stem points up */
#define StemDown   2  /* The stem points down */
#define LeftSide   1  /* The stem is to the left of the note */
#define RightSide  2  /* The stem is to the right of the note */

@interface Stem : NSObject {
    NoteDuration duration; /** Duration of the stem. */
    int direction;         /** Up, Down, or None */
    WhiteNote* top;        /** Topmost note in chord */
    WhiteNote* bottom;     /** Bottommost note in chord */
    WhiteNote* end;        /** Location of end of the stem */
    BOOL notesoverlap;     /** Do the chord notes overlap */
    int side;              /** Left side or right side of note */

    Stem* pair;            /** If pair != null, this is a horizontal 
                            * beam stem to another chord */
    int width_to_pair;     /** The width (in pixels) to the chord pair */
    BOOL receiver;         /** This stem is the receiver of a horizontal
                            * beam stem from another chord. */
}

@property (nonatomic, retain) WhiteNote *top;
@property (nonatomic, retain) WhiteNote *bottom;
@property (nonatomic, retain) WhiteNote *end;
@property (nonatomic, retain) Stem *pair;
@property (nonatomic, assign) int direction;
@property (nonatomic, assign) BOOL receiver;
@property (nonatomic, readonly) int side;
@property (nonatomic, readonly) BOOL isBeam;
@property (nonatomic, readonly) NoteDuration duration;

-(id)initWithBottom:(WhiteNote*)b andTop:(WhiteNote*)t
     andDuration:(int)dur andDirection:(int)dir
     andOverlap:(BOOL)overlap;
-(WhiteNote*)calculateEnd;
-(void)setPair:(Stem*)pair withWidth:(int)width_to_pair;
-(void)draw:(int)ytop topStaff:(WhiteNote*)topstaff;
-(void)drawVerticalLine:(int)ytop topStaff:(WhiteNote*)topstaff;
-(void)drawCurvyStem:(int)ytop topStaff:(WhiteNote*)topstaff;
-(void)drawBeamStem:(int)ytop topStaff:(WhiteNote*)topstaff;
-(void)dealloc;

@end


