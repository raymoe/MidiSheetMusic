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

#import <Foundation/NSFileHandle.h>
#import "SheetMusicWindow.h"
#import "FlippedView.h"
#import "SavedMidiOptions.h"

/** @class SheetMusicWindow
 *
 * The SheetMusicWindow is the main window of the application,
 * that contains the Midi Player and the Sheet Music.
 * The form supports the following menu commands
 *
 * File
 *   Open 
 *     Open a midi file, read it into a MidiFile object, and create a
 *     SheetMusic child control based on the MidiFile.  The SheetMusic 
 *     control is then displayed.
 *
 *   Open Sample Song
 *     Open one of the sample midi files that comes with MidiSheetMusic
 *
 *   Close 
 *     Close the SheetMusic control.
 *
 *   Save As PDF
 *     Save the sheet music as a PDF file.
 *
 *   Print 
 *     Create a PrintDialog to print the sheet music.  
 * 
 *   Exit 
 *     Exit the application.
 *
 * View
 *   Scroll Vertically
 *     Scroll the sheet music vertically.
 *
 *   Scroll Horizontally
 *     Scroll the sheet music horizontally.
 *
 *   Zoom In
 *     Increase the zoom level on the sheet music.
 *
 *   Zoom Out
 *     Decrease the zoom level on the sheet music.
 *
 *   Zoom to 100/150%
 *     Set the zoom level to 100/150%.
 *
 *   Large/Small Notes
 *     Display large or small note sizes
 *
 * Color
 *   Enable Color
 *     Show colored notes instead of black notes
 *
 *   Choose Color
 *     Choose the colors for each note
 *
 * Tracks
 *  Track X
 *     Select which tracks of the Midi file to display
 *
 *   Use One/Two Staffs
 *     Display the Midi tracks in one staff per track, or two staffs 
 *     for all tracks.
 *
 *   Choose Instruments...
 *     Choose which instruments to use per track, when playing the sound.
 *
 * Notes
 *
 *   Key Signature
 *     Change the key signature.
 *
 *   Time Signature
 *     Change the time signature to 3/4, 4/4, etc
 *
 *   Transpose Keys
 *     Shift the note keys up or down.
 *
 *   Shift Notes
 *     Shift the notes left/right by the given number of 8th notes.
 *
 *   Measure Length
 *     Adjust the length (in pulses) of a single measure
 *
 *   Combine Notes Within
 *     Combine notes within the given millisec interval.
 *
 *   Show Note Letters
 *     In the sheet music, display the note letters (A, A#, Bb, etc)
 *     next to the notes.
 *
 *   Show Lyrics
 *     If the midi file has lyrics, display them under the notes.
 *
 *   Show Measure Numbers.
 *     In the sheet music, display the measure numbers in the staffs.
 *
 *   Play Measures in a Loop
 *     Play the selected measures in a loop
 *
 * Help
 *   Contents
 *     Display a text area describing the MidiSheetMusic options.
 */


@implementation SheetMusicWindow

/** Create a new instance of this Window. Create the menu.
 *  This window has three child views:
 * - The MidiPlayer
 * - The SheetMusic
 * - The scrollView, for scrolling the SheetMusic
 * Create the menus.
 * Create the color and instrument dialog.
 */
- (id)initWithMidiFile:(MidiFile*)file {
    /* Create the window */
    int mask = NSTitledWindowMask | NSClosableWindowMask | \
               NSMiniaturizableWindowMask | NSResizableWindowMask;
    NSRect screensize = [[NSScreen mainScreen] frame];
    if (screensize.size.width >= 1200) {
        zoom = 1.5f;
    }
    else {
        zoom = 1.0f;
    }

    NSRect frame = NSMakeRect(0, 0, screensize.size.width * 95/100,
                              screensize.size.height * 7/8);
    [self initWithContentRect:frame
          styleMask:mask
          backing:NSBackingStoreBuffered
          defer:NO];

    midifile = [file retain];
    NSString *path = midifile.filename;
    NSArray *parts = [path pathComponents];
    NSString *name = [MidiFile titleName:[parts lastObject]]; 
    NSString *title = [name stringByAppendingString:@" - Midi Sheet Music"];
    [self setTitle:title];

    FlippedView *view = [[FlippedView alloc] initWithFrame:frame];
    [view setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];
    [self setContentView:view];

    /* Create the player panel */
    player = [[MidiPlayer alloc] init];
    [view addSubview:player];

    /* Create the piano */
    piano = [[Piano alloc] init];
    frame = [piano frame];
    frame.origin.y += [player frame].size.height;
    [piano setFrame:frame];
    [view addSubview:piano];
    [player setPiano:piano];

    /* Add a scroll view to the window */
    frame = [view frame];
    int yoffset = [player frame].size.height + [piano frame].size.height;
    frame.origin.y += yoffset;
    frame.size.height -= yoffset;

    scrollView = [[NSScrollView alloc] initWithFrame:frame];
    [scrollView setBorderType:NSBezelBorder];
    [scrollView setHasVerticalScroller:YES];
    [scrollView setHasHorizontalScroller:YES];
    [scrollView setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];

    [view addSubview:scrollView];
    [self makeFirstResponder:scrollView];
    [view release];

    [self restoreMidiOptions];
    colordialog = [[NoteColorDialog alloc] init];
    instrumentDialog = [[InstrumentDialog alloc] initWithMidi:midifile];
    playMeasuresDialog = [[PlayMeasuresDialog alloc] initWithMidi:midifile];
    menus = [[Array new:10] retain];
    [self createMenu];
    [self setMenuFromMidiOptions];
    [self redrawSheetMusic];

    return self;
}


