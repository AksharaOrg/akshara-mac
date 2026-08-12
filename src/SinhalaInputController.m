#import "SinhalaInputController.h"
#import "SinhalaTransliterator.h"
#import "AutoUpdater.h"
#import <Carbon/Carbon.h>

@interface SinhalaInputController ()
@property(nonatomic, strong) NSMutableString *rawBuffer;
@property(nonatomic, strong) NSDate *lastSpaceTime;
@property(nonatomic, strong) NSString *lastCommittedString;
@property(nonatomic, assign) NSUInteger expectedCursorLocation;
@property(nonatomic, assign) NSUInteger expectedCursorLocationGraphemes;
@property(nonatomic, assign) NSRange lastReportedRange;
- (void)updateCustomComposition;
@end

@implementation SinhalaInputController

- (instancetype)initWithServer:(IMKServer *)server delegate:(id)delegate client:(id)inputClient {
  self = [super initWithServer:server delegate:delegate client:inputClient];
  if (self) {
    _rawBuffer = [NSMutableString string];
    _lastCommittedString = @"";
    _expectedCursorLocation = NSNotFound;
    _expectedCursorLocationGraphemes = NSNotFound;
    _lastReportedRange = NSMakeRange(NSNotFound, 0);
    [[AutoUpdater sharedUpdater] startCheckingForUpdates];
  }
  return self;
}

typedef NS_ENUM(NSInteger, AksharaInputMode) {
  AksharaInputModeWijesekara,
  AksharaInputModePhonetic,
  AksharaInputModeSmartPhonetic
};

- (AksharaInputMode)currentInputMode {
  TISInputSourceRef source = TISCopyCurrentKeyboardInputSource();
  if (!source) {
    return AksharaInputModePhonetic;
  }
  NSString *sourceID = (__bridge NSString *)TISGetInputSourceProperty(source, kTISPropertyInputSourceID);
  AksharaInputMode mode = AksharaInputModeWijesekara;
  if ([sourceID containsString:@"SmartPhonetic"]) {
    mode = AksharaInputModeSmartPhonetic;
  } else if ([sourceID containsString:@"Phonetic"]) {
    mode = AksharaInputModePhonetic;
  }
  CFRelease(source);
  return mode;
}

- (void)insertString:(NSString *)string client:(id)sender {
  SEL selector = @selector(insertText:replacementRange:);
  if ([sender respondsToSelector:selector]) {
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[sender methodSignatureForSelector:selector]];
    NSRange range = NSMakeRange(NSNotFound, NSNotFound);
    [invocation setSelector:selector];
    [invocation setTarget:sender];
    [invocation setArgument:&string atIndex:2];
    [invocation setArgument:&range atIndex:3];
    [invocation invoke];
  }
}

- (NSString *)usKeyStringForKeyCode:(NSInteger)keyCode shifted:(BOOL)shifted {
  switch (keyCode) {
    case kVK_ANSI_A: return shifted ? @"A" : @"a";
    case kVK_ANSI_B: return shifted ? @"B" : @"b";
    case kVK_ANSI_C: return shifted ? @"C" : @"c";
    case kVK_ANSI_D: return shifted ? @"D" : @"d";
    case kVK_ANSI_E: return shifted ? @"E" : @"e";
    case kVK_ANSI_F: return shifted ? @"F" : @"f";
    case kVK_ANSI_G: return shifted ? @"G" : @"g";
    case kVK_ANSI_H: return shifted ? @"H" : @"h";
    case kVK_ANSI_I: return shifted ? @"I" : @"i";
    case kVK_ANSI_J: return shifted ? @"J" : @"j";
    case kVK_ANSI_K: return shifted ? @"K" : @"k";
    case kVK_ANSI_L: return shifted ? @"L" : @"l";
    case kVK_ANSI_M: return shifted ? @"M" : @"m";
    case kVK_ANSI_N: return shifted ? @"N" : @"n";
    case kVK_ANSI_O: return shifted ? @"O" : @"o";
    case kVK_ANSI_P: return shifted ? @"P" : @"p";
    case kVK_ANSI_Q: return shifted ? @"Q" : @"q";
    case kVK_ANSI_R: return shifted ? @"R" : @"r";
    case kVK_ANSI_S: return shifted ? @"S" : @"s";
    case kVK_ANSI_T: return shifted ? @"T" : @"t";
    case kVK_ANSI_U: return shifted ? @"U" : @"u";
    case kVK_ANSI_V: return shifted ? @"V" : @"v";
    case kVK_ANSI_W: return shifted ? @"W" : @"w";
    case kVK_ANSI_X: return shifted ? @"X" : @"x";
    case kVK_ANSI_Y: return shifted ? @"Y" : @"y";
    case kVK_ANSI_Z: return shifted ? @"Z" : @"z";
    case kVK_ANSI_Grave: return shifted ? @"~" : @"`";
    case kVK_ANSI_Minus: return shifted ? @"_" : @"-";
    case kVK_ANSI_Equal: return shifted ? @"+" : @"=";
    case kVK_ANSI_LeftBracket: return shifted ? @"{" : @"[";
    case kVK_ANSI_RightBracket: return shifted ? @"}" : @"]";
    case kVK_ANSI_Backslash: return shifted ? @"|" : @"\\";
    case kVK_ANSI_Semicolon: return shifted ? @":" : @";";
    case kVK_ANSI_Quote: return shifted ? @"\"" : @"'";
    case kVK_ANSI_Comma: return shifted ? @"<" : @",";
    case kVK_ANSI_Period: return shifted ? @">" : @".";
    case kVK_ANSI_Slash: return shifted ? @"?" : @"/";
    case kVK_Space: return @" ";
    default: return nil;
  }
}

