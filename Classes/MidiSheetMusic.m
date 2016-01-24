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

#import "MidiSheetMusic.h"
#import <Foundation/NSFileHandle.h>
#import "SavedMidiOptions.h"

static MidiSheetMusic *_globalMidiSheetMusic = nil;

/** @class MidiSheetMusic
 *
 * The MidiSheetMusic class is the main class that handles 
 * launching the application.  MidiSheetMusic supports multiple
 * open SheetMusicWindows at a time.  This class tracks which
 * window is currently active, and updates the menus based on
 * the window.
 *
 * In addition, this class creates a default menu when no
 * Midi file is currently selected.
 */

@implementation MidiSheetMusic

/** Create a blank window titled "Midi Sheet Music", and initilize the menus */
- (void)applicationWillFinishLaunching:(NSNotification*)notification {
    _globalMidiSheetMusic = self;

    windows = [[Array new:10] retain];

    /* Create a blank window */
    [self createBlankWindow];

    /* Initialize the File and Help menus */
    [self createEmptyMenu];
}


/** Create a 'blank' window (without any sheet music), with a message:
 *  "Use the menu File:Open to select a MIDI file"
 */
- (void)createBlankWindow {
    int mask = NSTitledWindowMask | NSClosableWindowMask | \
               NSMiniaturizableWindowMask | NSResizableWindowMask;
    NSRect screensize = [[NSScreen mainScreen] frame];
    NSRect bounds = NSMakeRect(0, 0, screensize.size.width * 7/8,  
                               screensize.size.height*5/6);
    blankWindow = [[NSWindow alloc] 
                      initWithContentRect:bounds
                      styleMask:mask
                      backing:NSBackingStoreBuffered
                      defer:NO];
    [blankWindow setTitle:@"Midi Sheet Music"];
    [blankWindow setDelegate:self];
    [blankWindow makeKeyAndOrderFront:NSApp];
    [blankWindow makeMainWindow];
    NSPoint origin; 
    origin.x = screensize.size.width/16; 
    origin.y = screensize.size.height/6;

    [blankWindow setFrameOrigin:origin];

    NSRect frame = [blankWindow frame];
    FlippedView *view = [[FlippedView alloc] initWithFrame:frame];
    [view setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];
    [blankWindow setContentView:view];

    /* Add a  MidiPlayer and Piano */
    MidiPlayer *player = [[MidiPlayer alloc] init];
    [view addSubview:player];
    Piano* piano = [[Piano alloc] init];
    frame = [piano frame];
    frame.origin.y += [player frame].size.height;
    [piano setFrame:frame];
    [view addSubview:piano];
    [player release];
    [piano release];

    /* Add the text "Use the menu File:Open to select a MIDI file" */
    frame.origin.y += [piano frame].size.height;
    NSTextField *label = [[NSTextField alloc] initWithFrame:frame];
    [label setStringValue:@"Use the Menu File:Open to select a MIDI file" ];
    [label setEditable:NO];
    [label setBordered:NO];
    [label setFont:[NSFont labelFontOfSize:20.0]];
    [label setAlignment:NSCenterTextAlignment];
    [view addSubview:label];
    [label release];
    [view release];
}


/** Open the given midi file.  This delegate is called when the
 *  user double-clicks a Midi file, and MidiSheetMusic is the
 *  default application that opens it.
 */
- (BOOL)application:(NSApplication*)app openFile:(NSString*)filename {
    [self openMidiFile:filename];
    return YES;
}

/** Create an empty menu item with no callback function,
 *  and add it to the main menu.
 */
- (void)createEmptyMenuItem:(NSString*)title {
    NSMenu *mainmenu = [NSApp mainMenu];
    NSMenuItem *menu = [[NSMenuItem alloc] 
             initWithTitle:title action:NULL keyEquivalent:@""];
    NSMenu* submenu = [[NSMenu alloc] initWithTitle:title];
    [menu setSubmenu:submenu];
    [submenu release];
    [mainmenu addItem:menu];
    [menu release];
}

