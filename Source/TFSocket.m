//
//  TFSocket.m
//  TFSocket
//
//  Created by Tomas Franzén on 2011-06-28.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "TFSocket.h"
#import "GCDAsyncSocket.h"


@interface TFSocket () <GCDAsyncSocketDelegate>
@property(strong) GCDAsyncSocket *socket;

@property long tagCounter;
@property(strong) NSMutableDictionary *writeCallbacks;
@property(strong) NSMutableDictionary *readCallbacks;
@end



@implementation TFSocket


- (id)initWithGCDAsyncSocket:(GCDAsyncSocket*)socket {
	if(!(self = [super init])) return nil;
	
	self.socket = socket;
	socket.delegate = self;
	
	self.readCallbacks = [NSMutableDictionary dictionary];
	self.writeCallbacks = [NSMutableDictionary dictionary];
	
	return self;
}


- (id)initWithHost:(NSString*)host port:(uint16_t)port {
	GCDAsyncSocket *socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_current_queue()];
	if(![socket connectToHost:host onPort:port error:NULL])
		return nil;
	
	return [self initWithGCDAsyncSocket:socket];
}


- (void)dealloc {
	[self disconnectImmediately];
}


- (void)disconnect {
	[self.socket disconnectAfterReadingAndWriting];
	
	// Our owner may let go of us after disconnecting, so we want to survive until the socket is disconnected.
	// GCDAsyncSocket will keep sending delegate messages until it's disconnected,
	// and setting the delegate to nil doesn't work, since that's async, too.
	[self.socket performBlock:^{[self self];}];
}


- (void)disconnectImmediately {
	[self disconnect];
	[self.socket disconnect];
}


- (void)writeData:(NSData*)data timeout:(NSTimeInterval)timeout callback:(void(^)())didWriteCallback {
	long tag = self.tagCounter++;
	if(didWriteCallback)
		[self.writeCallbacks setObject:[didWriteCallback copy] forKey:@(tag)];
	
	[self.socket writeData:data withTimeout:timeout tag:tag];
}


- (long)storeReadCallback:(void(^)(NSData *data))didReadCallback {
	long tag = self.tagCounter++;
	if(didReadCallback)
		[self.readCallbacks setObject:[didReadCallback copy] forKey:@(tag)];
	return tag;
}


- (void)readDataToLength:(NSUInteger)length timeout:(NSTimeInterval)timeout callback:(void(^)(NSData *data))didReadCallback {
	[self.socket readDataToLength:length withTimeout:timeout tag:[self storeReadCallback:didReadCallback]];
}


- (void)readDataToData:(NSData*)data timeout:(NSTimeInterval)timeout callback:(void(^)(NSData *data))didReadCallback {
	[self.socket readDataToData:data withTimeout:timeout tag:[self storeReadCallback:didReadCallback]];
}


- (void)readDataToData:(NSData*)data maxLength:(NSUInteger)maxLength timeout:(NSTimeInterval)timeout callback:(void(^)(NSData *data))didReadCallback {
	[self.socket readDataToData:data withTimeout:timeout maxLength:maxLength tag:[self storeReadCallback:didReadCallback]];
}


- (NSString*)host {
	return [self.socket connectedHost];
}


- (void)startTLSWithPeerHostname:(NSString*)hostname certificates:(NSArray*)certs {
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	if(hostname) [dict setObject:hostname forKey:(id)kCFStreamSSLPeerName];
	if(certs) [dict setObject:certs forKey:(id)kCFStreamSSLCertificates];
	[self.socket startTLS:dict];
}



#pragma mark GCDAsyncSocket callbacks


- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString*)host port:(UInt16)port {
	if(self.connectHandler)
		self.connectHandler();
}


- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError*)err {
	if(self.disconnectHandler)
		self.disconnectHandler(err);
}


- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData*)data withTag:(long)tag {
	void(^callback)(NSData *data) = [self.readCallbacks objectForKey:@(tag)];
	if(callback) {
		callback(data);
		[self.readCallbacks removeObjectForKey:@(tag)];
	}
}


- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
	void(^callback)() = [self.writeCallbacks objectForKey:@(tag)];
	if(callback) {
		callback();
		[self.writeCallbacks removeObjectForKey:@(tag)];
	}
}

@end




@interface TFSocketListener () <GCDAsyncSocketDelegate>
@property(strong) GCDAsyncSocket *socket;
@end


@implementation TFSocketListener
@synthesize acceptHandler;


- (id)initWithPort:(uint16_t)port {
	if(!(self = [super init])) return nil;
	
	self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_current_queue()];
	if(![self.socket acceptOnPort:port error:NULL])
		return nil;
	
	return self;
}


- (void)dealloc {
	[self stop];
}


- (void)stop {
	[self.socket disconnect];
	self.socket = nil;
}


- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
	if(self.acceptHandler) {
		TFSocket *tfSocket = [[TFSocket alloc] initWithGCDAsyncSocket:newSocket];
		self.acceptHandler(tfSocket);
	}
}


@end