/** Create the MidiOptions based on the menus */
- (void)getMidiOptions {
    for (int track = 0; track < [midifile.tracks count]; track++) {
        int state = [[trackDisplayMenu itemAtIndex:track+2] state];
        [options.tracks set:(state == NSOnState) index:track ];
        state = [[trackMuteMenu itemAtIndex:track+2] state];
        [options.mute set:(state == NSOnState) index:track ];
    }

    options.scrollVert = ([scrollVertMenu state] == NSOnState);
    options.largeNoteSize = ([largeNotesMenu state] == NSOnState);
    options.twoStaffs = ([twoStaffMenu state] == NSOnState);
    options.showNoteLetters = NoteNameNone;
    for (int i = 0; i < 6; i++) {
        NSMenuItem *menu = [showLettersMenu itemAtIndex:i];
        if ([menu state] == NSOnState) {
            options.showNoteLetters = [menu tag];
        }
    }
    if (showLyricsMenu != nil) {
        options.showLyrics = ([showLyricsMenu state] == NSOnState);
    }
    options.showMeasures = ([showMeasuresMenu state] == NSOnState);
    options.shifttime = 0;
    options.transpose = 0;
    options.key = -1;
    options.time = nil;

    /* Get the time signature to use */
    for (int i = 0; i < [timeSigMenu numberOfItems]; i++) {
        int quarter = midifile.time.quarter;
        int tempo = midifile.time.tempo;
        NSMenuItem *menu = [timeSigMenu itemAtIndex:i];
        NSRange is_default = [[menu title] rangeOfString:@"default"];
        if ( ([menu state] == NSOnState) && is_default.length == 0) {
            if ([[menu title] isEqual:@"3/4"]) {
                options.time = [[[TimeSignature alloc]
                                initWithNumerator:3
                                andDenominator:4
                                andQuarter:quarter
                                andTempo:tempo
                               ] autorelease];
            } else if ([[menu title] isEqual:@"4/4"]) {
                options.time = [[[TimeSignature alloc]
                                initWithNumerator:4
                                andDenominator:4
                                andQuarter:quarter
                                andTempo:tempo
                               ] autorelease];
            }
        }
    }
    if (options.time == nil) {
        options.time = [midifile.time copy];
    }

    /* Get the measure length to use */
    for (int i = 0; i < [measureMenu numberOfItems]; i++) {
        NSMenuItem *menu = [measureMenu itemAtIndex:i];
        if ([menu state] == NSOnState) {
            int num = options.time.numerator;
            int denom = options.time.denominator;
            int tempo = options.time.tempo;
            int measure = [menu tag];
            int quarter = measure * options.time.quarter / options.time.measure;
            options.time = [[[TimeSignature alloc]
                            initWithNumerator:num
                            andDenominator:denom
                            andQuarter:quarter
                            andTempo:tempo
                           ] autorelease];
        }
    }

    /* Get the amount to shift the notes left/right */
    for (int i = 0; i < [shiftNotesMenu numberOfItems]; i++) {
        NSMenuItem *menu = [shiftNotesMenu itemAtIndex:i];
        if ([menu state] == NSOnState) {
            int shift = [menu tag];
            if (shift >= 0)
                options.shifttime = midifile.time.quarter/2 * (shift);
            else
                options.shifttime = shift;
        }
    }

    /* Get the key signature to use */
    for (int i = 0; i < [changeKeyMenu numberOfItems]; i++) {
        NSMenuItem *menu = [changeKeyMenu itemAtIndex:i];
        NSRange is_default = [[menu title] rangeOfString:@"Default"];
        if ( ([menu state] == NSOnState) && is_default.length == 0) {
            int tag = [menu tag];
            /* If the tag is positive, it has the number of sharps.
             * If the tag is negative, it has the number of flats.
             */
            int num_flats = 0;
            int num_sharps = 0;
            if (tag < 0)
               num_flats = -tag;
            else
               num_sharps = tag;
            KeySignature *k = [[KeySignature alloc] initWithSharps:num_sharps andFlats:num_flats ];
            options.key = [k notescale];
            [k release];
        }
    }

    /* Get the amount to transpose the key up/down */
    for (int i = 0; i < [transposeMenu numberOfItems]; i++) {
        NSMenuItem *menu = [transposeMenu itemAtIndex:i];
        if ([menu state] == NSOnState) {
            options.transpose = [menu tag];
        }
    }

    /* Get the time interval for combining notes into the same chord. */
    for (int i = 0; i < [combineNotesMenu numberOfItems]; i++) {
        NSMenuItem *menu = [combineNotesMenu itemAtIndex:i];
        if ([menu state] == NSOnState) {
            options.combineInterval = [menu tag];
        }
    }

    /* Get the list of instruments from the Instrument dialog */
    options.instruments = [instrumentDialog instruments];
    options.useDefaultInstruments = [instrumentDialog isDefault];

    /* Get the speed/tempo to use */
    options.tempo = midifile.time.tempo;

    /* Get whether to play measures in a loop */
    options.playMeasuresInLoop = [playMeasuresDialog getEnabled];
    if (options.playMeasuresInLoop) {
        options.playMeasuresInLoopStart = [playMeasuresDialog getStartMeasure];
        options.playMeasuresInLoopEnd = [playMeasuresDialog getEndMeasure];
        if (options.playMeasuresInLoopStart > options.playMeasuresInLoopEnd) {
            options.playMeasuresInLoopEnd = options.playMeasuresInLoopStart;
        }
    }

    /* Get the note colors to use */
    options.shadeColor = [colordialog shadeColor];
    options.shade2Color = [colordialog shade2Color];
    if ([useColorMenu state] == NSOnState) {
        options.colors = [colordialog colors];
    }
    else {
        options.colors = nil;
    }
}

- (void)setMenuFromMidiOptions
{
    NSMenuItem *menu = nil;
    /* Set the Track Dsply and Track Mute menus */
    for (int track = 0; track < [midifile.tracks count]; track++) {
        menu = [trackDisplayMenu itemAtIndex:track+2];
        [menu setState: [options.tracks get:track]];
        menu = [trackMuteMenu itemAtIndex:track+2];
        [menu setState: [options.mute get:track]];
    }
    [scrollVertMenu setState: options.scrollVert];
    [scrollHorizMenu setState: !options.scrollVert];
    [largeNotesMenu setState: options.largeNoteSize];
    [smallNotesMenu setState: !options.largeNoteSize];
    [twoStaffMenu setState: options.twoStaffs];
    [oneStaffMenu setState: !options.twoStaffs];

    /* Set the show letters menu value */
    for (int i = 0; i < 6; i++) {
        menu = [showLettersMenu itemAtIndex:i];
        if (i == options.showNoteLetters) {
            [menu setState:NSOnState]; 
        }
        else {
            [menu setState:NSOffState]; 
        }
    }

    /* Set the Show Measures menu value */
    [showMeasuresMenu setState:options.showMeasures];
    for (int i = 0; i < [shiftNotesMenu numberOfItems]; i++) {
        if (options.shifttime == 0) {
            break;
        }

        menu = [shiftNotesMenu itemAtIndex:i];
        int tag = (int)[menu tag];
        if (options.shifttime == tag ||
            options.shifttime == (tag * midifile.time.quarter/2) ) {

            [menu setState:NSOnState];
        }
        else {
            [menu setState:NSOffState];
        }
    }

    /* Set the time signature menu value */
    if (options.time != nil) {
        NSString *text = [NSString stringWithFormat:@"%d/%d", options.time.numerator, options.time.denominator];
        NSMenuItem *match = nil;
        for (int i = 0; i < [timeSigMenu numberOfItems]; i++) {
            menu = [timeSigMenu itemAtIndex:i];
            if ([[menu title] isEqual:text]) {
                match = menu; break;
            }
        }
        if (match != nil) {
            for (int i = 0; i < [timeSigMenu numberOfItems]; i++) {
                menu = [timeSigMenu itemAtIndex:i];
                [menu setState:NSOffState];
            }
            [match setState:NSOnState];
        }
    }

    /* Set the measure length menu value - TODO */

    /* Set the key signature menu value */
    for (int i = 0; i < [changeKeyMenu numberOfItems]; i++) {
        menu = [changeKeyMenu itemAtIndex:i];
        int tag = [menu tag];
        BOOL isDefault = [[menu title] rangeOfString:@"Default"].location != NSNotFound;
        if (options.key == -1) {
            if (isDefault) {
                [menu setState:NSOnState];
            }
            else {
                [menu setState:NSOffState];
            }
        }
        else {
            if (isDefault) {
                [menu setState:NSOffState];
            }
            else if (options.key == tag) {
                [menu setState:NSOnState];
            }
            else {
                [menu setState:NSOffState];
            }
        }
    }

    /* Set the transpose menu value */
    for (int i = 0; i < [transposeMenu numberOfItems]; i++) {
        menu = [transposeMenu itemAtIndex:i];
        if ([menu tag] == options.transpose) {
            [menu setState:NSOnState];
        }
        else {
            [menu setState:NSOffState];
        }
    }

    /* Set the combine notes menu value */
    for (int i = 0; i < [combineNotesMenu numberOfItems]; i++) {
        menu = [combineNotesMenu itemAtIndex:i];
        if ([menu tag] == options.combineInterval) {
            [menu setState:NSOnState];
        }
        else {
            [menu setState:NSOffState];
        }
    }

    /* Set the instruments to use */
    if (!options.useDefaultInstruments) {
        [instrumentDialog setInstruments:options.instruments];
    }

    /* Set the menu values for play measures in a loop */
    if (options.playMeasuresInLoop) {
        [playMeasuresDialog setEnabled: options.playMeasuresInLoop];
        [playMeasuresDialog setStartMeasure: options.playMeasuresInLoopStart];
        [playMeasuresDialog setEndMeasure: options.playMeasuresInLoopEnd];
    }

    /* Set the note colors */
    [colordialog setShadeColor: options.shadeColor];
    [colordialog setShade2Color: options.shade2Color];
    [colordialog setColors: options.colors];
}


/** The Sheet Music needs to be redrawn.  Gather the sheet music
 * options from the menu items.  Then create the sheetmusic
 * control, and add it to this form. Update the MidiPlayer with
 * the new midi file.
 */
