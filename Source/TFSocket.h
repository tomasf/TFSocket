//
//  TFSocket.h
//  TFSocket
//
//  Created by Tomas Franzén on 2011-06-28.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "GCDAsyncSocket.h"


@interface TFSocket : NSObject <GCDAsyncSocketDelegate> {
	GCDAsyncSocket *socket;
	
	long tagCounter;
	NSMutableDictionary *writeCallbacks;
	NSMutableDictionary *readCallbacks;
	
	void(^connectHandler)();
	void(^disconnectHandler)(NSError *error);
}

- (id)initWithHost:(NSString*)host port:(uint16_t)port;
- (void)disconnect;
- (void)disconnectImmediately;

- (void)startTLSWithPeerHostname:(NSString*)hostname certificates:(NSArray*)certs;

- (void)writeData:(NSData*)data timeout:(NSTimeInterval)timeout callback:(void(^)())didWriteCallback;

- (void)readDataToLength:(NSUInteger)length timeout:(NSTimeInterval)timeout callback:(void(^)(NSData *data))didReadCallback;
- (void)readDataToData:(NSData*)data timeout:(NSTimeInterval)timeout callback:(void(^)(NSData *data))didReadCallback;


@property(copy) void(^connectHandler)();
@property(copy) void(^disconnectHandler)(NSError *error);

@property(readonly) NSString *host;

@end



@interface TFSocketListener : NSObject <GCDAsyncSocketDelegate> {
	GCDAsyncSocket *socket;
	
	void(^acceptHandler)(TFSocket *socket);
}

- (id)initWithPort:(uint16_t)port;
- (void)stop;

@property(copy) void(^acceptHandler)(TFSocket *socket);
@end