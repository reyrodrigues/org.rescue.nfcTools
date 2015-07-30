
#import "RQACR35Controller.h"
#import <CommonCrypto/CommonCrypto.h>
#import <AudioToolbox/AudioToolbox.h>
#import "AJDHex.h"


@implementation RQACR35Controller {
        ACRAudioJackReader *_reader;

        NSCondition* deviceBusy;
        NSMutableString* response;
        NSString * loadKeyCommand;
        NSString * authCommand;
        NSString * authKeyCommand;
        NSString * defaultKey;
        NSTimer* timeoutTimer;
        NSString * _callbackId;
        NSString * _atrResult;
        NSUInteger timeout;

        BOOL timedOut;
        BOOL shuttingDown;

}

- (void)pluginInitialize {
        NSLog(@"Initiaizing plugin");

        timeout = 10;

        _reader = [[ACRAudioJackReader alloc] initWithMute:YES];
        [_reader setDelegate:self];

        // Set mute to YES if the reader is unplugged, otherwise NO.
        _reader.mute = !AJDIsReaderPlugged();

        // Listen the audio route change.
        AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, AJDAudioRouteChangeListener, (__bridge void *) self);

        deviceBusy = [[NSCondition alloc]init];

        [_reader resetWithCompletion:^{

         }];
        response = [[NSMutableString alloc] init];

        loadKeyCommand = @"FF 82 00 00 06 %@";
        defaultKey = @"FF FF FF FF FF"; //@"12 34 56 FF 07 80";
        authCommand =  @"FF 86 00 00 05 01 00 %@ 60 00";
        authKeyCommand =  @"FF 86 00 00 05 01 00 00 60 00";
}

- (NSString*)prepareKey:(CDVInvokedUrlCommand *)command
{
        return [NSString stringWithFormat:loadKeyCommand, defaultKey];
}


-(void)getDeviceStatus:(CDVInvokedUrlCommand *)command {

        _callbackId = [command callbackId];
        [_reader resetWithCompletion:^{
                 if (![_reader getStatus]) {
                         NSLog(@"Can't Get Status");
                 }
         }];



        timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:timeout
                        target:self
                        selector:@selector(operationTimedOut)
                        userInfo:nil
                        repeats:NO];

        if(!_reader.mute) {

                CDVPluginResult* result = [CDVPluginResult
                                           resultWithStatus:CDVCommandStatus_OK
                                           messageAsString:@"IGNORE"];
                [result setKeepCallback :[NSNumber numberWithBool:YES]];
                [self.commandDelegate sendPluginResult:result callbackId:_callbackId];
        } else{
                [timeoutTimer invalidate];


                CDVPluginResult* result = [CDVPluginResult
                                           resultWithStatus:CDVCommandStatus_OK
                                           messageAsString:@"NOTFOUND"];
                [result setKeepCallback :[NSNumber numberWithBool:YES]];
                [self.commandDelegate sendPluginResult:result callbackId:_callbackId];
        }
}


-(void)getDeviceId:(CDVInvokedUrlCommand *)command {

        _callbackId = [command callbackId];
        [_reader resetWithCompletion:^{
                 if (![_reader getDeviceId]) {
                         NSLog(@"Can't Get Device Id");
                 }
         }];



        timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:timeout
                        target:self
                        selector:@selector(operationTimedOut)
                        userInfo:nil
                        repeats:NO];


        if(!_reader.mute) {
                CDVPluginResult* result = [CDVPluginResult
                                           resultWithStatus:CDVCommandStatus_OK
                                           messageAsString:@"IGNORE"];
                [result setKeepCallback :[NSNumber numberWithBool:YES]];
                [self.commandDelegate sendPluginResult:result callbackId:_callbackId];
        } else{
                [timeoutTimer invalidate];

                CDVPluginResult* result = [CDVPluginResult
                                           resultWithStatus:CDVCommandStatus_OK
                                           messageAsString:@"NOTFOUND"];
                [result setKeepCallback :[NSNumber numberWithBool:YES]];
                [self.commandDelegate sendPluginResult:result callbackId:_callbackId];
        }
}