/** Create the default menu, when no midi file is selected */
- (void)createEmptyMenu {
    NSMenu *mainmenu = [NSApp mainMenu];
    int i;

    /* Remove the existing menu items */
    int menucount = [mainmenu numberOfItems];
    for (i = 1; i < menucount; i++) {
        [mainmenu removeItemAtIndex:1];
    }

    [self createFileMenu];
    [self createEmptyMenuItem:@"View"];
    [self createEmptyMenuItem:@"Color"];
    [self createEmptyMenuItem:@"Tracks"];
    [self createEmptyMenuItem:@"Notes"];
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
                 action:@selector(openAction:)
                 keyEquivalent:@"o"];
    [menuitem setTarget:self];
    [filemenu addItem:menuitem];
    [menuitem release];

    menuitem = [[NSMenuItem alloc] 
                 initWithTitle:@"Open Sample Song..."
                 action:@selector(openSampleSongAction:)
                 keyEquivalent:@""];
    [menuitem setTarget:self];
    [filemenu addItem:menuitem];
    [menuitem release];

    menuitem = [[NSMenuItem alloc] 
                 initWithTitle:@"Close Window"
                 action:@selector(closeAction:)
                 keyEquivalent:@"w"];
    [menuitem setTarget:self];
    [filemenu addItem:menuitem];
    [menuitem release];

    [filemenu addItem:[NSMenuItem separatorItem]];

    [self createRecentFilesMenu:filemenu]; 

    [result setSubmenu:filemenu];
    [filemenu release];
    NSMenu *mainmenu = [NSApp mainMenu];
    [mainmenu addItem:result];
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
                     action:@selector(openRecentFileAction:)
                     keyEquivalent:@""];
        [menuitem setTarget:self];
        [menuitem setRepresentedObject:filename];
        [filemenu addItem:menuitem];
        [menuitem release];
    }
}

/** Create the Help Menu */
- (void)createHelpMenu {
    NSMenuItem *result = [[NSMenuItem alloc]
                           initWithTitle:@"Help" action:NULL keyEquivalent:@""];
    NSMenu* helpmenu = [[NSMenu alloc] initWithTitle:@"Help"];
     
    NSMenuItem *contents = [[NSMenuItem alloc]
                            initWithTitle:@"Help Contents..."
                            action:@selector(help:)
                            keyEquivalent:@""];
    [contents setTarget:self];

    [helpmenu addItem:contents];
    [contents release];
    [result setSubmenu:helpmenu];
    [helpmenu release];
    NSMenu *mainmenu = [NSApp mainMenu];
    [mainmenu addItem:result];
    [result release];
}


/** The callback function for the "Open..." menu.
 * Display a "File Open" dialog, to select a midi filename.
 * If a file is selected, call OpenMidiFile()
 */
- (IBAction)openAction:(id)sender {
    NSOpenPanel *dialog = [NSOpenPanel openPanel];
    [dialog setCanChooseFiles:YES];
    [dialog setCanChooseDirectories:NO];
    [dialog setAllowsMultipleSelection:NO];

    NSArray *types = [NSArray arrayWithObjects:@"mid", @"midi", nil];
    [dialog runModalForTypes:types];

    NSArray *result = [dialog filenames];
    if ([result count] == 1) {
        NSString *filename = [result objectAtIndex:0];
        [self openMidiFile:filename];
    }
}

/** The single, global, SampleSongDialog */
static SampleSongDialog *songDialog = NULL;

/** The callback function for the "Open Sample Song..." menu.
 * Create a SampleSongDialog.  If a song is chosen, read the 
 * file, and save it to an actual file in the temp directory.
 * Then call OpenMidiFile() using that temp filename.
 */
