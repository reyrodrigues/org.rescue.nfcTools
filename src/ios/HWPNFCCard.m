#import   "HWPNFCCard.h"
#import "AJDHex.h"

#import <CommonCrypto/CommonCrypto.h>

@implementation HWPNFCCard {
        NSCondition *_responseCondition;
        NSCondition *_picWaitResponseCondition;
        NSCondition * _picWaitAuthenticateResponseCondition;
        NSCondition * _picWaitReadResponseCondition;
        NSCondition * _picWaitWriteResponseCondition;

        NSData* _masterKey;
        NSData* _masterKey2;
        NSData* _aesKey;
        NSData* _iksn;
        NSData* _ipek;
        NSString* _piccTimeoutString;
        NSString* _piccCardTypeString;
        NSString* _piccCommandApduString;
        NSString* _piccRfConfigString;
        NSUInteger _piccTimeout;
        NSUInteger _piccCardType;
        NSData *_piccCommandApdu;
        NSData *_piccRfConfig;



        NSOperationQueue * picQueue;
        NSBlockOperation * picRead;
        NSBlockOperation * picResponse;
        NSBlockOperation * picAuthenticate;
        NSBlockOperation * picWrite;

        NSMutableData * tagData;
        BOOL tagDataFlag;
}
@synthesize className;

ACRAudioJackReader *_reader;
ACRDukptReceiver *_dukptReceiver;

- (void) init:(CDVInvokedUrlCommand*)command {
        self.className = [command className];
        NSString* configurationString = [[command arguments] objectAtIndex:0];
        NSError* err;
        NSDictionary * config = (NSDictionary *)[NSJSONSerialization
                                                 JSONObjectWithData:[configurationString
                                                                     dataUsingEncoding:NSUTF8StringEncoding]
                                                 options:NSJSONReadingMutableContainers
                                                 error: &err
                                ];



        _responseCondition = [[NSCondition alloc] init];

        _picWaitResponseCondition = [[NSCondition alloc] init];
        _picWaitAuthenticateResponseCondition = [[NSCondition alloc] init];
        _picWaitReadResponseCondition = [[NSCondition alloc] init];
        _picWaitWriteResponseCondition = [[NSCondition alloc] init];


        picQueue = [[NSOperationQueue alloc]init];
        tagData = [[NSMutableData alloc]initWithCapacity:32];
        tagDataFlag = NO; // this flag will be set when the tagData is updated, it is up to the user to clear it after accessing.

        [self.commandDelegate runInBackground :^{
                 _reader = [[ACRAudioJackReader alloc] init];
                 [_reader setDelegate:self];

                 _masterKey = [config valueForKey:@"MasterKey"];
                 if (_masterKey == nil) {
                         _masterKey = [self toByteArray:@"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00"];
                 }

                 _masterKey2 = [config valueForKey:@"MasterKey2"];
                 if (_masterKey2 == nil) {
                         _masterKey2 = [self toByteArray:@"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00"];
                 }

                 _aesKey = [config valueForKey:@"AesKey"];
                 if (_aesKey == nil) {
                         _aesKey = [self toByteArray:@"4E 61 74 68 61 6E 2E 4C 69 20 54 65 64 64 79 20"];
                 }

                 _iksn = [config valueForKey:@"IKSN"];
                 if (_iksn == nil) {
                         _iksn = [self toByteArray:@"FF FF 98 76 54 32 10 E0 00 00"];
                 }

                 _ipek = [config valueForKey:@"IPEK"];
                 if (_ipek == nil) {
                         _ipek = [self toByteArray:@"6A C2 92 FA A1 31 5B 4D 85 8A B3 A3 D7 D5 93 3A"];
                 }

                 _piccTimeoutString = [config valueForKey:@"PiccTimeout"];
                 _piccCardTypeString = [config valueForKey:@"PiccCardType"];
                 _piccCommandApduString = [config valueForKey:@"PiccCommandApdu"];
                 _piccRfConfigString = [config valueForKey:@"PiccRfConfig"];

                 if (_piccTimeoutString == nil) {
                         _piccTimeoutString = @"1";
                 }

                 if (_piccCardTypeString == nil) {
                         _piccCardTypeString = @"8F";
                 }

                 if (_piccCommandApduString == nil) {
                         _piccCommandApduString = @"00 84 00 00 08";
                 }

                 if (_piccRfConfigString == nil) {
                         _piccRfConfigString = @"07 85 85 85 85 85 85 85 85 69 69 69 69 69 69 69 69 3F 3F";
                 }


                 _piccTimeout = [_piccTimeoutString integerValue];
                 uint8_t cardType[] = { 0 };
                 [self toByteArray:_piccCardTypeString buffer:cardType bufferSize:sizeof(cardType)];
                 _piccCardType = cardType[0];
                 _piccCommandApdu = [self toByteArray:_piccCommandApduString];
                 _piccRfConfig = [self toByteArray:_piccRfConfigString];

                 // Initialize the DUKPT receiver object.
                 _dukptReceiver = [[ACRDukptReceiver alloc] init];

                 // Set the key serial number.
                 [_dukptReceiver setKeySerialNumber:_iksn];

                 // Load the initial key.
                 [_dukptReceiver loadInitialKey:_ipek];


                 CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
                 [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];

                 [self getNfcData];
         }];
}

