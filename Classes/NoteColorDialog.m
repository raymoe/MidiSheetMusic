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

#import "NoteColorDialog.h"
#import "FlippedView.h"


/** @class NoteColorDialog 
 * The NoteColorDialog is used to choose what color to display for each of
 * the 12 notes in a scale, as well as the shade color.
 */
@implementation NoteColorDialog


/** Create a new NoteColorDialog.  Call the showDialog method
 * to display the dialog.
 */
- (id)init {
    /* Create the dialog box */
    float unit = [[NSFont labelFontOfSize:[NSFont labelFontSize]] capHeight] * 5/3;
    float xstart = unit * 2;
    float ystart = unit * 2;
    float labelheight = unit * 2;

    window = [NSPanel alloc];
    int mask = NSTitledWindowMask | NSResizableWindowMask | NSMiniaturizableWindowMask;
    NSRect bounds = NSMakeRect(0, 0, 
                               xstart + labelheight*2 + unit + labelheight*2 +
                               labelheight*2 + labelheight*2 + unit + 
                               labelheight*2 + xstart,
                               ystart + 9*labelheight + labelheight*2 + ystart);

    window = [window initWithContentRect:bounds styleMask:mask
              backing:NSBackingStoreBuffered defer:YES ];
    [window setTitle:@"Choose Note Colors"];
    FlippedView *view = [[FlippedView alloc] initWithFrame:bounds];
    [window setContentView:view];
    [window setHidesOnDeactivate:YES];

    /* Initialize the colors */
    colorwells = [[Array new:12] retain];
    NSArray* names = [NSMutableArray arrayWithObjects:
                      @"A",  @"A#", @"B", @"C",  @"C#", @"D",
                      @"D#", @"E",  @"F", @"F#", @"G",  @"G#", nil];

    /* Create the first column, note labels A thru D */
    for (int i = 0; i < 6; i++) {
        NSRect frame = NSMakeRect(xstart, ystart + i * labelheight,
                                  labelheight * 2, labelheight);

        NSTextField *label = [[NSTextField alloc] initWithFrame:frame];
        [label setStringValue:[names objectAtIndex:i]];
        [label setEditable:NO];
        [label setBordered:NO];
        [label setBackgroundColor: [window backgroundColor]];
        [view addSubview:label];
        [label release];
    } 

    /* Create the second column, the colors */
    xstart += (labelheight * 2) + unit;
    for (int i = 0; i < 6; i++) {
        NSRect frame = NSMakeRect(xstart, ystart + i * labelheight,
                                  labelheight * 2, labelheight);

        NSColorWell *well = [[NSColorWell alloc] initWithFrame:frame];
        [view addSubview:well];
        [colorwells add:well];
        [well release];
    }

    /* Create the third column, note labels D# thru G# */
    xstart += labelheight * 4;
    for (int i = 6; i < 12; i++) {
        NSRect frame = NSMakeRect(xstart, ystart + (i-6) * labelheight,
                                  labelheight * 2, labelheight);

        NSTextField *label = [[NSTextField alloc] initWithFrame:frame];
        [label setStringValue:[names objectAtIndex:i]];
        [label setEditable:NO];
        [label setBordered:NO];
        [label setBackgroundColor: [window backgroundColor]];
        [view addSubview:label];
        [label release];
    } 

    /* Create the fourth column, the colors */
    xstart += (labelheight*2) + unit;
    for (int i = 6; i < 12; i++) {
        NSRect frame = NSMakeRect(xstart, ystart + (i-6) * labelheight,
                                  labelheight * 2, labelheight);

        NSColorWell *well = [[NSColorWell alloc] initWithFrame:frame];
        [view addSubview:well];
        [colorwells add:well];
        [well release];
    }

    /* Create the shade Colorwell */
    int colorwell_x = xstart;
    xstart = unit*2;
    NSRect frame = NSMakeRect(xstart,
                              ystart + 6 * labelheight,
                              labelheight * 4 + labelheight*2, labelheight);
    NSTextField *label = [[NSTextField alloc] initWithFrame:frame];
    [label setStringValue:@"Right Shade "];
    [label setEditable:NO];
    [label setBordered:NO];
    [label setAlignment:NSRightTextAlignment];
    [label setBackgroundColor: [window backgroundColor]];
    [view addSubview:label];
    [label release];

    frame.origin.x = colorwell_x;
    frame.size.width = labelheight * 2;
    shadeWell = [[NSColorWell alloc] initWithFrame:frame];
    NSColor *color = [NSColor colorWithDeviceRed:210/255.0
                     green:205/255.0 blue:220/255.0 alpha:1.0];
    [shadeWell setColor:color];
    [view addSubview:shadeWell];


    /* Create the shade2 Colorwell */
    xstart = unit*2;
    frame = NSMakeRect(xstart, ystart + 7 * labelheight,
                      labelheight * 4 + labelheight*2, labelheight);
    label = [[NSTextField alloc] initWithFrame:frame];
    [label setStringValue:@"Left Shade "];
    [label setEditable:NO];
    [label setBordered:NO];
    [label setAlignment:NSRightTextAlignment];
    [label setBackgroundColor: [window backgroundColor]];
    [view addSubview:label];
    [label release];

    frame.origin.x = colorwell_x;
    frame.size.width = labelheight * 2;
    shade2Well = [[NSColorWell alloc] initWithFrame:frame];
    color = [NSColor colorWithDeviceRed:150/255.0
             green:200/255.0 blue:220/255.0 alpha:1.0];
    [shade2Well setColor:color];
    [view addSubview:shade2Well];


    /* Create the OK and Cancel buttons */
    xstart = unit*2;
    frame = NSMakeRect(xstart, ystart + 9 * labelheight,
                       labelheight * 3, labelheight + unit);

    NSButton *ok = [[NSButton alloc] initWithFrame:frame];
    [view addSubview:ok];
    [ok setTitle:@"OK"];
    [ok setTarget:NSApp];
    [ok setAction:@selector(stopModal)];
    [ok setBezelStyle:NSRoundedBezelStyle];
    [ok highlight:YES];
    [ok release];

    frame.origin.x += frame.size.width + unit;
    frame.size.width = labelheight * 4;
    NSButton *cancel = [[NSButton alloc] initWithFrame:frame];
    [cancel setTitle:@"Cancel"];
    [cancel setTarget:NSApp];
    [cancel setAction:@selector(abortModal)];
    [cancel setBezelStyle:NSRoundedBezelStyle];
    [view addSubview:cancel];
    [cancel release];

    /* Initialize the default colors */
    float rgb[12][3] = {
        {180.0,   0.0,   0.0},
        {230.0,   0.0,   0.0},
        {220.0, 128.0,   0.0},
        {130.0, 130.0,   0.0},
        {187.0, 187.0,   0.0},
        {  0.0, 100.0,   0.0},
        {  0.0, 140.0,   0.0},
        {  0.0, 180.0, 180.0},
        {  0.0,   0.0, 120.0},
        {  0.0,   0.0, 180.0},
        { 88.0,   0.0, 147.0},
        {129.0,   0.0, 215.0}
    };

    for (int i = 0; i < 12; i++) {
        NSColor *c = [NSColor colorWithDeviceRed:rgb[i][0]/255.0
                     green:rgb[i][1]/255.0 blue:rgb[i][2]/255.0 alpha:1.0];
        
        NSColorWell *well = [colorwells get:i];
        [well setColor:c];
    }

    [view release];
    return self;
}

