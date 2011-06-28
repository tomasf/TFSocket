#import <Foundation/Foundation.h>
#import "TFSocket.h"

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

	// Server
	
	TFSocketListener *server = [[TFSocketListener alloc] initWithPort:1234];
	NSMutableSet *clients = [NSMutableSet set];
	server.acceptHandler = ^(TFSocket *newSocket) {
		[clients addObject:newSocket];
		NSData *crlf = [NSData dataWithBytes:"\r\n" length:2];
		
		[newSocket readDataToData:crlf timeout:-1 callback:^(NSData *data) {
			NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
			NSLog(@"Server got line: %@", string);
			[newSocket disconnect];
		}];
		newSocket.disconnectHandler = ^(NSError *e) {
			[clients removeObject:newSocket];
		};
	};
	
	
	// Client
	
	TFSocket *client = [[TFSocket alloc] initWithHost:@"localhost" port:1234];
	client.connectHandler = ^{
		NSString *string = @"Wello horld!\r\n";
		NSLog(@"Client says: %@", string);
		[client writeData:[string dataUsingEncoding:NSUTF8StringEncoding] timeout:-1 callback:nil];
		[client disconnect];
	};
	client.disconnectHandler = ^(NSError *error) {
		if(error) NSLog(@"Client failed: %@", error);
	};
	
	
	for(;;) [[NSRunLoop currentRunLoop] run];
    [pool drain];
    return 0;
}
