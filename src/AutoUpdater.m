#import "AutoUpdater.h"
#import <UserNotifications/UserNotifications.h>
#import <AppKit/AppKit.h>

// A-01: Expected Team ID embedded in the binary — verified before opening any package.
static NSString * const kExpectedTeamID     = @"8292UX7379";
static NSString * const kExpectedCertPrefix = @"Developer ID Installer:";
// A-01: Only accept download URLs from these GitHub-owned hosts.
static NSArray<NSString *> *allowedAssetHosts(void) {
    return @[@"objects.githubusercontent.com",
             @"github.com",
             @"github-releases.githubusercontent.com"];
}

@interface AutoUpdater () <UNUserNotificationCenterDelegate>
@property (nonatomic, strong) NSString *downloadUrl;
@property (nonatomic, strong) NSString *availableVersion;
@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;
// A-03: Track staging directory so we can clean it up on cancel or failure.
@property (nonatomic, strong) NSString *stagingDirectory;
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


// A-01: Validate that a URL has an HTTPS scheme and is on an allowed GitHub host.
- (BOOL)isAllowedURL:(NSURL *)url {
    if (!url) return NO;
    if (![url.scheme isEqualToString:@"https"]) return NO;
    NSString *host = url.host;
    if (!host) return NO;
    for (NSString *allowed in allowedAssetHosts()) {
        if ([host isEqualToString:allowed] ||
            [host hasSuffix:[@"." stringByAppendingString:allowed]]) {
            return YES;
        }
    }
    return NO;
}

- (void)checkForUpdatesWithManualFlag:(BOOL)isManual {
    NSURL *apiURL = [NSURL URLWithString:@"https://api.github.com/repos/AksharaOrg/akshara-mac/releases/latest"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:apiURL
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:30];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (error || !data || httpResponse.statusCode != 200) {
            if (isManual) { [self showManualCheckError]; }
            return;
        }
        // A-01: Confirm response came from an allowed host (redirect check).
        if (![self isAllowedURL:httpResponse.URL]) {
            if (isManual) { [self showManualCheckError]; }
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
        // A-01: Validate tagName type.
        if (![tagName isKindOfClass:[NSString class]] || tagName.length == 0) {
            if (isManual) { [self showManualCheckError]; }
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
            if (![assets isKindOfClass:[NSArray class]]) {
                if (isManual) { [self showManualCheckError]; }
                return;
            }
            NSString *pkgUrl = nil;
            // A-01: Match exact expected asset filename (Akshara-vX.Y.Z.pkg), not just any .pkg.
            NSString *expectedName = [NSString stringWithFormat:@"Akshara-v%@.pkg", tagName];
            for (NSDictionary *asset in assets) {
                if (![asset isKindOfClass:[NSDictionary class]]) continue;
                NSString *name = asset[@"name"];
                if ([name isKindOfClass:[NSString class]] && [name isEqualToString:expectedName]) {
                    NSString *candidate = asset[@"browser_download_url"];
                    if (![candidate isKindOfClass:[NSString class]]) break;
                    // A-01: Validate asset download URL host before storing.
                    NSURL *candidateURL = [NSURL URLWithString:candidate];
                    if ([self isAllowedURL:candidateURL]) {
                        pkgUrl = candidate;
                    }
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
    if (!self.downloadUrl || !self.availableVersion) return;

    // A-01: Re-validate URL immediately before starting download.
    NSURL *url = [NSURL URLWithString:self.downloadUrl];
    if (![self isAllowedURL:url]) {
        NSLog(@"[AutoUpdater] Rejected disallowed download URL: %@", url);
        return;
    }

    NSString *expectedVersion = self.availableVersion;

    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = @"Downloading Update";
    content.body = @"Akshara is downloading the latest update. It will open automatically when ready.";
    content.sound = [UNNotificationSound defaultSound];
    [[UNUserNotificationCenter currentNotificationCenter]
        addNotificationRequest:[UNNotificationRequest requestWithIdentifier:@"AksharaDownloading"
                                                                    content:content trigger:nil]
             withCompletionHandler:nil];

    // A-03: Private, randomly-named staging directory (mode 0700) prevents same-user
    // processes from predicting or replacing the downloaded file before it is opened.
    NSString *uuid = [[NSUUID UUID] UUIDString];
    NSString *stagingDir = [NSTemporaryDirectory() stringByAppendingPathComponent:uuid];
    NSError *mkdirError = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:stagingDir
                                withIntermediateDirectories:YES
                                               attributes:@{NSFilePosixPermissions: @(0700)}
                                                    error:&mkdirError];
    if (mkdirError) {
        NSLog(@"[AutoUpdater] Failed to create staging directory: %@", mkdirError);
        return;
    }
    self.stagingDirectory = stagingDir;

    NSString *pkgName  = [NSString stringWithFormat:@"Akshara-v%@.pkg", expectedVersion];
    NSString *destPath = [stagingDir stringByAppendingPathComponent:pkgName];
    NSURL    *destURL  = [NSURL fileURLWithPath:destPath];

    NSURLSessionDownloadTask *downloadTask = [[NSURLSession sharedSession]
        downloadTaskWithURL:url
          completionHandler:^(NSURL *location, NSURLResponse *response, NSError *dlError) {

        if (dlError || !location) {
            NSLog(@"[AutoUpdater] Download failed: %@", dlError);
            [self cleanupStagingDirectory:stagingDir];
            return;
        }

        // A-01: Verify final response URL is still on an allowed host after any redirects.
        NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
        if (![self isAllowedURL:httpResp.URL]) {
            NSLog(@"[AutoUpdater] Download redirected to disallowed host: %@", httpResp.URL.host);
            [self cleanupStagingDirectory:stagingDir];
            return;
        }

        NSFileManager *fm = [NSFileManager defaultManager];
        [fm removeItemAtURL:destURL error:nil];

        NSError *moveError = nil;
        if (![fm moveItemAtURL:location toURL:destURL error:&moveError]) {
            NSLog(@"[AutoUpdater] Move to staging failed: %@", moveError);
            [self cleanupStagingDirectory:stagingDir];
            return;
        }

        // A-01: Verify Developer ID Installer signature and Team ID BEFORE opening.
        NSString *signerInfo = nil;
        if (![self verifyPackageSignature:destPath signerInfo:&signerInfo]) {
            NSLog(@"[AutoUpdater] Package signature verification FAILED: %@", destPath);
            [self cleanupStagingDirectory:stagingDir];
            dispatch_async(dispatch_get_main_queue(), ^{
                NSAlert *alert = [[NSAlert alloc] init];
                alert.alertStyle = NSAlertStyleCritical;
                alert.messageText = @"Update Blocked — Signature Verification Failed";
                alert.informativeText =
                    @"The downloaded update package could not be verified. "
                     "It may have been tampered with. The update has been cancelled for your safety.";
                [alert addButtonWithTitle:@"OK"];
                [alert runModal];
            });
            return;
        }
        NSLog(@"[AutoUpdater] Signature OK — %@", signerInfo);

        NSDictionary *fileAttrs = [fm attributesOfItemAtPath:destPath error:nil];
        unsigned long long fileSize = [fileAttrs fileSize];

        // A-01: Show verified confirmation dialog before launching Installer.
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self showVerifiedInstallConfirmation:signerInfo
                                             version:expectedVersion
                                            fileSize:fileSize]) {
                [[NSWorkspace sharedWorkspace] openURL:destURL];
            } else {
                [self cleanupStagingDirectory:stagingDir];
            }
        });
    }];
    [downloadTask resume];
    self.downloadTask = downloadTask;
}

