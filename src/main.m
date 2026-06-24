#import <Cocoa/Cocoa.h>
#import <InputMethodKit/InputMethodKit.h>

static IMKServer *server;

int main(int argc, const char *argv[]) {
  @autoreleasepool {
    (void)argc;
    (void)argv;
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *identifier = [bundle bundleIdentifier];
    NSString *connectionName = [bundle objectForInfoDictionaryKey:@"InputMethodConnectionName"];
    server = [[IMKServer alloc] initWithName:connectionName bundleIdentifier:identifier];
    [[NSApplication sharedApplication] run];
  }
  return 0;
}

