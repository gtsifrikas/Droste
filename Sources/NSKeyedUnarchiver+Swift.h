//
//  NSKeyedUnarchiver+SwiftUtilities.h
//  RxCache
//
//  Created by George Tsifrikas
//  Copyright (c) 2017 George Tsifrikas. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSKeyedUnarchiver (Swift)

/**
 Safely unarchives an object at a given file path through NSKeyedUnarchiver
 
 :param: filePath The path to the file to unarchive
 
 :returns: The unarchived object if the unarchive operation was successful, or nil if the unarchiver threw an exception
 */
+ (id) unarchiveObjectSafelyWithFilePath:(NSString *)filePath;

@end
