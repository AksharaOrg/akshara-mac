#import <Foundation/Foundation.h>

@interface AutoUpdater : NSObject

+ (instancetype)sharedUpdater;
- (void)startCheckingForUpdates;
- (void)checkForUpdatesNow;
- (void)checkForUpdatesManually;
- (BOOL)isUpdateAvailable;
- (NSString *)availableVersion;
- (void)downloadAndInstallUpdate;

@end
