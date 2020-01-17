//
//  ISOSignatureMgr.m
//  Halime
//
//  Created by Imdat Solak on Mon Jan 28 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import "ISOSignatureMgr.h"
#import "ISOSignatureMgr.h"
#import "ISOResourceMgr.h"
#import "ISOPreferences.h"

#define K_SIGNATURESFILE	@"Signatures.plist"

@implementation ISOSignatureMgr
static ISOSignatureMgr	*sharedSignatureMgr = nil;

+ sharedSignatureMgr
{
	if (sharedSignatureMgr == nil) {
		sharedSignatureMgr = [[self alloc] init];
	}
	return sharedSignatureMgr;
}

- (void)_loadSignatures
{
	if (!signatures) {
		NSString		*aString;
		NSDictionary	*aDict;
		int				i, count;
		
		randomSignatures = [[NSMutableArray array] retain];
		aString = [ISOResourceMgr fullResourcePathForFileWithString:K_SIGNATURESFILE];
		aDict = [NSDictionary dictionaryWithContentsOfFile:aString];
		if (aDict) {
			lastRandomSigIndex = [[aDict objectForKey:@"LastRandomSigIndex"] intValue];
			signatures = [NSMutableArray arrayWithArray:[aDict objectForKey:@"Signatures"]];
		} else {
			lastRandomSigIndex = 0;
			signatures = [NSMutableArray array];
		}
	
		[signatures retain];
		count = [signatures count];
		for (i=0;i<count;i++) {
			NSMutableDictionary	*signature = [signatures objectAtIndex:i];
			if ([[signature objectForKey:@"SignatureSigRandom"] boolValue]) {
				[randomSignatures addObject:signature];
			}
		}
	}
}

- (void)_saveSignatures
{
	NSString		*aString;
	NSDictionary	*aDict = [NSDictionary dictionaryWithObjectsAndKeys:
								signatures, @"Signatures",
								[NSNumber numberWithInt:lastRandomSigIndex], @"LastRandomSigIndex",
								nil];
	aString = [ISOResourceMgr fullResourcePathForFileWithString:K_SIGNATURESFILE];
	[aDict writeToFile:aString atomically:NO];
}


- init
{
	if (!sharedSignatureMgr) {
		sharedSignatureMgr = [super init];
		[self _loadSignatures];
	} else {
		[self dealloc];
	}
	lastRandomSigIndex = 0;
	return sharedSignatureMgr;
}

- (void)dealloc
{
	[signatures release];
	[randomSignatures release];
	[super dealloc];
}

- (void)updateSignatureTable
{
	[signatureTable reloadData];
	[signatureTable setTarget:self];
	[signatureTable setAction:@selector(signatureSelected:)];
	[signatureTable setDoubleAction:@selector(changeSignature:)];
}

- (void)signatureSelected:sender
{
	[removeSignatureButton setEnabled:([signatureTable selectedRow] >= 0)];
	[changeSignatureButton setEnabled:([signatureTable selectedRow] >= 0)];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)context
{
}


- (void)addSignature:sender
{
	[sheetOkButton setTarget:self];
	[sheetOkButton setAction:@selector(reallyAddSignature:)];
	[sheetOkButton setTitle:NSLocalizedString(@"Add", @"")];
	[[NSApplication sharedApplication] beginSheet:signatureSheet
			modalForWindow:[signatureTable window]
			modalDelegate:self
			didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
			contextInfo:nil];
}

- (void)removeSignature:sender
{
	int	rowIndex = [signatureTable selectedRow];
	
	if (rowIndex >=0 && (rowIndex < [signatures count])) {
		NSDictionary *signature = [signatures objectAtIndex:rowIndex];
		[randomSignatures removeObject:signature];
		[signatures removeObjectAtIndex:rowIndex];
		[self _saveSignatures];
		[signatureTable reloadData];
	}
}

- (void)changeSignature:sender
{
	int	rowIndex = [signatureTable selectedRow];
	
	if (rowIndex >=0 && (rowIndex < [signatures count])) {
		NSMutableDictionary	*signature = [signatures objectAtIndex:rowIndex];
		
		[titleField setStringValue:[signature objectForKey:@"SignatureTitle"]];
		[signatureField setString:[signature objectForKey:@"SignatureText"]];
		[randomSigSwitch setState:[[signature objectForKey:@"SignatureSigRandom"] boolValue]? 1:0];
	}
	[sheetOkButton setTarget:self];
	[sheetOkButton setAction:@selector(reallyChangeSignature:)];
	[sheetOkButton setTitle:NSLocalizedString(@"Change", @"")];
	[[NSApplication sharedApplication] beginSheet:signatureSheet
			modalForWindow:[signatureTable window]
			modalDelegate:self
			didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
			contextInfo:nil];
}

- (void)reallyChangeSignature:sender
{
	int	rowIndex = [signatureTable selectedRow];
	
	if (rowIndex >=0 && (rowIndex < [signatures count])) {
		NSMutableDictionary	*signature = [signatures objectAtIndex:rowIndex];
		[signature setObject:[titleField stringValue] forKey:@"SignatureTitle"];
		[signature setObject:[NSString stringWithString:[signatureField string]] forKey:@"SignatureText"];
		[signature setObject:[NSNumber numberWithBool:[randomSigSwitch state]? YES:NO] forKey:@"SignatureSigRandom"];
		if ([randomSigSwitch state] && ![randomSignatures containsObject:signature]) {
			[randomSignatures addObject:signature];
		} else if (![randomSigSwitch state] && [randomSignatures containsObject:signature]) {
			[randomSignatures removeObject:signature];
		}
	}
	[signatureSheet orderOut:self];
	[[NSApplication sharedApplication] endSheet:signatureSheet];
	[signatureTable reloadData];
	[self _saveSignatures];
}

