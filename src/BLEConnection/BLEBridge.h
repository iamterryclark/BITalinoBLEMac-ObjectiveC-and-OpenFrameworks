//
//  BLEBridge.h
//  objCTest
//
//  Created by Terry Clark on 11/02/2018.
//

#include "ofMain.h"
#include "BLEDevice.h"
#import <Foundation/Foundation.h>
#include "ofxMaxim.h"

using namespace std;

struct BLEImpl;

class BLEBridge
{
public:
    BLEBridge();
    ~BLEBridge();
    
   
    void update();
    void draw();
    
    short rms(short _value);
    
    BLEImpl* impl;
  
    short seq;
    short rawAnalog[6];
    short emg[3];
    short acc[3];
    
   // int bufferSize = 30;
    ofxMaxiFilter filter;
    bool   captureBLE;
   
private:
    
};
