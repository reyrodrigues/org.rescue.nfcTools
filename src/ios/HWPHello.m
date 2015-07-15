#import "HWPHello.h"

@implementation HWPHello
@synthesize callbackId;

- (void)piggyBack:(CDVInvokedUrlCommand*)command
{
        NSString* msg = @"HI! I'M MR MEESEEKS! LOOK AT ME!";
        CDVPluginResult* result = [CDVPluginResult
                                   resultWithStatus:CDVCommandStatus_OK
                                   messageAsString:msg];


        [self.commandDelegate sendPluginResult:result callbackId:[self callbackId]];
}

- (void)greet:(CDVInvokedUrlCommand*)command
{
        self.callbackId = [command callbackId];
        NSString* callbackId = [command callbackId];
        NSString* name = [[command arguments] objectAtIndex:0];
        NSString* msg = [NSString stringWithFormat: @"Hello, %@", name];

        CDVPluginResult* result = [CDVPluginResult
                                   resultWithStatus:CDVCommandStatus_OK
                                   messageAsString:msg];

        [result setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
}

@end