-(IBAction)openSampleSongAction:(id)sender {
    if (songDialog == NULL) {
        songDialog = [[SampleSongDialog alloc] init];
    }
    int ret = [songDialog showDialog];
    if (ret == NSRunStoppedResponse) {
        NSString *name = [songDialog getSong];
        NSLog(@"sample name is start %@ end\n", name);
        NSString *filename = [[NSBundle mainBundle] pathForResource:name ofType:@"mid"];
        NSLog(@"here filename start %@ end\n", filename);
        [self openMidiFile:filename];
    }
}

/** Return just the filename given a full path to a file */
-(NSString*) getFileName:(NSString*)path {
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


/**
 * Open the recent midi file, stored in the menu representedObject.
 */
- (IBAction)openRecentFileAction:(id)sender {
    NSMenuItem *menu = (NSMenuItem *)sender;
    NSString *filename = [menu representedObject];
    [self openMidiFile:filename];
}


/**
 * Read the midi file into a MidiFile instance.
 * Create a SheetMusic control based on the MidiFile.
 * Add the sheetmusic control to this form.
 * Enable all the menu items.
 *
 * If any error occurs while reading the midi file,
 * display a MessageBox with the error message.
 */
- (void)openMidiFile:(NSString*)filepath {
    NSString *filename = [self getFileName:filepath];
    @try {
        MidiFile *midifile = [[MidiFile alloc] initWithFile:filepath];
        SheetMusicWindow *window = [[SheetMusicWindow alloc]
                                     initWithMidiFile:midifile];
        [midifile release];
        [windows add:window];
        currentWindow = window;
        [self updateMenu];
        [window setDelegate:self];
        [window makeKeyAndOrderFront:NSApp];
        [window makeMainWindow];

        NSRect screensize = [[NSScreen mainScreen] frame];
        NSSize windowsize = [window frame].size;
        NSPoint origin;
        origin.x = (screensize.size.width - windowsize.width) / 2.0;
        origin.y = (screensize.size.height - windowsize.height);
        [window setFrameOrigin:origin];

        /* Remove the blank window once the user has
         * selected an actual midi file.
         */
        if (blankWindow != nil) {
            [blankWindow performClose:self];
            blankWindow = nil;
        }
    }
    @catch (MidiFileException* e) {
        NSString *message = [NSString stringWithFormat:
             @"MidiSheetMusic was unable to open the file %@.\nIt does not appear to be a valid midi file.\n%@", filename, [e reason]];
        [self showAlertWithTitle:@"Error Opening File" andMessage:message];
    }
}

/** The callback function for the "Close" menu.
 * This indirectly performs a close on the current window.
 * The actual cleanup is done in the method windowWillClose below.
 */
- (IBAction)closeAction:(id)sender {
    if (currentWindow == nil) {
        return;
    }
    [currentWindow performClose:self];
}


/** The callback function for the "Exit" menu.
 * Exit the application.
 */
- (IBAction)exitAction:(id)sender {
    for (int i = 0; i < [windows count]; i++ ) {
        SheetMusicWindow *w = [windows get:i];
        /* Before exiting, stop the midi player, which
         * deletes any temporary sound files created.
         */
        [w stopMidiPlayer];
        [w performClose:self];
    }
    exit(0);
}


/** Callback function for the "Help Contents" Menu.
 * Display the Help Dialog.
 */
- (IBAction)help:(id)sender {
    NSPanel *helpwindow = [NSPanel alloc];
    int mask = NSTitledWindowMask | NSResizableWindowMask | \
               NSMiniaturizableWindowMask | NSClosableWindowMask;
    NSRect bounds = NSMakeRect(100, 100, 650, 400);
    helpwindow = [helpwindow initWithContentRect:bounds
                             styleMask:mask
                             backing:NSBackingStoreBuffered
                             defer:YES ];
    [helpwindow setTitle:@"Midi Sheet Music - Help Contents"];
    NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:[helpwindow frame]];
    [scroll setBorderType:NSBezelBorder];
    [scroll setHasVerticalScroller:YES];
    [scroll setHasHorizontalScroller:YES];
    [scroll setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];
    [helpwindow setContentView:scroll];
    [helpwindow makeFirstResponder:scroll]; 
    NSTextView *view = [[NSTextView alloc] initWithFrame:bounds];
    [scroll setDocumentView:view];
    [view setBackgroundColor:[NSColor whiteColor]];
    NSString *rtfpath = [[NSBundle mainBundle] 
                         pathForResource:@"help" ofType:@"rtf"];
    BOOL success = [view readRTFDFromFile:rtfpath];
    [helpwindow orderFront:NSApp];
}



