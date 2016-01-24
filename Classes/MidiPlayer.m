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

#include <sys/time.h>
#include <unistd.h>
#import "MidiPlayer.h"

/* A note about changing the volume:
 * MidiSheetMusic does not support volume control in Mac OS X 10.4
 * and earlier, because the NSSound setVolume method does not exist
 * in those earlier versions. In the code below, we check if the NSSound
 * class supports the setVolume method, using respondsToSelector.
 */

#if MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_5
@interface NSSound(NSVolume)

- (void)setVolume:(float)x;

@end
#endif


/** @class MidiPlayer
 *
 * The MidiPlayer is the panel at the top used to play the sound
 * of the midi file.  It consists of:
 *
 * - The Rewind button
 * - The Play/Pause button
 * - The Stop button
 * - The Fast Forward button
 * - The Playback speed bar
 * - The Volume bar
 *
 * The sound of the midi file depends on
 * - The MidiOptions (taken from the menus)
 *   Which tracks are selected
 *   How much to transpose the keys by
 *   What instruments to use per track
 * - The tempo (from the Speed bar)
 * - The volume
 *
 * The MidiFile.changeSound() method is used to create a new midi file
 * with these options.  The NSSound class is used for
 * playing, pausing, and stopping the sound.
 *
 * For shading the notes during playback, the method
 * Staff.shadeNotes() is used.  It takes the current 'pulse time',
 * and determines which notes to shade.
 */
@implementation MidiPlayer

static NSImage* rewindImage = NULL;  /** The rewind image */
static NSImage* playImage = NULL;    /** The play image */
static NSImage* pauseImage = NULL;   /** The pause image */
static NSImage* stopImage = NULL;    /** The stop image */
static NSImage* fastFwdImage = NULL; /** The fast forward image */
static NSImage* volumeImage = NULL;  /** The volume image */