- (void)redrawSheetMusic {
    if (sheetmusic != nil) {
        [sheetmusic release];
    }
    [self getMidiOptions];

    /* Create a new SheetMusic Control from the midifile */
    sheetmusic = [[SheetMusic alloc] 
                   initWithFile:midifile andOptions:options];
    [sheetmusic setZoom:zoom];
    [scrollView setDocumentView:sheetmusic];

    /* Update the Midi Player and piano */
    [piano setShade:options.shadeColor andShade2:options.shade2Color];
    [piano setMidiFile:midifile withOptions:options];
    [player setMidiFile:midifile withOptions:options andSheet:sheetmusic];
}


/** Create the menu items for this SheetMusicWindow */
- (void)createMenu {
    [self createFileMenu];
    [self createViewMenu];
    [self createColorMenu];
    [self createTrackMenu];
    [self createNotesMenu];
    [self createHelpMenu];
}


/** Create the file menu. */
- (void)createFileMenu {
    NSMenuItem *result = [[NSMenuItem alloc] 
                          initWithTitle:NSLocalizedString(@"File", nil) action:NULL keyEquivalent:@""];
    NSMenu* filemenu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"File", nil)];

    NSMenuItem *menuitem;
    menuitem = [[NSMenuItem alloc] 
                 initWithTitle:@"Open..."
                 action:nil
                 keyEquivalent:@"o"];
    [filemenu addItem:menuitem];
    [menuitem release];

    menuitem = [[NSMenuItem alloc] 
                 initWithTitle:@"Open Sample Song..."
                 action:nil
                 keyEquivalent:@""];
    [filemenu addItem:menuitem];
    [menuitem release];

    menuitem = [[NSMenuItem alloc] 
                 initWithTitle:@"Close Window"
                 action:nil
                 keyEquivalent:@"w"];
    [filemenu addItem:menuitem];
    [menuitem release];

    menuitem = [[NSMenuItem alloc] 
                 initWithTitle:@"Save As PDF..."
                 action:@selector(savePDF:)
                 keyEquivalent:@"s"];
    [menuitem setTarget:self];
    [filemenu addItem:menuitem];
    [menuitem release];

    [filemenu addItem:[NSMenuItem separatorItem]];

    menuitem = [[NSMenuItem alloc] 
                   initWithTitle:@"Print..."
                   action:@selector(printAction:)
                   keyEquivalent:@"p"];
    [menuitem setTarget:self];
    [filemenu addItem:menuitem];
    [menuitem release];

    [filemenu addItem:[NSMenuItem separatorItem]];

    [self createRecentFilesMenu:filemenu];

    [result setSubmenu:filemenu];
    [filemenu release];
    [menus add:result];
    [result release];
}

/** Create a list of recently opened midi files,
 *  and add them to the file menu.
 */
- (void)createRecentFilesMenu:(NSMenu *)filemenu {
    Array *recentFiles = [[SavedMidiOptions shared] getRecentFilenames];
    for (int i = 0; i < [recentFiles count]; i++) {
        NSString *filename = [recentFiles get:i];
        NSString *title = [[filename pathComponents] lastObject];
        title = [NSString stringWithFormat:@"%d. %@", i+1, title];
        NSMenuItem *menuitem = [[NSMenuItem alloc]
                     initWithTitle:title
                     action:nil
                     keyEquivalent:@""];
        [menuitem setRepresentedObject:filename];
        [filemenu addItem:menuitem];
        [menuitem release];
    }
}


/** Create the View Menu */
- (void)createViewMenu {
    NSMenuItem *result = [[NSMenuItem alloc]
                 initWithTitle:@"View" action:NULL keyEquivalent:@""];

    NSMenu *view = [[NSMenu alloc] initWithTitle:@"View"];
    NSMenuItem *zoomin = [[NSMenuItem alloc] 
                           initWithTitle:@"Zoom In"
                           action:@selector(zoomIn:)
                           keyEquivalent:@"+"];
    [zoomin setTarget:self];
    NSMenuItem *zoomout = [[NSMenuItem alloc] 
                           initWithTitle:@"Zoom Out"
                           action:@selector(zoomOut:)
                           keyEquivalent:@"-"];
    [zoomout setTarget:self];
    NSMenuItem *zoom100menu = [[NSMenuItem alloc] 
                              initWithTitle:@"Zoom to 100%"
                              action:@selector(zoom100:)
                              keyEquivalent:@"0"];
    NSMenuItem *zoom150menu = [[NSMenuItem alloc] 
                               initWithTitle:@"Zoom to 150%"
                               action:@selector(zoom150:)
                               keyEquivalent:@""];
	
    [view addItem:zoomin];
    [view addItem:zoomout];
    [view addItem:zoom100menu];
    [view addItem:zoom150menu];
    [view addItem:[NSMenuItem separatorItem]];
    [zoomin release];
    [zoomout release];
    [zoom100menu release];
    [zoom150menu release];

    scrollVertMenu = [[NSMenuItem alloc]  
                 initWithTitle:@"Scroll Vertically"
                 action:@selector(scrollVertically:)
                 keyEquivalent:@""];
    [scrollVertMenu setTarget:self];
    [scrollVertMenu setState:NSOnState];
    [view addItem:scrollVertMenu];

    scrollHorizMenu = [[NSMenuItem alloc]  
                 initWithTitle:@"Scroll Horizontally"
                 action:@selector(scrollHorizontally:)
                 keyEquivalent:@""];
    [scrollHorizMenu setTarget:self];
    [scrollHorizMenu setState:NSOffState];
    [view addItem:scrollHorizMenu];

    [view addItem:[NSMenuItem separatorItem]];

    smallNotesMenu = [[NSMenuItem alloc]
                 initWithTitle:@"Small Notes"
                 action:@selector(smallNotes:)
                 keyEquivalent:@""];
    [smallNotesMenu setTarget:self];
    [smallNotesMenu setState:NSOnState];
    [view addItem:smallNotesMenu];

    largeNotesMenu = [[NSMenuItem alloc]
                 initWithTitle:@"Large Notes"
                 action:@selector(largeNotes:)
                 keyEquivalent:@""];
    [largeNotesMenu setTarget:self];
    [largeNotesMenu setState:NSOffState];
    [view addItem:largeNotesMenu];

    [result setSubmenu:view];
    [view release];
    [menus add:result];
    [result release];
}

/** Create the Color Menu */
- (void)createColorMenu {
    NSMenuItem *result = [[NSMenuItem alloc]
                           initWithTitle:@"Color" action:NULL keyEquivalent:@""];
    NSMenu *colormenu = [[NSMenu alloc] initWithTitle:@"Color"];

    useColorMenu = [[NSMenuItem alloc]
                 initWithTitle:@"Use Color"
                 action:@selector(useColor:)
                 keyEquivalent:@"u"];
    [useColorMenu setTarget:self];
    [colormenu addItem:useColorMenu];

    NSMenuItem *menuitem = [[NSMenuItem alloc]
                 initWithTitle:@"Choose Colors..."
                 action:@selector(chooseColor:)
                 keyEquivalent:@""];
    [menuitem setTarget:self];
    [colormenu addItem:menuitem];
    [menuitem release];

    [result setSubmenu:colormenu];
    [colormenu release];
    [menus add:result];
    [result release];
}

/** Create the Help Menu */
- (void)createHelpMenu {
    NSMenuItem *result = [[NSMenuItem alloc]
                           initWithTitle:@"Help" action:NULL keyEquivalent:@""];
    NSMenu* helpmenu = [[NSMenu alloc] initWithTitle:@"Help"];
     
    NSMenuItem *contents = [[NSMenuItem alloc]
                            initWithTitle:@"Help Contents..."
                            action:nil
                            keyEquivalent:@""];
    [helpmenu addItem:contents];
    [contents release];
    [result setSubmenu:helpmenu];
    [helpmenu release];
    [menus add:result];
    [result release];
}