- (void) writeData:(CDVInvokedUrlCommand*)command
{

}

- (NSString *)toHexString:(const uint8_t *)buffer length:(size_t)length {

        NSString *hexString = @"";
        size_t i = 0;

        for (i = 0; i < length; i++) {
                if (i == 0) {
                        hexString = [hexString stringByAppendingFormat:@"%02X", buffer[i]];
                } else {
                        hexString = [hexString stringByAppendingFormat:@" %02X", buffer[i]];
                }
        }

        return hexString;
}

- (NSUInteger)toByteArray:(NSString *)hexString buffer:(uint8_t *)buffer bufferSize:(NSUInteger)bufferSize {

        NSUInteger length = 0;
        BOOL first = YES;
        int num = 0;
        unichar c = 0;
        NSUInteger i = 0;

        for (i = 0; i < [hexString length]; i++) {

                c = [hexString characterAtIndex:i];
                if ((c >= '0') && (c <= '9')) {
                        num = c - '0';
                } else if ((c >= 'A') && (c <= 'F')) {
                        num = c - 'A' + 10;
                } else if ((c >= 'a') && (c <= 'f')) {
                        num = c - 'a' + 10;
                } else {
                        num = -1;
                }

                if (num >= 0) {

                        if (first) {

                                buffer[length] = num << 4;

                        } else {

                                buffer[length] |= num;
                                length++;
                        }

                        first = !first;
                }

                if (length >= bufferSize) {
                        break;
                }
        }

        return length;
}

- (NSData *)toByteArray:(NSString *)hexString {

        NSData *byteArray = nil;
        uint8_t *buffer = NULL;
        NSUInteger i = 0;
        unichar c = 0;
        NSUInteger count = 0;
        int num = 0;
        BOOL first = YES;
        NSUInteger length = 0;

        // Count the number of HEX characters.
        for (i = 0; i < [hexString length]; i++) {

                c = [hexString characterAtIndex:i];
                if (((c >= '0') && (c <= '9')) ||
                    ((c >= 'A') && (c <= 'F')) ||
                    ((c >= 'a') && (c <= 'f'))) {
                        count++;
                }
        }

        // Allocate the buffer.
        buffer = (uint8_t *) malloc((count + 1) / 2);

        if (buffer != NULL) {

                for (i = 0; i < [hexString length]; i++) {

                        c = [hexString characterAtIndex:i];
                        if ((c >= '0') && (c <= '9')) {
                                num = c - '0';
                        } else if ((c >= 'A') && (c <= 'F')) {
                                num = c - 'A' + 10;
                        } else if ((c >= 'a') && (c <= 'f')) {
                                num = c - 'a' + 10;
                        } else {
                                num = -1;
                        }

                        if (num >= 0) {

                                if (first) {

                                        buffer[length] = num << 4;

                                } else {

                                        buffer[length] |= num;
                                        length++;
                                }

                                first = !first;
                        }
                }

                // Create the byte array.
                byteArray = [[NSData alloc] initWithBytes:buffer length:length];

                // Free the buffer.
                free(buffer);
                buffer = NULL;
        }

        return byteArray;
}


