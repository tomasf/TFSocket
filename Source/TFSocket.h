//
//  TFSocket.h
//  TFSocket
//
//  Created by Tomas Franzén on 2011-06-28.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

@interface TFSocket : NSObject
@property(copy) void(^connectHandler)();
@property(copy) void(^disconnectHandler)(NSError *error);
@property(readonly) NSString *host;

- (id)initWithHost:(NSString*)host port:(uint16_t)port;
- (void)disconnect;
- (void)disconnectImmediately;

- (void)startTLSWithPeerHostname:(NSString*)hostname certificates:(NSArray*)certs;

- (void)writeData:(NSData*)data timeout:(NSTimeInterval)timeout callback:(void(^)())didWriteCallback;

- (void)readDataToLength:(NSUInteger)length timeout:(NSTimeInterval)timeout callback:(void(^)(NSData *data))didReadCallback;
- (void)readDataToData:(NSData*)data timeout:(NSTimeInterval)timeout callback:(void(^)(NSData *data))didReadCallback;
- (void)readDataToData:(NSData*)data maxLength:(NSUInteger)maxLength timeout:(NSTimeInterval)timeout callback:(void(^)(NSData *data))didReadCallback;
@end



@interface TFSocketListener : NSObject
@property(copy) void(^acceptHandler)(TFSocket *socket);

- (id)initWithPort:(uint16_t)port;
- (void)stop;
@end