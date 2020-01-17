//
//  ISONewsBody.h
//  Halime
//
//  Created by iso on Mon May 21 2001.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ISONewsBody : NSObject
{
	NSString	*body;
}

- init;
- initFromString:(NSString *)aString;
- (BOOL)readFromString:(NSString *)aString;
- (BOOL)writeToString:(NSMutableString *)aString;
- (NSString *)body;
- (int)hasAttachments;
@end