- (BOOL)getNfcData //:(NSData *) data
{
        BOOL result = YES;

        picAuthenticate = [NSBlockOperation blockOperationWithBlock: ^{
                                   NSData * commandApdu = [AJDHex byteArrayFromHexString:@"FF 86 00 00 05 01 00 04 60 00"]; // authenticate block
                                   [_picWaitAuthenticateResponseCondition lock];
                                   [_picWaitAuthenticateResponseCondition wait];

                                   if (![_reader piccTransmitWithTimeout:9.0 commandApdu:[commandApdu bytes] length:[commandApdu length]]) {
                                   } else
                                   {
                                           [self powerOn];
                                   }
                                   NSLog(@"::commandApdu = %@",commandApdu);
                                   [_picWaitAuthenticateResponseCondition unlock];
                           }];

        //picQueue
        picRead = [NSBlockOperation blockOperationWithBlock: ^{
                           NSData * commandApdu = [AJDHex byteArrayFromHexString:@"FF B0 00 04 20"];
                           BOOL predicate = NO;
                           [_picWaitReadResponseCondition lock];
                           [_picWaitReadResponseCondition wait];
                           if (![_reader piccTransmitWithTimeout:9.0 commandApdu:[commandApdu bytes] length:[commandApdu length]]) {
                           } else
                           {
                                   [self powerOn];
                           }
                           [_picWaitReadResponseCondition unlock];
                           NSLog(@"::commandApdu = %@",commandApdu);
                   }];

        [picQueue cancelAllOperations];
        [picQueue addOperation:picAuthenticate];
        [picQueue addOperation:picRead];

        return YES;
}



- (void)powerOn {
        if (![_reader piccPowerOnWithTimeout:_piccTimeout cardType:_piccCardType]) {
        } else {
        }

}

- (void)reader:(ACRAudioJackReader *)reader didSendRawData:(const uint8_t *)rawData length:(NSUInteger)length {
        NSString *hexString = [self toHexString:rawData length:length];

        hexString = [hexString stringByAppendingString:[_reader verifyData:rawData length:length] ? @" (Checksum OK)" : @" (Checksum Error)"];

        //  State machine to read tag data.
//    accessState = BlockAuthenticationCommand;
//    accessState = BlockReadCommand;
//    accessState = BlockWriteCommand;
//    accessState = BlockReadWriteData
        if((rawData[4] == 0x3B && rawData[5] == 0x8F) || (rawData[4] == 0x00 && rawData[5] == 0xE4)) //periodic atq or status
        {
                // trigger block authentication
                NSLog(@"_picWaitAuthenticateResponseCondition signal");
                [_picWaitAuthenticateResponseCondition signal];
        }
        else if((rawData[4] == 0x90 && rawData[5] == 0x00) || (rawData[4] == 0x63 && rawData[5] == 0x00)) // Authentication ok, send read command
        {
                // trigger block read/write
                NSLog(@"_picWaitReadResponseCondition signal");
                [_picWaitReadResponseCondition signal];
                [_picWaitWriteResponseCondition signal];
        }
        else if((rawData[length - 4] == 0x90 && rawData[length - 3] == 0x00) && (rawData[2] == 0x25)) // Appears to be read data.
        {
                // capture data
                NSRange range = {.location = 0, .length = 32};
                [tagData replaceBytesInRange:range withBytes:rawData];
                NSLog(@"capture data %@", tagData);
                tagDataFlag = YES;
        }
}

