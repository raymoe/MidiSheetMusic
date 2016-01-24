#import "NSMutableDictionary+Extensions.h"

@implementation NSMutableDictionary (Extensions)

- (void)setBool:(BOOL)value forKey:(id)key
{
    [self setValue:[NSNumber numberWithBool:value] forKey:key];
}

- (void)setInt:(int)value forKey:(id)key
{
    [self setValue:[NSNumber numberWithInt:value] forKey:key];
}

- (void)setIntArray:(IntArray *)value forKey:(id)key
{
    [self setValue:[value toArray] forKey:key];
}

- (NSArray *)colorToArray:(NSColor *)color
{
    int red   = (int)([color redComponent] * 255);
    int green = (int)([color greenComponent] * 255);
    int blue  = (int)([color blueComponent] * 255);
    NSArray *array = [NSArray arrayWithObjects:
      [NSNumber numberWithInt:red],
      [NSNumber numberWithInt:green],
      [NSNumber numberWithInt:blue], nil];
    return array;
}

- (void)setColor:(NSColor *)color forKey:(id)key
{
    [self setValue:[self colorToArray:color] forKey:key];
}

- (void)setColors:(Array *)colors forKey:(id)key
{
    NSMutableArray *array = [NSMutableArray array];
    for (int i = 0; i < [colors count]; i++) {
        NSColor *color = [colors get:i];
        NSArray *colorArray = [self colorToArray:color];
        [array addObject:colorArray];
    }
    [self setValue:array forKey:key];
}

@end

