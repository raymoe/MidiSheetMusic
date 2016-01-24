/*
 * Copyright (c) 2007-2011 Madhav Vaidyanathan
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
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSPanel.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSView.h>
#import <AppKit/NSButton.h>
#import <AppKit/NSTextField.h>
#import <AppKit/NSColorWell.h>
#import "Array.h"


@interface NoteColorDialog : NSObject {
    Array* colorwells;       /** The 12 color wells used to select the colors. */
    NSColorWell* shadeWell;  /** The color used for shading notes during playback */
    NSColorWell* shade2Well; /** The color used for shading the left hand piano. */
    NSPanel* window;         /** The dialog box */
}

-(id)init;
-(int)showDialog;
-(Array*)colors;
-(NSColor*)shadeColor;
-(NSColor*)shade2Color;
-(void)setShadeColor:(NSColor *)color;
-(void)setShade2Color:(NSColor *)color;
-(void)setColors:(Array *)colors;
-(void)dealloc;

@end


