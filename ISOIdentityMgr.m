//
//  ISOIdentityMgr.m
//  Halime
//
//  Created by Imdat Solak on Mon Jan 28 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import "ISOIdentityMgr.h"
#import "ISOSignatureMgr.h"
#import "ISOResourceMgr.h"
#import "Functions.h"

#define K_IDENTITIESFILE	@"Identities.plist"

@implementation ISOIdentityMgr
static ISOIdentityMgr	*sharedIdentityMgr = nil;

+ sharedIdentityMgr
{
	if (sharedIdentityMgr == nil) {
		sharedIdentityMgr = [[self alloc] init];
	}
	return sharedIdentityMgr;
}

- (void)_loadIdentities
{
	NSString	*aString;
	
	aString = [ISOResourceMgr fullResourcePathForFileWithString:K_IDENTITIESFILE];
	identities = [NSMutableArray arrayWithContentsOfFile:aString];
	if (!identities) {
		identities = [NSMutableArray array];
	}
	[identities retain];
}

- (void)_saveIdentities
{
	NSString		*aString;

	aString = [ISOResourceMgr fullResourcePathForFileWithString:K_IDENTITIESFILE];
	[identities writeToFile:aString atomically:NO];
}


- init
{
	if (!sharedIdentityMgr) {
		sharedIdentityMgr = [super init];
		[self _loadIdentities];
	} else {
		[self dealloc];
	}
	return sharedIdentityMgr;
}

- (void)dealloc
{
	[identities release];
	[super dealloc];
}

- (void)updateIdentityTable
{
	[identityTable reloadData];
	[identityTable setTarget:self];
	[identityTable setAction:@selector(identitySelected:)];
	[identityTable setDoubleAction:@selector(changeIdentity:)];
}

- (void)identitySelected:sender
{
	[removeIdentityButton setEnabled:([identityTable selectedRow] >= 0)];
	[changeIdentityButton setEnabled:([identityTable selectedRow] >= 0)];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)context
{
}


- (void)addIdentity:sender
{
	[sheetOkButton setTarget:self];
	[sheetOkButton setAction:@selector(reallyAddIdentity:)];
	[sheetOkButton setTitle:NSLocalizedString(@"Add", @"")];
	[signatureTable reloadData];
	[[NSApplication sharedApplication] beginSheet:identitySheet
			modalForWindow:[identityTable window]
			modalDelegate:self
			didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
			contextInfo:nil];
}

- (void)removeIdentity:sender
{
	int	rowIndex = [identityTable selectedRow];
	
	if (rowIndex >=0 && (rowIndex < [identities count])) {
		[identities removeObjectAtIndex:rowIndex];
		[self _saveIdentities];
		[identityTable reloadData];
	}
}

- (void)changeIdentity:sender
{
	int	rowIndex = [identityTable selectedRow];

	[sheetOkButton setTarget:self];
	[sheetOkButton setAction:@selector(reallyChangeIdentity:)];
	[sheetOkButton setTitle:NSLocalizedString(@"Change", @"")];
	[signatureTable reloadData];
	
	if (rowIndex >=0 && (rowIndex < [identities count])) {
		NSMutableDictionary	*identity = [identities objectAtIndex:rowIndex];
		
		[emailField setStringValue:[identity objectForKey:@"IdentityEmail"]];
		[nameField setStringValue:[identity objectForKey:@"IdentityName"]];
		if ([identity objectForKey:@"IdentityIDName"]) {
			[idNameField setStringValue:[identity objectForKey:@"IdentityIDName"]];
		}
		if ([identity objectForKey:@"IdentityXFace"]) {
			[xFaceField setStringValue:[identity objectForKey:@"IdentityXFace"]];
		} else {
			[xFaceField setStringValue:@""];
		}
		if ([identity objectForKey:@"IdentityXFaceURL"]) {
			[xFaceURLField setStringValue:[identity objectForKey:@"IdentityXFaceURL"]];
		} else {
			[xFaceURLField setStringValue:@""];
		}
		[emailField setStringValue:[identity objectForKey:@"IdentityEmail"]];
		[isDefaultSwitch setState:[[identity objectForKey:@"IdentityIsDefault"] boolValue]? 1:0];
		[randomSigSwitch setState:[[identity objectForKey:@"IdentitySigRandom"] boolValue]? 1:0];
		[signatureTable selectRow:[[ISOSignatureMgr sharedSignatureMgr] indexOfSignature:[identity objectForKey:@"IdentitySignatureTitle"]] byExtendingSelection:NO];
	}
	
	[[NSApplication sharedApplication] beginSheet:identitySheet
			modalForWindow:[identityTable window]
			modalDelegate:self
			didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
			contextInfo:nil];
}

