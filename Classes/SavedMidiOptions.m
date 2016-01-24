#import "SavedMidiOptions.h"
#import "JSONKit.h"
#import "NSDictionary+Extensions.h"
#import "NSMutableDictionary+Extensions.h"
#import "MidiFile.h"

const NSString *settingsFile = @"midisheetmusic.settings";

@implementation SavedMidiOptions

static SavedMidiOptions *_globalSavedMidiOptions = nil;

+ (SavedMidiOptions *)shared
{
    if (_globalSavedMidiOptions == nil) {
        _globalSavedMidiOptions = [[SavedMidiOptions alloc] init];
    }
    return _globalSavedMidiOptions;
}

- (id)init
{
    self = [super init];
    [self loadAllOptions];
	return self;
}

- (void)dealloc
{
    [savedOptions release]; savedOptions = nil;
    [super dealloc];
}

/* Load an array of MidiOptions from midisheetmusic.settings.json */
- (void)loadAllOptions
{
    savedOptions = [[NSMutableArray alloc] init];
    NSString *filename = [[NSBundle mainBundle] pathForResource:settingsFile ofType:@"json"];
    if (filename == nil) {
        return;
    }
    NSData *data = [NSData dataWithContentsOfFile:filename];
    if (data != nil && [data length] > 0) {
        @try {
            JSONDecoder *decoder = [[[JSONDecoder alloc] initWithParseOptions:0] autorelease];
            NSArray *array = [decoder objectWithData:data];
            [savedOptions addObjectsFromArray:array];
        }
        @catch (NSException *e) {
        }
    }
}

/* Save the options for the given MidiFile */
- (void)saveOptions:(MidiOptions *)options
{
    // Remove the existing entry for this options
    for (int i = 0; i < [savedOptions count]; i++) {
        NSDictionary *dict = [savedOptions objectAtIndex:i];
        if (dict != nil && [[dict objectForKey:@"title"] isEqual:options.title]) {
            [savedOptions removeObject:dict];
            break;
        }
    }

    // Add a new entry for this options, at the front
    [savedOptions insertObject:[options toDict] atIndex:0];
    if ([savedOptions count] > 20) {
        NSArray *subarray = [savedOptions subarrayWithRange:NSMakeRange(0, 20)];
        savedOptions = [NSMutableArray array];
        [savedOptions addObjectsFromArray:subarray];
    }
    NSString *jsonString = [savedOptions JSONString];
    NSString *filename = [[NSBundle mainBundle] pathForResource:settingsFile ofType:@"json"];
    if (jsonString != nil) {
        NSError *error = nil;
        @try {
            [jsonString writeToFile:filename atomically:YES encoding:NSUTF8StringEncoding error:&error];
        }
        @catch (NSException *e) {
        }
    }
}

/* Load the options for the given MidiFile */
- (MidiOptions *)loadOptions:(MidiFile *)midifile
{
    NSString *title = [[midifile.filename pathComponents] lastObject];
    for (int i = 0; i < [savedOptions count]; i++) {
        NSDictionary *dict = [savedOptions objectAtIndex:i];
        if (dict != nil && [[dict objectForKey:@"title"] isEqual:title]) {
            MidiOptions *options = [[MidiOptions alloc] initFromDict:dict];
            return [options autorelease];
        }
    }
    return nil;
}


/* Load the first song options from midisheetmusic.settings.json */
- (MidiOptions *)loadFirstOptions
{
    if ([savedOptions count] == 0) {
        return nil;
    }
    NSDictionary *dict = [savedOptions objectAtIndex:0];
    MidiOptions *options = [[MidiOptions alloc] initFromDict:dict];
    return [options autorelease];
}

/* Return a list of the first 10 filenames */
- (Array *)getRecentFilenames
{
    Array *result = [Array new:10];
    int total = 0;
    for (int i = 0; i < [savedOptions count]; i++) {
        NSDictionary *dict = [savedOptions objectAtIndex:i];
        if (dict != nil && [dict objectForKey:@"filename"] != nil) {
            [result add:[dict objectForKey:@"filename"]];
        }
        if (total >= 10) {
            break;
        }
    }
    return result; 
}

@end

