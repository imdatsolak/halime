#import <Cocoa/Cocoa.h>
#import <ExceptionHandling/NSExceptionHandler.h>
int main(int argc, const char *argv[])
{
//	[[NSExceptionHandler defaultExceptionHandler] setExceptionHandlingMask: 63 + 64 + 128 + 256 + 512];
    return NSApplicationMain(argc, argv);
}
