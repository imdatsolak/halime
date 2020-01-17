//
//  ISOResourceMgr.m
//  Halime
//
//  Created by iso on Sat May 19 2001.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import "ISOResourceMgr.h"
#import "ISONewsServer.h"

#define K_HALIME_DEFAULT_DIRECTORY				"Library/Application Support/Halime"
#define K_HALIME_DEFAULT_DIRECTORY_AS_STRING	@"Library/Application Support/Halime"

//#define K_HALIME_DEFAULT_DIRECTORY				"Library/News"
//#define K_HALIME_DEFAULT_DIRECTORY_AS_STRING	@"Library/News"

@implementation ISOResourceMgr

+ (void)createResourceFilesIfNeeded
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *path = [self halimeResourceDirectory];
	
	[fileManager createDirectoryAtPath:path attributes:nil];
}

+ (BOOL)removePath:(NSString *)aDirectory
{
	[[NSFileManager defaultManager] removeFileAtPath:aDirectory handler:nil];
	return YES;
}


+ (BOOL)createDirectory:(NSString *)aDirectory
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	BOOL	isDir = NO;
	
	if ([fileManager fileExistsAtPath:aDirectory isDirectory:&isDir] && isDir) {
		return YES;
	} else {
		if ([self createDirectory:[aDirectory stringByDeletingLastPathComponent]]) {
			return [fileManager createDirectoryAtPath:aDirectory attributes:nil];
		} else {
			return NO;
		}
	}
}


+ (char *)extensionForActiveList
{
	return ".halime_active";
}

+ (char *)extensionForSubscription
{
	return ".halime";
}

+ (NSString *)halimeResourceDirectory
{
	char buffer[4096];
	char b[4096];
	
	[NSHomeDirectory() getCString:b];
	sprintf(buffer, "%s/%s", b, K_HALIME_DEFAULT_DIRECTORY);
	return [[NSString stringWithCString:buffer] retain];
}


+ (NSString *)fullResourcePathForFile:(char *)aFile
{
	char buffer[4096];
	char b[4096];

	[NSHomeDirectory() getCString:b];
	sprintf(buffer, "%s/%s/%s", b, K_HALIME_DEFAULT_DIRECTORY, aFile);
	return [[NSString stringWithCString:buffer] retain];
}

+ (NSString *)fullResourcePathForFileWithString:(NSString *)aFile
{
	NSMutableString *aString;
	
	aString = [NSMutableString stringWithString:NSHomeDirectory()];
	[aString appendString:@"/"];
	[aString appendString:K_HALIME_DEFAULT_DIRECTORY_AS_STRING];
	[aString appendString:@"/"];
	[aString appendString:aFile];
	[aString retain];
	return aString;

}

+ (NSString *)fullResourcePathFormNewsGroup:(ISONewsGroup *)aGroup
{
	NSRange	aRange;
	
	if (aGroup) {
		NSMutableString	*result = [NSMutableString stringWithString:NSHomeDirectory()];
		NSMutableString	*aString = [NSMutableString stringWithString:[aGroup groupName]];
		
		[result appendString:@"/"];
		[result appendString:K_HALIME_DEFAULT_DIRECTORY_AS_STRING];
		[result appendString:@"/"];
		if ([aGroup newsServer] && [[aGroup newsServer] serverName]) {
			[result appendString:[[aGroup newsServer] serverName]];
			[result appendString:@"/"];
		}
		aRange = [aString rangeOfString:@"."];
		while (aRange.length == 1) {
			[aString replaceCharactersInRange:aRange withString:@"/"];
			aRange = [aString rangeOfString:@"."];
		}
		[result appendString:aString];
		[result retain];
		return result;
	} else {
		return nil;
	}
}

@end
