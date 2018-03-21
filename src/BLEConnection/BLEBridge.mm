//
//  BLEBridge.m
//  objCTest
//
//  Created by Terry Clark on 11/02/2018.
//

#include "BLEBridge.h"

struct BLEImpl
{
    BLEDevice *bleDevice;
};

BLEBridge::BLEBridge() :
impl(new BLEImpl)
{
    std::cout << "SCANNING!!" << std::endl;
    impl->bleDevice = [[BLEDevice alloc] init];
    [impl->bleDevice viewDidLoad];
}

BLEBridge::~BLEBridge()
{
    if (impl->bleDevice)
       [impl->bleDevice cleanUp];

    delete impl;
    std::cout << "destructor called" << std::endl;
}

void BLEBridge::update(){
    
    seq = impl->bleDevice->outputFrame.seq;
    
    for(int i = 0; i < 6; i++)
        rawAnalog[i] = impl->bleDevice->outputFrame.analog[i];
    
//    smoothedSignal = rms(rawAnalog[2]);
   
    for (int i = 0; i < 3; i++){
        emg[i] = rawAnalog[i];
//        acc[i] = rawAnalog[i+3];
        
//        if (i+3 >= 5){
//            acc[i] = ofMap(acc[i], 0, 64, 0, 1023);
//        }
      
//        emg[i] = filter.lopass(emg[i], 0.125);
//        acc[i] = filter.lopass(acc[i], 0.125);
    }
    
    if ( (impl->bleDevice->isConnected) ){
        cout << "EMG " << seq << " : " << emg[2] << endl;
        captureBLE = true;
    }
}

void BLEBridge::draw(){
    ofSetColor(255, 0, 0);
    ofDrawRectangle(ofGetHeight(),0, 100, emg[2]);
}

short BLEBridge::rms(short _value){
    
}