- (NSString *)markedString {
  AksharaInputMode mode = [self currentInputMode];
  if (mode == AksharaInputModeSmartPhonetic) {
    return [SinhalaTransliterator transliterateSmartPhonetic:self.rawBuffer];
  } else if (mode == AksharaInputModePhonetic) {
    return [SinhalaTransliterator transliteratePhonetic:self.rawBuffer];
  }
  return [SinhalaTransliterator markedSLSInputOrder:self.rawBuffer];
}

- (void)clearComposition {
  [self.rawBuffer setString:@""];
  self.lastCommittedString = @"";
  self.expectedCursorLocation = NSNotFound;
  self.expectedCursorLocationGraphemes = NSNotFound;
  self.lastReportedRange = NSMakeRange(NSNotFound, 0);
  [self updateCustomComposition];
}

- (void)commitBufferWithSuffix:(NSString *)suffix client:(id)sender {
  [self.rawBuffer setString:@""];
  self.lastCommittedString = @"";
  [self updateCustomComposition];
  if (suffix.length > 0) {
    [self insertString:suffix client:sender];
  }
  self.expectedCursorLocation = NSNotFound;
  self.expectedCursorLocationGraphemes = NSNotFound;
  self.lastReportedRange = NSMakeRange(NSNotFound, 0);
}

- (BOOL)commitBufferAndForwardCommand:(SEL)command client:(id)sender {
  BOOL hadComposition = self.rawBuffer.length > 0;
  if (!hadComposition) {
    return NO;
  }

  [self commitBufferWithSuffix:@"" client:sender];

  // A client that uses key bindings (including Electron-based messengers) may
  // consume Return while an IME composition is active. Forward the command
  // after committing so the client receives the same action it would receive
  // with a non-IME keyboard layout.
  if ([sender respondsToSelector:@selector(doCommandBySelector:)]) {
    [sender doCommandBySelector:command];
    return YES;
  }

  return NO;
}

- (BOOL)shouldCommitBufferBeforeInput:(NSString *)newInput {
  if (self.rawBuffer.length == 0) {
    return NO;
  }
  
  NSString *vowelsStr = @"aeiouAEIOU";
  unichar lastChar = [self.rawBuffer characterAtIndex:self.rawBuffer.length - 1];
  BOOL lastWasVowel = [vowelsStr rangeOfString:[NSString stringWithCharacters:&lastChar length:1]].location != NSNotFound;
  
  if (lastWasVowel) {
    unichar newChar = (newInput.length > 0) ? [newInput characterAtIndex:0] : 0;
    BOOL newIsVowel = (newInput.length > 0) && ([vowelsStr rangeOfString:[NSString stringWithCharacters:&newChar length:1]].location != NSNotFound);
    
    if (newIsVowel) {
      NSMutableString *temp = [self.rawBuffer mutableCopy];
      [temp appendString:newInput];
      AksharaInputMode mode = [self currentInputMode];
      NSString *transCommitted = [self markedString];
      NSString *transCombined = (mode == AksharaInputModeSmartPhonetic)
          ? [SinhalaTransliterator transliterateSmartPhonetic:temp]
          : [SinhalaTransliterator transliteratePhonetic:temp];
      if (![transCombined isEqualToString:transCommitted]) {
        return NO;
      }
    }
    
    return YES;
  }
  
  return NO;
}

