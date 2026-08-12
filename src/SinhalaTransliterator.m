#import "SmartPhoneticMaps.h"
#import "SinhalaTransliterator.h"

static NSString * const SLSTokenJoin = @"\uE000";
static NSString * const SLSTokenTouch = @"\uE001";
static NSString * const SLSTokenRepaya = @"\uE002";
static NSString * const SLSTokenSanyakaya = @"\uE003";
static NSString * const SLSTokenRakaransaya = @"\uE004";
static NSString * const SLSTokenYansaya = @"\uE005";

@implementation SinhalaTransliterator

+ (NSDictionary<NSString *, NSString *> *)consonants {
  static NSDictionary *map;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    map = @{
      @"ng": @"ඞ", @"gn": @"ඥ", @"ny": @"ඤ",
      @"kh": @"ඛ", @"gh": @"ඝ", @"ch": @"ච", @"jh": @"ඣ",
      @"Th": @"ඨ", @"Dh": @"ඪ", @"th": @"ත", @"dh": @"ද",
      @"ph": @"ඵ", @"bh": @"භ", @"sh": @"ශ", @"Sh": @"ෂ",
      @"k": @"ක", @"g": @"ග", @"c": @"ක", @"j": @"ජ",
      @"C": @"ඡ", @"T": @"ට", @"D": @"ඩ", @"N": @"ණ", @"t": @"ට", @"d": @"ඩ",
      @"n": @"න", @"p": @"ප", @"b": @"බ", @"m": @"ම",
      @"y": @"ය", @"r": @"ර", @"l": @"ල", @"L": @"ළ",
      @"v": @"ව", @"w": @"ව", @"s": @"ස", @"h": @"හ",
      @"f": @"ෆ", @"R": @"ර", @"Y": @"ය"
    };
  });
  return map;
}

+ (NSDictionary<NSString *, NSString *> *)smartConsonants {
  static NSDictionary *map;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    map = @{
      @"ng": @"ඞ", @"gn": @"ඥ", @"ny": @"ඤ",
      @"kh": @"ඛ", @"gh": @"ඝ", @"ch": @"ච", @"jh": @"ඣ",
      @"Th": @"ඨ", @"Dh": @"ඪ", @"th": @"ත", @"dh": @"ද",
      @"ph": @"ඵ", @"bh": @"භ", @"sh": @"ශ", @"Sh": @"ෂ",
      @"k": @"ක", @"g": @"ග", @"c": @"ක", @"j": @"ජ",
      @"C": @"ඡ", @"T": @"ට", @"D": @"ඩ", @"N": @"ණ", @"t": @"ට", @"d": @"ඩ",
      @"n": @"න", @"p": @"ප", @"b": @"බ", @"m": @"ම",
      @"y": @"ය", @"r": @"ර", @"l": @"ල", @"L": @"ළ",
      @"v": @"ව", @"w": @"ව", @"s": @"ස", @"h": @"හ",
      @"f": @"ෆ", @"R": @"ර", @"Y": @"ය"
    };
  });
  return map;
}

+ (NSDictionary<NSString *, NSString *> *)smartVowels {
  static NSDictionary *map;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    map = @{
      @"aee": @"ඈ", @"ae": @"ඇ", @"aa": @"ආ", @"ii": @"ඊ",
      @"uu": @"ඌ", @"ee": @"ඒ", @"ai": @"ඓ", @"oo": @"ඕ",
      @"au": @"ඖ", @"A": @"ආ", @"I": @"ඊ", @"U": @"ඌ",
      @"E": @"ඒ", @"O": @"ඕ", @"a": @"අ", @"i": @"ඉ",
      @"u": @"උ", @"e": @"එ", @"o": @"ඔ"
    };
  });
  return map;
}

