#import "MidiOptions.h"
#import "JSONKit.h"
#import "NSDictionary+Extensions.h"
#import "NSMutableDictionary+Extensions.h"
#import "MidiFile.h"

@implementation MidiOptions

@synthesize filename;
@synthesize title;
@synthesize tracks;
@synthesize scrollVert;
@synthesize numtracks;
@synthesize largeNoteSize;
@synthesize twoStaffs;
@synthesize showNoteLetters;
@synthesize showLyrics;
@synthesize showMeasures;
@synthesize shifttime;
@synthesize transpose;
@synthesize key;
@synthesize time;
@synthesize combineInterval;
@synthesize colors;
@synthesize shadeColor;
@synthesize shade2Color;
@synthesize mute;
@synthesize tempo;
@synthesize pauseTime;
@synthesize instruments;
@synthesize useDefaultInstruments;
@synthesize playMeasuresInLoop;
@synthesize playMeasuresInLoopStart;
@synthesize playMeasuresInLoopEnd;

- (void)dealloc
{
    self.filename = nil;
    self.title = nil;
    self.tracks = nil;
    self.time = nil;
    self.colors = nil;
    self.shadeColor = nil;
    self.shade2Color = nil;
    self.mute = nil;
    self.instruments = nil;
    [super dealloc];
}

/* Initialize the default options given the midi file */
- (MidiOptions *)initFromMidi:(MidiFile *)midifile
{
    self = [super init];
    self.filename = midifile.filename;
    self.title = [[midifile.filename pathComponents] lastObject];
    numtracks = [midifile.tracks count];
    self.tracks = [IntArray new:numtracks];
    self.mute = [IntArray new:numtracks];
    self.instruments = [IntArray new:numtracks];
    for (int i = 0; i < [midifile.tracks count]; i++) {
        MidiTrack *track = [midifile.tracks get:i];
        [self.tracks add:1];
        [self.mute add:0];
        [self.instruments add: track.instrument];
        if (track.instrument == 128) { /* Percussion */
            [self.tracks set:0 index:i];
			[self.mute set:1 index:i];
        }
    }
    self.useDefaultInstruments = YES;
    self.scrollVert = YES;
    self.largeNoteSize = NO;
    if ([self.tracks count] == 1) {
        self.twoStaffs = YES;
    }
    else {
        self.twoStaffs = NO;
    }
    self.showNoteLetters = 0;
    self.showMeasures = NO;
    self.shifttime = NO;
    self.transpose = NO;
    self.key = -1;
    self.time = time;
    self.colors = nil;
    self.shadeColor = [NSColor colorWithDeviceRed:210.0/255.0
                     green:205.0/255.0 blue:220.0/255.0 alpha:1.0];
    self.shade2Color = [NSColor colorWithDeviceRed:150.0/255.0
                     green:190.0/255.0 blue:220.0/255.0 alpha:1.0];
    self.combineInterval = 40;
    self.tempo = time.tempo;
    self.pauseTime = 0;
    self.playMeasuresInLoop = NO;
    self.playMeasuresInLoopStart = NO;
    self.playMeasuresInLoopEnd = midifile.endTime / midifile.time.measure;
    return self;
}

/* Initialize the MidiOptions from a JSON Dictionary */
- (MidiOptions *)initFromDict:(NSDictionary *)dict
{
    self.filename = (NSString *)[dict objectForKey:@"filename"];
    self.title = (NSString *)[dict objectForKey:@"title"];
    self.tracks = [dict intArrayForKey:@"tracks"];
    self.scrollVert = [dict boolForKey:@"scrollVert"];
    self.largeNoteSize = [dict boolForKey:@"largeNoteSize"];
    self.twoStaffs = [dict boolForKey:@"twoStaffs"];
    self.showNoteLetters = [dict intForKey:@"showNoteLetters"];
    self.showLyrics = [dict boolForKey:@"showLyrics"];
    self.showMeasures = [dict boolForKey:@"showMeasures"];
    self.shifttime = [dict intForKey:@"shifttime"];
    self.transpose = [dict intForKey:@"transpose"];
    self.key = [dict intForKey:@"key"];
    // self.time = [dict objectForKey:@"time"];
    self.combineInterval = [dict intForKey:@"combineInterval"];
    self.colors = [dict colorsForKey:@"colors"];
    self.shadeColor = [dict colorForKey:@"shadeColor"];
    self.shade2Color = [dict colorForKey:@"shade2Color"];
    self.mute = [dict intArrayForKey:@"mute"];
    self.tempo = [dict intForKey:@"tempo"];
    self.pauseTime = [dict intForKey:@"pauseTime"];
    self.instruments = [dict intArrayForKey:@"instruments"];
    self.useDefaultInstruments = [dict boolForKey:@"useDefaultInstruments"];
    self.playMeasuresInLoop = [dict boolForKey:@"playMeasuresInLoop"];
    self.playMeasuresInLoopStart = [dict intForKey:@"playMeasuresInLoopStart"];
    self.playMeasuresInLoopEnd = [dict intForKey:@"playMeasuresInLoopEnd"];

    return self;
}

