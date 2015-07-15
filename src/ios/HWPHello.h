#import <Cordova/CDV.h>
#import "AudioJack/AudioJack.h"

@interface HWPHello : CDVPlugin

@property NSString *callbackId;

- (void) greet:(CDVInvokedUrlCommand*)command;
- (void) piggyBack:(CDVInvokedUrlCommand*)command;

@end