-(void)readIdFromTag:(CDVInvokedUrlCommand *)command {
        NSString* key = [self prepareKey:command];

        [self executeCommands:[NSArray arrayWithObjects:key,
                               @"FFCA000000",
                               nil]];
        _callbackId = [command callbackId];


        if(!_reader.mute) {
                CDVPluginResult* result = [CDVPluginResult
                                           resultWithStatus:CDVCommandStatus_OK
                                           messageAsString:@"IGNORE"];
                [result setKeepCallback :[NSNumber numberWithBool:YES]];
                [self.commandDelegate sendPluginResult:result callbackId:_callbackId];
        } else{
                [timeoutTimer invalidate];

                CDVPluginResult* result = [CDVPluginResult
                                           resultWithStatus:CDVCommandStatus_OK
                                           messageAsString:@"NOTFOUND"];
                [result setKeepCallback :[NSNumber numberWithBool:YES]];
                [self.commandDelegate sendPluginResult:result callbackId:_callbackId];
        }
}

// Read the 128B from the card
-(void)readDataFromTag:(CDVInvokedUrlCommand *)command {
        NSString* key = [self prepareKey:command];

        [self executeCommands:[NSArray arrayWithObjects:key,
                               [NSString stringWithFormat:authCommand, @"04"],
                               @"FF B0 00 04 10",
                               @"FF B0 00 05 10",
                               @"FF B0 00 06 10",
                               [NSString stringWithFormat:authCommand, @"08"],
                               @"FF B0 00 08 10",
                               @"FF B0 00 09 10",
                               @"FF B0 00 0A 10",
                               [NSString stringWithFormat:authCommand, @"10"],
                               @"FF B0 00 10 10",
                               @"FF B0 00 11 10",
                               nil]];


        _callbackId = [command callbackId];


        if(!_reader.mute) {
                CDVPluginResult* result = [CDVPluginResult
                                           resultWithStatus:CDVCommandStatus_OK
                                           messageAsString:@"IGNORE"];
                [result setKeepCallback :[NSNumber numberWithBool:YES]];
                [self.commandDelegate sendPluginResult:result callbackId:_callbackId];
        } else{
                [timeoutTimer invalidate];

                CDVPluginResult* result = [CDVPluginResult
                                           resultWithStatus:CDVCommandStatus_OK
                                           messageAsString:@"NOTFOUND"];
                [result setKeepCallback :[NSNumber numberWithBool:YES]];
                [self.commandDelegate sendPluginResult:result callbackId:_callbackId];
        }
}

// Writes up to 128B to the card
- (void)writeDataIntoTag:(CDVInvokedUrlCommand *)command
{
        NSString* key = [self prepareKey:command];
        NSData*  immutableData = [AJDHex byteArrayFromHexString:[[command arguments] objectAtIndex:0]];
        NSMutableData* data = [NSMutableData dataWithData:immutableData];
        if([data length] <128) {
                [data increaseLengthBy:128 - [data length]];
        }
        NSString * hexTag =[AJDHex hexStringFromByteArray:data];
        hexTag = [hexTag stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSString * commandString1 =[@"FF D6 00 04 30 " stringByAppendingString :[hexTag substringWithRange:NSMakeRange(0, 96)]];
        NSString * commandString2 =[@"FF D6 00 08 30 " stringByAppendingString :[hexTag substringWithRange:NSMakeRange(96, 96)]];
        NSString * commandString3 =[@"FF D6 00 10 20 " stringByAppendingString :[hexTag substringWithRange:NSMakeRange(96*2, 64)]];

        [self executeCommands:[NSArray arrayWithObjects:key,
                               [NSString stringWithFormat:authCommand, @"04"],
                               commandString1,
                               [NSString stringWithFormat:authCommand, @"08"],
                               commandString2,
                               [NSString stringWithFormat:authCommand, @"10"],
                               commandString3,
                               nil]];


        _callbackId = [command callbackId];

        if(!_reader.mute) {
                CDVPluginResult* result = [CDVPluginResult
                                           resultWithStatus:CDVCommandStatus_OK
                                           messageAsString:@"IGNORE"];
                [result setKeepCallback :[NSNumber numberWithBool:YES]];
                [self.commandDelegate sendPluginResult:result callbackId:_callbackId];
        } else{
                [timeoutTimer invalidate];

                CDVPluginResult* result = [CDVPluginResult
                                           resultWithStatus:CDVCommandStatus_OK
                                           messageAsString:@"NOTFOUND"];
                [result setKeepCallback :[NSNumber numberWithBool:YES]];
                [self.commandDelegate sendPluginResult:result callbackId:_callbackId];
        }
}

-(void)executeCommands:(NSArray*)commands
{
        shuttingDown = NO;
        timedOut = NO; // 1 second.
        NSUInteger cardType = ACRPiccCardTypeIso14443TypeA |
                              ACRPiccCardTypeIso14443TypeB |
                              ACRPiccCardTypeFelica212kbps |
                              ACRPiccCardTypeFelica424kbps |
                              ACRPiccCardTypeAutoRats;

        [_reader resetWithCompletion:^{
                 // Power on the PICC.
                 [_reader piccPowerOnWithTimeout:timeout cardType:cardType];

                 for(NSString* commandString in commands) {
                         NSData* command = [AJDHex byteArrayFromHexString:commandString];
                         [_reader piccTransmitWithTimeout:timeout commandApdu:[command bytes]
                          length:[command length]];
                 }

                 [_reader piccPowerOff];
                 //[_reader sleep];
         }];

        timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:timeout
                        target:self
                        selector:@selector(operationTimedOut)
                        userInfo:nil
                        repeats:NO];

}

