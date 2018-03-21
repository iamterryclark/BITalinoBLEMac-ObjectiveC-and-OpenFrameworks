//
//  CBMicroBitBridge.mm
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

/*
 Full Bitalino Data Sheets at
 - http://bitalino.com/datasheets/REVOLUTION_MCU_Block_Datasheet.pdf
 - http://bitalino.com/datasheets/REVOLUTION_BLE_Block_Datasheet.pdf
 
 References Used:
 - Some code copied from Bitalino.cpp api https://github.com/BITalinoWorld/cpp-api/blob/master/bitalino.cpp
 - BBCMicroBit BLE Bridge created by Louis McCallum https://github.com/Louismac/CBMicroBit
 - Reference also to https://www.cloudcity.io/blog/2015/10/15/developing-ios-app-using-ble-standard/
 */


#import "BLEDevice.h"


#define BLE_DEVICE_NAME @"BITalino BLE"

#define DeviceInfo_UUID @"180A"
#define PrimaryService_UUID @"C566488A-0882-4E1B-A6D0-0B717E652234"
#define Command_UUID @"4051eb11-bf0a-4c74-8730-a48f4193fcea"
#define Frame_UUID @"40fdba6b-672e-47c4-808a-e529adff3633"

int counter;

@implementation BLEDevice

/******************************
 Private Bitalino Functions taken from API
 ******************************/

// Sleep method
void Sleep(int millisecs)
{
    usleep(millisecs*1000);
}

// CRC4 check function

const unsigned char CRC4tab[16] = {0, 3, 6, 5, 12, 15, 10, 9, 11, 8, 13, 14, 7, 4, 1, 2};

bool checkCRC4(const unsigned char *data, int len)
{
    unsigned char crc = 0;
    
    for (int i = 0; i < len-1; i++)
    {
        const unsigned char b = data[i];
        crc = CRC4tab[crc] ^ (b >> 4);
        crc = CRC4tab[crc] ^ (b & 0x0F);
    }
    
    // CRC for last byte
    crc = CRC4tab[crc] ^ (data[len-1] >> 4);
    
    crc = CRC4tab[crc];
    return ( crc == (data[len-1] & 0x0F));
}

/******************************
End of Privat Bitalino Functions
 ******************************/

- (void) cleanUp
{
    [self.manager stopScan];
    
    if(self.peripheral)
    {
        [self.manager cancelPeripheralConnection:self.peripheral];
        self.peripheral = nil;
    }
    
    self.manager.delegate = nil;
    self.manager = nil;
}

/*****************************************************************************/

-(void)viewDidLoad{
    self.connecting = NO;
    self.connected = NO;
    isConnected = false;
    self.foundBLEDevice = NO;
    self.poweredOn = NO;
    self.manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

- (void) startScan
{
    [self.manager scanForPeripheralsWithServices:nil options:nil];
    std::cout << "scanning for peripherals" << std::endl;
  
}

/*****************************************************************************/


- (void) stopScan
{
    [self.manager stopScan];
}

/*****************************************************************************/


#pragma --mark CBCentralManagerDelegate

- (void) centralManagerDidUpdateState:(CBCentralManager *)central
{
    [self isLECapableHardware];
    std::cout << "Did update state" << std::endl;
}

/*****************************************************************************/

- (void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)aPeripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    if([aPeripheral name])
    {
        BOOL isBLEDevice = [[aPeripheral name] rangeOfString:BLE_DEVICE_NAME].location != NSNotFound;
        
        if(isBLEDevice && !self.connecting && !self.connected)
        {
            self.connecting = YES;
            const char * name = [[aPeripheral name] UTF8String];
            std::cout << "didDiscoverPeripheral, connecting "<< name << std::endl;
            self.foundBLEDevice = YES;
            if(self.onFindingBLEDevice)
            {
                self.onFindingBLEDevice();
            }
            self.peripheral = aPeripheral;
            [self.manager connectPeripheral:self.peripheral options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
        }
        
    }
}

/*****************************************************************************/

- (NSArray *) peripherals
{
    return _peripherals;
}

/*****************************************************************************/

- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals
{
    NSLog(@"Retrieved peripheral: %lu - %@", [peripherals count], peripherals);
    NSMutableArray *p = [NSMutableArray new];
    self.peripherals = [NSArray arrayWithArray:p];
}

/*****************************************************************************/

- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)aPeripheral
{
    self.connecting = NO;
    self.connected = YES;
    isConnected = true;
    if(self.onConnection)
    {
        self.onConnection();
    }
    std::cout << "didConnectPeripheral" << std::endl;
    [aPeripheral setDelegate:self];
    [aPeripheral discoverServices:nil];
}

/*****************************************************************************/

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)aPeripheral error:(NSError *)error
{
    std::cout << "didDisconnectPeripheral" << std::endl;
    self.connected = NO;
    if(self.peripheral )
    {
        [aPeripheral setDelegate:nil];
        aPeripheral = nil;
    }
}

