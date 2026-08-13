#import <Cocoa/Cocoa.h>
#import <InputMethodKit/InputMethodKit.h>
#import "Akshara-Swift.h"

static IMKServer *server;

int main(int argc, const char *argv[]) {
  @autoreleasepool {
    (void)argc;
    (void)argv;
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *identifier = [bundle bundleIdentifier];
    NSString *connectionName = [bundle objectForInfoDictionaryKey:@"InputMethodConnectionName"];
    server = [[IMKServer alloc] initWithName:connectionName bundleIdentifier:identifier];
    dispatch_async(dispatch_get_main_queue(), ^{
      [WelcomeWindowManager.shared showWelcomeWindow];
    });
    [[NSApplication sharedApplication] run];
  }
  return 0;
}


