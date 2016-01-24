/*
 * Copyright (c) 2007-2012 Madhav Vaidyanathan
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License version 2.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 */

#import <Foundation/Foundation.h>

/** @class LyricSymbol
 *  A lyric contains the lyric to display, the start time the lyric occurs at,
 *  the the x-coordinate where it will be displayed.
 */
@interface LyricSymbol : NSObject {
    int starttime;   /** The start time, in pulses */
    NSString* text;  /** The lyric text */
    int x;           /** The x (horizontal) position within the staff */
}

@property (nonatomic, assign) int startTime;
@property (nonatomic, retain) NSString *text;
@property (nonatomic, assign) int x;
@property (nonatomic, readonly) int minWidth;

-(id)init;
-(NSString*)description;

@end

