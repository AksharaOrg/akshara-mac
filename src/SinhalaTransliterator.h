#import <Foundation/Foundation.h>

@interface SinhalaTransliterator : NSObject
+ (NSString *)transliteratePhonetic:(NSString *)input;
+ (NSString *)transliterateSmartPhonetic:(NSString *)input;
+ (NSString *)slsCharacterForInput:(NSString *)input shifted:(BOOL)shifted altGr:(BOOL)altGr;
+ (NSString *)normalizeSLSInputOrder:(NSString *)input;
+ (BOOL)isSinhalaInputUnit:(NSString *)input;
@end
