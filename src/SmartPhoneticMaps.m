#import "SmartPhoneticMaps.h"

@implementation SmartPhoneticMaps

+ (NSDictionary<NSString *, NSString *> *)smartConsonants {
  static NSDictionary *map;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    map = @{
      @"k": @"ක", @"g": @"ග",
      @"ch": @"ච", @"j": @"ජ",
      @"t": @"ට", @"d": @"ඩ",
      @"th": @"ත",
      @"dh": @"ද", @"q": @"ද",
      @"n": @"න", @"N": @"ණ",
      @"p": @"ප", @"b": @"බ",
      @"m": @"ම",
      @"y": @"ය", @"r": @"ර", @"l": @"ල", @"L": @"ළ",
      @"w": @"ව", @"v": @"ව",
      @"s": @"ස", @"sh": @"ශ", @"S": @"ෂ", @"Sh": @"ෂ",
      @"h": @"හ",
      @"f": @"ෆ",
      @"kh": @"ඛ", @"gh": @"ඝ",
      @"chh": @"ඡ",
      @"T": @"ඨ",
      @"D": @"ඪ",
      @"thh": @"ථ", @"dhh": @"ධ",
      @"ph": @"ඵ", @"bh": @"භ",
      @"zg": @"ඟ", @"zj": @"ඦ", @"zd": @"ඬ", @"zdh": @"ඳ", @"zq": @"ඳ",
      @"zk": @"ඤ", @"zh": @"ඥ", @"B": @"ඹ",
      @"X": @"ඞ"
    };
  });
  return map;
}

+ (NSDictionary<NSString *, NSString *> *)smartVowels {
  static NSDictionary *map;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    map = @{
      @"a": @"අ", @"aa": @"ආ",
      @"A": @"ඇ", @"Aa": @"ඈ", @"AA": @"ඈ",
      @"i": @"ඉ", @"ii": @"ඊ",
      @"u": @"උ", @"uu": @"ඌ",
      @"R": @"ඍ", @"Ru": @"ඎ",
      @"e": @"එ", @"ee": @"ඒ",
      @"ai": @"ඓ",
      @"o": @"ඔ", @"oo": @"ඕ",
      @"au": @"ඖ", @"ou": @"ඖ"
    };
  });
  return map;
}

+ (NSDictionary<NSString *, NSString *> *)smartVowelSigns {
  static NSDictionary *map;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    map = @{
      @"a": @"", @"aa": @"ා",
      @"A": @"ැ", @"Aa": @"ෑ", @"AA": @"ෑ",
      @"i": @"ි", @"ii": @"ී",
      @"u": @"ු", @"uu": @"ූ",
      @"e": @"ෙ", @"ee": @"ේ",
      @"ai": @"ෛ",
      @"o": @"ො", @"oo": @"ෝ",
      @"au": @"ෞ", @"ou": @"ෞ",
      @"ru": @"ෘ", @"ruu": @"ෲ"
    };
  });
  return map;
}

+ (NSArray<NSString *> *)smartConsonantKeys {
  return @[@"chh", @"thh", @"dhh", @"zdh",
           @"ch", @"th", @"dh", @"sh", @"Sh", @"kh", @"gh", @"ph", @"bh",
           @"zg", @"zj", @"zd", @"zq", @"zk", @"zh",
           @"k", @"g", @"j", @"t", @"d", @"q", @"n", @"N", @"p", @"b", @"m",
           @"y", @"r", @"l", @"L", @"w", @"v", @"s", @"S", @"h", @"f",
           @"T", @"D", @"B", @"X"];
}

+ (NSArray<NSString *> *)smartVowelKeys {
  return @[@"ruu", @"aee", @"Aa", @"AA", @"aa", @"ii", @"uu", @"ee", @"ai", @"oo", @"au", @"ou", @"Ru", @"ru",
           @"A", @"I", @"U", @"E", @"O", @"a", @"i", @"u", @"e", @"o", @"R"];
}

@end
