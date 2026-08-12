#import "AutoUpdater.h"
#import <UserNotifications/UserNotifications.h>
#import <AppKit/AppKit.h>

@interface AutoUpdater () <UNUserNotificationCenterDelegate>
@property (nonatomic, strong) NSString *downloadUrl;
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
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        (void)response;
        if (error || !data) return;
        
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if (![json isKindOfClass:[NSDictionary class]]) return;
        
        NSString *tagName = json[@"tag_name"];
        if (!tagName) return;
        
        if ([tagName hasPrefix:@"v"]) {
            tagName = [tagName substringFromIndex:1];
        }
        
        NSString *currentVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        if (!currentVersion) return;
        
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
                self.downloadUrl = pkgUrl;
                [self showUpdateNotificationForVersion:tagName];
            }
        } else if (isManual) {
            [self showUpToDateNotification];
        }
    }];
    [task resume];
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