// A-01: Verify the Developer ID Installer signature and Team ID of a downloaded
// package using /usr/sbin/pkgutil --check-signature. NSTask is used directly
// (no shell). Returns YES only if both the cert type and expected Team ID are present.
- (BOOL)verifyPackageSignature:(NSString *)pkgPath signerInfo:(NSString **)outSignerInfo {
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/sbin/pkgutil";
    task.arguments = @[@"--check-signature", pkgPath];

    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    task.standardError  = pipe;

    NSError *launchError = nil;
    [task launchAndReturnError:&launchError];
    if (launchError) {
        NSLog(@"[AutoUpdater] pkgutil launch error: %@", launchError);
        return NO;
    }

    NSData *outputData = [pipe.fileHandleForReading readDataToEndOfFile];
    [task waitUntilExit];
    if (task.terminationStatus != 0) return NO;

    NSString *output = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding] ?: @"";

    BOOL hasTeamID   = [output containsString:kExpectedTeamID];
    BOOL hasCertType = [output containsString:kExpectedCertPrefix];

    if (outSignerInfo) {
        for (NSString *line in [output componentsSeparatedByString:@"\n"]) {
            NSString *trimmed = [line stringByTrimmingCharactersInSet:
                                 [NSCharacterSet whitespaceCharacterSet]];
            if ([trimmed hasPrefix:kExpectedCertPrefix]) {
                *outSignerInfo = trimmed;
                break;
            }
        }
    }
    return hasTeamID && hasCertType;
}

// A-01: Show a confirmation dialog with verified signer identity, version, and size
// BEFORE opening Installer. Returns YES if the user confirms.
- (BOOL)showVerifiedInstallConfirmation:(NSString *)signerInfo
                                version:(NSString *)version
                               fileSize:(unsigned long long)fileSize {
    double sizeMB = fileSize / (1024.0 * 1024.0);
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = [NSString stringWithFormat:@"Install Akshara %@?", version];
    alert.informativeText = [NSString stringWithFormat:
        @"✓ Verified: %@\n\nVersion: %@  |  Size: %.1f MB\n\n"
         "Akshara Installer will open for you to authorize the update.",
        signerInfo ?: [NSString stringWithFormat:@"%@ (%@)", kExpectedCertPrefix, kExpectedTeamID],
        version, sizeMB];
    [alert addButtonWithTitle:@"Install"];
    [alert addButtonWithTitle:@"Cancel"];
    return ([alert runModal] == NSAlertFirstButtonReturn);
}

// A-03: Remove the per-update staging directory on cancel or failure.
- (void)cleanupStagingDirectory:(NSString *)path {
    if (path.length == 0) return;
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    if ([self.stagingDirectory isEqualToString:path]) {
        self.stagingDirectory = nil;
    }
}

@end

