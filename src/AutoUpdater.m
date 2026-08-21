#import "AutoUpdater.h"
#import <UserNotifications/UserNotifications.h>
#import <AppKit/AppKit.h>
#import <mach-o/dyld.h>
#import <mach-o/fat.h>
#import <mach/machine.h>
#import <CommonCrypto/CommonDigest.h>

// Exact package identity used to verify downloaded updates before opening.
static NSString * const kExpectedTeamID = @"8292UX7379";
static NSString * const kExpectedInstallerCertificate = @"Developer ID Installer: Lahiru Himesh Madusanka Siddha Dewayala Gedara (8292UX7379)";
static NSString * const kExpectedPackageIdentifier = @"com.local.inputmethod.Akshara.pkg";
// Only accept download URLs from known GitHub-owned hosts.
static NSArray<NSString *> *allowedAssetHosts(void) {
    return @[@"githubusercontent.com",
             @"github.com",
             @"github-releases.githubusercontent.com"];
}

static NSString *currentPackageArchitecture(void) {
    NSString *executablePath = [[NSBundle mainBundle] executablePath];
    NSData *headerData = executablePath ? [NSData dataWithContentsOfFile:executablePath
                                                                  options:NSDataReadingMappedIfSafe
                                                                    error:nil] : nil;
    if (headerData.length >= sizeof(uint32_t)) {
        uint32_t magic = 0;
        [headerData getBytes:&magic length:sizeof(magic)];
        if (magic == FAT_MAGIC || magic == FAT_CIGAM || magic == FAT_MAGIC_64 || magic == FAT_CIGAM_64) {
            return @"universal";
        }
    }

    const struct mach_header *header = _dyld_get_image_header(0);
    if (!header) return @"universal";

    cpu_type_t cpuType = header->cputype;
    if ((cpuType & CPU_ARCH_ABI64) && (cpuType & ~CPU_ARCH_ABI64) == CPU_TYPE_ARM) {
        return @"arm64";
    }
    if ((cpuType & CPU_ARCH_ABI64) && (cpuType & ~CPU_ARCH_ABI64) == CPU_TYPE_X86) {
        return @"x86_64";
    }
    return @"universal";
}

@interface AutoUpdater () <UNUserNotificationCenterDelegate>
@property (nonatomic, strong) NSString *downloadUrl;
@property (nonatomic, strong) NSString *availableVersion;
@property (nonatomic, strong) NSString *expectedSHA256;
@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;
// Tracks the per-download staging directory so it can be cleaned up on cancel or failure.
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