/* Create the "Select Tracks to Display" menu. */
- (void)createTrackDisplayMenu {
    NSMenuItem *menuItem = [[NSMenuItem alloc]
                            initWithTitle:@"Select Tracks to Display" 
                            action:NULL keyEquivalent:@""];
    trackDisplayMenu = [[NSMenu alloc] initWithTitle:@"Select Tracks to Display"];
    [menuItem setSubmenu:trackDisplayMenu];
    [trackMenu addItem:menuItem];
    [menuItem release];

    NSMenuItem *menu;

    menu = [[NSMenuItem alloc] initWithTitle:@"Select All Tracks"
                            action:@selector(selectAllTracks:)
                            keyEquivalent:@""];
    [menu setTarget:self];
    [trackDisplayMenu addItem:menu];
    [menu release];

    menu = [[NSMenuItem alloc] initWithTitle:@"Deselect All Tracks"
                            action:@selector(deselectAllTracks:)
                            keyEquivalent:@""];
    [menu setTarget:self];
    [trackDisplayMenu addItem:menu];
    [menu release];


    for (int i = 0; i < [midifile.tracks count]; i++) {
        MidiTrack *track = [midifile.tracks get:i];
        NSString *instrname = [track instrumentName];
        NSString *title;
        if (![instrname isEqual:@""] ) {
            title = [NSString stringWithFormat:@"Track %d   (%@)", i+1, instrname];
        }
        else {
            title = [NSString stringWithFormat:@"Track %d", i+1];
        }
        menu = [[NSMenuItem alloc] initWithTitle:title
                                action:@selector(trackSelect:)
                                keyEquivalent:@""];
        [menu setTarget:self];
        [menu setState:NSOnState];
        if ([instrname isEqual:@"Percussion"]) {
            [menu setState:NSOffState]; /* Disable percussion by default */
        }
        [menu setTag:i];
        [trackDisplayMenu addItem:menu];
        [menu release];
    }
}

/* Create the "Select Tracks to Mute" menu. */
- (void)createTrackMuteMenu {
    NSMenuItem *menuItem = [[NSMenuItem alloc]
                            initWithTitle:@"Select Tracks to Mute" 
                            action:NULL keyEquivalent:@""];
    trackMuteMenu = [[NSMenu alloc] initWithTitle:@"Select Tracks to Mute"];
    [menuItem setSubmenu:trackMuteMenu];
    [trackMenu addItem:menuItem];
    [menuItem release];

    NSMenuItem *menu;

    menu = [[NSMenuItem alloc] initWithTitle:@"Mute All Tracks"
                            action:@selector(muteAllTracks:)
                            keyEquivalent:@""];
    [menu setTarget:self];
    [trackMuteMenu addItem:menu];
    [menu release];

    menu = [[NSMenuItem alloc] initWithTitle:@"Unmute All Tracks"
                            action:@selector(unmuteAllTracks:)
                            keyEquivalent:@""];
    [menu setTarget:self];
    [trackMuteMenu addItem:menu];
    [menu release];


    for (int i = 0; i < [midifile.tracks count]; i++) {
        MidiTrack *track = [midifile.tracks get:i];
        NSString *instrname = [track instrumentName];
        NSString *title;
        if (![instrname isEqual:@""] ) {
            title = [NSString stringWithFormat:@"Track %d   (%@)", i+1, instrname];
        }
        else {
            title = [NSString stringWithFormat:@"Track %d", i+1];
        }
        menu = [[NSMenuItem alloc] initWithTitle:title
                                action:@selector(trackMute:)
                                keyEquivalent:@""];
        [menu setTarget:self];
        [menu setState:NSOffState];
        if ([instrname isEqual:@"Percussion"]) {
            [menu setState:NSOnState]; /* Disable percussion by default */
        }
        [menu setTag:i];
        [trackMuteMenu addItem:menu];
        [menu release];
    }
}


/** Create the "Track" Menu after a Midi file has been selected.
 * Add a menu item to enable/disable displaying each track.
 * Add a menu item to mute/unmute each track.
 * Add a menu item to select one staff per track.
 * Add a menu item to combine all tracks into two staffs.
 * Add a menu item to choose track instruments.
 */