+ (NSDictionary<NSString *, NSString *> *)smartVowelSigns {
  static NSDictionary *map;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    map = @{
      @"aee": @"ෑ", @"ae": @"ැ", @"aa": @"ා", @"ii": @"ී",
      @"uu": @"ූ", @"ee": @"ේ", @"ai": @"ෛ", @"oo": @"ෝ",
      @"au": @"ෞ", @"A": @"ා", @"I": @"ී", @"U": @"ූ",
      @"E": @"ේ", @"O": @"ෝ", @"a": @"", @"i": @"ි",
      @"u": @"ු", @"e": @"ෙ", @"o": @"ො"
    };
  });
  return map;
}

+ (NSArray<NSString *> *)smartConsonantKeys {
  return @[@"aee", @"ng", @"gn", @"ny", @"kh", @"gh", @"ch", @"jh", @"Th", @"Dh",
           @"th", @"dh", @"ph", @"bh", @"sh", @"Sh", @"k", @"g", @"c", @"j",
           @"C", @"T", @"D", @"N", @"t", @"d", @"n", @"p", @"b", @"m", @"y", @"r",
           @"l", @"L", @"v", @"w", @"s", @"h", @"f", @"R", @"Y"];
}

+ (NSArray<NSString *> *)smartVowelKeys {
  return @[@"aee", @"ae", @"aa", @"ii", @"uu", @"ee", @"ai", @"oo", @"au",
           @"A", @"I", @"U", @"E", @"O", @"a", @"i", @"u", @"e", @"o"];
}

+ (NSDictionary<NSString *, NSString *> *)vowels {
  static NSDictionary *map;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    map = @{
      @"aee": @"ඈ", @"ae": @"ඇ", @"aa": @"ආ", @"ii": @"ඊ",
      @"uu": @"ඌ", @"ee": @"ඒ", @"ai": @"ඓ", @"oo": @"ඕ",
      @"au": @"ඖ", @"A": @"ආ", @"I": @"ඊ", @"U": @"ඌ",
      @"E": @"ඒ", @"O": @"ඕ", @"a": @"අ", @"i": @"ඉ",
      @"u": @"උ", @"e": @"එ", @"o": @"ඔ"
    };
  });
  return map;
}

+ (NSDictionary<NSString *, NSString *> *)vowelSigns {
  static NSDictionary *map;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    map = @{
      @"aee": @"ෑ", @"ae": @"ැ", @"aa": @"ා", @"ii": @"ී",
      @"uu": @"ූ", @"ee": @"ේ", @"ai": @"ෛ", @"oo": @"ෝ",
      @"au": @"ෞ", @"A": @"ා", @"I": @"ී", @"U": @"ූ",
      @"E": @"ේ", @"O": @"ෝ", @"a": @"", @"i": @"ි",
      @"u": @"ු", @"e": @"ෙ", @"o": @"ො"
    };
  });
  return map;
}

+ (NSArray<NSString *> *)consonantKeys {
  return @[@"aee", @"ng", @"gn", @"ny", @"kh", @"gh", @"ch", @"jh", @"Th", @"Dh",
           @"th", @"dh", @"ph", @"bh", @"sh", @"Sh", @"k", @"g", @"c", @"j",
           @"C", @"T", @"D", @"N", @"t", @"d", @"n", @"p", @"b", @"m", @"y", @"r",
           @"l", @"L", @"v", @"w", @"s", @"h", @"f", @"R", @"Y"];
}

+ (NSArray<NSString *> *)vowelKeys {
  return @[@"aee", @"ae", @"aa", @"ii", @"uu", @"ee", @"ai", @"oo", @"au",
           @"A", @"I", @"U", @"E", @"O", @"a", @"i", @"u", @"e", @"o"];
}

+ (NSString *)matchFrom:(NSString *)input at:(NSUInteger)index keys:(NSArray<NSString *> *)keys {
  for (NSString *key in keys) {
    if (index + key.length <= input.length &&
        [[input substringWithRange:NSMakeRange(index, key.length)] isEqualToString:key]) {
      return key;
    }
  }
  return nil;
}

