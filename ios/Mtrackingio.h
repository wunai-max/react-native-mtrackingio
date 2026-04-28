#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import <TrackingIOSDK/Tracking.h>

@interface Mtrackingio : RCTEventEmitter <RCTBridgeModule, DeferredDeeplinkCalllback>

@end
