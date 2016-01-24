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

#import "SampleSongDialog.h"
#import "FlippedView.h"

/** @class SampleSongDialog
 * The SampleSongDialog is used to select one of the 50+ sample
 * midi songs that ship with MidiSheetMusic.
 *
 * The method showDialog() returns NSRunStopped/Abort Response.
 * The method getSong() returns the selected song.
 */
@implementation SampleSongDialog

/** The list of sample midi songs */
static NSArray* songs = NULL;
+(NSArray*)songNames {
    if (songs != NULL) {
        return songs;
    }
    songs = [NSArray arrayWithObjects:
      @"Bach__Invention_No._13",
      @"Bach__Minuet_in_G_major",
      @"Bach__Musette_in_D_major",
      @"Bach__Prelude_in_C_major",
      @"Beethoven__Fur_Elise",
      @"Beethoven__Minuet_in_G_major",
      @"Beethoven__Moonlight_Sonata",
      @"Beethoven__Sonata_Pathetique_2nd_Mov",
      @"Bizet__Habanera_from_Carmen",
      @"Borodin__Polovstian_Dance",
      @"Brahms__Hungarian_Dance_No._5",
      @"Brahms__Waltz_No._15_in_A-flat_major",
      @"Brahms__Waltz_No._9_in_D_minor",
      @"Chopin__Minute_Waltz_Op._64_No._1_in_D-flat_major",
      @"Chopin__Nocturne_Op._9_No._1_in_B-flat_minor",
      @"Chopin__Nocturne_Op._9_No._2_in_E-flat_major",
      @"Chopin__Nocturne_in_C_minor",
      @"Chopin__Prelude_Op._28_No._20_in_C_minor",
      @"Chopin__Prelude_Op._28_No._4_in_E_minor",
      @"Chopin__Prelude_Op._28_No._6_in_B_minor",
      @"Chopin__Prelude_Op._28_No._7_in_A_major",
      @"Chopin__Waltz_Op._64_No._2_in_Csharp_minor",
      @"Clementi__Sonatina_Op._36_No._1",
      @"Easy_Songs__Brahms_Lullaby",
      @"Easy_Songs__Greensleeves",
      @"Easy_Songs__Jingle_Bells",
      @"Easy_Songs__Silent_Night",
      @"Easy_Songs__Twinkle_Twinkle_Little_Star",
      @"Field__Nocturne_in_B-flat_major",
      @"Grieg__Canon_Op._38_No._8",
      @"Grieg__Peer_Gynt_Morning",
      @"Handel__Sarabande_in_D_minor",
      @"Liadov__Prelude_Op._11_in_B_minor",
      @"MacDowelll__To_a_Wild_Rose",
      @"Massenet__Elegy_in_E_minor",
      @"Mendelssohn__Venetian_Boat_Song_Op._19b_No._6",
      @"Mendelssohn__Wedding_March",
      @"Mozart__Aria_from_Don_Giovanni",
      @"Mozart__Eine_Kleine_Nachtmusik",
      @"Mozart__Fantasy_No._3_in_D_minor",
      @"Mozart__Minuet_from_Don_Juan",
      @"Mozart__Rondo_Alla_Turca",
      @"Mozart__Sonata_K.545_in_C_major",
      @"Offenbach__Barcarolle_from_The_Tales_of_Hoffmann",
      @"Pachelbel__Canon_in_D_major",
      @"Prokofiev__Peter_and_the_Wolf",
      @"Puccini__O_Mio_Babbino_Caro",
      @"Rebikov__Valse_Melancolique_Op._2_No._3",
      @"Saint-Saens__The_Swan",
      @"Satie__Gnossienne_No._1",
      @"Satie__Gymnopedie_No._1",
      @"Schubert__Impromptu_Op._90_No._4_in_A-flat_major",
      @"Schubert__Moment_Musicaux_No._1_in_C_major",
      @"Schubert__Moment_Musicaux_No._3_in_F_minor",
      @"Schubert__Serenade_in_D_minor",
      @"Schumann__Scenes_From_Childhood_Op._15_No._12",
      @"Schumann__The_Happy_Farmer",
      @"Strauss__The_Blue_Danube_Waltz",
      @"Tchaikovsky__Album_for_the_Young_-_Old_French_Song",
      @"Tchaikovsky__Album_for_the_Young_-_Polka",
      @"Tchaikovsky__Album_for_the_Young_-_Waltz",
      @"Tchaikovsky__Nutcracker_-_Dance_of_the_Reed_Flutes",
      @"Tchaikovsky__Nutcracker_-_Dance_of_the_Sugar_Plum_Fairies",
      @"Tchaikovsky__Nutcracker_-_March_of_the_Toy_Soldiers",
      @"Tchaikovsky__Nutcracker_-_Waltz_of_the_Flowers",
      @"Tchaikovsky__Swan_Lake",
      @"Verdi__La_Donna_e_Mobile",
      nil
    ];
    songs = [songs retain];
    return songs;
} 