- (void)createTrackMenu {
    NSMenuItem *menuitem = [[NSMenuItem alloc]
                             initWithTitle:@"Tracks" action:nil keyEquivalent:@""];
    trackMenu = [[NSMenu alloc] initWithTitle:@"Tracks"];
    [menuitem setSubmenu:trackMenu];
    [menus add:menuitem];
    [menuitem release];

    [self createTrackDisplayMenu];
    [self createTrackMuteMenu];

    [trackMenu addItem:[NSMenuItem separatorItem]];

    oneStaffMenu = [[NSMenuItem alloc]
                  initWithTitle:@"Show One Staff Per Track"
                  action:@selector(useOneStaff:)
                  keyEquivalent:@""];
    [oneStaffMenu setTarget:self];

    if ([midifile.tracks count] == 1) {
        twoStaffMenu = [[NSMenuItem alloc]
                    initWithTitle:@"Split Track Into Two Staffs"
                    action:@selector(useTwoStaffs:)
                    keyEquivalent:@""];
        [twoStaffMenu setTarget:self];

        [oneStaffMenu setState:NSOffState];
        [twoStaffMenu setState:NSOnState];
    }
    else {
        twoStaffMenu = [[NSMenuItem alloc]
                    initWithTitle:@"Combine All Tracks Into Two Staffs"
                    action:@selector(useTwoStaffs:)
                    keyEquivalent:@""];
        [twoStaffMenu setTarget:self];

        [oneStaffMenu setState:NSOnState];
        [twoStaffMenu setState:NSOffState];
    }
    [trackMenu addItem:oneStaffMenu];
    [trackMenu addItem:twoStaffMenu];

    [trackMenu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *menu = [[NSMenuItem alloc] initWithTitle:@"Choose Instruments..."
                            action:@selector(chooseInstruments:)
                            keyEquivalent:@""];
    [menu setTarget:self];
    [trackMenu addItem:menu];
    [menu release];
}


/** Create the "Notes" menu after a Midi file has been selected. */
- (void)createNotesMenu {
    NSMenuItem *result = [[NSMenuItem alloc]
                           initWithTitle:@"Notes" action:nil keyEquivalent:@""];
    notesMenu = [[NSMenu alloc] initWithTitle:@"Notes"];

    [self createKeySignatureMenu];
    [self createTimeSignatureMenu];
    [self createTransposeMenu];
    [self createShiftNoteMenu];
    [self createMeasureLengthMenu];
    [self createCombineNotesMenu];
    [self createShowLettersMenu];
    [self createShowLyricsMenu];
    [self createShowMeasuresMenu];
    [self createPlayMeasuresMenu];

    [result setSubmenu:notesMenu];
    [menus add:result];
    [result release];
}

/** Create the "Show Note Letters" sub-menu. */
- (void)createShowLettersMenu {
    NSMenuItem *menu;
    showLettersMenu = [[NSMenu alloc] initWithTitle:@"Show Note Letters"];
    NSArray *values = [NSArray arrayWithObjects: @"None", @"Letters", @"Fixed Do-Re-Mi", @"Movable Do-Re-Mi", @"Fixed Numbers", @"Movable Numbers", nil];
    for (int i = 0; i < [values count]; i++) {
        menu = [[NSMenuItem alloc] initWithTitle:[values objectAtIndex:i]
                action:@selector(showNoteLetters:) keyEquivalent:@""];
        [menu setTarget:self];
        [menu setTag:i];
        if (i == 0) {
            [menu setState:NSOnState];
        }
        else {
            [menu setState:NSOffState];
        }
        [showLettersMenu addItem:menu];
        [menu release];
    }
    NSMenuItem *result = [[NSMenuItem alloc]
                             initWithTitle:@"Show Note Letters"
                             action:nil
                             keyEquivalent:@""];
    [result setSubmenu:showLettersMenu];
    [notesMenu addItem:result];
    [result release];
}

/** Create the "Show Lyrics" sub-menu. */
- (void)createShowLyricsMenu {
    if (![midifile hasLyrics]) {
        showLyricsMenu = nil;
        return;
    }
    showLyricsMenu = [[NSMenuItem alloc]
                       initWithTitle:@"Show Lyrics"
                       action:@selector(showLyrics:)
                       keyEquivalent:@""];
    [showLyricsMenu setTarget:self];
    [showLyricsMenu setState:NSOnState];
    [notesMenu addItem:showLyricsMenu];
}


/** Create the "Show Measure Numbers" sub-menu. */
- (void)createShowMeasuresMenu {
    showMeasuresMenu = [[NSMenuItem alloc]
                       initWithTitle:@"Show Measure Numbers"
                       action:@selector(showMeasureNumbers:)
                       keyEquivalent:@""];
    [showMeasuresMenu setTarget:self];
    [showMeasuresMenu setState:NSOffState];
    [notesMenu addItem:showMeasuresMenu];
}


/** Create the "Key Signature" sub-menu.
 * Create sub-menus for changing the key signature.
 * The Menu.Tag contains the number of sharps (if positive)
 * or the number of flats (if negative) in the key.
 */
- (void)createKeySignatureMenu {
    NSMenuItem* menu;
    KeySignature *key;

    changeKeyMenu = [[NSMenu alloc] initWithTitle:@"Key Signature"];

    /* Add the default key signature */
    menu = [[NSMenuItem alloc] initWithTitle:@"Default"
                                action:@selector(changeKeySignature:)
                                keyEquivalent:@""];
    [menu setTarget:self];
    [menu setState:NSOnState];
    [menu setTag:0];
    [changeKeyMenu addItem:menu];
    [menu release];
    
    /* Add the sharp key signatures */
    for (int sharps = 0; sharps <= 5; sharps++) {
        key = [[KeySignature alloc] initWithSharps:sharps andFlats:0];

        menu = [[NSMenuItem alloc] initWithTitle:[key description]
                                action:@selector(changeKeySignature:)
                                keyEquivalent:@""];
        [menu setTarget:self];
        [menu setState:NSOffState];
        [menu setTag:sharps];
        [changeKeyMenu addItem:menu];
        [menu release];
        [key release];
    }

    /* Add the flat key signatures */
    for (int flats = 1; flats <= 6; flats++) {
        key = [[KeySignature alloc] initWithSharps:0 andFlats:flats];

        menu = [[NSMenuItem alloc] initWithTitle:[key description]
                                action:@selector(changeKeySignature:)
                                keyEquivalent:@""];
        [menu setTarget:self];
        [menu setState:NSOffState];
        [menu setTag:-flats];
        [changeKeyMenu addItem:menu];
        [menu release];
        [key release];
    }

    NSMenuItem *result = [[NSMenuItem alloc] 
                             initWithTitle:@"Change Key Signature"
                             action:nil
                             keyEquivalent:@""];
    [result setSubmenu:changeKeyMenu];
    [notesMenu addItem:result];
    [result release];
}


/** Create the "Transpose" sub-menu.
 * Create sub-menus for moving the key up or down.
 * The Menu.Tag contains the amount to shift the key by.
 */
- (void)createTransposeMenu {
    NSMenuItem* menu;

    int amounts[] = { 12, 6, 5, 4, 3, 2, 1, 0, -1, -2, -3, -4, -5, -6, -12 };
    transposeMenu = [[NSMenu alloc] initWithTitle:@"Transpose"];
   
    for (int i = 0; i < 15; i++) {
        NSString *title;
        int amount = amounts[i];
        if (amount > 0)
            title = [NSString stringWithFormat:@"Up %d", amount];
        else if (amount == 0) 
            title = @"none";
        else if (amount < 0)
            title = [NSString stringWithFormat:@"Down %d", -amount];

        menu = [[NSMenuItem alloc] initWithTitle:title
                                action:@selector(transpose:)
                                keyEquivalent:@""];
        [menu setTarget:self];
        if (amount == 0)
            [menu setState:NSOnState];
        else
            [menu setState:NSOffState];
        [menu setTag:amount];
        [transposeMenu addItem:menu];
        [menu release];
    }
    NSMenuItem *result = [[NSMenuItem alloc] 
                             initWithTitle:@"Transpose"
                             action:nil
                             keyEquivalent:@""];
    [result setSubmenu:transposeMenu];
    [notesMenu addItem:result];
    [result release];
}


/** Create the "Shift Note" sub-menu.
 * For the "Left to Start" sub-menu, the Menu.Tag contains the
 * time (in pulses) where the first note occurs.
 * For the "Right" sub-menus, the Menu.Tag contains the number
 * of eighth notes to shift right by.
 */
- (void) createShiftNoteMenu {
    NSMenuItem* menu;

    shiftNotesMenu = [[NSMenu alloc] initWithTitle:@"Shift Notes"];
    menu = [[NSMenuItem alloc] initWithTitle:@"Left to start"
                            action:@selector(shiftTime:)
                            keyEquivalent:@""];
    [menu setState:NSOffState];
    [menu setTarget:self];
    
    int firsttime = midifile.time.measure * 10;
    for (int tracknum = 0; tracknum < [midifile.tracks count]; tracknum++) {
        MidiTrack *track = [midifile.tracks get:tracknum];
		MidiNote *note = [track.notes get:0];
        int starttime = note.startTime;
        if (firsttime > starttime) { 
            firsttime = starttime;
        }
    }
    [menu setTag:-firsttime];
    [shiftNotesMenu addItem:menu];
    [menu release];

    NSArray *titles = [NSArray arrayWithObjects:
        @"none (default)", @"Right 1/8 note", @"Right 1/4 note", @"Right 3/8 note",
        @"Right 1/2 note", @"Right 5/8 note", @"Right 3/4 note", @"Right 7/8 note", nil ];

    for (int i = 0; i < 8; i++) {
        menu = [[NSMenuItem alloc] initWithTitle:[titles objectAtIndex:i]
                                action:@selector(shiftTime:)
                                keyEquivalent:@""];
        if (i == 0)
            [menu setState:NSOnState];
        else
            [menu setState:NSOffState];
        [menu setTag:i];
        [shiftNotesMenu addItem:menu];
        [menu release];
    }
    NSMenuItem *result = [[NSMenuItem alloc] initWithTitle:@"Shift Notes"
                                           action:nil
                                           keyEquivalent:@""];
    [result setSubmenu:shiftNotesMenu];
    [notesMenu addItem:result];
    [result release];
}

/** Create the Measure Length sub-menu.
 * The method MidiFile guessMeasureLength guesses possible values for the
 * measure length (in pulses). Create a sub-menu for each possible measure
 * length.  The Menu.Tag field contains the measure length (in pulses) for
 * each menu item.
 */
- (void)createMeasureLengthMenu {
    NSMenuItem* menu;

    measureMenu = [[NSMenu alloc] initWithTitle:@"Measure Length"];
    NSString *title = [NSString stringWithFormat:@"%d pulses (default)",
                        midifile.time.measure ];
    menu = [[NSMenuItem alloc] initWithTitle:title
                            action:@selector(measureLength:)
                            keyEquivalent:@""];
    [menu setState:NSOnState];
    [menu setTag:midifile.time.measure]; 
    [measureMenu addItem:menu];
    [menu release];
    [measureMenu addItem:[NSMenuItem separatorItem]];

    IntArray *lengths = [midifile guessMeasureLength];
    for (int i = 0; i < [lengths count]; i++) {
        int len = [lengths get:i];
        NSString *title = [NSString stringWithFormat:@"%d pulses ", len];
        menu = [[NSMenuItem alloc] initWithTitle:title
                                action:@selector(measureLength:)
                                keyEquivalent:@""];
        [menu setTarget:self];
        [menu setState:NSOffState];
        [menu setTag:len]; 
        [measureMenu addItem:menu];
        [menu release];
    }
    NSMenuItem *result = [[NSMenuItem alloc] 
                            initWithTitle:@"Measure Length"
                            action:nil
                            keyEquivalent:@""];
    [result setSubmenu:measureMenu];
    [notesMenu addItem:result];
    [result release];
}


/** Create the Time Signature Menu.
 * In addition to the default time signature, add 3/4 and 4/4
 */
- (void)createTimeSignatureMenu {
    NSMenuItem* menu;

    timeSigMenu = [[NSMenu alloc] initWithTitle:@"Time Signature"];
    menu = [[NSMenuItem alloc] initWithTitle:@"3/4"
                            action:@selector(changeTimeSignature:)
                            keyEquivalent:@""];
    [menu setTarget:self]; 
    [menu setState:NSOffState];
    [timeSigMenu addItem:menu];
    [menu release];

    menu = [[NSMenuItem alloc] initWithTitle:@"4/4"
                            action:@selector(changeTimeSignature:)
                            keyEquivalent:@""];
    [menu setTarget:self]; 
    [menu setState:NSOffState];
    [timeSigMenu addItem:menu];
    [menu release];

    if (midifile.time.numerator == 3 && 
        midifile.time.denominator == 4) {

        [[timeSigMenu itemAtIndex:0] setTitle:@"3/4 (default)"];
        [[timeSigMenu itemAtIndex:0] setState:NSOnState];
    }
    else if (midifile.time.numerator == 4 && 
             midifile.time.denominator == 4) {
        [[timeSigMenu itemAtIndex:1] setTitle:@"4/4 (default)"];
        [[timeSigMenu itemAtIndex:1] setState:NSOnState];
    }
    else {
        NSString *title = [NSString stringWithFormat:@"%d/%d (default)", 
                           midifile.time.numerator,
                           midifile.time.denominator];
        menu = [[NSMenuItem alloc] initWithTitle:title
                                action:@selector(changeTimeSignature:)
                                keyEquivalent:@""];
        [menu setTarget:self];
        [menu setState:NSOnState];
        [timeSigMenu addItem:menu];
        [menu release];
    }

    NSMenuItem *result = [[NSMenuItem alloc] 
                             initWithTitle:@"Time Signature"
                             action:nil
                             keyEquivalent:@""];
    [result setSubmenu:timeSigMenu];
    [notesMenu addItem:result];
    [result release];
}

/** Create the Combine Notes Within Interval sub-menu.
 * The method MidiFile.RoundStartTimes() is used to combine notes within
 * a given time interval (millisec) into the same chord.
 * The Menu.Tag field contains the millisecond value.
 */
- (void)createCombineNotesMenu {
    NSMenuItem* menu;

    combineNotesMenu = [[NSMenu alloc] initWithTitle:@"Combine Notes Within Interval"];

    for (int millisec = 20; millisec <= 100; millisec += 20) {
        NSString *title;
        if (millisec == 40) {
            title = [NSString stringWithFormat:@"%d milliseconds (default)", millisec];
        }
        else {
            title = [NSString stringWithFormat:@"%d milliseconds", millisec];
        }
        menu = [[NSMenuItem alloc] initWithTitle:title
                                action:@selector(combineNotes:)
                                keyEquivalent:@""];
        [menu setTarget:self];
        if (millisec == 60) {
            [menu setState:NSOnState];
        }
        else {
            [menu setState:NSOffState];
        }
        [menu setTag:millisec]; 
        [combineNotesMenu addItem:menu];
        [menu release];
    }

    NSMenuItem *result = [[NSMenuItem alloc] 
                            initWithTitle:@"Combine Notes Within Interval"
                            action:nil
                            keyEquivalent:@""];
    [result setSubmenu:combineNotesMenu];
    [notesMenu addItem:result];
    [result release];
}

/** Create the "Play Measures in a Loop" sub-menu. */
-(void)createPlayMeasuresMenu {
    playMeasuresMenu = [[NSMenuItem alloc] initWithTitle:@"Play Measures in a Loop..."
                        action:@selector(playMeasuresInLoop:)
                        keyEquivalent:@""];
    [playMeasuresMenu setTarget:self];
    [playMeasuresMenu setState: NSOffState];
    [notesMenu addItem:playMeasuresMenu];
}


/** Return just the filename given a full path to a file */
- (NSString*)getFileName:(NSString*)path {
    NSArray *parts = [path pathComponents];
    NSString *name = [parts lastObject];
    return name;
} 

/** Display an alert box with the given title and message */
- (void)showAlertWithTitle:(NSString*)title andMessage:(NSString*)msg {
    NSAlert *alert = [NSAlert alertWithMessageText:title
                              defaultButton:nil
                              alternateButton:nil
                              otherButton:nil
                              informativeTextWithFormat:msg];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert runModal];
}


