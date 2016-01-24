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
#import <Foundation/NSRange.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>
#import <AppKit/AppKit.h>

#import "AccidSymbol.h"
#import "Array.h"
#import "BarSymbol.h"
#import "BlankSymbol.h"
#import "ChordSymbol.h"
#import "ClefMeasures.h"
#import "ClefSymbol.h"
#import "KeySignature.h"
#import "MidiFile.h"
#import "MidiPlayer.h"
#import "MusicSymbol.h"
#import "NoteColorDialog.h"
#import "RestSymbol.h"
#import "SampleSongDialog.h"
#import "SheetMusic.h"
#import "SheetMusicWindow.h"
#import "Staff.h"
#import "Stem.h"
#import "SymbolWidths.h"
#import "TimeSignature.h"
#import "WhiteNote.h"


@interface MidiSheetMusic : NSObject {
    Array* windows;             /** Array of SheetMusicWindows */
    SheetMusicWindow *currentWindow; /** The current main window */
    NSWindow *blankWindow;      /** The initial blank window */
}

-(void)applicationWillFinishLaunching:(NSNotification*)notification;
-(BOOL)application:(NSApplication*)app openFile:(NSString*)filename;
-(void)createBlankWindow;
-(void)createEmptyMenuItem:(NSString*)title;
-(void)createEmptyMenu;
-(void)createFileMenu;
-(void)createRecentFilesMenu:(NSMenu *)filemenu;
-(void)createHelpMenu;
-(void)updateMenu;

-(void)openMidiFile:(NSString*)filename;
-(void)windowDidBecomeMain:(NSNotification*) n;
-(void)windowWillClose:(NSNotification*) n;
-(NSString*)getFileName: (NSString*)path;
-(void)showAlertWithTitle:(NSString*)title andMessage:(NSString*)msg;

/* Callback functions for each menu item */
-(IBAction)openAction:(id)sender;
-(IBAction)openSampleSongAction:(id)sender;
-(IBAction)closeAction:(id)sender;
-(IBAction)exitAction:(id)sender;
-(IBAction)help:(id)sender;

+ (MidiSheetMusic *)shared;

@end

