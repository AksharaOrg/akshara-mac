#import "AutoUpdater.h"
#import <UserNotifications/UserNotifications.h>
#import <AppKit/AppKit.h>

static NSString * const AksharaUpdateDownloadURLKey = @"AksharaUpdateDownloadURL";
static NSString * const AksharaUpdateVersionKey = @"AksharaUpdateVersion";
static NSString * const AksharaLastNotifiedVersionKey = @"AksharaLastNotifiedVersion";
static NSString * const AksharaUpdatePackageSigner = @"Developer ID Installer: Lahiru Himesh Madusanka Siddha Dewayala Gedara (8292UX7379)";

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

        dispatch_async(dispatch_get_main_queue(), ^{
            [NSTimer scheduledTimerWithTimeInterval:3600
                                             target:self
                                           selector:@selector(checkForUpdatesNow)
                                           userInfo:nil
                                            repeats:YES];
        });
    });
}

- (void)checkForUpdatesNow {
    
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
            NSString *expectedPackageName = [NSString stringWithFormat:@"Akshara-v%@.pkg", tagName];
            for (NSDictionary *asset in assets) {
                NSString *name = asset[@"name"];
                if ([name isEqualToString:expectedPackageName]) {
                    pkgUrl = asset[@"browser_download_url"];
                    break;
                }
            }
            
            if (pkgUrl) {
                self.downloadUrl = pkgUrl;
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setObject:pkgUrl forKey:AksharaUpdateDownloadURLKey];
                [defaults setObject:tagName forKey:AksharaUpdateVersionKey];

                if (![[defaults stringForKey:AksharaLastNotifiedVersionKey] isEqualToString:tagName]) {
                    [self showUpdateNotificationForVersion:tagName];
                    [defaults setObject:tagName forKey:AksharaLastNotifiedVersionKey];
                }
            }
        }
    }];
    [task resume];
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
    NSString *downloadURLString = self.downloadUrl ?: [[NSUserDefaults standardUserDefaults] stringForKey:AksharaUpdateDownloadURLKey];
    if (!downloadURLString) return;
    
    NSURL *url = [NSURL URLWithString:downloadURLString];
    if (![url.scheme isEqualToString:@"https"] || !url.host.length) return;

    self.downloadTask = [[NSURLSession sharedSession] downloadTaskWithURL:url completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        (void)response;
        if (error || !location) return;
        
        NSString *tempDir = NSTemporaryDirectory();
        NSString *fileName = [NSString stringWithFormat:@"Akshara-Update-%@.pkg", [NSUUID UUID].UUIDString];
        NSString *destPath = [tempDir stringByAppendingPathComponent:fileName];
        NSURL *destURL = [NSURL fileURLWithPath:destPath];
        
        NSFileManager *fm = [NSFileManager defaultManager];
        
        if ([fm moveItemAtURL:location toURL:destURL error:nil]) {
            if (![self isTrustedUpdatePackageAtURL:destURL]) {
                [fm removeItemAtURL:destURL error:nil];
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSWorkspace sharedWorkspace] openURL:destURL];
            });
        }
    }];
    [self.downloadTask resume];
}

- (BOOL)isTrustedUpdatePackageAtURL:(NSURL *)packageURL {
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/sbin/pkgutil";
    task.arguments = @[@"--check-signature", packageURL.path];

    NSPipe *output = [NSPipe pipe];
    task.standardOutput = output;
    task.standardError = output;

    @try {
        [task launch];
        [task waitUntilExit];
    } @catch (NSException *exception) {
        return NO;
    }

    NSData *data = [[output fileHandleForReading] readDataToEndOfFile];
    NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return task.terminationStatus == 0 &&
           [result containsString:AksharaUpdatePackageSigner] &&
           [result containsString:@"Notarization: trusted by the Apple notary service"];
}

@end
