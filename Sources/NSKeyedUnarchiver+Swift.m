//
//  NSKeyedUnarchiver+SwiftUtilities.h
//  RxCache
//
//  Created by George Tsifrikas
//  Copyright (c) 2017 George Tsifrikas. All rights reserved.
//

#import "NSKeyedUnarchiver+Swift.h"

@implementation NSKeyedUnarchiver (Swift)

+ (id) unarchiveObjectSafelyWithFilePath:(NSString *)filePath {
  id object = nil;
  
  @try {
    object = [self unarchiveObjectWithFile:filePath];
  } @catch (NSException *exception) {
    object = nil;
  }
  
  return object;
}

+ (id) unarchiveObjectSafelyWithData:(NSData *)data {
  id object = nil;
  
  @try {
    object = [self unarchiveObjectWithData:data];
  } @catch (NSException *exception) {
    object = nil;
  }
  
  return object;
}

@end
