#import <Foundation/NSDictionary.h>
#import "IntArray.h"
#import "Array.h"

@interface NSMutableDictionary (Extensions)

- (void)setBool:(BOOL)value forKey:(id)key;
- (void)setInt:(int)value forKey:(id)key;
- (void)setIntArray:(IntArray *)value forKey:(id)key;
- (void)setColor:(NSColor *)value forKey:(id)key;
- (void)setColors:(Array *)value forKey:(id)key;

@end

