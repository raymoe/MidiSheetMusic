/*
 * Copyright (c) 2011 Madhav Vaidyanathan
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
#import "IntArray.h"
#import "MidiFile.h"

@interface InstrumentDialog : NSObject {
    Array* instrumentChoices;  /** The ComboBoxes showing the instruments to use per track */
    NSPanel* window;     /** The dialog box */
}

-(id)initWithMidi:(MidiFile*)file;
-(int)showDialog;
-(IntArray*)instruments;
-(void)setInstruments:(IntArray*)value;
-(BOOL)isDefault;
-(IBAction)setAllPiano:(id)sender;
-(void)dealloc;

@end


