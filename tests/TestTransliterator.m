#import <Foundation/Foundation.h>
#import "SinhalaTransliterator.h"

static BOOL expectPhonetic(NSString *input, NSString *expected) {
  NSString *actual = [SinhalaTransliterator transliteratePhonetic:input];
  if (![actual isEqualToString:expected]) {
    fprintf(stderr, "FAIL phonetic %s: expected %s, got %s\n",
            input.UTF8String, expected.UTF8String, actual.UTF8String);
    return NO;
  }
  return YES;
}

static BOOL expectSLSOrder(NSString *input, NSString *expected) {
  NSString *actual = [SinhalaTransliterator normalizeSLSInputOrder:input];
  if (![actual isEqualToString:expected]) {
    fprintf(stderr, "FAIL SLS %s: expected %s, got %s\n",
            input.UTF8String, expected.UTF8String, actual.UTF8String);
    return NO;
  }
  return YES;
}

static BOOL expectSLSKey(NSString *key, BOOL shifted, BOOL altGr, NSString *expected) {
  NSString *actual = [SinhalaTransliterator slsCharacterForInput:key shifted:shifted altGr:altGr];
  if (![actual isEqualToString:expected]) {
    fprintf(stderr, "FAIL key %s: expected %s, got %s\n",
            key.UTF8String, expected.UTF8String, actual.UTF8String);
    return NO;
  }
  return YES;
}

static BOOL expectSLSLexiconFixture(void) {
  NSString *path = @"tests/SLSLexiconStress.tsv";
  NSError *error = nil;
  NSString *contents = [NSString stringWithContentsOfFile:path
                                                 encoding:NSUTF8StringEncoding
                                                    error:&error];
  if (!contents) {
    fprintf(stderr, "FAIL fixture: could not read %s: %s\n",
            path.UTF8String, error.localizedDescription.UTF8String);
    return NO;
  }

  __block BOOL ok = YES;
  __block NSUInteger cases = 0;
  [contents enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
    (void)stop;
    if (line.length == 0 || [line hasPrefix:@"#"]) {
      return;
    }
    NSArray<NSString *> *parts = [line componentsSeparatedByString:@"\t"];
    if (parts.count != 2) {
      fprintf(stderr, "FAIL fixture malformed line: %s\n", line.UTF8String);
      ok = NO;
      return;
    }
    cases++;
    NSString *actual = [SinhalaTransliterator normalizeSLSInputOrder:parts[0]];
    if (![actual isEqualToString:parts[1]]) {
      fprintf(stderr, "FAIL lexicon case %lu: expected %s, got %s, input %s\n",
              (unsigned long)cases,
              parts[1].UTF8String,
              actual.UTF8String,
              parts[0].UTF8String);
      ok = NO;
    }
  }];

  if (cases != 500) {
    fprintf(stderr, "FAIL fixture: expected 500 cases, got %lu\n", (unsigned long)cases);
    ok = NO;
  }
  return ok;
}

int main(void) {
  @autoreleasepool {
    BOOL ok = YES;
    ok = expectPhonetic(@"amma", @"අම්ම") && ok;
    ok = expectPhonetic(@"mama", @"මම") && ok;
    ok = expectPhonetic(@"siMhala", @"සිංහල") && ok;
    ok = expectPhonetic(@"ka", @"ක") && ok;
    ok = expectPhonetic(@"k", @"ක්") && ok;
    ok = expectPhonetic(@"kii", @"කී") && ok;
    ok = expectPhonetic(@"kramaya", @"ක්‍රමය") && ok;
    ok = expectPhonetic(@"priya", @"ප්‍රිය") && ok;
    ok = expectSLSOrder(@"ෙකා", @"කො") && ok;
    ok = expectSLSOrder(@"ෙකා්", @"කෝ") && ok;
    ok = expectSLSOrder(@"ෙක්", @"කේ") && ok;
    ok = expectSLSOrder(@"ෙකෟ", @"කෞ") && ok;
    ok = expectSLSOrder(@"ෙගා", @"ගො") && ok;
    ok = expectSLSOrder(@"අා", @"ආ") && ok;
    ok = expectSLSOrder(@"අැ", @"ඇ") && ok;
    ok = expectSLSOrder(@"අෑ", @"ඈ") && ok;
    ok = expectSLSOrder(@"ඉී", @"ඊ") && ok;
    ok = expectSLSOrder(@"උූ", @"ඌ") && ok;
    ok = expectSLSOrder(@"එ්", @"ඒ") && ok;
    ok = expectSLSOrder(@"ෙඑ", @"ඓ") && ok;
    ok = expectSLSOrder(@"ඔ්", @"ඕ") && ok;
    ok = expectSLSOrder(@"ඔෟ", @"ඖ") && ok;
    ok = expectSLSOrder(@"ෙෙක", @"කෛ") && ok;
    ok = expectSLSOrder(@"ෙෙකෙ", @"කෛ‌ෙ") && ok;
    ok = expectSLSOrder(@"ගෘෘ", @"ගෲ") && ok;
    ok = expectSLSOrder(@"ගං", @"ගං") && ok;
    ok = expectSLSOrder(@"ගඃ", @"ගඃ") && ok;
    ok = expectSLSOrder(@"ග", @"ඟ") && ok;
    ok = expectSLSOrder(@"ද", @"ඳ") && ok;
    ok = expectSLSOrder(@"ක", @"ක්‍ර") && ok;
    ok = expectSLSOrder(@"ක", @"ක්‍ය") && ok;
    ok = expectSLSOrder(@"ක", @"ර්‍ක") && ok;
    ok = expectSLSOrder(@"කෂ", @"ක්‍ෂ") && ok;
    ok = expectSLSOrder(@"කෂ", @"ක්‍ෂ") && ok;
    ok = expectSLSOrder(@"", @"‌්‍ර") && ok;
    ok = expectSLSOrder(@"ෙ", @"‌ෙ") && ok;
    ok = expectSLSKey(@"o", NO, YES, @"ඳ") && ok;
    ok = expectSLSKey(@".", NO, YES, @"ඟ") && ok;
    ok = expectSLSKey(@"v", NO, YES, @"ඬ") && ok;
    ok = expectSLSKey(@"c", NO, YES, @"ඦ") && ok;
    ok = expectSLSKey(@"x", NO, YES, @"ඃ") && ok;
    ok = expectSLSKey(@"'", NO, YES, @"෴") && ok;
    ok = expectSLSKey(@",", NO, YES, @"ඏ") && ok;
    ok = expectSLSKey(@" ", NO, YES, @"‌") && ok;
    ok = expectSLSLexiconFixture() && ok;
    return ok ? 0 : 1;
  }
}
