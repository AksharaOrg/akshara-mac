#import <Foundation/Foundation.h>

@interface SmartPhoneticMaps : NSObject

+ (NSDictionary<NSString *, NSString *> *)smartConsonants;
+ (NSDictionary<NSString *, NSString *> *)smartVowels;
+ (NSDictionary<NSString *, NSString *> *)smartVowelSigns;
+ (NSArray<NSString *> *)smartConsonantKeys;
+ (NSArray<NSString *> *)smartVowelKeys;

@end