/** The callback function for the "Save As PDF" menu.
 * When invoked this will save the sheet music as a PDF file.
 * Create a "Save File" dialog for choosing the filename.
 * Set the printer settings to 8.5 x 11 inches.
 * Then perform a print operation to save Sheet Music to the file.
 */
- (IBAction)savePDF:(id)sender {
    /* We can only print sheet music in 'vertical scrolling' view */
    [self scrollVertically:nil];

    NSSavePanel *dialog = [NSSavePanel savePanel];
    NSArray *types = [NSArray arrayWithObjects:@"pdf", nil];
    [dialog setRequiredFileType:@"pdf"];
    [dialog setAllowedFileTypes:types];
    [dialog setExtensionHidden:NO];

    /* The initial filename in the dialog will be <midi filename>.pdf */
    NSString *initname = [self getFileName:midifile.filename];
    if ([initname hasSuffix:@".mid"]) {
        initname = [initname substringToIndex:[initname length]-4];
    }
    initname = [initname stringByAppendingString:@".pdf"];
    if ([dialog runModalForDirectory:nil file:initname] == NSFileHandlingPanelOKButton) {

        NSString *filepath = dialog.filename;
        NSPrintInfo *info = [NSPrintInfo sharedPrintInfo];

        /* Create a print job that saves to a file */
        NSMutableDictionary *dict = 
            [NSMutableDictionary dictionaryWithDictionary:[info dictionary]];
        [dict setObject:NSPrintSaveJob forKey:NSPrintJobDisposition];
        [dict setObject:filepath forKey:NSPrintSavePath];
        [dict setObject:[NSNumber numberWithBool:YES] forKey:NSPrintHeaderAndFooter];
        info = [[NSPrintInfo alloc] initWithDictionary:dict];

        /* Set the page size to 8.5 x 11 inches, US Letter Size, 
         * with 0.2 inch margin. 
         */
        NSSize papersize;
        [info setPaperName:@"Letter"];
        papersize = [info paperSize];
        float margin = (0.2 / 8.5) * papersize.width;
        [info setLeftMargin:margin];
        [info setRightMargin:margin];
        [info setTopMargin:margin];
        [info setBottomMargin:margin];

        [info setHorizontalPagination:NSAutoPagination];
        [info setVerticalPagination:NSAutoPagination];
        [info setHorizontallyCentered:YES];
        [info setVerticallyCentered:NO];
        [info setPaperName:@"Letter"];

        NSPrintOperation* printer = 
            [NSPrintOperation printOperationWithView:sheetmusic printInfo:info];
        [printer setShowPanels:NO];
        @try {
           [printer runOperation];
        }
        @catch (NSException *e) {
            NSString *err = [e reason];
            NSString *message = [NSString stringWithFormat:
                                 @"MidiSheetMusic was unable to save to file %@ because\n %@", 
                                 filepath, err];
            [self showAlertWithTitle:@"Error Saving File" andMessage:message];
        }
    }
}


/** The callback function for the "Print..." menu.
 * When invoked, this will spawn a Print dialog.
 * The dialog will then invoke the SheetMusic methods
 * knowsPageRange and rectForPage, in order to determine
 * the bounds of each page.
 */
