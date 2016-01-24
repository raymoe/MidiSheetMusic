/*
 * Copyright (c) 2007-2013 Madhav Vaidyanathan
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
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>
#import <Foundation/NSZone.h>
#import <Foundation/NSException.h>
#import <AppKit/NSColor.h>
#import "Array.h"
#import "IntArray.h"
#import "TimeSignature.h"
#import "MidiOptions.h"

/** @class SavedMidiOptions
 *
 * When the app is closed, the MidiOptions are saved to
 * MidiSheetMusic.app/Contents/Resources/midisheetmusic.settings.json
 * as an array of MidiOptions dictionaries, converted to JSON.
 *
 * This class is used to load and save those settings.
 */
@interface SavedMidiOptions : NSObject {
    NSMutableArray *savedOptions;
}

+ (SavedMidiOptions *)shared;
- (void)loadAllOptions;
- (MidiOptions *)loadOptions:(MidiFile *)midifile;
- (MidiOptions *)loadFirstOptions;
- (void)saveOptions:(MidiOptions *)options;
- (Array *)getRecentFilenames;


@end