/* Convert the options to a JSON Dictionary */
- (NSDictionary *)toDict
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:@"2.6.0" forKey:@"version"];
    [dict setValue:filename forKey:@"filename"];
    [dict setValue:title forKey:@"title"];
    [dict setIntArray:tracks forKey:@"tracks"];
    [dict setBool:scrollVert forKey:@"scrollVert"];
    [dict setInt:numtracks forKey:@"numtracks"];
    [dict setBool:largeNoteSize forKey:@"largeNoteSize"];
    [dict setBool:twoStaffs forKey:@"twoStaffs"];
    [dict setInt:showNoteLetters forKey:@"showNoteLetters"];
    [dict setBool:showLyrics forKey:@"showLyrics"];
    [dict setBool:showMeasures forKey:@"showMeasures"];
    [dict setInt:shifttime forKey:@"shifttime"];
    [dict setInt:transpose forKey:@"transpose"];
    [dict setInt:key forKey:@"key"];
    // [dict setValue:time forKey:@"time"];
    [dict setInt:combineInterval forKey:@"combineInterval"];
    [dict setColors:colors forKey:@"colors"];
    [dict setColor:shadeColor forKey:@"shadeColor"];
    [dict setColor:shade2Color forKey:@"shade2Color"];
    [dict setIntArray:mute forKey:@"mute"];
    [dict setInt:tempo forKey:@"tempo"];
    [dict setInt:pauseTime forKey:@"pauseTime"];
    [dict setIntArray:instruments forKey:@"instruments"];
    [dict setBool:useDefaultInstruments forKey:@"useDefaultInstruments"];
    [dict setBool:playMeasuresInLoop forKey:@"playMeasuresInLoop"];
    [dict setInt:playMeasuresInLoopStart forKey:@"playMeasuresInLoopStart"];
    [dict setInt:playMeasuresInLoopEnd forKey:@"playMeasuresInLoopEnd"];
    return dict;
}

/* Merge in the saved options to this MidiOptions */
- (void)merge:(MidiOptions *)saved
{
    if (saved.tracks != nil && [saved.tracks count] == [tracks count]) {
        for (int i = 0; i < [tracks count]; i++) {
            int value = [saved.tracks get:i];
            [tracks set:value index:i];
        }
    }
    if (saved.mute != nil && [saved.mute count] == [mute count]) {
        for (int i = 0; i < [mute count]; i++) {
            int value = [saved.mute get:i];
            [mute set:value index:i];
        }
    }
    if (saved.instruments != nil && [saved.instruments count] == [instruments count]) {
        for (int i = 0; i < [instruments count]; i++) {
            int value = [saved.instruments get:i];
            [instruments set:value index:i];
        }
    }
    // if (saved.time != nil) {
    //    time = [[TimeSignature alloc] initWithNumerator:saved.time.numerator 
    //                                  andDenominator:saved.time.denominator,
    //                                  andQuarter:saved.time.Quarter 
    //                                  andTempo:saved.time.Tempo];
    // }
    useDefaultInstruments = saved.useDefaultInstruments;
    scrollVert = saved.scrollVert;
    largeNoteSize = saved.largeNoteSize;
    showLyrics = saved.showLyrics;
    twoStaffs = saved.twoStaffs;
    showNoteLetters = saved.showNoteLetters;
    transpose = saved.transpose;
    key = saved.key;
    combineInterval = saved.combineInterval;
    if (saved.shadeColor != nil) {
        self.shadeColor = saved.shadeColor;
    }
    if (saved.shade2Color != nil) {
        self.shade2Color = saved.shade2Color;
    }
    if (saved.colors != nil) {
        self.colors = saved.colors;
    }
    showMeasures = saved.showMeasures;
    playMeasuresInLoop = saved.playMeasuresInLoop;
    playMeasuresInLoopStart = saved.playMeasuresInLoopStart;
    playMeasuresInLoopEnd = saved.playMeasuresInLoopEnd;
}

- (id)copyWithZone:(NSZone *)zone
{
    MidiOptions *options = [[MidiOptions alloc] init];
    options.filename = filename;
    options.title = title;
    options.tracks = [tracks clone];
    options.scrollVert = scrollVert;
    options.numtracks = numtracks;
    options.largeNoteSize = largeNoteSize;
    options.twoStaffs = twoStaffs;
    options.showNoteLetters = showNoteLetters;
    options.showLyrics = showLyrics;
    options.showMeasures = showMeasures;
    options.shifttime = shifttime;
    options.transpose = transpose;
    options.key = key;
    //options.time = time;
    options.combineInterval = combineInterval;
    options.colors = colors;
    options.shadeColor = shadeColor;
    options.shade2Color = shade2Color;
    options.mute = [mute clone];
    options.tempo = tempo;
    options.pauseTime = pauseTime;
    options.instruments = [instruments clone];
    options.useDefaultInstruments = useDefaultInstruments;
    options.playMeasuresInLoop = playMeasuresInLoop;
    options.playMeasuresInLoopStart = playMeasuresInLoopStart;
    options.playMeasuresInLoopEnd = playMeasuresInLoopEnd;
    return options;
}


@end

