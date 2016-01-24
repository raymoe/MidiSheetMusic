#import "NSDictionary+Extensions.h"

@implementation NSDictionary (Extensions)

- (NSString *)stringForKey:(id)key
{
    NSString *result = [self objectForKey:key];
    if ([result isKindOfClass:[NSString class]]) {
        return result;
    }
    else {
        return nil;
    }
}

- (BOOL)boolForKey:(id)key
{
    NSNumber *result = [self objectForKey:key];
    if (result != nil && [result isKindOfClass:[NSNumber class]]) {
        return [result boolValue];
    }
    else {
        return NO;
    }
}

- (int)intForKey:(id)key
{
    NSNumber *result = [self objectForKey:key];
    if (result != nil && [result isKindOfClass:[NSNumber class]]) {
        return [result intValue];
    }
    else {
        return 0;
    }
}

- (IntArray *)intArrayForKey:(id)key
{
    NSArray *array = [self objectForKey:key];
    if (array == nil) {
        return nil;
    }
    IntArray *intarray = [[IntArray alloc] initFromArray:array];
    return [intarray autorelease];
}

- (NSColor *)arrayToColor:(NSArray *)array
{
    if (array == nil || [array count] != 3) {
        return nil;
    }
    int red, green, blue;
    NSNumber *num;
    num = [array objectAtIndex:0];
    red = [num intValue];
    num = [array objectAtIndex:1];
    green = [num intValue];
    num = [array objectAtIndex:2];
    blue = [num intValue];

    return [NSColor colorWithDeviceRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:1.0];
}

- (NSColor *)colorForKey:(id)key
{
    NSArray *array = [self objectForKey:key];
    return [self arrayToColor:array];
}

- (Array *)colorsForKey:(id)key
{
    NSArray *array = [self objectForKey:key];
    Array *colors = [Array new:12];
    for (int i = 0; i < [array count]; i++) {
        NSArray *colorArray = [array objectAtIndex:i];
        NSColor *color = [self arrayToColor:colorArray];
        if (color != nil) {
            [colors add:color];
        }
    }
    if ([colors count] == 12) {
        return colors;
    }
    return nil;
}

@end

