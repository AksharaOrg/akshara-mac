#import "AutoUpdater.h"
#import <UserNotifications/UserNotifications.h>
#import <AppKit/AppKit.h>

@interface AutoUpdater () <UNUserNotificationCenterDelegate>
@property (nonatomic, strong) NSString *downloadUrl;
@property (nonatomic, strong) NSString *availableVersion;
@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;
@end

@implementation AutoUpdater

+ (instancetype)sharedUpdater {
    static AutoUpdater *sharedUpdater = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedUpdater = [[self alloc] init];
    });
    return sharedUpdater;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        center.delegate = self;
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound)
                              completionHandler:^(BOOL granted, NSError * _Nullable error) {
                                  (void)granted;
                                  (void)error;
                              }];
    }
    return self;
}

- (void)startCheckingForUpdates {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self checkForUpdatesNow];
        
        [NSTimer scheduledTimerWithTimeInterval:3600
                                         target:self
                                       selector:@selector(checkForUpdatesNow)
                                       userInfo:nil
                                        repeats:YES];
    });
}

- (void)checkForUpdatesManually {
    [self checkForUpdatesWithManualFlag:YES];
}

- (void)checkForUpdatesNow {
    [self checkForUpdatesWithManualFlag:NO];
}

- (void)checkForUpdatesWithManualFlag:(BOOL)isManual {
    
    NSURL *url = [NSURL URLWithString:@"https://api.github.com/repos/AksharaOrg/akshara-mac/releases/latest"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (error || !data || httpResponse.statusCode != 200) {
            if (isManual) {
                [self showManualCheckError];
            }
            return;
        }
        
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if (![json isKindOfClass:[NSDictionary class]]) {
            if (isManual) {
                [self showManualCheckError];
            }
            return;
        }
        
        NSString *tagName = json[@"tag_name"];
        if (!tagName) {
            if (isManual) {
                [self showManualCheckError];
            }
            return;
        }
        
        if ([tagName hasPrefix:@"v"]) {
            tagName = [tagName substringFromIndex:1];
        }
        
        NSString *currentVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        if (!currentVersion) {
            if (isManual) {
                [self showManualCheckError];
            }
            return;
        }
        
        if ([tagName compare:currentVersion options:NSNumericSearch] == NSOrderedDescending) {
            NSArray *assets = json[@"assets"];
            NSString *pkgUrl = nil;
            for (NSDictionary *asset in assets) {
                NSString *name = asset[@"name"];
                if ([name hasSuffix:@".pkg"]) {
                    pkgUrl = asset[@"browser_download_url"];
                    break;
                }
            }
            
            if (pkgUrl) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.downloadUrl = pkgUrl;
                    self.availableVersion = tagName;
                    [self showUpdateNotificationForVersion:tagName];
                    if (isManual) {
                        [self showManualUpdateAlertForVersion:tagName];
                    }
                });
            } else if (isManual) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSAlert *alert = [[NSAlert alloc] init];
                    alert.messageText = @"Update Available";
                    alert.informativeText = [NSString stringWithFormat:@"Version %@ is released but the installer package is not available yet. Please try again later.", tagName];
                    [alert addButtonWithTitle:@"OK"];
                    [alert runModal];
                });
            }
        } else if (isManual) {
            [self showUpToDateNotification];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showManualUpToDateAlertForCurrent:currentVersion latest:tagName];
            });
        }
    }];
    [task resume];
}

- (BOOL)isUpdateAvailable {
    return self.downloadUrl.length > 0 && self.availableVersion.length > 0;
}

- (void)showManualUpdateAlertForVersion:(NSString *)version {
    NSString *currentVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Akshara Update Available";
    alert.informativeText = [NSString stringWithFormat:@"Your current Akshara version is %@. Version %@ is ready to install.", currentVersion ?: @"Unknown", version];
    [alert addButtonWithTitle:@"Install Update"];
    [alert addButtonWithTitle:@"Later"];
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        [self downloadAndInstallUpdate];
    }
}

- (void)showManualUpToDateAlertForCurrent:(NSString *)current latest:(NSString *)latest {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Akshara is up to date.";
    alert.informativeText = [NSString stringWithFormat:@"You are already running the latest version of Akshara. There are currently no updates available.\n\nAkshara v%@", current];
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}

- (void)showManualCheckError {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Unable to Check for Updates";
        alert.informativeText = @"Please check your internet connection and try again.";
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
    });
}

- (void)showUpToDateNotification {
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = @"Akshara is Up to Date";
    content.body = @"You are already running the latest version of Akshara.";
    content.sound = [UNNotificationSound defaultSound];
    
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"AksharaUpToDate"
                                                                          content:content
                                                                          trigger:nil];
    
    [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:nil];
}

- (void)showUpdateNotificationForVersion:(NSString *)version {
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = @"Akshara Update Available";
    content.body = [NSString stringWithFormat:@"Version %@ is now available. Click to install.", version];
    content.sound = [UNNotificationSound defaultSound];
    
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"AksharaUpdate"
                                                                          content:content
                                                                          trigger:nil];
    
    [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:nil];
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
         withCompletionHandler:(void (^)(void))completionHandler {
    
    if ([response.notification.request.identifier isEqualToString:@"AksharaUpdate"]) {
        [self downloadAndInstallUpdate];
    }
    completionHandler();
}

- (void)downloadAndInstallUpdate {
    if (!self.downloadUrl) return;
    
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = @"Downloading Update";
    content.body = @"Akshara is downloading the latest update. It will open automatically when ready.";
    content.sound = [UNNotificationSound defaultSound];
    UNNotificationRequest *req = [UNNotificationRequest requestWithIdentifier:@"AksharaDownloading" content:content trigger:nil];
    [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:req withCompletionHandler:nil];
    
    NSURL *url = [NSURL URLWithString:self.downloadUrl];
    NSURLSessionDownloadTask *downloadTask = [[NSURLSession sharedSession] downloadTaskWithURL:url completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        (void)response;
        if (error || !location) return;
        
        NSString *tempDir = NSTemporaryDirectory();
        NSString *destPath = [tempDir stringByAppendingPathComponent:@"Akshara-Update.pkg"];
        NSURL *destURL = [NSURL fileURLWithPath:destPath];
        
        NSFileManager *fm = [NSFileManager defaultManager];
        [fm removeItemAtURL:destURL error:nil];
        
        if ([fm moveItemAtURL:location toURL:destURL error:nil]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSWorkspace sharedWorkspace] openURL:destURL];
            });
        }
    }];
    [downloadTask resume];
}

@end