/** Display the NoteColorDialog.
 * Save the old colors for restoring, in case "Cancel" is clicked.
 * Return NSRunStoppedResponse if "OK" was clicked.
 * Return NSRunAbortResponse if "Cancel" was clicked.
 */
- (int) showDialog {
    Array *oldcolors = [self colors];
    NSColor* oldShade = [shadeWell color];
    NSColor* oldShade2 = [shade2Well color];
    int ret = [NSApp runModalForWindow:window];
    [window orderOut:self];
    if (ret != NSRunStoppedResponse) {
        /* Restore the old colors */
        for (int i = 0; i < 12; i++) {
            NSColorWell *well = [colorwells get:i];
            [well setColor:[oldcolors get:i] ];
        }
        [shadeWell setColor:oldShade];
        [shade2Well setColor:oldShade2];
    }
    return ret;
}

- (void)dealloc {
    [window release];
    [colorwells release];
    [shadeWell release]; 
    [shade2Well release]; 
    [super dealloc];
}

/** Get the colors used for each note. There are 12 colors
 * in the array.
 */
- (Array *)colors {
    Array *result = [Array new:12];
    int i;
    for (i = 0; i < 12; i++) {
        NSColor *c = [[colorwells get:i] color];
        [result add:c];
    }
    return result;
}

/** Set the colors used for each note */
- (void)setColors:(Array *)newcolors {
    if (newcolors == nil || [newcolors count] != 12) {
        return;
    }
    for (int i = 0; i < 12; i++) {
        NSColorWell *colorwell = [colorwells get:i];
        [colorwell setColor: [newcolors get:i]];    
    }
}

/** Get the shade color selected */
- (NSColor*)shadeColor {
    return [shadeWell color];
}

/** Set the shade color */
- (void)setShadeColor:(NSColor *)color {
    [shadeWell setColor:color];
}

/** Get the shade2 (left-hand) color selected */
- (NSColor*)shade2Color {
    return [shade2Well color];
}

/** Set the shade2 color */
- (void)setShade2Color:(NSColor *)color {
    [shade2Well setColor:color];
}


@end