/*****************************************************************************/

#pragma --mark CBCBPeripheralDelegate

- (void) peripheral:(CBPeripheral *)aPeripheral didDiscoverServices:(NSError *)error
{
    for (CBService *aService in aPeripheral.services)
    {
        // 1
        if ([aService.UUID isEqual:[CBUUID UUIDWithString:PrimaryService_UUID]]) {
            // 2
            [aPeripheral discoverCharacteristics:@[[CBUUID UUIDWithString:Command_UUID], [CBUUID UUIDWithString:Frame_UUID]] forService:aService];
        }
        
    }
}

/*****************************************************************************/

- (void)peripheral:(CBPeripheral *)aPeripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if ([service.UUID isEqual:[CBUUID UUIDWithString:PrimaryService_UUID]]){
        for (CBCharacteristic *aChar in service.characteristics){
            std::cout << "Found Characteristics : " << [[aChar.UUID UUIDString] UTF8String] << std::endl;
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:Command_UUID]]){
                Sleep(150);
                
                //Bitalino Startup Settings
                int modeSwitch = 2;
                int sampleRate = 1000;
                int numChans = 6; //Number of analog channels
                
                char mode;
                char sampleMode;
                char numChannels;
                
                //Live Mode
                switch(modeSwitch){
                    case 0:
                        mode = 0x00; //Idle Mode
                        std::cout << "Idle Mode" << std::endl;
                        break;
                    case 1:
                        mode = 0xF1; //Live Mode
                        std::cout << "Live Mode" << std::endl;
                        break;
                    case 2:
                        mode = 0x02; //Simulated  Mode
                        std::cout << "Simulated Mode" << std::endl;
                        break;
                    case 3:
                        mode = 0xFD; // Live Mode for all 6 channels
                        std::cout << "Live Mode, All 6 Channels" << std::endl;
                        break;
                    case 4:
                        mode = 0x07; // Version Command
                        std::cout << "Return Version" << std::endl;
                        break;
                }
                
                //Taken from the Bitalino API for setting sample rate
                switch (sampleRate)
                {
                    case 1:
                        sampleMode = 0x03;
                        break;
                    case 10:
                        sampleMode = 0x43;
                        break;
                    case 100:
                        sampleMode = 0x83;
                        break;
                    case 1000:
                        sampleMode = 0xC3;
                        break;
                    default:
                        sampleMode = 0x43;
                        break;
                }
                
                switch(numChans){
                    case 6:
                        numChannels = 0x3F; //6 Channels
                        break;
                }
                
                //BITalino Setup
                if (modeSwitch != 4) {
                    
                    //Load bitalino setup parameters
                    NSData *loadMode = [NSData dataWithBytes:&mode length:sizeof(uint8_t)];
                    NSData *setSampleRate = [NSData dataWithBytes:&sampleMode length:sizeof(uint8_t)];
                    
                    // Write to the peripheral
                    [aPeripheral writeValue:loadMode forCharacteristic:aChar type:CBCharacteristicWriteWithResponse];
                    [aPeripheral writeValue:setSampleRate forCharacteristic:aChar type:CBCharacteristicWriteWithResponse];
                } else {
                    //Get Version string from Bitalino
                    NSData *sendVersion = [NSData dataWithBytes:&mode length:sizeof(uint8_t)];
                    [aPeripheral writeValue:sendVersion forCharacteristic:aChar type:CBCharacteristicWriteWithResponse];
                }
            }
            
            //Set notify as on to read the data
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:Frame_UUID]]){
                [aPeripheral setNotifyValue:YES forCharacteristic:aChar];
            }
        }
    }
}

/*****************************************************************************/

- (void) peripheral:(CBPeripheral *)aPeripheral didUpdateValueForCharacteristic:(CBCharacteristic *)aChar error:(NSError *)error
{
    
    if (error) {
        std::cout << "Error changing notification state: " << error.localizedDescription << std::endl;
    } else {
        // 1
        // Extract the data from the Characteristic's value property
        // and display the value based on the Characteristic type
        NSData *dataBytes = aChar.value;
        
        if ([aChar.UUID isEqual:[CBUUID UUIDWithString:Frame_UUID]]) {
            
            VFrame frames(1); // initialize the frames vector with 100 frames
            //2
            [self getEMGData:dataBytes:frames];
            _results = [NSMutableData alloc];
            
           
            
        }
    }
}

- (void) peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if(!error)
    {
        NSLog(@"notify updated for characteristic %@",[characteristic.UUID UUIDString]);
    }
    else{
        NSLog(@"ERROR updating notify for characteristic %@ : %@",characteristic.UUID, error.localizedDescription);
    }
}

/*****************************************************************************/