- (IBAction)printAction:(id)sender {
    /* We can only print sheet music in 'vertical scrolling' view */
    [self scrollVertically:nil];

    NSPrintOperation* printer = 
        [NSPrintOperation printOperationWithView:sheetmusic];
    NSPrintInfo *info = [printer printInfo];

    /* Print page numbers on each page */
    NSMutableDictionary *dict = [info dictionary];
    [dict setObject:[NSNumber numberWithBool:YES] forKey:NSPrintHeaderAndFooter];

    /* Reduce the margin sizes to 0.2 inches */
    [info setPaperName:@"Letter"];
    NSSize papersize = [info paperSize];
    float margin = (0.2 / 8.5) * papersize.width;
    [info setLeftMargin:margin];
    [info setRightMargin:margin];
    [info setTopMargin:margin];
    [info setBottomMargin:margin];

    [info setHorizontalPagination:NSAutoPagination];
    [info setVerticalPagination:NSAutoPagination];
    [info setHorizontallyCentered:YES];
    [info setVerticallyCentered:NO];

    [printer setShowPanels:YES];
    [printer runOperation];
}

/** The callback function for the "Exit" menu.
 * Exit the application.
 */
- (IBAction)exitAction:(id)sender {
    exit(0);
}


/** The callback function for the "Track <num>" menu items.
 * Update the checked status of the menu item.
 * Also, unmute/mute the track if displayed/not-displayed.
 * Then, redraw the sheetmusic.
 */
- (IBAction)trackSelect:(id)sender {
    NSMenuItem* menu = (NSMenuItem*) sender;
    if ([menu state] == NSOnState) {
        [menu setState:NSOffState];
    }
    else {
        [menu setState:NSOnState];
    }
    for (int i = 0; i < [midifile.tracks count]; i++) {
        if (menu == [trackDisplayMenu itemAtIndex:i+2]) {
            [[trackMuteMenu itemAtIndex:i+2] setState: ![menu state]];
        }
    }
    [self redrawSheetMusic];
}

/** The callback function for the "Select All Tracks" menu items.
 * Check all the tracks. Then redraw the sheetmusic.
 */
- (IBAction)selectAllTracks:(id)sender {
    int i;
    for (i = 0; i < [midifile.tracks count]; i++) {
        NSMenuItem *menu = [trackDisplayMenu itemAtIndex:i+2];
        [menu setState:NSOnState];
        menu = [trackMuteMenu itemAtIndex:i+2];
        [menu setState:NSOffState];
    }
    [self redrawSheetMusic];
}

/** The callback function for the "Deselect All Tracks" menu items.
 * Uncheck all the tracks. Then redraw the sheetmusic.
 */
- (IBAction)deselectAllTracks:(id)sender {
    int i;

    for (i = 0; i < [midifile.tracks count]; i++) {
        NSMenuItem *menu = [trackDisplayMenu itemAtIndex:i+2];
        [menu setState:NSOffState];
        menu = [trackMuteMenu itemAtIndex:i+2];
        [menu setState:NSOnState];
    }
    [self redrawSheetMusic];
}


/** The callback function for the "Mute Track <num>" menu items.
 * Update the checked status of the menu item.
 * Then, redraw the sheetmusic.
 */
- (IBAction)trackMute:(id)sender {
    NSMenuItem* menu = (NSMenuItem*) sender;
    if ([menu state] == NSOnState) {
        [menu setState:NSOffState];
    }
    else {
        [menu setState:NSOnState];
    }
    [self redrawSheetMusic];
}

/** The callback function for the "Mute All Tracks" menu items.
 * Check all the tracks. Then redraw the sheetmusic.
 */
- (IBAction)muteAllTracks:(id)sender {
    int i;
    for (i = 0; i < [midifile.tracks count]; i++) {
        NSMenuItem *menu = [trackMuteMenu itemAtIndex:i+2];
        [menu setState:NSOnState];
    }
    [self redrawSheetMusic];
}

/** The callback function for the "Unmute All Tracks" menu items.
 * Uncheck all the tracks. Then redraw the sheetmusic.
 */
- (IBAction)unmuteAllTracks:(id)sender {
    int i;

    for (i = 0; i < [midifile.tracks count]; i++) {
        NSMenuItem *menu = [trackMuteMenu itemAtIndex:i+2];
        [menu setState:NSOffState];
    }
    [self redrawSheetMusic];
}


/** The callback function for the "One Staff per Track" menu.
 * Update the checked status of the menu items, and redraw
 * the sheet music.
 */
- (IBAction)useOneStaff:(id)sender {
    if ([oneStaffMenu state] == NSOnState)
        return;
    [oneStaffMenu setState:NSOnState];
    [twoStaffMenu setState:NSOffState];
    [self redrawSheetMusic];
}


/** The callback function for the "Combine/Split Into Two Staffs" menu.
 * Update the checked status of the menu item, and then
 * redraw the sheet music.
 */
- (IBAction)useTwoStaffs:(id)sender {
    if ([twoStaffMenu state] == NSOnState)
        return;
    [twoStaffMenu setState:NSOnState];
    [oneStaffMenu setState:NSOffState];
    [self redrawSheetMusic];
}

/** The callback function for the "Zoom In" menu.
 * Increase the zoom level on the sheet music by 10%.
 */
- (IBAction)zoomIn:(id)sender {
    if (zoom >= 4.0f)
        return;

    zoom += 0.08f;
    [sheetmusic setZoom:zoom];
}

/** The callback function for the "Zoom Out" menu.
 * Decrease the zoom level on the sheet music by 10%.
 */
- (IBAction)zoomOut:(id)sender {
    if (zoom <= 0.4f)
        return;

    zoom -= 0.08f;
    [sheetmusic setZoom:zoom];
}

/** The callback function for the "Zoom to 100%" menu.
 * Set the zoom level to 100%.
 */
- (IBAction)zoom100:(id)sender {
    zoom = 1.0f;
    [sheetmusic setZoom:zoom];
}

/** The callback function for the "Zoom to 150%" menu.
 * Set the zoom level to 150%.
 */
- (IBAction)zoom150:(id)sender {
    zoom = 1.5f;
    [sheetmusic setZoom:zoom];
}

/** The callback function for the "Scroll Vertically" menu. */
- (IBAction)scrollVertically:(id)sender {
    if ([scrollVertMenu state] == NSOnState)
        return;
    [scrollVertMenu setState:NSOnState];
    [scrollHorizMenu setState:NSOffState];
    [self redrawSheetMusic];
}

/** The callback function for the "Scroll Horizontally" menu. */
- (IBAction)scrollHorizontally:(id)sender {
    if ([scrollHorizMenu state] == NSOnState)
        return;
    [scrollHorizMenu setState:NSOnState];
    [scrollVertMenu setState:NSOffState];
    [self redrawSheetMusic];
}

/** The callback function for the "Large Notes" menu. */
- (IBAction)largeNotes:(id)sender {
    if ([largeNotesMenu state] == NSOnState)
        return;
    [largeNotesMenu setState:NSOnState];
    [smallNotesMenu setState:NSOffState];
    [self redrawSheetMusic];
}

/** The callback function for the "Small Notes" menu. */
- (IBAction)smallNotes:(id)sender {
    if ([smallNotesMenu state] == NSOnState)
        return;
    [largeNotesMenu setState:NSOffState];
    [smallNotesMenu setState:NSOnState];
    [self redrawSheetMusic];
}

/** The callback function for the "Show Note Letters" menu. */
- (IBAction)showNoteLetters:(id)sender {
    NSMenuItem *menu = (NSMenuItem*)sender;
    if ([menu state] == NSOnState) {
        return;
    }
    for (int i = 0; i < 6; i++) {
        NSMenuItem *othermenu = [showLettersMenu itemAtIndex:i];
        [othermenu setState:NSOffState];
    }
    [menu setState:NSOnState];

    if ([menu tag] != 0) { 
        [largeNotesMenu setState:NSOnState];
        [smallNotesMenu setState:NSOffState];
    }
    [self redrawSheetMusic];
}