- (void)reallyChangeIdentity:sender
{
	int	rowIndex = [identityTable selectedRow];
	
	[identitySheet orderOut:self];
	[[NSApplication sharedApplication] endSheet:identitySheet];
	if ([isDefaultSwitch state]) {
		int i, count;
		
		count = [identities count];
		for (i=0;i<count;i++) {
			[[identities objectAtIndex:i] setObject:[NSNumber numberWithInt:0] forKey:@"IdentityIsDefault"];
		}
	}
	if (rowIndex >=0 && (rowIndex < [identities count])) {
		NSMutableDictionary	*identity = [identities objectAtIndex:rowIndex];
		
		[identity setObject:[emailField stringValue] forKey:@"IdentityEmail"];
		[identity setObject:[nameField stringValue] forKey:@"IdentityName"];
		[identity setObject:[idNameField stringValue] forKey:@"IdentityIDName"];
		[identity setObject:[xFaceField stringValue] forKey:@"IdentityXFace"];
		[identity setObject:[xFaceURLField stringValue] forKey:@"IdentityXFaceURL"];
		[identity setObject:[NSNumber numberWithBool:[isDefaultSwitch state]? YES:NO] forKey:@"IdentityIsDefault"];
		[identity setObject:[NSNumber numberWithBool:[randomSigSwitch state]? YES:NO] forKey:@"IdentitySigRandom"];
		[identity setObject:[[ISOSignatureMgr sharedSignatureMgr] signatureTitleAtIndex:[signatureTable selectedRow]] forKey:@"IdentitySignatureTitle"];
	}
	[identityTable reloadData];
	[self _saveIdentities];
}

- (void)reallyAddIdentity:sender
{
	NSMutableDictionary	*identity = [NSMutableDictionary dictionary];
	
	[identitySheet orderOut:self];
	[[NSApplication sharedApplication] endSheet:identitySheet];
		
	if ([isDefaultSwitch state]) {
		int i, count;
		
		count = [identities count];
		for (i=0;i<count;i++) {
			[[identities objectAtIndex:i] setObject:[NSNumber numberWithInt:0] forKey:@"IdentityIsDefault"];
		}
	}
	[identity setObject:[emailField stringValue] forKey:@"IdentityEmail"];
	[identity setObject:[nameField stringValue] forKey:@"IdentityName"];
	[identity setObject:[idNameField stringValue] forKey:@"IdentityIDName"];
	[identity setObject:[xFaceField stringValue] forKey:@"IdentityXFace"];
	[identity setObject:[xFaceURLField stringValue] forKey:@"IdentityXFaceURL"];
	[identity setObject:[NSNumber numberWithBool:[isDefaultSwitch state]? YES:NO] forKey:@"IdentityIsDefault"];
	[identity setObject:[NSNumber numberWithBool:[randomSigSwitch state]? YES:NO] forKey:@"IdentitySigRandom"];
	[identity setObject:[[ISOSignatureMgr sharedSignatureMgr] signatureTitleAtIndex:[signatureTable selectedRow]] forKey:@"IdentitySignatureTitle"];
	[identities addObject:identity];
	
	[self _saveIdentities];
	[identityTable reloadData];
}

- (void)cancel:sender
{
	[identitySheet orderOut:self];
	[[NSApplication sharedApplication] endSheet:identitySheet];
}

- (void)randomSigSwitchClicked:sender
{
	[signatureTable setEnabled:([randomSigSwitch state]==0)];
}

- (void)displayXFace:sender
{
	NSImage	*anImage = ISOCreateXFaceImageFromString([xFaceField stringValue]);
	if (anImage) {
		[anImage autorelease];
		[faceImageView setImage:anImage];
	} else {
		[faceImageView setImage:nil];
		NSBeep();
	}
}