+ (NSString *)transliteratePhonetic:(NSString *)input {
  NSMutableString *out = [NSMutableString string];
  NSUInteger i = 0;
  NSDictionary *consonants = [self consonants];
  NSDictionary *vowels = [self vowels];
  NSDictionary *vowelSigns = [self vowelSigns];

  while (i < input.length) {
    NSString *ch = [input substringWithRange:NSMakeRange(i, 1)];
    if ([ch isEqualToString:@"M"]) {
      [out appendString:@"ං"];
      i++;
      continue;
    }
    if ([ch isEqualToString:@"H"]) {
      [out appendString:@"ඃ"];
      i++;
      continue;
    }

    NSString *consonantKey = [self matchFrom:input at:i keys:[self consonantKeys]];
    if (consonantKey && consonants[consonantKey]) {
      [out appendString:consonants[consonantKey]];
      i += consonantKey.length;
      NSString *vowelKey = [self matchFrom:input at:i keys:[self vowelKeys]];
      if (vowelKey && vowelSigns[vowelKey] != nil) {
        [out appendString:vowelSigns[vowelKey]];
        i += vowelKey.length;
      } else if (i < input.length &&
                 [[input substringWithRange:NSMakeRange(i, 1)] isEqualToString:@"r"]) {

        [out appendString:@"්‍ර"];
        i++;
        vowelKey = [self matchFrom:input at:i keys:[self vowelKeys]];
        if (vowelKey && vowelSigns[vowelKey] != nil) {
          [out appendString:vowelSigns[vowelKey]];
          i += vowelKey.length;
        }
      } else {
        NSString *nextConsonant = [self matchFrom:input at:i keys:[self consonantKeys]];
        BOOL isYansaya = [nextConsonant isEqualToString:@"y"];
        BOOL isRakaaranshaya = [nextConsonant isEqualToString:@"r"] && 
                               ![consonantKey isEqualToString:@"m"] && 
                               ![consonantKey isEqualToString:@"n"] && 
                               ![consonantKey isEqualToString:@"l"];
        
        if (isYansaya || isRakaaranshaya) {
          [out appendFormat:@"%C%C", (unichar)0x0DCA, (unichar)0x200D];
        } else {
          [out appendString:@"්"];
        }
      }
      continue;
    }

    NSString *vowelKey = [self matchFrom:input at:i keys:[self vowelKeys]];
    if (vowelKey && vowels[vowelKey]) {
      [out appendString:vowels[vowelKey]];
      i += vowelKey.length;
      continue;
    }

    [out appendString:ch];
    i++;
  }

  return out;
}