/** Resize an image */
+ (NSImage*) resizeImage:(NSImage*)origImage toSize:(NSSize)newsize {
    NSImage *image = [[NSImage alloc] initWithSize:newsize];
    [image lockFocus];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    [origImage setScalesWhenResized:YES];
    [origImage setSize:newsize];
    [origImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
    [image unlockFocus];
    [image setFlipped:YES];
    return [image autorelease];
}


/** Load the play/pause/stop button images */
+ (void)loadImages {
    float buttonheight = [[NSFont labelFontOfSize:[NSFont labelFontSize]] capHeight] * 3;
    NSSize imagesize;
    imagesize.width = buttonheight;
    imagesize.height = buttonheight;
    NSImage *image;
    if (rewindImage == NULL) {
        NSString *name = [[NSBundle mainBundle] pathForResource:@"rewind" ofType:@"png"];
        image = [[NSImage alloc] initWithContentsOfFile:name];
        rewindImage = [[MidiPlayer resizeImage:image toSize:imagesize] retain];
        [image release];
    }
    if (playImage == NULL) {
        NSString *name = [[NSBundle mainBundle] pathForResource:@"play" ofType:@"png"];
        image = [[NSImage alloc] initWithContentsOfFile:name];
        playImage = [[MidiPlayer resizeImage:image toSize:imagesize] retain];
        [image release];
    }
    if (pauseImage == NULL) {
        NSString *name = [[NSBundle mainBundle] pathForResource:@"pause" ofType:@"png"];
        image = [[NSImage alloc] initWithContentsOfFile:name];
        pauseImage = [[MidiPlayer resizeImage:image toSize:imagesize] retain];
        [image release];
    }
    if (stopImage == NULL) {
        NSString *name = [[NSBundle mainBundle] pathForResource:@"stop" ofType:@"png"];
        image = [[NSImage alloc] initWithContentsOfFile:name];
        stopImage = [[MidiPlayer resizeImage:image toSize:imagesize] retain];
        [image release];
    }
    if (fastFwdImage == NULL) {
        NSString *name = [[NSBundle mainBundle] pathForResource:@"fastforward" ofType:@"png"];
        image = [[NSImage alloc] initWithContentsOfFile:name];
        fastFwdImage = [[MidiPlayer resizeImage:image toSize:imagesize] retain];
        [image release];
    }
    if (volumeImage == NULL) {
        NSString *name = [[NSBundle mainBundle] pathForResource:@"volume" ofType:@"png"];
        image = [[NSImage alloc] initWithContentsOfFile:name];
        volumeImage = [[MidiPlayer resizeImage:image toSize:imagesize] retain];
        [image release];
    }
}

/** Create a new MidiPlayer, displaying the play/stop buttons, the
 *  speed bar, and volume bar.  The midifile and sheetmusic are initially null.
 */
- (id)init {
    [MidiPlayer loadImages];
    float buttonheight = [[NSFont labelFontOfSize:[NSFont labelFontSize]] capHeight] * 4;
    NSRect frame = NSMakeRect(0, 0, buttonheight * 27, buttonheight * 2);
    self = [super initWithFrame:frame];
    [self setAutoresizingMask:NSViewWidthSizable];

    midifile = nil;
    sheet = nil;
    options = nil;
    playstate = stopped;
    gettimeofday(&startTime, NULL);
    startPulseTime = 0;
    currentPulseTime = 0;
    prevPulseTime = -10;
    timer = nil;
    sound = nil;

    /* Create the rewind button */
    frame = NSMakeRect(buttonheight/4, 0, 1.5*buttonheight, 2*buttonheight);
    rewindButton = [[NSButton alloc] initWithFrame:frame];
    [self addSubview:rewindButton];
    [rewindButton setImage:rewindImage];
    [rewindButton setToolTip:@"Rewind"];
    [rewindButton setAction:@selector(rewind:)];
    [rewindButton setTarget:self];
    [rewindButton setBezelStyle:NSRoundedBezelStyle];

    /* Create the play button */
    frame.origin.x += buttonheight + buttonheight/2;
    playButton = [[NSButton alloc] initWithFrame:frame];
    [self addSubview:playButton];
    [playButton setImage:playImage];
    [playButton setToolTip:@"Play"];
    [playButton setAction:@selector(playPause:)];
    [playButton setTarget:self];
    [playButton setBezelStyle:NSRoundedBezelStyle];

    /* Create the stop button */
    frame.origin.x += buttonheight + buttonheight/2;
    stopButton = [[NSButton alloc] initWithFrame:frame];
    [self addSubview:stopButton];
    [stopButton setImage:stopImage];
    [stopButton setToolTip:@"Stop"];
    [stopButton setAction:@selector(stop:)];
    [stopButton setTarget:self];
    [stopButton setBezelStyle:NSRoundedBezelStyle];

    /* Create the fast forward button */
    frame.origin.x += buttonheight + buttonheight/2;
    fastFwdButton = [[NSButton alloc] initWithFrame:frame];
    [self addSubview:fastFwdButton];
    [fastFwdButton setImage:fastFwdImage];
    [fastFwdButton setToolTip:@"Fast Forward"];
    [fastFwdButton setAction:@selector(fastForward:)];
    [fastFwdButton setTarget:self];
    [fastFwdButton setBezelStyle:NSRoundedBezelStyle];

    /* Create the Speed bar */
    frame.origin.x += 2*buttonheight;
    frame.origin.y = buttonheight/2;
    frame.size.height = buttonheight;
    frame.size.width = buttonheight * 3;
    speedLabel = [[NSButton alloc] initWithFrame:frame];
    [speedLabel setTitle:@"Speed: 100%"];
    [speedLabel setBordered:NO];
    [speedLabel setAlignment:NSLeftTextAlignment];
    [self addSubview:speedLabel]; 

    frame.origin.x += buttonheight*3 + 2;
    frame.size.width = buttonheight * 6;
    speedBar = [[NSSlider alloc] initWithFrame:frame];
    [speedBar setMinValue:1];
    [speedBar setMaxValue:150];
    [speedBar setDoubleValue:100];
    [speedBar setTarget:self];
    [speedBar setAction:@selector(speedBarChanged:)];
    [self addSubview:speedBar]; 

    /* Create the volume bar */
    frame.origin.x += buttonheight*6 + buttonheight/2;
    frame.origin.y = 0;
    frame.size.width = 1.5 *buttonheight;
    frame.size.height = 2*buttonheight;
    NSButton *volumeLabel = [[NSButton alloc] initWithFrame:frame]; 
    [self addSubview:volumeLabel];
    [volumeLabel setImage:volumeImage];
    [volumeLabel setToolTip:@"Adjust Volume"];
    [volumeLabel setBordered:NO]; 
    [volumeLabel release];

    frame.origin.x += buttonheight*2 + 2;
    frame.origin.y = buttonheight/2;
    frame.size.width = buttonheight * 6;
    frame.size.height = buttonheight;
    volumeBar = [[NSSlider alloc] initWithFrame:frame];
    [volumeBar setMinValue:1];
    [volumeBar setMaxValue:100];
    [volumeBar setDoubleValue:100];
    [volumeBar setAction:@selector(changeVolume:)];
    [volumeBar setTarget:self];
    [self addSubview:volumeBar];
    return self;
}

- (void)setPiano:(Piano*)p {
    piano = [p retain];
}

/** The MidiFile and/or SheetMusic has changed. Stop any playback sound,
 *  and store the current midifile and sheet music.
 */
- (void)setMidiFile:(MidiFile*)file withOptions:(MidiOptions *)opt andSheet:(SheetMusic*)s {

    /* If we're paused, and using the same midi file, redraw the
     * highlighted notes.
     */
    if ((midifile == file && midifile != nil && playstate == paused)) {
        if (sheet != nil) {
            [sheet release];
        }
        sheet = [s retain];
        [options release];
        options = [opt retain];

        [sheet shadeNotes:(int)currentPulseTime withPrev:-10 gradualScroll:NO];
        [sheet setMouseClickTarget:self action:@selector(moveToClicked:)];
        NSTimer *reShadeTimer = [NSTimer scheduledTimerWithTimeInterval:0.2
                 target:self selector:@selector(reshade:) userInfo:nil repeats:NO];
    }
    else {
        [self stop:nil];
        if (sheet != nil) {
            [sheet release];
        }
        sheet = [s retain];
        if (sheet != nil) {
            [sheet setMouseClickTarget:self action:@selector(moveToClicked:)];
        }
        if (midifile != nil) {
            [midifile release];
        }
        midifile = [file retain];
        [options release]; options = nil;
        if (midifile != nil) {
            if (opt != nil) {
                options = [opt retain];
            }
            else {
                options = [[MidiOptions alloc] initFromMidi:midifile];
            }
        }
    }
}

/** If we're paused, reshade the sheet music and piano. */
- (void)reshade:(NSTimer*)arg {
    if (playstate == paused) {
        [sheet shadeNotes:(int)currentPulseTime withPrev:-10 gradualScroll:NO];
        [piano shadeNotes:(int)currentPulseTime withPrev:(int)prevPulseTime];
    }
    [arg invalidate];
}

/** Update the speed label when the speed bar changes */
- (void)speedBarChanged:(NSSlider *)slider {
    NSString *title = [NSString stringWithFormat:@"Speed: %d%", (int)[speedBar doubleValue]];
    [speedLabel setTitle:title];
}


/** Delete the temporary midi sound file */
- (void)deleteSoundFile {
    if (tempSoundFile == nil) {
        return;
    }
    [self stop:nil];
    const char *cfile = [tempSoundFile cStringUsingEncoding:NSUTF8StringEncoding];
    unlink(cfile);
    [tempSoundFile release];
    tempSoundFile = nil;
}
    

/** Return the number of tracks selected in the MidiOptions.
 *  If the number of tracks is 0, there is no sound to play.
 */
- (int)numberTracks {
    int count = 0;
    for (int i = 0; i < [options.tracks count]; i++) {
        if ([options.tracks get:i] && ![options.mute get:i]) {
            count += 1;
        }
    }
    return count;
}


/** Create a new midi sound data with all the MidiOptions incorporated.
 *  Store the new midi sound into the file tempSoundFile.
 */
- (void)createMidiFile {
    [tempSoundFile release];
    tempSoundFile = nil;
    double inverse_tempo = 1.0 / midifile.time.tempo;
    double inverse_tempo_scaled = inverse_tempo * [speedBar doubleValue] / 100.0;
    options.tempo = (int)(1.0 / inverse_tempo_scaled);
    pulsesPerMsec = midifile.time.quarter * (1000.0 / options.tempo);
    tempSoundFile = [midifile.filename stringByAppendingString:@".MSM.mid"];
    tempSoundFile = [tempSoundFile retain];
    if ([midifile changeSound:options toFile:tempSoundFile] == NO) {
        /* Failed to write to tempSoundFile */
        [tempSoundFile release]; tempSoundFile = nil;
    }
}

/** The callback for the play/pause button (a single button).
 *  If we're stopped or pause, then play the midi file.
 *  If we're currently playing, then initiate a pause.
 *  (The actual pause is done when the timer is invoked).
 */
- (IBAction)playPause:(id)sender {
    if (midifile == nil || sheet == nil || [self numberTracks] == 0) {
        return;
    }
    else if (playstate == initStop || playstate == initPause) {
        return;
    }
    else if (playstate == playing) {
        playstate = initPause;
        return;
    }
    else if (playstate == stopped || playstate == paused) {
        /* The startPulseTime is the pulse time of the midi file when
         * we first start playing the music.  It's used during shading.
         */
        if (options.playMeasuresInLoop) {
            /* If we're playing measures in a loop, make sure the
             * currentPulseTime is somewhere inside the loop measures.
             */
            double nearEndTime = currentPulseTime + pulsesPerMsec*50;
            int measure = (int)(nearEndTime / midifile.time.measure);
            if ((measure < options.playMeasuresInLoopStart) ||
                (measure > options.playMeasuresInLoopEnd)) {

                currentPulseTime = options.playMeasuresInLoopStart * 
                                   midifile.time.measure;
            }
            startPulseTime = currentPulseTime;
            options.pauseTime = (int)(currentPulseTime - options.shifttime);
        }
        else if (playstate == paused) {
            startPulseTime = currentPulseTime;
            options.pauseTime = (int)(currentPulseTime - options.shifttime);
        }
        else {
            options.pauseTime = 0;
            startPulseTime = options.shifttime;
            currentPulseTime = options.shifttime;
            prevPulseTime = options.shifttime - midifile.time.quarter;
        }
        [self createMidiFile];
        playstate = playing;
        [sound release];
        sound = [[NSSound alloc] initWithContentsOfFile:tempSoundFile byReference:NO];
        if ([sound respondsToSelector:@selector(setVolume:)] ) {
            [sound setVolume:[volumeBar doubleValue] / 100.0];
        }
        [sound play];
        (void)gettimeofday(&startTime, NULL);
        if (timer != nil) {
            [timer invalidate];
        }
        timer = [NSTimer scheduledTimerWithTimeInterval:0.1
                 target:self selector:@selector(timerCallback:) userInfo:nil repeats:YES];
        [playButton setImage:pauseImage];
        [playButton setToolTip:@"Pause"];
        [sheet shadeNotes:(int)currentPulseTime withPrev:(int)prevPulseTime gradualScroll:YES];
        [piano shadeNotes:(int)currentPulseTime withPrev:(int)prevPulseTime];
        return;
    }
}


/** The callback for the Stop button.
 *  If paused, clear the sound settings and state.
 *  Else, initiate a stop (the actual stop is done in the timer).
 */
- (IBAction)stop:(id)sender {
    if (midifile == nil || sheet == nil || playstate == stopped) {
        return;
    }
    if (playstate == initPause || playstate == initStop || playstate == playing) {
        /* Wait for the timer to finish */
        playstate = initStop;
        usleep(400 * 1000);
        [self doStop];
    }
    else if (playstate == paused) {
        [self doStop];
    }
}

/** Perform the actual stop, by stopping the sound,
 *  removing any shading, and clearing the state.
 */
- (void)doStop {
    playstate = stopped;
    [sound stop];
    [sound release]; sound = nil;
    [self deleteSoundFile];

    /* Remove all shading by redrawing the music */
    [sheet display];
    [piano display];

    startPulseTime = 0;
    currentPulseTime = 0;
    prevPulseTime = 0;
    [playButton setImage:playImage];
    [playButton setToolTip:@"Play"];
    return;
}

/** Rewind the midi music back one measure.
 *  The music must be in the paused state.
 *  When we resume in playPause, we start at the currentPulseTime.
 *  So to rewind, just decrease the currentPulseTime,
 *  and re-shade the sheet music.
 */
- (IBAction)rewind:(id)sender {
    if (midifile == nil || sheet == nil || playstate != paused) {
        return;
    }

    /* Remove any highlighted notes */
    [sheet shadeNotes:-10 withPrev:(int)currentPulseTime gradualScroll:NO];
    [piano shadeNotes:-10 withPrev:(int)currentPulseTime];

    prevPulseTime = currentPulseTime;
    currentPulseTime -= midifile.time.measure;
    if (currentPulseTime < options.shifttime) {
        currentPulseTime = options.shifttime;
    }
    [piano shadeNotes:(int)currentPulseTime withPrev:(int)prevPulseTime];
    [sheet shadeNotes:(int)currentPulseTime withPrev:(int)prevPulseTime gradualScroll:NO];
}

/** Fast forward the midi music by one measure.
 *  The music must be in the paused/stopped state.
 *  When we resume in playPause, we start at the currentPulseTime.
 *  So to fast forward, just increase the currentPulseTime,
 *  and re-shade the sheet music.
 */
- (IBAction)fastForward:(id)sender {
    if (midifile == nil || sheet == nil) {
        return;
    }
    if (playstate != paused && playstate != stopped) {
        return;
    }
    playstate = paused;

    /* Remove any highlighted notes */
    [sheet shadeNotes:-10 withPrev:(int)currentPulseTime gradualScroll:NO];
    [piano shadeNotes:-10 withPrev:(int)currentPulseTime];

    prevPulseTime = currentPulseTime;
    currentPulseTime += midifile.time.measure;
    if (currentPulseTime > midifile.totalpulses) {
        currentPulseTime -= midifile.time.measure;
    }
    [piano shadeNotes:(int)currentPulseTime withPrev:(int)prevPulseTime];
    [sheet shadeNotes:(int)currentPulseTime withPrev:(int)prevPulseTime gradualScroll:NO];
}


/** Move the current position to the location clicked.
 *  The music must be in the paused/stopped state.
 *  When we resume in playPause, we start at the currentPulseTime.
 *  So, set the currentPulseTime to the position clicked.
 */
- (IBAction)moveToClicked:(NSEvent *)event {
    if (midifile == nil || sheet == nil) {
        return;
    }
    if (playstate != paused && playstate != stopped) {
        return;
    }
    playstate = paused;

    /* Remove any highlighted notes */
    [sheet shadeNotes:-10 withPrev:(int)currentPulseTime gradualScroll:NO];
    [piano shadeNotes:-10 withPrev:(int)currentPulseTime];

    NSPoint point = [sheet convertPoint: [event locationInWindow] fromView:nil];
    currentPulseTime = [sheet pulseTimeForPoint:point];
    prevPulseTime = currentPulseTime - midifile.time.measure;
    if (currentPulseTime > midifile.totalpulses) {
        currentPulseTime -= midifile.time.measure;
    }
    [piano shadeNotes:(int)currentPulseTime withPrev:(int)prevPulseTime];
    [sheet shadeNotes:(int)currentPulseTime withPrev:(int)prevPulseTime gradualScroll:NO];
}


/** The callback for the timer. If the midi is still playing,
 *  update the currentPulseTime and shade the sheet music.
 *  If a stop or pause has been initiated (by someone clicking
 *  the stop or pause button), then stop the timer.
 */
- (void)timerCallback:(NSTimer*)arg {
    if (midifile == nil || sheet == nil) {
        [timer invalidate]; timer = nil;
        playstate = stopped;
        return;
    }
    else if (playstate == stopped || playstate == paused) {
        /* This case should never happen */
        [timer invalidate]; timer = nil;
        return;
    }
    else if (playstate == initStop) {
        [timer invalidate]; timer = nil;
        return;
    } 
    else if (playstate == playing) {
        struct timeval now;
        gettimeofday(&now, NULL);
        long msec = (now.tv_sec - startTime.tv_sec)*1000 +
                    (now.tv_usec - startTime.tv_usec)/1000;
        prevPulseTime = currentPulseTime;
        currentPulseTime = startPulseTime + msec * pulsesPerMsec;

        /* If we're playing in a loop, stop and restart */
        if (options.playMeasuresInLoop) {
            int measure = (int)(currentPulseTime / midifile.time.measure);
            if (measure > options.playMeasuresInLoopEnd) {
                [self restartPlayMeasuresInLoop];
                return;
            }
        }

        /* Stop if we've reached the end of the song */
        if (currentPulseTime > midifile.totalpulses) {
            [timer invalidate]; timer = nil;
            [self doStop]; 
            return;
        }
        [sheet shadeNotes:(int)currentPulseTime withPrev:(int)prevPulseTime gradualScroll:YES];
        [piano shadeNotes:(int)currentPulseTime withPrev:(int)prevPulseTime];
        return;
    }
    else if (playstate == initPause) {
        [timer invalidate]; timer = nil;
        struct timeval now;
        gettimeofday(&now, NULL);
        long msec = (now.tv_sec - startTime.tv_sec)*1000 + 
                    (now.tv_usec - startTime.tv_usec)/1000;

        [sound stop];
        [sound release]; sound = nil;

        prevPulseTime = currentPulseTime;
        currentPulseTime = startPulseTime + msec * pulsesPerMsec;
        [sheet shadeNotes:(int)currentPulseTime withPrev:(int)prevPulseTime gradualScroll:YES];
        [piano shadeNotes:(int)currentPulseTime withPrev:(int)prevPulseTime];
        prevPulseTime = currentPulseTime - midifile.time.measure;
        [playButton setImage:playImage];
        [playButton setToolTip:@"Play"];
        playstate = paused;
        return;
    }
}

/** The "Play Measures in a Loop" feature is enabled, and we've reached
 *  the last measure. Stop the sound, and then start playing again.
 */
-(void)restartPlayMeasuresInLoop {
    [timer invalidate]; timer = nil;
    [self doStop];
    NSTimer *playTimer = [NSTimer scheduledTimerWithTimeInterval:0.4
                 target:self selector:@selector(replay:) userInfo:nil repeats:NO];
}

-(void)replay:(NSTimer*)arg {
    [self playPause:NULL];
}

/** Callback for volume bar.  Adjust the volume if the midi sound
 *  is currently playing.
 */
- (IBAction)changeVolume:(id)sender {
    double value = [volumeBar doubleValue] / 100.0;
    if (playstate == playing && sound != nil) {
        if ([sound respondsToSelector:@selector(setVolume:)] ) {
            [sound setVolume:value];
        }
    }
}

/** This view uses flipped coordinates, where upper-left corner is (0,0) */
- (BOOL)isFlipped {
    return YES;
}

- (void)dealloc {
    [self deleteSoundFile];
    [playButton release]; 
    [stopButton release];
    [rewindButton release];
    [fastFwdButton release];
    [speedBar release];
    [speedLabel release];
    [volumeBar release];
    [midifile release];
    [sheet release]; 
    [piano release];
    [sound release];
    [tempSoundFile release];
    if (timer != nil) {
        [timer invalidate];
    }
    [super dealloc];
}

@end


