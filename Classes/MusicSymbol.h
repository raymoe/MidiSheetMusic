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


/** @class MusicSymbol
 * The MusicSymbol class represents music symbols that can be displayed
 * on a staff.  This includes:
 *  - Accidental symbols: sharp, flat, natural
 *  - Chord symbols: single notes or chords
 *  - Rest symbols: whole, half, quarter, eighth
 *  - Bar symbols, the vertical bars which delimit measures.
 *  - Treble and Bass clef symbols
 *  - Blank symbols, used for aligning notes in different staffs
 */

#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSBezierPath.h>
#import <AppKit/NSView.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSAffineTransform.h>
#import <AppKit/NSGraphicsContext.h>


/* Constants used by the MusicSymbols when drawing. */
extern int LineWidth;
extern int LeftMargin;
extern int LineSpace;
extern int StaffHeight;
extern int NoteHeight;
extern int NoteWidth;


@protocol MusicSymbol

/** Get the time (in pulses) this symbol occurs at.
 * This is used to determine the measure this symbol belongs to.
 */
@property (nonatomic, readonly) int startTime; 

/** Get the minimum width (in pixels) needed to draw this symbol */
@property (nonatomic, readonly) int minWidth;

/** Get/Set the width (in pixels) of this symbol. The width is set
 * in SheetMusic.alignSymbols() to vertically align symbols.
 */
@property (nonatomic, assign) int width;

/** Get the number of pixels this symbol extends above the staff. Used
 *  to determine the minimum height needed for the staff (Staff:findBounds).
 */
@property (nonatomic, readonly) int aboveStaff;

/** Get the number of pixels this symbol extends below the staff. Used
 *  to determine the minimum height needed for the staff (Staff:findBounds).
 */
@property (nonatomic, readonly) int belowStaff;

/** Draw the symbol.
 * @param ytop The ylocation (in pixels) where the top of the staff starts.
 */
-(void) draw:(int) ytop;

@end