- (void)reader:(ACRAudioJackReader *)reader didSendTrackData:(ACRTrackData *)trackData {
        ACRTrack1Data *track1Data = [[ACRTrack1Data alloc] init];
        ACRTrack2Data *track2Data = [[ACRTrack2Data alloc] init];
        ACRTrack1Data *track1MaskedData = [[ACRTrack1Data alloc] init];
        ACRTrack2Data *track2MaskedData = [[ACRTrack2Data alloc] init];
        NSString *track1MacString = @"";
        NSString *track2MacString = @"";

        NSString *keySerialNumberString = @"";
        NSString *errorString = @"";

        // Dismiss the track data alert.
        dispatch_async(dispatch_get_main_queue(), ^{
                       });

        if ((trackData.track1ErrorCode != ACRTrackErrorSuccess) &&
            (trackData.track2ErrorCode != ACRTrackErrorSuccess)) {
                errorString = @"The track 1 and track 2 data";
        } else {
                if (trackData.track1ErrorCode != ACRTrackErrorSuccess) {
                        errorString = @"The track 1 data";
                }
                if (trackData.track2ErrorCode != ACRTrackErrorSuccess) {
                        errorString = @"The track 2 data";
                }
        }

        errorString = [errorString stringByAppendingString:@" may be corrupted. Please swipe the card again!"];

        // Show the track error.
        if ((trackData.track1ErrorCode != ACRTrackErrorSuccess) ||
            (trackData.track2ErrorCode != ACRTrackErrorSuccess)) {
                dispatch_async(dispatch_get_main_queue(), ^{
                               });
        }

        if ([trackData isKindOfClass:[ACRAesTrackData class]]) {
                ACRAesTrackData *aesTrackData = (ACRAesTrackData *) trackData;
                uint8_t *buffer = (uint8_t *) [aesTrackData.trackData bytes];
                NSUInteger bufferLength = [aesTrackData.trackData length];
                uint8_t decryptedTrackData[128];
                size_t decryptedTrackDataLength = 0;

                // Decrypt the track data.
                if (![self decryptData:buffer dataInLength:bufferLength key:[_aesKey bytes] keyLength:[_aesKey length] dataOut:decryptedTrackData dataOutLength:sizeof(decryptedTrackData) pBytesReturned:&decryptedTrackDataLength]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                                       });

                        goto cleanup;
                }

                // Verify the track data.
                if (![_reader verifyData:decryptedTrackData length:decryptedTrackDataLength]) {

                        dispatch_async(dispatch_get_main_queue(), ^{
                                       });

                        goto cleanup;
                }

                // Decode the track data.
                track1Data = [track1Data initWithBytes:decryptedTrackData length:trackData.track1Length];
                track2Data = [track2Data initWithBytes:decryptedTrackData + 79 length:trackData.track2Length];

        } else if ([trackData isKindOfClass:[ACRDukptTrackData class]]) {

                ACRDukptTrackData *dukptTrackData = (ACRDukptTrackData *) trackData;
                NSUInteger ec = 0;
                NSUInteger ec2 = 0;
                NSData *key = nil;
                NSData *dek = nil;
                NSData *macKey = nil;
                uint8_t dek3des[24];

                keySerialNumberString = [AJDHex hexStringFromByteArray:dukptTrackData.keySerialNumber];
                track1MacString = [AJDHex hexStringFromByteArray:dukptTrackData.track1Mac];
                track2MacString = [AJDHex hexStringFromByteArray:dukptTrackData.track2Mac];
                track1MaskedData = [track1MaskedData initWithString:dukptTrackData.track1MaskedData];
                track2MaskedData = [track2MaskedData initWithString:dukptTrackData.track2MaskedData];

                // Compare the key serial number.
                if (![ACRDukptReceiver compareKeySerialNumber:_iksn ksn2:dukptTrackData.keySerialNumber]) {

                        dispatch_async(dispatch_get_main_queue(), ^{
                                       });

                        goto cleanup;
                }

                // Get the encryption counter from KSN.
                ec = [ACRDukptReceiver encryptionCounterFromKeySerialNumber:dukptTrackData.keySerialNumber];

                // Get the encryption counter from DUKPT receiver.
                ec2 = [_dukptReceiver encryptionCounter];

                // Load the initial key if the encryption counter from KSN is less than
                // the encryption counter from DUKPT receiver.
                if (ec < ec2) {

                        [_dukptReceiver loadInitialKey:_ipek];
                        ec2 = [_dukptReceiver encryptionCounter];
                }

                // Synchronize the key if the encryption counter from KSN is greater
                // than the encryption counter from DUKPT receiver.
                while (ec > ec2) {

                        [_dukptReceiver key];
                        ec2 = [_dukptReceiver encryptionCounter];
                }

                if (ec != ec2) {

                        dispatch_async(dispatch_get_main_queue(), ^{
                                       });

                        goto cleanup;
                }

                key = [_dukptReceiver key];
                if (key == nil) {

                        dispatch_async(dispatch_get_main_queue(), ^{
                                       });

                        goto cleanup;
                }

                dek = [ACRDukptReceiver dataEncryptionRequestKeyFromKey:key];
                macKey = [ACRDukptReceiver macRequestKeyFromKey:key];

                // Generate 3DES key (K1 = K3).
                memcpy(dek3des, [dek bytes], [dek length]);
                memcpy(dek3des + [dek length], [dek bytes], 8);

                if (dukptTrackData.track1Data != nil) {

                        uint8_t track1Buffer[80];
                        size_t bytesReturned = 0;
                        NSString *track1DataString = nil;

                        // Decrypt the track 1 data.
                        if (![self AJD_tripleDesDecryptData:[dukptTrackData.track1Data bytes] dataInLength:[dukptTrackData.track1Data length] key:dek3des keyLength:sizeof(dek3des) dataOut:track1Buffer dataOutLength:sizeof(track1Buffer) bytesReturned:&bytesReturned]) {

                                dispatch_async(dispatch_get_main_queue(), ^{
                                               });

                                goto cleanup;
                        }

                        // Generate the MAC for track 1 data.
                        track1MacString = [track1MacString stringByAppendingFormat:@" (%@)", [AJDHex hexStringFromByteArray:[ACRDukptReceiver macFromData:track1Buffer dataLength:sizeof(track1Buffer) key:[macKey bytes] keyLength:[macKey length]]]];

                        // Get the track 1 data as string.
                        track1DataString = [[NSString alloc] initWithBytes:track1Buffer length:dukptTrackData.track1Length encoding:NSASCIIStringEncoding];

                        // Divide the track 1 data into fields.
                        track1Data = [track1Data initWithString:track1DataString];
                }

                if (dukptTrackData.track2Data != nil) {

                        uint8_t track2Buffer[48];
                        size_t bytesReturned = 0;
                        NSString *track2DataString = nil;

                        // Decrypt the track 2 data.
                        if (![self AJD_tripleDesDecryptData:[dukptTrackData.track2Data bytes] dataInLength:[dukptTrackData.track2Data length] key:dek3des keyLength:sizeof(dek3des) dataOut:track2Buffer dataOutLength:sizeof(track2Buffer) bytesReturned:&bytesReturned]) {

                                dispatch_async(dispatch_get_main_queue(), ^{
                                               });

                                goto cleanup;
                        }

                        // Generate the MAC for track 2 data.
                        track2MacString = [track2MacString stringByAppendingFormat:@" (%@)", [AJDHex hexStringFromByteArray:[ACRDukptReceiver macFromData:track2Buffer dataLength:sizeof(track2Buffer) key:[macKey bytes] keyLength:[macKey length]]]];

                        // Get the track 2 data as string.
                        track2DataString = [[NSString alloc] initWithBytes:track2Buffer length:dukptTrackData.track2Length encoding:NSASCIIStringEncoding];

                        // Divide the track 2 data into fields.
                        track2Data = [track2Data initWithString:track2DataString];
                }
        }

        cleanup :
        // Show the data.
        dispatch_async(dispatch_get_main_queue(), ^{

                       });
}


- (BOOL)decryptData:(const void *)dataIn dataInLength:(size_t)dataInLength key:(const void *)key keyLength:(size_t)keyLength dataOut:(void *)dataOut dataOutLength:(size_t)dataOutLength pBytesReturned:(size_t *)pBytesReturned {

        BOOL ret = NO;

        // Decrypt the data.
        if (CCCrypt(kCCDecrypt, kCCAlgorithmAES128, 0, key, keyLength, NULL, dataIn, dataInLength, dataOut, dataOutLength, pBytesReturned) == kCCSuccess) {
                ret = YES;
        }

        return ret;
}


- (BOOL)AJD_tripleDesDecryptData:(const void *)dataIn dataInLength:(size_t)dataInLength key:(const void *)key keyLength:(size_t)keyLength dataOut:(void *)dataOut dataOutLength:(size_t)dataOutLength bytesReturned:(size_t *)bytesReturnedPtr {

        BOOL ret = NO;

        // Decrypt the data.
        if (CCCrypt(kCCDecrypt, kCCAlgorithm3DES, 0, key, keyLength, NULL, dataIn, dataInLength, dataOut, dataOutLength, bytesReturnedPtr) == kCCSuccess) {
                ret = YES;
        }

        return ret;
}


@end
