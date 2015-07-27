#import <Cordova/CDV.h>
#import "AudioJack/AudioJack.h"

@interface RQACR35Controller : CDVPlugin <ACRAudioJackReaderDelegate>

- (void) readIdFromTag:(CDVInvokedUrlCommand*)command;
- (void) readDataFromTag:(CDVInvokedUrlCommand*)command;
- (void) writeDataIntoTag:(CDVInvokedUrlCommand *)command;

@end