-(void)operationTimedOut {
        NSLog(@"Timed Out");
        timedOut = YES;
        [_reader piccPowerOff];
        [_reader resetWithCompletion:^{
                 CDVPluginResult* timeOutResult = [CDVPluginResult
                                                   resultWithStatus:CDVCommandStatus_OK
                                                   messageAsString:@"TIMEDOUT"];


                 [self.commandDelegate sendPluginResult:timeOutResult callbackId:_callbackId];
         }];

}

#pragma mark - Audio Jack Reader


- (void)reader:(ACRAudioJackReader *)reader didSendDeviceId:(const uint8_t *)deviceId length:(NSUInteger)length {
        [timeoutTimer invalidate];
        dispatch_sync(dispatch_get_main_queue(),
                      ^{
                              CDVPluginResult* statusResult = [CDVPluginResult
                                                               resultWithStatus:CDVCommandStatus_OK
                                                               messageAsString:[AJDHex hexStringFromByteArray:[NSData dataWithBytes:deviceId length:length]]];


                              [self.commandDelegate sendPluginResult:statusResult callbackId:_callbackId];
                      });
}

- (void)reader:(ACRAudioJackReader *)reader didSendStatus:(ACRStatus *)status {

        [timeoutTimer invalidate];
        dispatch_sync(dispatch_get_main_queue(),
                      ^{
                              // This here is the single ugliest piece of code I've ever been forced to write by a stupid programming language
                              NSArray* result = @[
                                      [NSString stringWithFormat:@"%tu", (unsigned long)status.batteryLevel],
                                      [NSString stringWithFormat:@"%tu", (unsigned long)status.sleepTimeout]
                                                ];
                              CDVPluginResult* statusResult = [CDVPluginResult
                                                               resultWithStatus:CDVCommandStatus_OK
                                                               messageAsArray:result];


                              [self.commandDelegate sendPluginResult:statusResult callbackId:_callbackId];
                      });
}

- (void)reader:(ACRAudioJackReader *)reader didSendPiccAtr:(const uint8_t *)atr
        length:(NSUInteger)length {
        NSLog([NSString stringWithFormat:@"ATR: %@", [AJDHex hexStringFromByteArray:[NSData dataWithBytes:atr length:length]]]);
        _atrResult = [AJDHex hexStringFromByteArray:[NSData dataWithBytes:atr length:length]];
}

