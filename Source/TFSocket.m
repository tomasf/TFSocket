//
//  TFSocket.m
//  TFSocket
//
//  Created by Tomas Franzén on 2011-06-28.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "TFSocket.h"
#import "GCDAsyncSocket.h"


@implementation TFSocket


- (id)initWithGCDAsyncSocket:(GCDAsyncSocket*)sock {
	if(!(self = [super init])) return nil;
	
	socket = [sock retain];
	[socket setDelegate:self];
	readCallbacks = [[NSMutableDictionary alloc] init];
	writeCallbacks = [[NSMutableDictionary alloc] init];
	
	return self;
}


- (id)initWithHost:(NSString*)host port:(uint16_t)port {
	GCDAsyncSocket *sock = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_current_queue()];
	if(![sock connectToHost:host onPort:port error:NULL]) {
		[self release];
		return nil;
	}
	return [self initWithGCDAsyncSocket:sock];
}


- (void)dealloc {
	[self disconnectImmediately];
	[socket release];
	[connectHandler release];
	[disconnectHandler release];
	[readCallbacks release];
	[writeCallbacks release];
	[super dealloc];
}


- (void)disconnect {
	[socket disconnectAfterReadingAndWriting];
	
	// Our owner may let go of us after disconnecting, so we want to survive until the socket is disconnected.
	// GCDAsyncSocket will keep sending delegate messages until it's disconnected,
	// and setting the delegate to nil doesn't work, since that's async, too.
	[socket performBlock:^{[self self];}];
}


- (void)disconnectImmediately {
	[self disconnect];
	[socket disconnect];
}


- (void)writeData:(NSData*)data timeout:(NSTimeInterval)timeout callback:(void(^)())didWriteCallback {
	long tag = tagCounter++;
	if(didWriteCallback)
		[writeCallbacks setObject:[[didWriteCallback copy] autorelease] forKey:[NSNumber numberWithLong:tag]];
	
	[socket writeData:data withTimeout:timeout tag:tag];
}


- (long)storeReadCallback:(void(^)(NSData *data))didReadCallback {
	long tag = tagCounter++;
	if(didReadCallback)
		[readCallbacks setObject:[[didReadCallback copy] autorelease] forKey:[NSNumber numberWithLong:tag]];
	return tag;
}


- (void)readDataToLength:(NSUInteger)length timeout:(NSTimeInterval)timeout callback:(void(^)(NSData *data))didReadCallback {
	[socket readDataToLength:length withTimeout:timeout tag:[self storeReadCallback:didReadCallback]];
}


- (void)readDataToData:(NSData*)data timeout:(NSTimeInterval)timeout callback:(void(^)(NSData *data))didReadCallback {
	[socket readDataToData:data withTimeout:timeout tag:[self storeReadCallback:didReadCallback]];
}



@synthesize connectHandler, disconnectHandler;

- (NSString*)host {
	return [socket connectedHost];
}


- (void)startTLSWithPeerHostname:(NSString*)hostname certificates:(NSArray*)certs {
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	if(hostname) [dict setObject:hostname forKey:(id)kCFStreamSSLPeerName];
	if(certs) [dict setObject:certs forKey:(id)kCFStreamSSLCertificates];
	[socket startTLS:dict];
}



#pragma mark GCDAsyncSocket callbacks


- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString*)host port:(UInt16)port {
	if(connectHandler)
		connectHandler();
}


- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError*)err {
	if(disconnectHandler)
		disconnectHandler(err);
}


- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData*)data withTag:(long)tag {
	void(^callback)(NSData *data) = [readCallbacks objectForKey:[NSNumber numberWithLong:tag]];
	if(callback) {
		callback(data);
		[readCallbacks removeObjectForKey:[NSNumber numberWithLong:tag]];
	}
}


- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
	void(^callback)() = [writeCallbacks objectForKey:[NSNumber numberWithLong:tag]];
	if(callback) {
		callback();
		[writeCallbacks removeObjectForKey:[NSNumber numberWithLong:tag]];
	}
}

@end





@implementation TFSocketListener
@synthesize acceptHandler;


- (id)initWithPort:(uint16_t)port {
	if(!(self = [super init])) return nil;
	
	socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_current_queue()];
	if(![socket acceptOnPort:port error:NULL]) {
		[self release];
		return nil;
	}
	
	return self;
}


- (void)dealloc {
	[self stop];
	[acceptHandler release];
	[super dealloc];
}


- (void)stop {
	[socket disconnect];
	[socket release];
	socket = nil;
}


- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
	if(acceptHandler) {
		TFSocket *tfSocket = [[[TFSocket alloc] initWithGCDAsyncSocket:newSocket] autorelease];
		acceptHandler(tfSocket);
	}
}


@end