+ (NSString *)transliterateSmartPhonetic:(NSString *)input {
  NSMutableString *out = [NSMutableString string];
  NSUInteger i = 0;
  NSDictionary *consonants = [SmartPhoneticMaps smartConsonants];
  NSDictionary *vowels = [SmartPhoneticMaps smartVowels];
  NSDictionary *vowelSigns = [SmartPhoneticMaps smartVowelSigns];

  while (i < input.length) {
    NSString *ch = [input substringWithRange:NSMakeRange(i, 1)];
    if ([ch isEqualToString:@"M"] || [ch isEqualToString:@"x"]) {
      [out appendString:@"ං"];
      i++;
      continue;
    }
    if ([self matchFrom:input at:i keys:@[@"zn"]]) {
      [out appendString:@"ං"];
      i += 2;
      continue;
    }
    if ([ch isEqualToString:@"z"]) {
      NSString *sanyakaKey = [self matchFrom:input at:i keys:@[@"zg", @"zj", @"zd", @"zdh", @"zq", @"zk", @"zh"]];
      if (!sanyakaKey) {
        i++;
        continue;
      }
    }
    if ([ch isEqualToString:@"H"]) {
      [out appendString:@"ඃ"];
      i++;
      continue;
    }

    NSString *consonantKey = [self matchFrom:input at:i keys:[SmartPhoneticMaps smartConsonantKeys]];
    if (consonantKey && consonants[consonantKey]) {
      [out appendString:consonants[consonantKey]];
      i += consonantKey.length;
      NSString *vowelKey = [self matchFrom:input at:i keys:[SmartPhoneticMaps smartVowelKeys]];
      if (vowelKey && vowelSigns[vowelKey] != nil) {
        [out appendString:vowelSigns[vowelKey]];
        i += vowelKey.length;
      } else {
        NSString *nextConsonant = [self matchFrom:input at:i keys:[SmartPhoneticMaps smartConsonantKeys]];
        BOOL isYansaya = [nextConsonant isEqualToString:@"y"];
        BOOL isRakaaranshaya = [nextConsonant isEqualToString:@"r"] && 
                               ![consonantKey isEqualToString:@"m"] && 
                               ![consonantKey isEqualToString:@"n"] && 
                               ![consonantKey isEqualToString:@"l"];
        
        if (isYansaya || isRakaaranshaya) {
          [out appendFormat:@"%C%C", (unichar)0x0DCA, (unichar)0x200D];
        } else {
          [out appendString:@"්"];
        }
      }
      continue;
    }

    NSString *vowelKey = [self matchFrom:input at:i keys:[SmartPhoneticMaps smartVowelKeys]];
    if (vowelKey && vowels[vowelKey]) {
      [out appendString:vowels[vowelKey]];
      i += vowelKey.length;
      continue;
    }

    [out appendString:ch];
    i++;
  }

  return out;
}

+ (NSDictionary<NSString *, NSString *> *)slsNormalMap {
  static NSDictionary *map;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    map = @{
      @"`": SLSTokenRakaransaya, @"q": @"ු", @"w": @"අ", @"e": @"ැ", @"r": @"ර", @"t": @"එ",
      @"y": @"හ", @"u": @"ම", @"i": @"ස", @"o": @"ද", @"p": @"ච", @"[": @"ඤ",
      @"]": @";", @"\\": SLSTokenJoin,
      @"a": @"්", @"s": @"ි", @"d": @"ා", @"f": @"ෙ", @"g": @"ට", @"h": @"ය",
      @"j": @"ව", @"k": @"න", @"l": @"ක", @";": @"ත", @"'": @".",
      @"z": @"'", @"x": @"ං", @"c": @"ජ", @"v": @"ඩ", @"b": @"ඉ", @"n": @"බ",
      @"m": @"ප", @",": @"ල", @".": @"ග", @"/": @"/"
    };
  });
  return map;
}

+ (NSDictionary<NSString *, NSString *> *)slsShiftMap {
  static NSDictionary *map;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    map = @{
      @"~": SLSTokenRepaya, @"Q": @"ූ", @"W": @"උ", @"E": @"ෑ", @"R": @"ඍ", @"T": @"ඔ",
      @"Y": @"ශ", @"U": @"ඹ", @"I": @"ෂ", @"O": @"ධ", @"P": @"ඡ", @"{": @"ඕ",
      @"}": @":", @"|": SLSTokenTouch,
      @"A": @"ෟ", @"S": @"ී", @"D": @"ෘ", @"F": @"ෆ", @"G": @"ඨ", @"H": SLSTokenYansaya,
      @"J": @"ළු", @"K": @"ණ", @"L": @"ඛ", @":": @"ථ", @"\"": @",",
      @"Z": @"\"", @"X": @"ඞ", @"C": @"ඣ", @"V": @"ඪ", @"B": @"ඊ", @"N": @"භ",
      @"M": @"ඵ", @"<": @"ළ", @">": @"ඝ", @"?": @"?"
    };
  });
  return map;
}