// Returns YES if the URL uses HTTPS and its host is one of the known GitHub asset hosts.
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
        // Guard against redirects to unexpected hosts.
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
            NSString *pkgSHA256 = nil;
            NSString *architecture = currentPackageArchitecture();
            NSArray<NSString *> *architecturesToTry = @[architecture, @"universal"];
            for (NSString *candidateArchitecture in architecturesToTry) {
                NSString *expectedName = [NSString stringWithFormat:@"Akshara-v%@-%@.pkg", tagName, candidateArchitecture];
                for (NSDictionary *asset in assets) {
                    if (![asset isKindOfClass:[NSDictionary class]]) continue;
                    NSString *name = asset[@"name"];
                    if (![name isKindOfClass:[NSString class]] || ![name isEqualToString:expectedName]) continue;

                    NSString *candidate = asset[@"browser_download_url"];
                    NSString *digest = asset[@"digest"];
                    if (![digest isKindOfClass:[NSString class]] ||
                        ![digest hasPrefix:@"sha256:"] ||
                        digest.length != 71) {
                        continue;
                    }
                    NSURL *candidateURL = [candidate isKindOfClass:[NSString class]] ? [NSURL URLWithString:candidate] : nil;
                    if ([self isAllowedURL:candidateURL]) {
                        pkgUrl = candidate;
                        pkgSHA256 = [digest substringFromIndex:7].lowercaseString;
                    }
                    break;
                }
                if (pkgUrl) break;
            }
            
            if (pkgUrl) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.downloadUrl = pkgUrl;
                    self.availableVersion = tagName;
                    self.expectedSHA256 = pkgSHA256;
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

    // Re-validate the URL right before starting the download.
    NSURL *url = [NSURL URLWithString:self.downloadUrl];
    if (![self isAllowedURL:url]) {
        NSLog(@"[AutoUpdater] Rejected disallowed download URL: %@", url);
        return;
    }

    NSString *expectedVersion = self.availableVersion;
    NSString *expectedSHA256 = [self.expectedSHA256 copy];

    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = @"Downloading Update";
    content.body = @"Akshara is downloading the latest update. It will open automatically when ready.";
    content.sound = [UNNotificationSound defaultSound];
    [[UNUserNotificationCenter currentNotificationCenter]
        addNotificationRequest:[UNNotificationRequest requestWithIdentifier:@"AksharaDownloading"
                                                                    content:content trigger:nil]
             withCompletionHandler:nil];

    // Use a randomly-named private staging directory (mode 0700) so the download
    // path is not predictable by other processes running as the same user.
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

    NSString *pkgName  = [url.lastPathComponent copy];
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

        // Check that we weren't redirected to an unexpected host.
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

        // Verify identity, package metadata, and digest before opening.
        NSString *signerInfo = nil;
        if (![self verifyPackageSignature:destPath expectedVersion:expectedVersion signerInfo:&signerInfo] ||
            ![self verifyPackageHash:destPath expectedSHA256:expectedSHA256]) {
            NSLog(@"[AutoUpdater] Package verification FAILED: %@", destPath);
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

        // Show a confirmation with the verified signer identity before launching Installer.
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

// Verifies the exact installer certificate, package identifier, and version.
- (BOOL)verifyPackageSignature:(NSString *)pkgPath expectedVersion:(NSString *)expectedVersion signerInfo:(NSString **)outSignerInfo {
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

    BOOL hasExactCertificate = NO;

    for (NSString *line in [output componentsSeparatedByString:@"\n"]) {
        NSString *trimmed = [line stringByTrimmingCharactersInSet:
                             [NSCharacterSet whitespaceCharacterSet]];
        NSString *certificateName = trimmed;
        if ([certificateName hasPrefix:@"1. "]) {
            certificateName = [certificateName substringFromIndex:3];
        }
        if ([certificateName isEqualToString:kExpectedInstallerCertificate] &&
            [certificateName hasSuffix:[NSString stringWithFormat:@"(%@)", kExpectedTeamID]]) {
            hasExactCertificate = YES;
            if (outSignerInfo) {
                *outSignerInfo = certificateName;
            }
            break;
        }
    }

    NSTask *infoTask = [[NSTask alloc] init];
    infoTask.launchPath = @"/usr/sbin/pkgutil";
    infoTask.arguments = @[@"--pkg-info-plist", pkgPath];
    NSPipe *infoPipe = [NSPipe pipe];
    infoTask.standardOutput = infoPipe;
    infoTask.standardError = [NSPipe pipe];
    NSError *infoError = nil;
    [infoTask launchAndReturnError:&infoError];
    if (infoError) return NO;
    NSData *plistData = [infoPipe.fileHandleForReading readDataToEndOfFile];
    [infoTask waitUntilExit];
    NSDictionary *packageInfo = [NSPropertyListSerialization propertyListWithData:plistData options:NSPropertyListImmutable format:nil error:nil];
    BOOL hasExpectedMetadata = infoTask.terminationStatus == 0 &&
        [packageInfo[@"identifier"] isEqualToString:kExpectedPackageIdentifier] &&
        [packageInfo[@"version"] isEqualToString:expectedVersion];
    return hasExactCertificate && hasExpectedMetadata && [kExpectedInstallerCertificate hasSuffix:kExpectedTeamID];
}

- (BOOL)verifyPackageHash:(NSString *)pkgPath expectedSHA256:(NSString *)expectedSHA256 {
    if (expectedSHA256.length != CC_SHA256_DIGEST_LENGTH * 2) return NO;
    NSData *packageData = [NSData dataWithContentsOfFile:pkgPath options:NSDataReadingMappedIfSafe error:nil];
    if (!packageData) return NO;
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(packageData.bytes, (CC_LONG)packageData.length, digest);
    NSMutableString *actual = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (NSUInteger index = 0; index < CC_SHA256_DIGEST_LENGTH; index++) {
        [actual appendFormat:@"%02x", digest[index]];
    }
    return [actual isEqualToString:expectedSHA256.lowercaseString];
}

// Shows a confirmation dialog with the verified signer identity, version, and size
// before opening Installer. Returns YES if the user confirms.
- (BOOL)showVerifiedInstallConfirmation:(NSString *)signerInfo
                                version:(NSString *)version
                               fileSize:(unsigned long long)fileSize {
    (void)signerInfo;
    double sizeMB = fileSize / (1024.0 * 1024.0);
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = [NSString stringWithFormat:@"Install Akshara %@?", version];
    NSString *details = [NSString stringWithFormat:
        @"✓ Verified v%@ (%.1f MB)\n\n"
         "Akshara Installer will open for you\n"
         "to authorize the update.",
        version, sizeMB];
    NSMutableAttributedString *attributedDetails =
        [[NSMutableAttributedString alloc] initWithString:details];
    NSRange verifiedRange = [details rangeOfString:@"✓ Verified"];
    if (verifiedRange.location != NSNotFound) {
        [attributedDetails addAttributes:@{
            NSFontAttributeName: [NSFont boldSystemFontOfSize:NSFont.systemFontSize],
            NSForegroundColorAttributeName: NSColor.labelColor
        } range:verifiedRange];
    }
    NSTextField *detailsLabel = [NSTextField labelWithString:@""];
    detailsLabel.attributedStringValue = attributedDetails;
    detailsLabel.editable = NO;
    detailsLabel.selectable = NO;
    detailsLabel.bezeled = NO;
    detailsLabel.drawsBackground = NO;
    detailsLabel.maximumNumberOfLines = 0;
    detailsLabel.lineBreakMode = NSLineBreakByWordWrapping;
    detailsLabel.frame = NSMakeRect(0, 0, 420, 0);
    [detailsLabel sizeToFit];
    alert.informativeText = @"";
    alert.accessoryView = detailsLabel;
    [alert addButtonWithTitle:@"Install"];
    [alert addButtonWithTitle:@"Cancel"];
    return ([alert runModal] == NSAlertFirstButtonReturn);
}

// Removes the per-update staging directory on cancel or failure.
- (void)cleanupStagingDirectory:(NSString *)path {
    if (path.length == 0) return;
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    if ([self.stagingDirectory isEqualToString:path]) {
        self.stagingDirectory = nil;
    }
}

@end

