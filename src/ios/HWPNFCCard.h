#import <Cordova/CDV.h>
#import "AudioJack/AudioJack.h"
#import <AVFoundation/AVFoundation.h>

@interface HWPNFCCard : CDVPlugin <ACRAudioJackReaderDelegate, AVAudioPlayerDelegate>

@property NSString *className;

- (void) init:(CDVInvokedUrlCommand*)command;
- (void) writeData:(CDVInvokedUrlCommand*)command;

@end