- (BOOL) isLECapableHardware
{
    NSString * state = nil;
    
    switch ([self.manager state])
    {
        case CBCentralManagerStateUnsupported:
            std::cout << "The platform/hardware doesn't support Bluetooth Low Energy" << std::endl;
            state = @"The platform/hardware doesn't support Bluetooth Low Energy.";
            break;
        case CBCentralManagerStateUnauthorized:
            std::cout << "The app is not authorized to use Bluetooth Low Energy." << std::endl;
            state = @"The app is not authorized to use Bluetooth Low Energy.";
            break;
        case CBCentralManagerStatePoweredOff:
            std::cout << "Bluetooth is currently powered off." << std::endl;
            state = @"Bluetooth is currently powered off.";
            break;
        case CBCentralManagerStatePoweredOn:
            std::cout << "CBCentralManagerStatePoweredOn" << std::endl;
            self.poweredOn = YES;
            if(self.onPoweringOn)
            {
                self.onPoweringOn();
            }
            [self startScan];
            return TRUE;
        case CBCentralManagerStateUnknown:
            std::cout << "CBCentralManagerStateUnknown" << std::endl;
        default:
            return FALSE;
    }
    return NO;
}

/*****************************************************************************/

- (int)getEMGData:(NSData *)dataBytes : (VFrame)frames {
    
    //To get the Bitalino data we must firstly collect two BLE data packets which amount to 40 in length
    //From this 40 we will split the data into 5 individual 8 byte Bitalino packets.
    char nChannels = 6;
    char nBytes = nChannels + 2;
    
    NSUInteger dataLength = 40; //40 Bytes = 2 BLE packets = 5 Bitalino Packets (8 bytes each)
    uint8_t dataArray[dataLength];
    
    Frame frame;
    
    if (counter % 2 == 0){
        
        [_results appendData:dataBytes];
        [_results getBytes:&dataArray length:40];
        
        for(int i = 0; i < 5; i++){
            
            unsigned char buffer[8] = { dataArray[0 + (8*i)],
                dataArray[1 + (8*i)],
                dataArray[2 + (8*i)],
                dataArray[3 + (8*i)],
                dataArray[4 + (8*i)],
                dataArray[5 + (8*i)],
                dataArray[6 + (8*i)],
                dataArray[7 + (8*i)]
            };
            
            
            for(VFrame::iterator it = frames.begin(); it != frames.end(); it++)
            {
                if (sizeof(buffer) != nBytes)   return int(it - frames.begin());   // a timeout has occurred
                
                while (!checkCRC4(buffer, nBytes))
                {  // if CRC check failed, try to resynchronize with the next valid frame
                    // checking with one new byte at a time
                    //std::cout << "CRCfailed" << std::endl;
                    memmove(buffer, buffer+1, nBytes-1);
                    //std::cout << "Ouch" << std::endl;
                    if (sizeof(buffer+nBytes-1) != 1)   return int(it - frames.begin());   // a timeout has occurred
                }

                frame = *it;
            }
            
            frame.seq = buffer[nBytes-1] >> 4;
            
            //            frame.analog[0] = (short(buffer[nBytes-2] & 0x0F) << 6) | (buffer[nBytes-3] >> 2);
            //            if (nChannels > 1)
            //                frame.analog[1] = (short(buffer[nBytes-3] & 0x03) << 8) | buffer[nBytes-4];
            //            if (nChannels > 2)
            //                frame.analog[2] = (short(buffer[nBytes-5]) << 2) | (buffer[nBytes-6] >> 6);
            //            if (nChannels > 3)
            //                frame.analog[3] = (short(buffer[nBytes-6] & 0x3F) << 4) | (buffer[nBytes-7] >> 4);
            //            if (nChannels > 4)
            //                frame.analog[4] = ((buffer[nBytes-7] & 0x0F) << 2) | (buffer[nBytes-8] >> 6);
            //            if (nChannels > 5)
            //                frame.analog[5] = buffer[nBytes-8] & 0x3F;
            
            frame.analog[0] = ((buffer[6] & 0x0F) << 6) | (buffer[5] >> 2);
            frame.analog[1] = ((buffer[5] & 0x03) << 8) | (buffer[4]);
            frame.analog[2] = ((buffer[3]       ) << 2) | (buffer[2] >> 6);
            frame.analog[3] = ((buffer[2] & 0x3F) << 4) | (buffer[1] >> 4);
            frame.analog[4] = ((buffer[1] & 0x0F) << 2) | (buffer[0] >> 6);
            frame.analog[5] = ((buffer[0] & 0x3F));
            
            outputFrame.seq = frame.seq;
            
            for (int i = 0; i < 6; i++) outputFrame.analog[i] = frame.analog[i];
           
            

//         printf("%d : %d %d %d %d %d %d\n",   // dump the first frame
//                   frame.seq,
//                   frame.analog[0], frame.analog[1], frame.analog[2], frame.analog[3], frame.analog[4], frame.analog[5]);
//            
//           s printf("%d\n", frame.analog[1]);
            
        }
    
        _prevData = dataBytes;
        [_results appendData:_prevData];
    }
    

    [_results setLength:0];
    counter++;
    
    return int(frames.size());
}
@end
