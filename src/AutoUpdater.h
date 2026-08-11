#import <Foundation/Foundation.h>

@interface AutoUpdater : NSObject

+ (instancetype)sharedUpdater;
- (void)startCheckingForUpdates;
- (void)checkForUpdatesNow;

@end
