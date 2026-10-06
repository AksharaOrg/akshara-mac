#import <Carbon/Carbon.h>
#import <Cocoa/Cocoa.h>
#import <InputMethodKit/InputMethodKit.h>
#import "Akshara-Swift.h"

static IMKServer *server;

// A freshly installed input method isn't in System Settings' keyboard list until macOS rescans the Input
// Methods folders at the next login. Register this bundle's input sources when it runs from an Input
// Methods folder and macOS doesn't know them yet, so they can be added straight after installing.
// A copy anywhere else (a dev build in dist/) is never registered, so no duplicate sources appear.
static void AksharaRegisterInputSourcesIfNeeded(NSBundle *bundle) {
  if (![bundle.bundlePath.stringByDeletingLastPathComponent.lastPathComponent isEqualToString:@"Input Methods"]) {
    return;
  }
  NSString *bundleID = bundle.bundleIdentifier;
  NSString *modePrefix = [bundleID stringByAppendingString:@"."];
  BOOL known = NO;
  CFArrayRef sources = TISCreateInputSourceList(NULL, true);
  if (sources) {
    for (id item in (__bridge NSArray *)sources) {
      NSString *sourceID = (__bridge NSString *)TISGetInputSourceProperty((__bridge TISInputSourceRef)item,
                                                                         kTISPropertyInputSourceID);
      if ([sourceID isEqualToString:bundleID] || [sourceID hasPrefix:modePrefix]) {
        known = YES;
        break;
      }
    }
    CFRelease(sources);
  }
  if (!known) {
    OSStatus status = TISRegisterInputSource((__bridge CFURLRef)bundle.bundleURL);
    if (status != noErr) {
      NSLog(@"Akshara: TISRegisterInputSource failed (%d)", (int)status);
    }
  }
}

int main(int argc, const char *argv[]) {
  @autoreleasepool {
    (void)argc;
    (void)argv;
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *identifier = [bundle bundleIdentifier];
    NSString *connectionName = [bundle objectForInfoDictionaryKey:@"InputMethodConnectionName"];
    AksharaRegisterInputSourcesIfNeeded(bundle);
    NSApplication *application = [NSApplication sharedApplication];
    // Keep the input method out of the Dock while permitting its Help & Guides
    // windows to become key. LSBackgroundOnly apps cannot present windows.
    [application setActivationPolicy:NSApplicationActivationPolicyAccessory];
    server = [[IMKServer alloc] initWithName:connectionName bundleIdentifier:identifier];
    [WelcomeWindowManager.shared registerURLHandler];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
      [WelcomeWindowManager.shared showWelcomeWindowIfNeeded];
    });
    [application run];
  }
  return 0;
}
