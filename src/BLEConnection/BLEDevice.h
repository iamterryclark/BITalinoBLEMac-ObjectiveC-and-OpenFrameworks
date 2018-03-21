//
// CBMicroBitBridge.h
//
// Copyright 2017 Louis McCallum
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the "Software"), to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
// and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial
// portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
// THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
// CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
//



#import <CoreBluetooth/CoreBluetooth.h>
#include <iostream>
#import <malloc/malloc.h>
#include <vector>

/// A frame returned by BITalino::read()
struct Frame
{
    /// %Frame sequence number (0...15).
    /// This number is incremented by 1 on each consecutive frame, and it overflows to 0 after 15 (it is a 4-bit number).
    /// This number can be used to detect if frames were dropped while transmitting data.
    short  seq;
    
    /// Array of analog inputs values (0...1023 on the first 4 channels and 0...63 on the remaining channels)
    short analog[6];
};

typedef std::vector<Frame> VFrame;  ///< Vector of Frame's.
typedef void(^BLEBlock)(void);
typedef void(^BLEIntBlock)(int);
typedef void(^BLEArrayBlock)(NSArray *);

@interface BLEDevice : NSObject
@end

@interface BLEDevice()<CBCentralManagerDelegate, CBPeripheralDelegate>{
@public
    Frame outputFrame;
    bool isConnected;
}

@property (nonatomic, strong) CBCentralManager *manager;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) NSArray *peripherals;

@property (nonatomic, strong) NSData *prevData;
@property (nonatomic, strong) NSMutableData *results;

@property (nonatomic) BLEArrayBlock onData;
@property (nonatomic) BLEBlock onPoweringOn;
@property (nonatomic) BLEBlock onConnection;
@property (nonatomic) BLEBlock onFindingBLEDevice;

@property (nonatomic, assign) BOOL connecting;
@property (nonatomic, assign) BOOL connected;
@property (nonatomic, assign) BOOL poweredOn;
@property (nonatomic, assign) BOOL foundBLEDevice;

- (void) startScan;
- (NSArray *) peripherals;
- (void) cleanUp;

@end

