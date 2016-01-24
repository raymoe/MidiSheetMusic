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

#import "PlayMeasuresDialog.h"
#import "FlippedView.h"

/** @class PlayMeasuresInLoop
 * This class displays the dialog used for the "Play Measures in Loop" feature.
 * It displays:
 * - A checkbox to enable this feature
 * - Two numeric spinboxes, to select the start and end measures.
 *
 * When the user clicks OK:
 * - isEnabled() returns true if the "play in loop" feature is enabled.
 * - getStartMeasure() returns the start measure of the loop
 * - getEndMeasure() returns the end measure of the loop
 */

@implementation PlayMeasuresDialog


/** Create a new PlayMeasuresDialog.  Call the showDialog method
 * to display the dialog.
 */
- (id)initWithMidi:(MidiFile*)midifile {
    int lastStart = midifile.endTime;
    int lastMeasure = 1 + lastStart / midifile.time.measure;

    /* Create the dialog box */
    float labelheight = [[NSFont labelFontOfSize:[NSFont labelFontSize]] capHeight] * 4;

    window = [NSPanel alloc];
    int mask = NSTitledWindowMask | NSResizableWindowMask | NSMiniaturizableWindowMask;
    NSRect bounds = NSMakeRect(0, 0, labelheight * 10, labelheight * 7);
    window = [window initWithContentRect:bounds styleMask:mask
              backing:NSBackingStoreBuffered defer:YES ];
    [window setTitle:@"Play Selected Measures in a Loop"];
    FlippedView *view = [[FlippedView alloc] initWithFrame:bounds];
    [window setContentView:view];
    [window setHidesOnDeactivate:YES];

    int xpos = labelheight/2;
    int ypos = labelheight/2;

    NSRect frame = NSMakeRect(xpos, ypos, labelheight*9, labelheight);
    enable = [[NSButton alloc] initWithFrame:frame];  
    [enable setButtonType: NSSwitchButton];
    [enable setTitle: @"Play Selected Measures in a Loop"];
    [enable setState:NSOffState];
    [view addSubview: enable];

    ypos += labelheight * 3/2;

    frame = NSMakeRect(xpos, ypos, labelheight * 3, labelheight);
    NSTextField *label = [[NSTextField alloc] initWithFrame:frame];
    [label setStringValue: @"Start Measure"];
    [label setEditable:NO];
    [label setBordered:NO];
    [label setBackgroundColor: [window backgroundColor]];
    [view addSubview:label];
    [label release];

    xpos += labelheight * 4;

    frame = NSMakeRect(xpos, ypos, labelheight * 2, labelheight);
    startMeasure = [[NSComboBox alloc] initWithFrame:frame];
    for (int i = 1; i <= lastMeasure; i++) {
        NSString *measure = [NSString stringWithFormat:@"%d", i];
        [startMeasure addItemWithObjectValue:measure];
    }
    [startMeasure selectItemAtIndex:0];
    [view addSubview:startMeasure];

    xpos = labelheight/2;
    ypos += labelheight * 3/2;

    frame = NSMakeRect(xpos, ypos, labelheight * 3, labelheight);
    label = [[NSTextField alloc] initWithFrame:frame];
    [label setStringValue: @"End Measure"];
    [label setEditable:NO];
    [label setBordered:NO];
    [label setBackgroundColor: [window backgroundColor]];
    [view addSubview:label];
    [label release];

    xpos += labelheight * 4;

    frame = NSMakeRect(xpos, ypos, labelheight * 2, labelheight);
    endMeasure = [[NSComboBox alloc] initWithFrame:frame];
    for (int i = 1; i <= lastMeasure; i++) {
        NSString *measure = [NSString stringWithFormat:@"%d", i];
        [endMeasure addItemWithObjectValue:measure];
    }
    [endMeasure selectItemAtIndex:lastMeasure-1];
    [view addSubview:endMeasure];

    /* Create the OK button */
    xpos = labelheight/2;
    ypos += labelheight * 3/2;
    frame = NSMakeRect(xpos, ypos, labelheight*3, labelheight);
    NSButton *ok = [[NSButton alloc] initWithFrame:frame];
    [ok setTitle:@"OK"];
    [ok setTarget:NSApp];
    [ok setAction:@selector(stopModal)];
    [ok setBezelStyle:NSRoundedBezelStyle];
    [view addSubview:ok];
    [ok release];

    [view release];
    return self;
}

/** Display the PlayMeasuresDialog.
 * This always returns NSRunStoppedResponse.
 */
- (int)showDialog {
    int ret = [NSApp runModalForWindow:window];
    [window orderOut:self];
    return ret;
}

/** Get the enabled value */
- (BOOL)getEnabled {
    return ([enable state] == NSOnState);
}

/** Set the enabled value */
- (void)setEnabled:(BOOL)enabled {
    if (enabled) {
        [enable setState:NSOnState];
    }
    else {
        [enable setState:NSOffState];
    }
}

/** Get the start measure */
- (int)getStartMeasure {
    if ([startMeasure indexOfSelectedItem] == -1) {
        [startMeasure selectItemAtIndex:0];
    }
    return [startMeasure indexOfSelectedItem];
}

/** Set the start measure */
- (void)setStartMeasure:(int)value {
    if (value >= 0 && value < [startMeasure numberOfItems]) {
        [startMeasure selectItemAtIndex:value];
    }
}

/** Get the end measure */
-(int)getEndMeasure {
    if ([endMeasure indexOfSelectedItem] == -1) {
        [endMeasure selectItemAtIndex:0];
    }
    return [endMeasure indexOfSelectedItem];
}

/** Set the end measure */
- (void)setEndMeasure:(int)value {
    if (value >= 0 && value < [endMeasure numberOfItems]) {
        [endMeasure selectItemAtIndex:value];
    }
}

- (void)dealloc {
    [window release];
    [enable release];
    [startMeasure release];
    [endMeasure release];
    [super dealloc];
}

@end

