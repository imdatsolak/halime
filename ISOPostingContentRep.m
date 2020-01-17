//
//  ISOPostingContentRep.m
//  Halime
//
//  Created by iso on Wed Jun 13 2001.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import "ISOPostingContentRep.h"


@implementation ISOPostingContentRep

- initLazyWithContentType:(NSString *)aContentType extension:(NSString *)anExtension forPath:(NSString *)aPath
{
	self = [super init];
	data = nil;
	contentType = aContentType;
	[contentType retain];
	extension = anExtension;
	[extension retain];
	thePath = aPath;
	[thePath retain];
	return self;
}

- initWithData:(NSData *)aData contentType:(NSString *)aContentType extension:(NSString *)anExtension
{
	self = [super init];
	data = aData;
	[data retain];
	contentType = aContentType;
	[contentType retain];
	extension = anExtension;
	[extension retain];
	thePath = nil;
	return self;
}

- (void)dealloc
{
	[data release];
	[contentType release];
	[extension release];
	[thePath release];
	[super dealloc];
}

- setPath:(NSString *)aPath
{
	if (thePath) {
		[thePath release];
	}
	thePath = aPath;
	[thePath retain];
	return self;
}

- (NSString *)path
{
	return thePath;
}

- setData:(NSData *)aData
{
	if (data) {
		[data release];
	}
	data = aData;
	[data retain];
	return self;
}

- (NSData *)data
{
	if (!data && thePath) {
		data = [NSData dataWithContentsOfFile:thePath];
		[data retain];
	}
	return data;
}

- setContentType:(NSString *)aContentType
{
	if (contentType) {
		[contentType release];
	}
	contentType = aContentType;
	[contentType retain];
	return self;
}

- (NSString *)contentType
{
	return contentType;
}

- setExtension:(NSString *)anExtension
{
	if (extension) {
		[extension release];
	}
	extension = anExtension;
	[extension retain];
	return self;
}

- (NSString *)extension
{
	return extension;
}

- (NSString *)repName
{
	return [thePath lastPathComponent];
}

- (int)repSize
{
	return [[self data] length];
}
@end