/** Create a new SampleSongDialog.  Call the showDialog method
 * to display the dialog.
 */
- (id)init {

    /* Create the dialog box */
    float labelheight  = [[NSFont labelFontOfSize:[NSFont labelFontSize]] capHeight] * 4;

    window = [NSPanel alloc];
    int mask = NSTitledWindowMask | NSResizableWindowMask | NSMiniaturizableWindowMask;
    NSRect bounds = NSMakeRect(0, 0, labelheight * 16, labelheight * 16);
    window = [window initWithContentRect:bounds styleMask:mask
              backing:NSBackingStoreBuffered defer:YES ];
    [window setTitle:@"Choose a Sample MIDI Song"];
    [window setHidesOnDeactivate:YES];

    FlippedView *view = [[FlippedView alloc] initWithFrame:bounds];
    [window setContentView:view];

    /* Create the scrollable table of sample songs */
    NSRect frame = NSMakeRect(0, 0, labelheight * 13, 
                              labelheight * [[SampleSongDialog songNames] count]);
    tableView = [[NSTableView alloc] initWithFrame: frame];
    [tableView setDataSource:self];
    [tableView reloadData];
    [tableView setUsesAlternatingRowBackgroundColors:YES];
    [tableView setAllowsColumnResizing:YES];
    NSTableColumn* column = [[NSTableColumn alloc] initWithIdentifier:@"Name"];
    column.width =  bounds.size.width;
    [column setResizingMask: NSTableColumnUserResizingMask];
    [tableView addTableColumn:column];
    [column release];

    bounds.origin.x += labelheight/2;
    bounds.origin.y += labelheight/2;
    bounds.size.width -= labelheight;
    bounds.size.height -= labelheight * 3;
    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:bounds];
    [scrollView setBorderType:NSBezelBorder];
    [scrollView setHasVerticalScroller:YES];
    /* [scrollView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable]; */
    [scrollView setDocumentView:tableView];
    [view addSubview:scrollView];
    [scrollView release];

    /* Create the OK and Cancel buttons */
    int ypos = bounds.origin.y + bounds.size.height + labelheight;
    bounds = NSMakeRect(labelheight/2, ypos, labelheight*2 + labelheight/2, labelheight);

    NSButton *ok = [[NSButton alloc] initWithFrame:bounds];
    [view addSubview:ok];
    [ok setTitle:@"OK"];
    [ok setTarget:NSApp];
    [ok setAction:@selector(stopModal)];
    [ok setBezelStyle:NSRoundedBezelStyle];
    [ok highlight:YES];
    [ok release];

    bounds.origin.x += bounds.size.width + labelheight/2;
    bounds.size.width = labelheight * 3;
    NSButton *cancel = [[NSButton alloc] initWithFrame:bounds];
    [cancel setTitle:@"Cancel"];
    [cancel setTarget:NSApp];
    [cancel setAction:@selector(abortModal)];
    [cancel setBezelStyle:NSRoundedBezelStyle];
    [view addSubview:cancel];
    [cancel release];

    [view release];

    return self;
}


/** Display the SampleSongDialog.
 * Return NSRunStoppedResponse if "OK" was clicked.
 * Return NSRunAbortResponse if "Cancel" was clicked.
 */
- (int)showDialog {
    int ret = [NSApp runModalForWindow:window];
    [window orderOut:self];
    return ret;
}


/** Return the number of rows (the number of sample songs) */
-(int)numberOfRowsInTableView:(NSTableView *)view {
    int count = [[SampleSongDialog songNames] count];
    return count;
}

/** Return the song name at the given row index */
-(id)tableView:(NSTableView *)view 
  objectValueForTableColumn:(NSTableColumn *)column row:(int)rowIndex {

    NSString *name = [[SampleSongDialog songNames] objectAtIndex:rowIndex];
    NSString *title = [MidiFile titleName:name];
    return title;
}


/** Get the currently selected song */
-(NSString*)getSong {
    int index = (int)[tableView selectedRow];
    if (index == -1) {
        index = 0;
    }
    return  [[SampleSongDialog songNames] objectAtIndex:index];
}


- (void)dealloc {
    [window release];
    [tableView release];
    [super dealloc];
}

@end

