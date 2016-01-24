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

#import <Foundation/NSTimer.h>
#import <Foundation/NSData.h>
#import <AppKit/NSSound.h>
#import <AppKit/NSButton.h>
#import <AppKit/NSSlider.h>
#import <AppKit/NSTextField.h>
#import "SheetMusic.h"
#import "MidiFile.h"
#import "Piano.h"

/* Possible playing states */
enum {
    stopped   = 1,   /** Currently stopped */
    playing   = 2,   /** Currently playing music */
    paused    = 3,   /** Currently paused */
    initStop  = 4,   /** Transitioning from playing to stop */
    initPause = 5,   /** Transitioning from playing to pause */
};


@interface MidiPlayer : NSView {
    NSButton* rewindButton;     /** The rewind button */
    NSButton* playButton;       /** The play/pause button */
    NSButton* stopButton;       /** The stop button */
    NSButton* fastFwdButton;    /** The fast forward button */
    NSSlider* speedBar;         /** The slider for controlling the playback speed */
    NSButton* speedLabel;       /** Label displaying the percent speed */
    NSSlider* volumeBar;        /** The slider for controlling the volume */

    int playstate;              /** The playing state of the Midi Player */
    MidiFile *midifile;         /** The midi file to play */
    MidiOptions *options;       /** The sound options for playing the midi file */
    NSString *tempSoundFile;    /** The temporary midi file currently being played */
    double pulsesPerMsec;       /** The number of pulses per millisec */
    SheetMusic *sheet;          /** The sheet music to highlight while playing */
    Piano *piano;               /** The piano to shade while playing */
    NSTimer *timer;             /** Timer used to update the sheet music while playing */
    NSSound *sound;             /** The sound player */
    struct timeval startTime;   /** Absolute time when music started playing */
    double startPulseTime;      /** Time (in pulses) when music started playing */
    double currentPulseTime;    /** Time (in pulses) music is currently at */
    double prevPulseTime;       /** Time (in pulses) music was last at */

}

-(id)init;
-(void)setMidiFile:(MidiFile*)file withOptions:(MidiOptions*)opt andSheet:(SheetMusic*)sheet;
-(void)setPiano:(Piano*)p;
-(void)reshade:(NSTimer*)timer;
-(IBAction)playPause:(id)sender;
-(IBAction)stop:(id)sender;
-(IBAction)rewind:(id)sender;
-(IBAction)fastForward:(id)sender;
-(IBAction)changeVolume:(id)sender;
-(void)timerCallback:(NSTimer*)timer;
-(void)restartPlayMeasuresInLoop;
-(void)replay:(NSTimer*)timer;
-(BOOL)isFlipped;
-(void)deleteSoundFile;
-(void)doStop;
-(void)dealloc;

@end


