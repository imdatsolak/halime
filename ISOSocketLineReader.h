//
//  ISOSocketLineReader.h
//  Halime
//
//  Created by iso on Mon May 21 2001.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KWTCPEndpoint.h"

@interface ISOSocketLineReader : NSObject 
{
	KWTCPEndpoint	*tcpEndpoint;
	id				delegate;
	NSMutableString	*sustainBuffer;
	int				readBufferSize;
	NSString		*finishText;
	BOOL			gracefullyKilled;
	int				readError;
}

- initWithTCPEndpoint:(KWTCPEndpoint *)anEndpoint;
- setDelegate:(id)anObject;
- setReadBufferSize:(int)aSize;
- setFinishText:(NSString *)aText;

- delegate;
- (int)readBufferSize;
- (NSString *)finishText;

- (int)readLineIntoString:(NSMutableString *)aString;
- (int)readLinesIntoArray:(NSMutableArray *)stringArray untilFinishText:(NSString *)aFinishText;
- (BOOL)gracefullyKillOperations;
- (int)readError;
- (void)setReadError:(int)anError;
@end

@interface NSObject(ISOSocketLineReaderDelegate)
- (int)socketLineReader:(id)sender didReadLine:(int)lineNo inString:(NSString *)oneLine;
@end