+ (NSDictionary<NSString *, NSString *> *)slsAltGrMap {
  static NSDictionary *map;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    map = @{
      @"o": @"ඳ", @".": @"ඟ", @"v": @"ඬ", @"c": @"ඦ",
      @"x": @"ඃ", @"'": @"෴", @",": @"ඏ", @"a": @"ෳ",
      @"z": SLSTokenSanyakaya, @"\\": SLSTokenTouch, @" ": @"\u200C"
    };
  });
  return map;
}

+ (NSString *)slsCharacterForInput:(NSString *)input shifted:(BOOL)shifted altGr:(BOOL)altGr {
  NSString *mapped = nil;
  if (altGr) {
    mapped = [self slsAltGrMap][[input lowercaseString]];
  }
  if (!mapped) {
    mapped = shifted ? [self slsShiftMap][input] : [self slsNormalMap][input];
  }
  return mapped ?: input;
}

+ (BOOL)isSinhalaScalar:(unichar)ch {
  return ch >= 0x0D80 && ch <= 0x0DFF;
}

+ (BOOL)isSinhalaConsonant:(unichar)ch {
  return ch >= 0x0D9A && ch <= 0x0DC6;
}

+ (BOOL)isSinhalaInputUnit:(NSString *)input {
  for (NSUInteger i = 0; i < input.length; i++) {
    unichar ch = [input characterAtIndex:i];
    if ([self isSinhalaScalar:ch] || ch == 0x200C || ch == 0x200D ||
        (ch >= 0xE000 && ch <= 0xE0FF)) {
      return YES;
    }
  }
  return NO;
}

+ (BOOL)isIndependentVowel:(unichar)ch {
  return ch >= 0x0D85 && ch <= 0x0D96;
}

+ (BOOL)isDependentVowelSign:(unichar)ch {
  return (ch >= 0x0DCF && ch <= 0x0DD4) || ch == 0x0DD6 ||
         (ch >= 0x0DD8 && ch <= 0x0DDF) || ch == 0x0DF2 || ch == 0x0DF3;
}

+ (BOOL)isTrailingVowelSign:(unichar)ch {
  return (ch >= 0x0DCF && ch <= 0x0DD4) || ch == 0x0DD6 ||
         ch == 0x0DD8 || ch == 0x0DDF || ch == 0x0DF2 || ch == 0x0DF3;
}

+ (BOOL)isSemiConsonantSign:(unichar)ch {
  return ch == 0x0D82 || ch == 0x0D83;
}

+ (unichar)charAt:(NSString *)input index:(NSUInteger)index {
  return [input characterAtIndex:index];
}

+ (void)appendStandaloneSign:(unichar)sign to:(NSMutableString *)out {
  [out appendFormat:@"%C%C", (unichar)0x200C, sign];
}

+ (NSString *)sanyakayaForConsonant:(unichar)base {
  switch (base) {
    case 0x0D9C: return @"ඟ";
    case 0x0DA2: return @"ඦ";
    case 0x0DA9: return @"ඬ";
    case 0x0DAF: return @"ඳ";
    default: return nil;
  }
}

+ (NSString *)composeIndependentVowel:(unichar)vowel input:(NSString *)input index:(NSUInteger *)index {
  if (*index < input.length) {
    unichar next = [self charAt:input index:*index];
    if (vowel == 0x0D85) {
      if (next == 0x0DCF) { (*index)++; return @"ආ"; }
      if (next == 0x0DD0) { (*index)++; return @"ඇ"; }
      if (next == 0x0DD1) { (*index)++; return @"ඈ"; }
    }
    if (vowel == 0x0D91 && next == 0x0DCA) {
      (*index)++;
      return @"ඒ";
    }
    if (vowel == 0x0D89 && next == 0x0DD3) {
      (*index)++;
      return @"ඊ";
    }
    if (vowel == 0x0D94) {
      if (next == 0x0DCA) { (*index)++; return @"ඕ"; }
      if (next == 0x0DDF || next == 0x0DD6) { (*index)++; return @"ඖ"; }
    }
    if (vowel == 0x0D8B && (next == 0x0DDF || next == 0x0DD6)) {
      (*index)++;
      return @"ඌ";
    }
    if (vowel == 0x0D8D && next == 0x0DD8) {
      (*index)++;
      return @"ඎ";
    }
  }
  return [NSString stringWithFormat:@"%C", vowel];
}

