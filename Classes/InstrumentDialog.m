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

#import "InstrumentDialog.h"
#import "FlippedView.h"


/** @class InstrumentDialog 
 * The InstrumentDialog is used to select what instrument to use
 * for each track, when playing the music.
 */
@implementation InstrumentDialog


/** Create a new InstrumentDialog.  Call the showDialog method
 * to display the dialog.
 */
- (id)initWithMidi:(MidiFile*)midifile {

    /* Create the dialog box */
    float unit = [[NSFont labelFontOfSize:[NSFont labelFontSize]] capHeight] * 2;
    float xstart = unit * 2;
    float ystart = unit * 2;
    float labelheight = unit * 2;

    window = [NSPanel alloc];
    int mask = NSTitledWindowMask | NSResizableWindowMask | NSMiniaturizableWindowMask;
    NSRect bounds = NSMakeRect(0, 0, xstart + labelheight * 14 + xstart,
                ystart + ([midifile.tracks count] + 3) * labelheight  
                + ystart);
    window = [window initWithContentRect:bounds styleMask:mask
              backing:NSBackingStoreBuffered defer:YES ];
    [window setTitle:@"Choose Instruments"];
    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:bounds];
    FlippedView *view = [[FlippedView alloc] initWithFrame:bounds];
    [scrollView setBackgroundColor: [window backgroundColor]];
    [scrollView setBorderType:NSBezelBorder];
    [scrollView setHasVerticalScroller:YES];
    [scrollView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [scrollView setDocumentView:view];
    [window setContentView:scrollView];
    [window setHidesOnDeactivate:YES];
    [scrollView release];

    Array* tracks = midifile.tracks;
    instrumentChoices = [[Array new:[tracks count] ] retain];

    /* For each midi track, create a label with the track number
     * ("Track 2"), and a ComboBox containing all the possible
     * midi instruments. Add the text "(default)" to the instrument
     * specified in the midi file.
     */
    for (int i = 0; i < [midifile.tracks count]; i++) {
        NSRect frame = NSMakeRect(xstart, ystart + i * labelheight, 
                                  labelheight*3 + labelheight/2, labelheight);

        NSTextField *label = [[NSTextField alloc] initWithFrame:frame];
        NSString *title = [NSString stringWithFormat:@"Track %d", i+1];
        [label setStringValue:title];
        [label setEditable:NO];
        [label setBordered:NO];
        [label setBackgroundColor: [window backgroundColor]];
        [view addSubview:label];
        [label release];
    }
    for (int i = 0; i < [tracks count]; i++) {
        NSRect frame = NSMakeRect(xstart + labelheight*3 + labelheight/2,
                                  ystart + i * labelheight,
                                  labelheight * 8, labelheight - 2);
        NSComboBox *combo = [[NSComboBox alloc] initWithFrame:frame];
        [instrumentChoices add:combo];
        [combo setHasVerticalScroller:YES];
        [combo setEditable:NO];

        NSArray *names = [MidiFile instrumentNames];
        for (int instr = 0; instr < [names count]; instr++) {
            NSString *name = [names objectAtIndex:instr];
			MidiTrack *track = [tracks get:i];
            if (track.instrument == instr) {
                name = [name stringByAppendingString:@" (default)"];
            }
            [combo addItemWithObjectValue:name];
        }
        MidiTrack *t = [tracks get:i];
        [combo selectItemAtIndex:t.instrument];
        [view addSubview:combo];
        [combo release];
    }

    /* Create the "Set All To Piano" button */
    NSRect frame = NSMakeRect(xstart + labelheight*3 + labelheight/2,
                              ystart + [tracks count] * labelheight,
                              labelheight * 5, labelheight);

    NSButton *allPiano = [[NSButton alloc] initWithFrame:frame];
    [view addSubview:allPiano];
    [allPiano setTitle:@"Set All To Piano"];
    [allPiano setTarget:self];
    [allPiano setAction:@selector(setAllPiano:)];
    [allPiano setBezelStyle:NSRoundedBezelStyle];
    [allPiano release];

    /* Create the OK and Cancel buttons */
    int ypos = ystart + ([tracks count] + 2) * labelheight + labelheight/2;
    frame = NSMakeRect(xstart, ypos, labelheight*3, labelheight);

    NSButton *ok = [[NSButton alloc] initWithFrame:frame];
    [view addSubview:ok];
    [ok setTitle:@"OK"];
    [ok setTarget:NSApp];
    [ok setAction:@selector(stopModal)];
    [ok setBezelStyle:NSRoundedBezelStyle];
    [ok release];

    frame.origin.x = xstart + labelheight*3 + labelheight/2;
    frame.size.width = labelheight * 3;
    NSButton *cancel = [[NSButton alloc] initWithFrame:frame];
    [cancel setTitle:@"Cancel"];
    [cancel setTarget:NSApp];
    [cancel setAction:@selector(abortModal)];
    [cancel setBezelStyle:NSRoundedBezelStyle];
    [view addSubview:cancel];
    [cancel release];

    [view release];

    return self;
}

/** Display the InstrumentDialog.
 * Return NSRunStoppedResponse if "OK" was clicked.
 * Return NSRunAbortResponse if "Cancel" was clicked.
 */
- (int)showDialog {
    IntArray *oldInstruments = [self instruments];
    int ret = [NSApp runModalForWindow:window];
    [window orderOut:self];
    if (ret != NSRunStoppedResponse) {
        /* If the user clicks 'Cancel', restore the old instruments */
        for (int i = 0; i < [instrumentChoices count]; i++) {
            NSComboBox *combo = [instrumentChoices get:i];
            [combo selectItemAtIndex:[oldInstruments get:i]];
        }
    }
    return ret;
}

/** Get the instruments currently selected */
- (IntArray*)instruments {
    IntArray *result = [IntArray new:[instrumentChoices count]];
    for (int i = 0; i < [instrumentChoices count]; i++) {
        NSComboBox *combo = [instrumentChoices get:i];
        if ([combo indexOfSelectedItem] == -1) {
            [combo selectItemAtIndex:0];
        }
        [result add:[combo indexOfSelectedItem]];
    }
    return result;
}

/** Set the instruments */
- (void)setInstruments:(IntArray*)values {
    if (values == nil || [values count] != [instrumentChoices count]) {
        return;
    }
    for (int i = 0; i < [values count]; i++) {
        NSComboBox *combo = [instrumentChoices get:i];
        [combo selectItemAtIndex: [values get:i]];
    }
}

/** Return true if all the default instruments are selected */
- (BOOL)isDefault {
    BOOL result = YES;
    for (int i = 0; i < [instrumentChoices count]; i++) {
        NSComboBox *combo = [instrumentChoices get:i];
        if ([combo indexOfSelectedItem] == -1) {
            [combo selectItemAtIndex:0];
        }
        int instr = [combo indexOfSelectedItem];
        NSString *name = [combo itemObjectValueAtIndex:instr];
        NSRange hasDefault = [name rangeOfString:@"default"];
        if (hasDefault.length == 0) {
            result = NO;
        }
    }
    return result;
}

/** Set all the instrument choices to "Acoustic Grand Piano",
 *  unless the instrument is Percussion (128).
 */
- (IBAction)setAllPiano:(id)sender {
    for (int i = 0; i < [instrumentChoices count]; i++) {
        NSComboBox *combo = [instrumentChoices get:i];
        int instr = [combo indexOfSelectedItem];
        if (instr != 128) {
            [combo selectItemAtIndex:0];
        }
    }
}


- (void)dealloc {
    [window release];
    [instrumentChoices release];
    [super dealloc];
}

@end