- (void)reader:(ACRAudioJackReader *)reader
        didSendPiccResponseApdu:(const uint8_t *)responseApdu
        length:(NSUInteger)length {

        NSMutableData* result = [NSMutableData dataWithBytes:responseApdu length:length];

        UInt16 resultCode[2];
        [result getBytes:resultCode range:(NSMakeRange(length-2, 2))];
        NSString* resultCodeString =[AJDHex hexStringFromByteArray:resultCode length:2];

        NSLog(resultCodeString);

        [result replaceBytesInRange:NSMakeRange(length-2, 2) withBytes:NULL length:0];
        NSString* resultString =[AJDHex hexStringFromByteArray:result];

        if(![resultCodeString isEqualToString:@"63 00"]) {
                [response appendString:resultString];
                [response appendString:@" "];
        }
}

- (void)reader:(ACRAudioJackReader *)reader didNotifyResult:(ACRResult *)result {
        if (shuttingDown) {
                return;
        }
        [timeoutTimer invalidate];
        NSData* responseData = [AJDHex byteArrayFromHexString:response];
        NSString* resultString = [response stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSString* atrResultString = [_atrResult stringByReplacingOccurrencesOfString:@" " withString:@""];

        shuttingDown = YES;
        [_reader piccPowerOff];
        [_reader resetWithCompletion:^{
                 //[_reader sleep];
         }];

        dispatch_sync(dispatch_get_main_queue(), ^{
                              if (timedOut) {
                              }
                              else {
                                      CDVPluginResult* result = [CDVPluginResult
                                                                 resultWithStatus:CDVCommandStatus_OK
                                                                 messageAsArray:@[resultString, atrResultString]];


                                      [self.commandDelegate sendPluginResult:result callbackId:_callbackId];
                              }

                      });


        [response setString:@""];
}


- (NSString *)dataToJavascriptByteArray:(NSData *)buffer {
        return [self dataToJavascriptByteArray:[buffer bytes] length:[buffer length]];
}

- (NSString *)dataToJavascriptByteArray:(const uint8_t *)buffer length:(NSUInteger)length {

        NSString *hexString = @"";
        NSUInteger i = 0;

        for (i = 0; i < length; i++) {
                if (i == 0) {
                        hexString = [hexString stringByAppendingFormat:@"0x%02X", buffer[i]];
                } else {
                        hexString = [hexString stringByAppendingFormat:@",0x%02X", buffer[i]];
                }
        }

        return hexString;
}

- (NSString *)toBatteryLevelString:(NSUInteger)batteryLevel {

        NSString *batteryLevelString = nil;

        switch (batteryLevel) {
        case 0:
                batteryLevelString = @">= 3.00V";
                break;
        case 1:
                batteryLevelString = @"2.90V - 2.99V";
                break;
        case 2:
                batteryLevelString = @"2.80V - 2.89V";
                break;
        case 3:
                batteryLevelString = @"2.70V - 2.79V";
                break;
        case 4:
                batteryLevelString = @"2.60V - 2.69V";
                break;
        case 5:
                batteryLevelString = @"2.50V - 2.59V";
                break;
        case 6:
                batteryLevelString = @"2.40V - 2.49V";
                break;
        case 7:
                batteryLevelString = @"2.30V - 2.39V";
                break;
        case 8:
                batteryLevelString = @"< 2.30V";
                break;
        default:
                batteryLevelString = @"Unknown";
                break;
        }

        return batteryLevelString;
}



static void AJDAudioRouteChangeListener(void *inClientData, AudioSessionPropertyID inID, UInt32 inDataSize, const void *inData) {

        RQACR35Controller *viewController = (__bridge RQACR35Controller *) inClientData;

        // Set mute to YES if the reader is unplugged, otherwise NO.
        viewController->_reader.mute = !AJDIsReaderPlugged();

        NSLog(viewController->_reader.mute ? @"MUTE" : @"NOT MUTE");
}

static BOOL AJDIsReaderPlugged() {

        BOOL plugged = NO;
        CFStringRef route = NULL;
        UInt32 routeSize = sizeof(route);

        if (AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &routeSize, &route) == kAudioSessionNoError) {
                if (CFStringCompare(route, CFSTR("HeadsetInOut"), kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
                        plugged = YES;
                }
        }

        return plugged;
}

@end
