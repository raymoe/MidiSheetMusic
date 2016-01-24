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

#import "FlippedView.h"
#import "MidiSheetMusic.h"

/** @class FlippedView
 * This view is simply a NSView with flipped coordinates,
 * with (0,0) indicating the top-left corner instead of the
 * bottom-left corner.
 */
@implementation FlippedView

- (id)initWithFrame:(NSRect)rect
{
    self = [super initWithFrame:rect];
    [self registerForDraggedTypes:[NSArray arrayWithObjects: NSFilenamesPboardType, nil]];
    return self;
}

- (BOOL)isFlipped {
    return YES;
}

- (BOOL)autoresizesSubviews {
    return YES;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    return NSDragOperationLink;
}


/* When the user drags a file onto the view, open the midi file */
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    if ([[pboard types] containsObject:NSFilenamesPboardType]) {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        MidiSheetMusic *sheet = [MidiSheetMusic shared];
        [sheet openMidiFile: [files objectAtIndex:0]];
    }

    return YES;

}

@end