+ (NSString *)vowelSignForPrefixCount:(NSUInteger)prefixCount input:(NSString *)input index:(NSUInteger *)index {
  if (prefixCount >= 2) {
    return @"ෛ";
  }
  if (prefixCount == 1) {
    if (*index < input.length) {
      unichar next = [self charAt:input index:*index];
      if (next == 0x0DCA) {
        (*index)++;
        return @"ේ";
      }
      if (next == 0x0DCF) {
        (*index)++;
        if (*index < input.length && [self charAt:input index:*index] == 0x0DCA) {
          (*index)++;
          return @"ෝ";
        }
        return @"ො";
      }
      if (next == 0x0DDF) {
        (*index)++;
        return @"ෞ";
      }
    }
    return @"ෙ";
  }
  if (*index < input.length) {
    unichar next = [self charAt:input index:*index];
    if ([self isTrailingVowelSign:next] || next == 0x0DCA) {
      (*index)++;
      if (next == 0x0DD8 && *index < input.length && [self charAt:input index:*index] == 0x0DD8) {
        (*index)++;
        return @"ෲ";
      }
      return [NSString stringWithFormat:@"%C", next];
    }
  }
  return @"";
}

+ (void)appendTrailingSemiSignsFrom:(NSString *)input index:(NSUInteger *)index to:(NSMutableString *)out {
  while (*index < input.length) {
    unichar next = [self charAt:input index:*index];
    if ([self isSemiConsonantSign:next]) {
      [out appendFormat:@"%C", next];
      (*index)++;
      continue;
    }
    break;
  }
}

+ (NSString *)composeConsonantClusterWithBase:(unichar)base
                                        input:(NSString *)input
                                        index:(NSUInteger *)index {
  NSMutableString *cluster = [NSMutableString stringWithFormat:@"%C", base];
  while (*index < input.length) {
    unichar marker = [self charAt:input index:*index];
    if (marker == 0xE000 || marker == 0xE001) {
      if (*index + 1 < input.length && [self isSinhalaConsonant:[self charAt:input index:*index + 1]]) {
        unichar nextBase = [self charAt:input index:*index + 1];
        [cluster appendFormat:@"%C%C%C", (unichar)0x0DCA, (unichar)0x200D, nextBase];
        *index += 2;
        continue;
      }
      break;
    }
    if (marker == 0xE004) {
      [cluster appendFormat:@"%C%C%C", (unichar)0x0DCA, (unichar)0x200D, (unichar)0x0DBB];
      (*index)++;
      continue;
    }
    if (marker == 0xE005) {
      [cluster appendFormat:@"%C%C%C", (unichar)0x0DCA, (unichar)0x200D, (unichar)0x0DBA];
      (*index)++;
      continue;
    }
    if (marker == 0xE002) {
      [cluster insertString:@"ර්‍" atIndex:0];
      (*index)++;
      continue;
    }
    break;
  }
  return cluster;
}

