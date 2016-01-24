/*
 * Copyright (c) 2011-2012 Madhav Vaidyanathan
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
#import "Array.h"
#import "MidiFile.h"

@interface PlayMeasuresDialog : NSObject {
    NSPanel* window;          /** The dialog box */
    NSComboBox* startMeasure; /** The starting measure */
    NSComboBox* endMeasure;   /** The ending measure */
    NSButton* enable;         /** Whether to enable or not */
}

-(id)initWithMidi:(MidiFile*)file;
-(int)showDialog;
-(BOOL)getEnabled;
-(void)setEnabled:(BOOL)value;
-(int)getStartMeasure;
-(void)setStartMeasure:(int)value;
-(int)getEndMeasure;
-(void)setEndMeasure:(int)value;
-(void)dealloc;

@end


