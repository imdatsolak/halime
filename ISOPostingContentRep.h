//
//  ISOPostingContentRep.h
//  Halime
//
//  Created by iso on Wed Jun 13 2001.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ISOPostingContentRep : NSObject 
{
	NSString	*contentType;
	NSString	*extension;
	NSData		*data;
	NSString	*thePath;
}

- initLazyWithContentType:(NSString *)aContentType extension:(NSString *)anExtension forPath:(NSString *)aPath;
- initWithData:(NSData *)aData contentType:(NSString *)aContentType extension:(NSString *)anExtension;
- (void)dealloc;
- setPath:(NSString *)aPath;
- (NSString *)path;
- (NSData *)data;
- setData:(NSData *)aData;
- (NSString *)contentType;
- setContentType:(NSString *)aContentType;
- (NSString *)extension;
- setExtension:(NSString *)anExtension;
- (NSString *)repName;
- (int)repSize;
@end