- (BOOL)inputText:(NSString *)string key:(NSInteger)keyCode modifiers:(NSUInteger)flags client:(id)sender {
  if ((keyCode >= 123 && keyCode <= 126) || keyCode == 115 || keyCode == 119 || keyCode == 116 || keyCode == 121) {
    if (self.rawBuffer.length > 0) {
      [self commitComposition:sender];
    }
    return NO;
  }

  if ([sender respondsToSelector:@selector(selectedRange)]) {
    NSRange sel = [sender selectedRange];
    if (sel.location != NSNotFound) {
      BOOL cursorMoved = (self.expectedCursorLocation != NSNotFound && 
                          sel.location != self.expectedCursorLocation && 
                          sel.location != self.expectedCursorLocationGraphemes);
                          
      if (cursorMoved && self.lastReportedRange.location != NSNotFound && sel.location == self.lastReportedRange.location) {
        cursorMoved = NO;
      }
      
      if (sel.length > 0 || cursorMoved) {
        [self commitComposition:sender];
      }
    }
    self.lastReportedRange = sel;
  }

  if (keyCode == 49 || [string isEqualToString:@" "]) {
    NSDate *now = [NSDate date];
    if (self.lastSpaceTime && [now timeIntervalSinceDate:self.lastSpaceTime] < 0.5) {
      self.lastSpaceTime = nil;
      NSRange range = [sender selectedRange];
      if (range.location != NSNotFound && range.location >= 2) {
        NSAttributedString *prev = [sender attributedSubstringFromRange:NSMakeRange(range.location - 1, 1)];
        NSAttributedString *prevPrev = [sender attributedSubstringFromRange:NSMakeRange(range.location - 2, 1)];
        if ([prev.string isEqualToString:@" "] && prevPrev.string.length > 0) {
          unichar ppChar = [prevPrev.string characterAtIndex:0];
          if (![[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:ppChar]) {
            [sender insertText:@". " replacementRange:NSMakeRange(range.location - 1, 1)];
            return YES;
          }
        }
      }
    }
    self.lastSpaceTime = now;
  } else if (string.length > 0 && keyCode != 51) {
    self.lastSpaceTime = nil;
  }

  AksharaInputMode mode = [self currentInputMode];
  BOOL isPhonetic = (mode == AksharaInputModePhonetic || mode == AksharaInputModeSmartPhonetic);
  NSUInteger blockedModifiers = isPhonetic
      ? (NSEventModifierFlagCommand | NSEventModifierFlagControl | NSEventModifierFlagOption)
      : (NSEventModifierFlagCommand | NSEventModifierFlagControl);
  BOOL commandLike = (flags & blockedModifiers) != 0;
  if (commandLike) {
    return NO;
  }

  if (keyCode == kVK_Delete) {
    if (self.rawBuffer.length == 0) {
      return NO;
    }
    
    NSString *currentComposed = self.lastCommittedString ?: @"";
    NSUInteger targetGraphemes = [self graphemeCountForString:currentComposed];
    if (targetGraphemes > 0) {
      targetGraphemes -= 1;
    }
    
    while (self.rawBuffer.length > 0) {
      [self.rawBuffer deleteCharactersInRange:NSMakeRange(self.rawBuffer.length - 1, 1)];
      NSString *newComposed = [self markedString];
      if ([self graphemeCountForString:newComposed] <= targetGraphemes) {
        break;
      }
    }
    
    BOOL shouldReturnNo = (self.rawBuffer.length == 0);
    [self updateCustomComposition];
    
    if (shouldReturnNo) {
        self.expectedCursorLocation = NSNotFound;
        self.expectedCursorLocationGraphemes = NSNotFound;
        return NO;
    }
    return YES;
  }

  if (!isPhonetic) {
    if (string.length == 0) {
      return NO;
    }
    BOOL shifted = (flags & NSEventModifierFlagShift) != 0;
    BOOL altGr = (flags & NSEventModifierFlagOption) != 0;
    NSString *lookup = altGr ? [self usKeyStringForKeyCode:keyCode shifted:shifted] ?: string : string;
    NSString *mapped = [SinhalaTransliterator slsCharacterForInput:lookup shifted:shifted altGr:altGr];
    if ([SinhalaTransliterator isSinhalaInputUnit:mapped]) {
      [self.rawBuffer appendString:mapped];
      [self updateCustomComposition];
      return YES;
    } else if (![mapped isEqualToString:lookup]) {
      [self commitBufferWithSuffix:mapped client:sender];
      return YES;
    } else {
      if (self.rawBuffer.length > 0) {
        [self commitBufferWithSuffix:@"" client:sender];
      }
      return NO;
    }
  }

  if (string.length == 0) {
    return NO;
  }

  unichar first = [string characterAtIndex:0];
  if ([[NSCharacterSet letterCharacterSet] characterIsMember:first]) {
    if ([self shouldCommitBufferBeforeInput:string]) {
      [self commitBufferWithSuffix:@"" client:sender];
    }
    [self.rawBuffer appendString:string];
    [self updateCustomComposition];
    return YES;
  }

  if ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:first] ||
      [[NSCharacterSet punctuationCharacterSet] characterIsMember:first] ||
      [[NSCharacterSet symbolCharacterSet] characterIsMember:first]) {
    if (first == '\r' || first == '\n') {
      self.expectedCursorLocation = NSNotFound;
      self.expectedCursorLocationGraphemes = NSNotFound;
      return [self commitBufferAndForwardCommand:@selector(insertNewline:) client:sender];
    }
    if (self.rawBuffer.length > 0) {
      [self commitBufferWithSuffix:@"" client:sender];
    }
    self.expectedCursorLocation = NSNotFound;
    self.expectedCursorLocationGraphemes = NSNotFound;
    return NO;
  }

  return NO;
}

