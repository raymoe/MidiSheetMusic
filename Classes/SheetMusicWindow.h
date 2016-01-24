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
#import <AppKit/NSWindow.h>

#import "AccidSymbol.h"
#import "Array.h"
#import "IntArray.h"
#import "BarSymbol.h"
#import "BlankSymbol.h"
#import "ChordSymbol.h"
#import "ClefMeasures.h"
#import "ClefSymbol.h"
#import "FlippedView.h"
#import "InstrumentDialog.h"
#import "KeySignature.h"
#import "MidiFile.h"
#import "MidiPlayer.h"
#import "Piano.h"
#import "MusicSymbol.h"
#import "NoteColorDialog.h"
#import "PlayMeasuresDialog.h"
#import "RestSymbol.h"
#import "SheetMusic.h"
#import "Staff.h"
#import "Stem.h"
#import "SymbolWidths.h"
#import "TimeSignature.h"
#import "WhiteNote.h"


@interface SheetMusicWindow : NSWindow {
    MidiFile *midifile;         /** The midifile that was read */
    SheetMusic *sheetmusic;     /** The sheet music to display */
    NSScrollView *scrollView;   /** For scrolling through the sheet music */
    MidiPlayer *player;         /** The top panel for playing the music */
    Piano *piano;               /** The piano at the top, for highlighting notes */
    Array *menus;               /** The menu items for this window */
    float zoom;                 /** The zoom level */
    MidiOptions *options;       /** The options selected in the menus */
    NoteColorDialog *colordialog; /** Dialog for choosing note colors */
    InstrumentDialog *instrumentDialog; /** Dialog for choosing instruments */
    PlayMeasuresDialog *playMeasuresDialog; /** Dialog for playing measures in a loop */


    /* Menu Items */
    NSMenu* trackMenu;
    NSMenu* trackDisplayMenu;
    NSMenu* trackMuteMenu;
    NSMenuItem* oneStaffMenu;
    NSMenuItem* twoStaffMenu;
    NSMenuItem* scrollVertMenu;
    NSMenuItem* scrollHorizMenu;
    NSMenuItem* largeNotesMenu;
    NSMenuItem* smallNotesMenu;
    NSMenu* showLettersMenu;
    NSMenuItem* showLyricsMenu;
    NSMenuItem* showMeasuresMenu;
    NSMenu* notesMenu;
    NSMenu* measureMenu;
    NSMenu* changeKeyMenu;
    NSMenu* transposeMenu;
    NSMenu* shiftNotesMenu;
    NSMenu* timeSigMenu;
    NSMenu* combineNotesMenu;
    NSMenuItem* playMeasuresMenu;
    NSMenuItem* useColorMenu;
}

-(id)initWithMidiFile:(MidiFile*)file;
-(void)setMenuFromMidiOptions;
-(void)getMidiOptions;
-(void)redrawSheetMusic;
-(void)createMenu;
-(void)createFileMenu;
-(void)createRecentFilesMenu:(NSMenu *)filemenu;
-(void)createViewMenu;
-(void)createColorMenu;
-(void)createTrackMenu;
-(void)createTrackDisplayMenu;
-(void)createTrackMuteMenu;
-(void)createNotesMenu;
-(void)createShowLettersMenu;
-(void)createShowLyricsMenu;
-(void)createShowMeasuresMenu;
-(void)createKeySignatureMenu;
-(void)createTransposeMenu;
-(void)createShiftNoteMenu;
-(void)createMeasureLengthMenu;
-(void)createTimeSignatureMenu;
-(void)createCombineNotesMenu;
-(void)createPlayMeasuresMenu;
-(void)createHelpMenu;
-(NSString*)getFileName: (NSString*)path;
-(void)showAlertWithTitle:(NSString*)title andMessage:(NSString*)msg;
-(void)stopMidiPlayer;
-(Array*)menus;
-(BOOL)isFlipped;
-(void)restoreMidiOptions;

/* Callback functions for each menu item */
-(IBAction)savePDF:(id)sender;
-(IBAction)printAction:(id)sender;
-(IBAction)exitAction:(id)sender;
-(IBAction)trackSelect:(id)sender;
-(IBAction)selectAllTracks:(id)sender;
-(IBAction)deselectAllTracks:(id)sender;
-(IBAction)trackMute:(id)sender;
-(IBAction)muteAllTracks:(id)sender;
-(IBAction)unmuteAllTracks:(id)sender;
-(IBAction)useOneStaff:(id)sender;
-(IBAction)useTwoStaffs:(id)sender;
-(IBAction)zoomIn:(id)sender;
-(IBAction)zoomOut:(id)sender;
-(IBAction)zoom100:(id)sender;
-(IBAction)scrollVertically:(id)sender;
-(IBAction)scrollHorizontally:(id)sender;
-(IBAction)largeNotes:(id)sender;
-(IBAction)smallNotes:(id)sender;
-(IBAction)showNoteLetters:(id)sender;
-(IBAction)showLyrics:(id)sender;
-(IBAction)showMeasureNumbers:(id)sender;
-(IBAction)changeKeySignature:(id)sender;
-(IBAction)transpose:(id)sender;
-(IBAction)shiftTime:(id)sender;
-(IBAction)changeTimeSignature:(id)sender;
-(IBAction)measureLength:(id)sender;
-(IBAction)useColor:(id)sender;
-(IBAction)chooseColor:(id)sender;
-(IBAction)chooseInstruments:(id)sender;
-(IBAction)playMeasuresInLoop:(id)sender;


@end