/** The callback function for the "Show Lyrics" menu. */
- (IBAction)showLyrics:(id)sender {
    NSMenuItem *menu = (NSMenuItem*)sender;
    if ([menu state] == NSOnState) {
        [menu setState:NSOffState];
    }
    else {
        [menu setState:NSOnState];
    }
    [self redrawSheetMusic];
}


/** The callback function for the "Show Measure Numbers" menu. */
- (IBAction)showMeasureNumbers:(id)sender {
    if ([showMeasuresMenu state] == NSOnState) {
        [showMeasuresMenu setState:NSOffState];
    }
    else {
        [showMeasuresMenu setState:NSOnState];
    }
    [self redrawSheetMusic];
}


/** The callback function for the "Change Key Signature" menu. */

/** The callback function for the "Change Key Signature" menu. */
- (IBAction)changeKeySignature:(id)sender {
    NSMenuItem* menu = (NSMenuItem*) sender;
    if ([menu state] == NSOnState)
        return;
    for (int i = 0; i < [changeKeyMenu numberOfItems]; i++) {
        NSMenuItem *othermenu = [changeKeyMenu itemAtIndex:i];
        [othermenu setState:NSOffState];
    }
    [menu setState:NSOnState];
    [self redrawSheetMusic];
}


/** The callback function for the "Transpose" menu. */
- (IBAction)transpose:(id)sender {
    NSMenuItem* menu = (NSMenuItem*) sender;
    if ([menu state] == NSOnState)
        return;

    for (int i = 0; i < [transposeMenu numberOfItems]; i++) {
        NSMenuItem *othermenu = [transposeMenu itemAtIndex:i];
        [othermenu setState:NSOffState];
    }
    [menu setState:NSOnState];
    [self redrawSheetMusic];
}


/** The callback function for the "Shift Notes" menu. */
- (IBAction)shiftTime:(id)sender {
    NSMenuItem* menu = (NSMenuItem*) sender;
    if ([menu state] == NSOnState)
        return;

    for (int i = 0; i < [shiftNotesMenu numberOfItems]; i++) {
        NSMenuItem *othermenu = [shiftNotesMenu itemAtIndex:i];
        [othermenu setState:NSOffState];
    }
    [menu setState:NSOnState];
    [self redrawSheetMusic];
}

/** The callback function for the "Time Signature" menu. */
- (IBAction)changeTimeSignature:(id)sender {
    NSMenuItem* menu = (NSMenuItem*) sender;
    if ([menu state] == NSOnState)
        return;

    for (int i = 0; i < [timeSigMenu numberOfItems]; i++) {
        NSMenuItem *othermenu = [timeSigMenu itemAtIndex:i];
        [othermenu setState:NSOffState];
    }
    [menu setState:NSOnState];

    /* The default measure length changes when we change
     * the time signature.
     */
    int defaultmeasure;
    if ([[menu title] isEqual:@"3/4"])
        defaultmeasure = 3 * midifile.time.quarter;
    else if ([[menu title] isEqual:@"4/4"])
        defaultmeasure = 4 * midifile.time.quarter;
    else
        defaultmeasure = midifile.time.measure;

    NSString *title = [NSString stringWithFormat:@"%d pulses (default)", defaultmeasure];
    [[measureMenu itemAtIndex:0] setTitle:title];
    [[measureMenu itemAtIndex:0] setTag:defaultmeasure];
 
    [self redrawSheetMusic];
}

/** The callback function for the "Measure Length" menu. */
- (IBAction)measureLength:(id)sender {
    NSMenuItem* menu = (NSMenuItem*) sender;
    if ([menu state] == NSOnState)
        return;

    for (int i = 0; i < [measureMenu numberOfItems]; i++) {
        NSMenuItem *othermenu = [measureMenu itemAtIndex:i];
        [othermenu setState:NSOffState];
    }
    [menu setState:NSOnState];
    [self redrawSheetMusic];
}

/** The callback function for the "Combine Notes Within Interval" menu. */
- (IBAction)combineNotes:(id)sender {
    NSMenuItem* menu = (NSMenuItem*) sender;
    if ([menu state] == NSOnState)
        return;

    for (int i = 0; i < [combineNotesMenu numberOfItems]; i++) {
        NSMenuItem *othermenu = [combineNotesMenu itemAtIndex:i];
        [othermenu setState:NSOffState];
    }
    [menu setState:NSOnState];
    [self redrawSheetMusic];
}


/** The callback function for the "Use Color" menu. */
- (IBAction)useColor:(id)sender {
    NSMenuItem* menu = (NSMenuItem*) sender;
    if ([menu state] == NSOnState) {
        [menu setState:NSOffState];
    }
    else {
        [menu setState:NSOnState];
    }

    [self redrawSheetMusic];
}

/** The callback function for the "Choose Colors" menu */
- (IBAction)chooseColor:(id)sender {
    int ret = [colordialog showDialog];
    if (ret == NSRunStoppedResponse) {
        [self redrawSheetMusic];
    }
}

/** The callback function for the "Choose Instruments" menu */
- (IBAction)chooseInstruments:(id)sender {
    int ret = [instrumentDialog showDialog];
    if (ret == NSRunStoppedResponse) {
        [self getMidiOptions];
        [player setMidiFile:midifile withOptions:options andSheet:sheetmusic];
    }
}

/** The callback function for the "Play Measures in a Loop" menu */
- (IBAction)playMeasuresInLoop:(id)sender {
    int ret = [playMeasuresDialog showDialog];
    if ([playMeasuresDialog getEnabled]) {
        [playMeasuresMenu setState:NSOnState];
    }
    else {
        [playMeasuresMenu setState:NSOffState];
    }
    [self getMidiOptions];
    [player setMidiFile:midifile withOptions:options andSheet:sheetmusic];
}


/** Return the menus for this window. The main application,
 *  MidiSheetMusic.m, will add these menu items to the main
 *  menu anytime this window obtains focus.
 */
- (Array*)menus {
    return menus;
}

/** Use flipped coordinates */
- (BOOL)isFlipped {
    return YES;
}

/** Stop the MidiPlayer */
- (void)stopMidiPlayer {
    [player stop:nil];
}

/** Restore the previously saved MidiOptions for this midi file */
- (void)restoreMidiOptions
{
    [options release]; options = nil;
    options = [[MidiOptions alloc] initFromMidi:midifile];
    SavedMidiOptions *savedMidiOptions = [SavedMidiOptions shared];
    MidiOptions *savedOptions = [savedMidiOptions loadOptions:midifile];
    MidiOptions *firstOptions = [savedMidiOptions loadFirstOptions];
    if (savedOptions != nil) {
        [options merge:savedOptions];
    }
    else if (firstOptions != nil) {
        options.scrollVert = firstOptions.scrollVert;
        options.largeNoteSize = firstOptions.largeNoteSize;
        options.shadeColor = firstOptions.shadeColor;
        options.shade2Color = firstOptions.shade2Color;
        options.colors = firstOptions.colors;
    }
}

/* When the window is closed, save the midi options */
- (void)close
{
    [[SavedMidiOptions shared] saveOptions:options];
    [super close];
}


- (void)dealloc {
    [player stop:nil];
    [player release];
    [midifile release];
    [sheetmusic release]; 
    [scrollView release];
    [piano release];
    [menus release];
    [colordialog release]; 
    [instrumentDialog release]; 
    [playMeasuresDialog release]; 
    [trackMenu release];
    [oneStaffMenu release];
    [twoStaffMenu release];
    [scrollVertMenu release];
    [scrollHorizMenu release];
    [largeNotesMenu release];
    [smallNotesMenu release];
    [notesMenu release];
    [showLettersMenu release];
    [showMeasuresMenu release];
    [measureMenu release];
    [playMeasuresMenu release];
    [changeKeyMenu release];
    [transposeMenu release];
    [shiftNotesMenu release];
    [timeSigMenu release];
    [combineNotesMenu release];
    [useColorMenu release];
    options.tracks = nil;
    options.instruments = nil;
    options.colors = nil;
    [super dealloc];
}

@end  /* SheetMusicWindow implementation */