- (BOOL)inputText:(NSString *)string client:(id)sender {
  return [self inputText:string key:0 modifiers:0 client:sender];
}

- (BOOL)didCommandBySelector:(SEL)aSelector client:(id)sender {
  if (aSelector == @selector(deleteBackward:)) {
    return [self inputText:@"" key:kVK_Delete modifiers:0 client:sender];
  }
  if (aSelector == @selector(insertNewline:)) {
    return [self commitBufferAndForwardCommand:aSelector client:sender];
  }
  if (aSelector == @selector(insertTab:)) {
    [self commitComposition:sender];
    return NO;
  }
  
  NSString *selectorName = NSStringFromSelector(aSelector);
  if ([selectorName hasPrefix:@"move"] || [selectorName hasPrefix:@"select"] || [selectorName hasPrefix:@"page"]) {
    if (self.rawBuffer.length > 0) {
      [self commitComposition:sender];
    }
    return NO;
  }
  return NO;
}

- (id)composedString:(id)sender {
  (void)sender;
  return [self markedString];
}

- (NSAttributedString *)originalString:(id)sender {
  (void)sender;
  return [[NSAttributedString alloc] initWithString:self.rawBuffer];
}

- (void)openHelp {
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://akshara.thimira.com/help"]];
}

- (void)commitComposition:(id)sender {
  [self commitBufferWithSuffix:@"" client:sender ?: [self client]];
}

- (NSRange)selectionRange {
  return NSMakeRange([self markedString].length, 0);
}

- (void)activateServer:(id)sender {
  [super activateServer:sender];
  [self.rawBuffer setString:@""];
  self.lastCommittedString = @"";
  self.expectedCursorLocation = NSNotFound;
  self.expectedCursorLocationGraphemes = NSNotFound;
  self.lastReportedRange = NSMakeRange(NSNotFound, 0);
}

- (void)deactivateServer:(id)sender {
  [self commitComposition:sender];
  [self.rawBuffer setString:@""];
  self.lastCommittedString = @"";
  self.expectedCursorLocation = NSNotFound;
  self.expectedCursorLocationGraphemes = NSNotFound;
  self.lastReportedRange = NSMakeRange(NSNotFound, 0);
  [super deactivateServer:sender];
}

- (NSMenu *)menu {
  NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Akshara Menu"];
  NSMenuItem *updateItem = [[NSMenuItem alloc] initWithTitle:@"Check for Updates..."
                                                      action:@selector(checkForUpdatesManually:)
                                               keyEquivalent:@""];
  updateItem.target = self;
  [menu addItem:updateItem];
  return menu;
}

- (void)checkForUpdatesManually:(id)sender {
  [[AutoUpdater sharedUpdater] checkForUpdatesManually];
}

- (NSUInteger)graphemeCountForString:(NSString *)string {
  __block NSUInteger count = 0;
  [string enumerateSubstringsInRange:NSMakeRange(0, string.length)
                             options:NSStringEnumerationByComposedCharacterSequences
                          usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                            (void)substring; (void)substringRange; (void)enclosingRange; (void)stop;
                            count++;
                          }];
  return count;
}