- (void)reallyAddSignature:sender
{
	NSMutableDictionary	*signature = [NSMutableDictionary dictionary];
		
	[signature setObject:[titleField stringValue] forKey:@"SignatureTitle"];
	[signature setObject:[signatureField string] forKey:@"SignatureText"];
	[signature setObject:[NSNumber numberWithBool:[randomSigSwitch state]? YES:NO] forKey:@"SignatureSigRandom"];
	[signatures addObject:signature];
	if ([randomSigSwitch state]) {
		[randomSignatures addObject:signature];
	}
	[signatureSheet orderOut:self];
	[[NSApplication sharedApplication] endSheet:signatureSheet];
	[self _saveSignatures];
	[signatureTable reloadData];
}

- (void)cancel:sender
{
	[signatureSheet orderOut:self];
	[[NSApplication sharedApplication] endSheet:signatureSheet];
}

- (NSString *)signatureTitleAtIndex:(int)index
{
	if ((index >=0) && (index < [signatures count]) ) {
		NSMutableDictionary	*signature = [signatures objectAtIndex:index];
		return [signature objectForKey:@"SignatureTitle"];
	} else {
		return @"";
	}
}

- (int)indexOfSignature:(NSString *)sigTitle
{
	int i, count;
	
	count = [signatures count];
	for (i=0;i<count;i++) {
		NSMutableDictionary	*signature = [signatures objectAtIndex:i];
		if ([((NSString *)[signature objectForKey:@"SignatureTitle"]) compare:sigTitle] == NSOrderedSame) {
			return i;
		}
	}
	return -1;
}

- (NSString *)signatureAtIndex:(int)index
{
	if ((index >=0) && (index < [signatures count]) ) {
		return [[signatures objectAtIndex:index] objectForKey:@"SignatureText"];
	} else {
		return @"";
	}
}

- (NSString *)randomSignature
{
    time_t t;
    srand(time(&t));
	if ([randomSignatures count]) {
		int anIndex = rand() % [randomSignatures count];
		return [[randomSignatures objectAtIndex:anIndex] objectForKey:@"SignatureText"];
	} else {
		return @"";
	}
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [signatures count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if ((rowIndex >=0) && (rowIndex < [signatures count]) ) {
		NSMutableDictionary	*signature = [signatures objectAtIndex:rowIndex];
		if ([(NSString *)[aTableColumn identifier] compare:@"S_TITLE"] == NSOrderedSame) {
			return [signature objectForKey:@"SignatureTitle"];
		} else if ([(NSString *)[aTableColumn identifier] compare:@"S_RANDOM"] == NSOrderedSame) {
			if ([[signature objectForKey:@"SignatureSigRandom"] boolValue]) {
				return NSLocalizedString(@"YES", @"");
			} else {
				return NSLocalizedString(@"NO", @"");
			}
		} else {
			return @"???";
		}
	} else {
		return @"??";
	}
}

- (void)readSignatureFile:(NSString *)filename
{
	NSString	*signatureText = [NSString stringWithContentsOfFile:filename];
	NSString	*oneString;
	BOOL		found = NO;
		
	if (signatureText) {
		NSScanner *scanner = [NSScanner scannerWithString:signatureText];
		while ([scanner scanUpToString:@"\n%\n" intoString:&oneString]) {
			NSMutableDictionary	*signature = [NSMutableDictionary dictionary];
			NSString *title = [NSString stringWithFormat:@"%@...", [oneString substringToIndex:MIN(48, [oneString length])]];
			[signature setObject:title forKey:@"SignatureTitle"];
			[signature setObject:oneString forKey:@"SignatureText"];
			[signature setObject:[NSNumber numberWithBool:YES] forKey:@"SignatureSigRandom"];
			[signatures addObject:signature];
			[randomSignatures addObject:signature];
			[scanner scanString:@"%\n" intoString:nil];
			found = YES;
		}
		if (found) {
			[self _saveSignatures];
			[signatureTable reloadData];
		} else {
			NSRunAlertPanel(NSLocalizedString(@"Couldn't find any signatures in file", @""),
				@"Sorry, but I couldn't find any signatures in the file specified. The signatures must be separated by the percent-sign (%) on a line by itself.",
				NSLocalizedString(@"OK", @""),
				nil,
				nil);
		}
	}
}

- (void)reallyImportSignatures:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)conInfo
{
	[sheet orderOut:self];
	if (returnCode == NSFileHandlingPanelOKButton) {
		NSArray		*filenames = [((NSOpenPanel *)sheet) filenames];
		NSString	*filename;

		if ([filenames count]) {
			filename = [filenames objectAtIndex:0];
			[[ISOPreferences sharedInstance] setGenericPref:[filename stringByDeletingLastPathComponent] forKey:@"ISOLastSelectedSignatureDirectory"];
			[self readSignatureFile:filename];
		}
	}
}

- (void)importSignatures:sender
{
	NSOpenPanel		*openPanel = [NSOpenPanel openPanel];
	
	[openPanel setTitle:NSLocalizedString(@"Import Signatures", @"")];
	[openPanel setCanChooseFiles:YES];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel beginSheetForDirectory:[[ISOPreferences sharedInstance] genericPrefForKey:@"ISOLastSelectedSignatureDirectory"]
				file:@""
				modalForWindow:[signatureTable window]
				modalDelegate:self
				didEndSelector:@selector(reallyImportSignatures:returnCode:contextInfo:)
				contextInfo:nil];
}


@end
