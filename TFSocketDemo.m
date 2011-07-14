#import <Foundation/Foundation.h>
#import "TFSocket.h"

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

	// Simple one-shot HTTP server
	
	TFSocketListener *HTTPServer = [[TFSocketListener alloc] initWithPort:8080];	
	HTTPServer.acceptHandler = ^(TFSocket *client) {
		NSData *crlfcrlf = [NSData dataWithBytes:"\r\n\r\n" length:4];
		[client readDataToData:crlfcrlf timeout:-1 callback:^(NSData *headerData) {
			CFHTTPMessageRef request = CFHTTPMessageCreateEmpty(NULL, YES);
			CFHTTPMessageAppendBytes(request, [headerData bytes], [headerData length]);
			NSString *path = [NSMakeCollectable(CFHTTPMessageCopyRequestURL(request)) autorelease];
			CFRelease(request);
			
			NSString *bodyString = [NSString stringWithFormat:@"<h1>This is %@!</h1>", path];
			NSData *bodyData = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
			
			CFHTTPMessageRef response = CFHTTPMessageCreateResponse(NULL, 200, NULL, kCFHTTPVersion1_0);
			CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Content-Type"), CFSTR("text/html"));
			CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Content-Length"), (CFStringRef)[NSString stringWithFormat:@"%lu", (unsigned long)[bodyData length]]);
			CFHTTPMessageSetBody(response, (CFDataRef)bodyData);
			
			NSData *responseData = [NSMakeCollectable(CFHTTPMessageCopySerializedMessage(response)) autorelease];
			CFRelease(response);
			[client writeData:responseData timeout:-1 callback:nil];
			[client disconnect];
		}];
	};
	
	NSLog(@"Try it: http://localhost:8080/SPARTA");	
	for(;;) [[NSRunLoop currentRunLoop] run];
    [pool drain];
    return 0;
}