+ (NSString *)normalizeSLSInputOrder:(NSString *)input {
  NSMutableString *out = [NSMutableString string];
  NSUInteger i = 0;

  while (i < input.length) {
    unichar ch = [input characterAtIndex:i];

    if (ch == 0x0DD9) {
      NSUInteger prefixCount = 0;
      while (i < input.length && [self charAt:input index:i] == 0x0DD9) {
        prefixCount++;
        i++;
      }

      if (i < input.length && [self isSinhalaConsonant:[self charAt:input index:i]]) {
        unichar base = [self charAt:input index:i++];
        NSString *sanyaka = nil;
        if (i < input.length && [self charAt:input index:i] == 0xE003) {
          sanyaka = [self sanyakayaForConsonant:base];
          if (sanyaka) {
            i++;
          }
        }
        NSMutableString *syllable = [NSMutableString stringWithString:sanyaka ?: [self composeConsonantClusterWithBase:base input:input index:&i]];
        [syllable appendString:[self vowelSignForPrefixCount:prefixCount input:input index:&i]];
        [self appendTrailingSemiSignsFrom:input index:&i to:syllable];
        [out appendString:[syllable precomposedStringWithCanonicalMapping]];
        continue;
      }

      if (prefixCount == 1 && i < input.length && [self charAt:input index:i] == 0x0D91) {
        [out appendString:@"ඓ"];
        i++;
        continue;
      }

      for (NSUInteger pending = 0; pending < prefixCount; pending++) {
        [self appendStandaloneSign:0x0DD9 to:out];
      }
      continue;
    }

    if ([self isIndependentVowel:ch]) {
      i++;
      NSMutableString *vowel = [NSMutableString stringWithString:[self composeIndependentVowel:ch input:input index:&i]];
      [self appendTrailingSemiSignsFrom:input index:&i to:vowel];
      [out appendString:vowel];
      continue;
    }

    if ([self isSinhalaConsonant:ch]) {
      i++;
      NSString *sanyaka = nil;
      if (i < input.length && [self charAt:input index:i] == 0xE003) {
        sanyaka = [self sanyakayaForConsonant:ch];
        if (sanyaka) {
          i++;
        }
      }
      NSMutableString *syllable = [NSMutableString stringWithString:sanyaka ?: [self composeConsonantClusterWithBase:ch input:input index:&i]];
      [syllable appendString:[self vowelSignForPrefixCount:0 input:input index:&i]];
      [self appendTrailingSemiSignsFrom:input index:&i to:syllable];
      [out appendString:[syllable precomposedStringWithCanonicalMapping]];
      continue;
    }

    if ([self isDependentVowelSign:ch] || ch == 0x0DCA || [self isSemiConsonantSign:ch]) {
      [self appendStandaloneSign:ch to:out];
      i++;
      continue;
    }

    if (ch == 0xE004) {
      [self appendStandaloneSign:0x0DCA to:out];
      [out appendFormat:@"%C%C", (unichar)0x200D, (unichar)0x0DBB];
      i++;
      continue;
    }
    if (ch == 0xE005) {
      [self appendStandaloneSign:0x0DCA to:out];
      [out appendFormat:@"%C%C", (unichar)0x200D, (unichar)0x0DBA];
      i++;
      continue;
    }
    if (ch == 0xE002) {
      [out appendString:@"ර්‍"];
      i++;
      continue;
    }
    if (ch == 0xE003) {
      i++;
      continue;
    }
    if (ch == 0xE000 || ch == 0xE001) {
      i++;
      if (i < input.length && [self isSinhalaConsonant:[self charAt:input index:i]]) {
        [out appendFormat:@"%C%C%C", (unichar)0x0DCA, (unichar)0x200D, [self charAt:input index:i]];
        i++;
      }
      continue;
    }

    [out appendFormat:@"%C", ch];
    i++;
  }

  return [out precomposedStringWithCanonicalMapping];
}

+ (NSString *)markedSLSInputOrder:(NSString *)input {
  NSString *normalized = [self normalizeSLSInputOrder:input];
  NSString *pendingKombuwa = @"\u200Cෙ";
  NSUInteger visibleLength = normalized.length;

  while (visibleLength >= pendingKombuwa.length &&
         [[normalized substringWithRange:NSMakeRange(visibleLength - pendingKombuwa.length,
                                                     pendingKombuwa.length)]
             isEqualToString:pendingKombuwa]) {
    visibleLength -= pendingKombuwa.length;
  }

  return [normalized substringToIndex:visibleLength];
}

@end
