#import <Foundation/Foundation.h>
#import "TFSocket.h"

// Simple one-shot HTTP server


int main (int argc, const char * argv[]) {
    @autoreleasepool {

		TFSocketListener *HTTPServer = [[TFSocketListener alloc] initWithPort:8080];
		HTTPServer.acceptHandler = ^(TFSocket *client) {
			NSData *crlfcrlf = [NSData dataWithBytes:"\r\n\r\n" length:4];
			[client readDataToData:crlfcrlf timeout:-1 callback:^(NSData *headerData) {
				CFHTTPMessageRef request = CFHTTPMessageCreateEmpty(NULL, YES);
				CFHTTPMessageAppendBytes(request, [headerData bytes], [headerData length]);
				NSURL *URL = CFBridgingRelease(CFHTTPMessageCopyRequestURL(request));
				CFRelease(request);
				
				NSString *bodyString = [NSString stringWithFormat:@"<h1>This is %@!</h1>", URL.path];
				NSData *bodyData = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
				
				CFHTTPMessageRef response = CFHTTPMessageCreateResponse(NULL, 200, NULL, kCFHTTPVersion1_0);
				CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Content-Type"), CFSTR("text/html"));
				CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Content-Length"), (__bridge CFStringRef)[NSString stringWithFormat:@"%llu", (uint64_t)bodyData.length]);
				CFHTTPMessageSetBody(response, (__bridge CFDataRef)bodyData);
				
				NSData *responseData = CFBridgingRelease(CFHTTPMessageCopySerializedMessage(response));
				CFRelease(response);
				
				[client writeData:responseData timeout:-1 callback:nil];
				[client disconnect];
			}];
		};
		
		NSLog(@"Try it: http://localhost:8080/SPARTA");
		for(;;) [[NSRunLoop currentRunLoop] run];
		
		return 0;
	}
}