- (void)deleteBackwardInClient:(id)client count:(NSUInteger)count {
  for (NSUInteger i = 0; i < count; i++) {
    if ([client respondsToSelector:@selector(doCommandBySelector:)]) {
      [client doCommandBySelector:@selector(deleteBackward:)];
    }
  }
}

- (void)updateCustomComposition {
  id client = [self client];
  if (!client) {
    return;
  }
  
  NSString *oldString = self.lastCommittedString ?: @"";
  NSString *newString = [self markedString];
  
  if ([oldString isEqualToString:newString]) {
    return;
  }
  
  NSMutableArray<NSString *> *oldGraphemes = [NSMutableArray array];
  [oldString enumerateSubstringsInRange:NSMakeRange(0, oldString.length)
                                options:NSStringEnumerationByComposedCharacterSequences
                             usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                               (void)substringRange; (void)enclosingRange; (void)stop;
                               [oldGraphemes addObject:substring];
                             }];
                             
  NSMutableArray<NSString *> *newGraphemes = [NSMutableArray array];
  [newString enumerateSubstringsInRange:NSMakeRange(0, newString.length)
                                options:NSStringEnumerationByComposedCharacterSequences
                             usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                               (void)substringRange; (void)enclosingRange; (void)stop;
                               [newGraphemes addObject:substring];
                             }];
                             
  NSUInteger commonCount = 0;
  NSUInteger minCount = MIN(oldGraphemes.count, newGraphemes.count);
  for (NSUInteger i = 0; i < minCount; i++) {
    if ([oldGraphemes[i] isEqualToString:newGraphemes[i]]) {
      commonCount++;
    } else {
      break;
    }
  }
  
  BOOL isDeletion = (oldGraphemes.count > newGraphemes.count && commonCount == newGraphemes.count);
  if (isDeletion && newString.length > 0) {
      commonCount = 0;
  }
  
  NSUInteger graphemesToDelete = oldGraphemes.count - commonCount;
  
  NSMutableString *inserts = [NSMutableString string];
  for (NSUInteger i = commonCount; i < newGraphemes.count; i++) {
    [inserts appendString:newGraphemes[i]];
  }
  
  NSUInteger unicharsToDelete = 0;
  for (NSUInteger i = commonCount; i < oldGraphemes.count; i++) {
    unicharsToDelete += [oldGraphemes[i] length];
  }
  
  if (unicharsToDelete > 0 || inserts.length > 0) {
    NSRange sel = [client respondsToSelector:@selector(selectedRange)] ? [client selectedRange] : NSMakeRange(NSNotFound, 0);
    
    BOOL isNativeApp = (self.expectedCursorLocation == NSNotFound || sel.location == self.expectedCursorLocation);
    BOOL isGraphemeApp = (self.expectedCursorLocationGraphemes != NSNotFound && sel.location == self.expectedCursorLocationGraphemes);
    BOOL isBrokenApp = (self.lastReportedRange.location != NSNotFound && sel.location == self.lastReportedRange.location);
    
    if (sel.location != NSNotFound && (isNativeApp || (!isGraphemeApp && !isBrokenApp && sel.location >= unicharsToDelete))) {
      NSRange replaceRange = (unicharsToDelete == 0) ? NSMakeRange(NSNotFound, 0) : NSMakeRange(sel.location - unicharsToDelete, unicharsToDelete);
      if (inserts.length > 0) {
        [client insertText:inserts replacementRange:replaceRange];
      } else if (unicharsToDelete > 0) {
        [client insertText:@"" replacementRange:replaceRange];
      }
      self.expectedCursorLocation = (sel.location - unicharsToDelete) + inserts.length;
      self.expectedCursorLocationGraphemes = (sel.location - graphemesToDelete) + [self graphemeCountForString:inserts];
    } else {
      // For clients where selectedRange returns NSNotFound, graphemes, or is buggy (e.g. Electron / Antigravity / Chromium):
      if (graphemesToDelete > 0) {
        [self deleteBackwardInClient:client count:graphemesToDelete];
      }
      if (inserts.length > 0) {
        [self insertString:inserts client:client];
      }
      
      if (sel.location != NSNotFound) {
        self.expectedCursorLocation = (sel.location - unicharsToDelete) + inserts.length;
        self.expectedCursorLocationGraphemes = (sel.location - graphemesToDelete) + [self graphemeCountForString:inserts];
      } else {
        self.expectedCursorLocation = NSNotFound;
        self.expectedCursorLocationGraphemes = NSNotFound;
      }
    }
  }
  
  self.lastCommittedString = newString;
}

@end