- (void)displayXFaceURL:sender
{
	NSImage	*anImage = ISOCreateXFaceURLImageFromString([xFaceURLField stringValue]);
	if (anImage) {
		[anImage autorelease];
		[faceImageView setImage:anImage];
	} else {
		[faceImageView setImage:nil];
		NSBeep();
	}
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	if (aTableView == identityTable) {
		return [identities count];
	} else if (aTableView == signatureTable) {
		return [[ISOSignatureMgr sharedSignatureMgr] numberOfRowsInTableView:aTableView];
	} else {
		return 0;
	}
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if ((aTableView == identityTable)  && (rowIndex >=0) && (rowIndex < [identities count]) ){
		NSMutableDictionary	*identity = [identities objectAtIndex:rowIndex];
		if ([(NSString *)[aTableColumn identifier] compare:@"I_NAME"] == NSOrderedSame) {
			return [identity objectForKey:@"IdentityName"];
		} else if ([(NSString *)[aTableColumn identifier] compare:@"I_EMAIL"] == NSOrderedSame) {
			return [identity objectForKey:@"IdentityEmail"];
		} else if ([(NSString *)[aTableColumn identifier] compare:@"I_IDNAME"] == NSOrderedSame) {
			if ([identity objectForKey:@"IdentityIDName"]) {
				return [identity objectForKey:@"IdentityIDName"];
			} else {
				return @"";
			}
		} else if ([(NSString *)[aTableColumn identifier] compare:@"I_DEFAULT"] == NSOrderedSame) {
			if ([[identity objectForKey:@"IdentityIsDefault"] boolValue]) {
				return @"¥";
			} else {
				return @"";
			}
		} else if ([(NSString *)[aTableColumn identifier] compare:@"I_SIGNATURE"] == NSOrderedSame) {
			NSMutableString *aText = [NSMutableString string];
			if ([[identity objectForKey:@"IdentitySigRandom"] boolValue]) {
				[aText appendString:NSLocalizedString(@"<R>&", @"")];
			}
			[aText appendString:[identity objectForKey:@"IdentitySignatureTitle"]];
			return aText;
		} else {
			return @"???";
		}
	} else if (aTableView == signatureTable) {
		return [[ISOSignatureMgr sharedSignatureMgr] tableView:aTableView objectValueForTableColumn:aTableColumn row:rowIndex];
	} else {
		return @"??";
	}
}

- (int)identityCount
{
	return [identities count];
}

- (int)defaultIdentityIndex
{
	int i, count;
	
	count = [identities count];
	for (i=0;i<count;i++) {
		if ([[[identities objectAtIndex:i] objectForKey:@"IdentityIsDefault"] boolValue]) {
			return i;
		}
	}
	return -1;
}

- (NSString *)idNameOfIdentityAtIndex:(int)index
{
	if (index >=0 && (index < [identities count])) {
		if ([[identities objectAtIndex:index] objectForKey:@"IdentityIDName"]) {
			return [[identities objectAtIndex:index] objectForKey:@"IdentityIDName"];
		} else {
			return @"";
		}
	} else {
		return @"";
	}
}

- (NSString *)nameOfIdentityAtIndex:(int)index
{
	if (index >=0 && (index < [identities count])) {
		return [[identities objectAtIndex:index] objectForKey:@"IdentityName"];
	} else {
		return @"";
	}
}

- (NSString *)emailOfIdentityAtIndex:(int)index
{
	if (index >=0 && (index < [identities count])) {
		return [[identities objectAtIndex:index] objectForKey:@"IdentityEmail"];
	} else {
		return @"";
	}
}

- (NSString *)signatureOfIdentityAtIndex:(int)index
{
	NSMutableString	*signature = [NSMutableString string];
	if (index >=0 && (index < [identities count])) {
		int sigIndex = [[ISOSignatureMgr sharedSignatureMgr] indexOfSignature:[[identities objectAtIndex:index] objectForKey:@"IdentitySignatureTitle"]];
		[signature setString:[[ISOSignatureMgr sharedSignatureMgr] signatureAtIndex:sigIndex]];
		if ([[[identities objectAtIndex:index] objectForKey:@"IdentitySigRandom"] boolValue]) {
			if ([signature length] && ([[signature substringWithRange:NSMakeRange([signature length]-1, 1)] compare:@"\n"] != NSOrderedSame) ) {
				[signature appendString:@"\n"];
			}
			[signature appendFormat:@"%@", [[ISOSignatureMgr sharedSignatureMgr] randomSignature]];
		}
		return signature;
	} else {
		return @"";
	}
}


- (NSString *)xFaceOfIdentityAtIndex:(int)index
{
	if (index >=0 && (index < [identities count])) {
		return [[identities objectAtIndex:index] objectForKey:@"IdentityXFace"];
	} else {
		return @"";
	}
}


- (NSString *)xFaceURLOfIdentityAtIndex:(int)index
{
	if (index >=0 && (index < [identities count])) {
		return [[identities objectAtIndex:index] objectForKey:@"IdentityXFaceURL"];
	} else {
		return @"";
	}
}


@end
