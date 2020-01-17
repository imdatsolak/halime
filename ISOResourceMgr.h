//
//  ISOResourceMgr.h
//  Halime
//
//  Created by iso on Sat May 19 2001.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ISONewsGroup.h"

@interface ISOResourceMgr : NSObject
{

}

+ (void)createResourceFilesIfNeeded;
+ (BOOL)createDirectory:(NSString *)aDirectory;
+ (BOOL)removePath:(NSString *)aDirectory;
+ (char *)extensionForActiveList;
+ (char *)extensionForSubscription;
+ (NSString *)halimeResourceDirectory;
+ (NSString *)fullResourcePathForFile:(char *)aFile;
+ (NSString *)fullResourcePathForFileWithString:(NSString *)aFile;
+ (NSString *)fullResourcePathFormNewsGroup:(ISONewsGroup *)aGroup;
@end
