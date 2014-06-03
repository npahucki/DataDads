//
//  PronounHelper.m
//  
//
//  Created by Nathan  Pahucki on 6/3/14.
//
//

#define PRONOUN_FILE_NAME @"Pronouns"

#import "PronounHelper.h"

@implementation PronounHelper

static NSArray * sTokenList;

+ (void)initialize {
  if (self == [PronounHelper self]) {
    // Dynamically load all the possible keys
    NSString *path = [[NSBundle mainBundle] pathForResource:PRONOUN_FILE_NAME
                                                     ofType:@"strings"
                                                inDirectory:nil
                                            forLocalization:nil];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
    NSMutableArray * tokenList = [[NSMutableArray alloc] initWithCapacity:dict.count / 2];
    for(NSString * token in [dict allKeys]) {
      NSString * newToken = [token substringWithRange:NSMakeRange(0, token.length - 2)];
      if(![tokenList containsObject:newToken]) {
        [tokenList addObject:newToken];
      }
    }
    sTokenList = tokenList;
  }
}

+(NSString*) replacePronounTokens:(NSString*) input forBaby:(Baby*) baby {
  NSString* result = input;
  for (NSString* token in sTokenList) {
    NSString * key = [NSString stringWithFormat:@"%@:%d",token, baby.isMale];
    NSString * replacement = [[NSBundle mainBundle] localizedStringForKey:key value:token table:PRONOUN_FILE_NAME];
    result = [result stringByReplacingOccurrencesOfString:token withString:replacement];
  }
  return result;
}




@end