/* NSWindow delegate methods */

/* MidiSheetMusic can have multiple SheetMusic windows open at a time.
 * This NSWindow method is called when a SheetMusicWindow gains focus
 * (becomes the main window). Set the currentWindow to this window.
 * In addition, the menu items are different depending on the SheetMusic
 * being displayed.  Therefore, each SheetMusicWindow stores its own
 * menu items.  Update the main menu with the SheetMusicWindows' menu items.
 */
- (void)windowDidBecomeMain:(NSNotification*)n {
    if ([n object] == blankWindow) {
        return;
    }
    SheetMusicWindow *window = [n object];
    if (currentWindow == window) {
        return;
    }
    currentWindow = window;
    [self updateMenu];
    [currentWindow redrawSheetMusic];
}

/* Update the main menu bar with the menu items from
 * the currentWindow.
 */
- (void)updateMenu {
    NSMenu *mainmenu = [NSApp mainMenu];
    int i;

    /* Remove the existing menu items */
    int menucount = [mainmenu numberOfItems];
    for (i = 1; i < menucount; i++) {
        [mainmenu removeItemAtIndex:1];
    }
 
    /* Add the menu items for this window to the Application's main menubar */
    Array *menus = [currentWindow menus];
    for (i = 0; i < [menus count]; i++) {
        NSMenuItem *item = [menus get:i];
        [mainmenu addItem:item];
    }

    /* This class (MidiSheetMusic) handles the open, close, exit, and help menus. */
    NSMenuItem* filemenu = [mainmenu itemWithTitle:NSLocalizedString(@"File", nil)];
    NSMenuItem* openmenu = [[filemenu submenu] itemWithTitle:@"Open..."];
    [openmenu setAction:@selector(openAction:)];
    [openmenu setTarget:self];

    NSMenuItem* openSampleMenu = [[filemenu submenu] itemWithTitle:@"Open Sample Song..."];
    [openSampleMenu setAction:@selector(openSampleSongAction:)];
    [openSampleMenu setTarget:self];

    NSMenuItem* closemenu = [[filemenu submenu] itemWithTitle:@"Close Window"];
    [closemenu setAction:@selector(closeAction:)];
    [closemenu setTarget:self];

    NSArray *fileSubmenus = [[filemenu submenu] itemArray];
    for (int i = 0; i < [fileSubmenus count]; i++) {
        NSMenuItem *recentFileMenu = [fileSubmenus objectAtIndex:i];
        if ([recentFileMenu representedObject] != nil) {
            [recentFileMenu setAction:@selector(openRecentFileAction:)];
            [recentFileMenu setTarget:self];
        }
    }

    NSMenuItem* helpmenu = [mainmenu itemWithTitle:@"Help"];
    NSMenuItem* helpcontents = [[helpmenu submenu] itemWithTitle:@"Help Contents..."];
    [helpcontents setAction:@selector(help:)];
    [helpcontents setTarget:self];
}

/* When a window is being closed, remove the window
 * from the windows list. If this is the last window,
 * set the menubar to the initial menu.
 */
- (void)windowWillClose:(NSNotification*)n {
    SheetMusicWindow *window = [[n object] retain];
    [windows remove:window];
    if (currentWindow == window) {
        currentWindow = nil;
    }
    if ([windows count] == 0) {
        [self createEmptyMenu];
    }
    [window release];
}

/* Return this MidiSheetMusic instance */
+ (MidiSheetMusic *)shared
{
    return _globalMidiSheetMusic;
}

@end  /* MidiSheetMusic implementation */


