#import "Mtrackingio.h"

@implementation Mtrackingio {
  BOOL _hasInitialized;
  BOOL _hasActiveListeners;
  NSDictionary *_cachedInstallParams;
  NSDictionary *_cachedStartupParams;
  NSDictionary *_cachedInitialDeepLink;
}

RCT_EXPORT_MODULE()

- (NSArray<NSString *> *)supportedEvents
{
  return @[@"mtrackingio:deepLink"];
}

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

- (void)startObserving
{
  _hasActiveListeners = YES;
}

- (void)stopObserving
{
  _hasActiveListeners = NO;
}

- (NSDictionary *)sanitizeTrackingParams:(NSDictionary *)params
{
  if (params == nil) {
    return @{};
  }

  NSMutableDictionary *result = [NSMutableDictionary dictionary];
  [params enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
    if (![key isKindOfClass:[NSString class]]) {
      return;
    }

    if ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]]) {
      result[key] = value;
    }
  }];
  return result;
}

- (NSString *)extractDeepLinkURLFromParams:(NSDictionary *)params
{
  for (NSString *key in @[@"url", @"deeplink", @"deepLink"]) {
    id value = params[key];
    if ([value isKindOfClass:[NSString class]] && [value length] > 0) {
      return value;
    }
  }
  return @"";
}

- (NSDictionary *)buildDeepLinkPayloadFromDeferredParams:(NSDictionary *)params
{
  NSDictionary *sanitizedParams = [self sanitizeTrackingParams:params];
  return @{
    @"url": [self extractDeepLinkURLFromParams:params],
    @"params": sanitizedParams,
  };
}

- (void)emitDeepLinkEventIfPossible:(NSDictionary *)payload
{
  if (_hasActiveListeners) {
    [self sendEventWithName:@"mtrackingio:deepLink" body:payload];
  }
}

- (void)onDeferredDeeplinkCalllback:(NSDictionary *)params
{
  NSDictionary *payload = [self buildDeepLinkPayloadFromDeferredParams:params];
  if (_cachedInitialDeepLink == nil) {
    _cachedInitialDeepLink = payload;
  }
  [self emitDeepLinkEventIfPossible:payload];
}

RCT_REMAP_METHOD(preInit,
                 preInitWithAppKey:(NSString *)appKey
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
  @try {
    [Tracking preInit:appKey];
    resolve(nil);
  } @catch (NSException *exception) {
    reject(@"ERR_PREINIT_FAILED", exception.reason, nil);
  }
}

RCT_REMAP_METHOD(initialize,
                 initializeWithOptions:(NSDictionary *)options
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
  @try {
    NSString *appKey = options[@"appKey"];
    if (appKey.length == 0) {
      reject(@"ERR_INITIALIZE_FAILED", @"appKey is required", nil);
      return;
    }

    NSString *channelId = options[@"channelId"] ?: @"_default_";
    NSString *caid = options[@"caid"];
    NSString *caid2 = options[@"caid2"];
    NSDictionary *installParams = [self sanitizeTrackingParams:options[@"installParams"]];
    NSDictionary *startupParams = [self sanitizeTrackingParams:options[@"startupParams"]];

    _cachedInstallParams = installParams;
    _cachedStartupParams = startupParams;

    [Tracking setDeferredDeeplinkCalllbackDelegate:self];
    [Tracking initWithAppKey:appKey
               withChannelId:channelId
                    withCAID:caid.length > 0 ? caid : nil
                   withCAID2:caid2.length > 0 ? caid2 : nil
           withInstallParams:installParams.count > 0 ? installParams : nil
           withStartupParams:startupParams.count > 0 ? startupParams : nil];
    _hasInitialized = YES;
    resolve(nil);
  } @catch (NSException *exception) {
    reject(@"ERR_INITIALIZE_FAILED", exception.reason, nil);
  }
}

RCT_REMAP_METHOD(setDebugLogging,
                 setDebugLoggingEnabled:(BOOL)enabled
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
  @try {
    [Tracking setPrintLog:enabled];
    resolve(nil);
  } @catch (NSException *exception) {
    reject(@"ERR_SET_DEBUG_LOGGING_FAILED", exception.reason, nil);
  }
}

RCT_REMAP_METHOD(setASAEnabled,
                 setASAEnabledValue:(BOOL)enabled
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
  @try {
    [Tracking setASAEnable:enabled];
    resolve(nil);
  } @catch (NSException *exception) {
    reject(@"ERR_SET_ASA_ENABLED_FAILED", exception.reason, nil);
  }
}

RCT_REMAP_METHOD(register,
                 registerWithOptions:(NSDictionary *)options
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
  if (!_hasInitialized) {
    reject(@"ERR_NOT_INITIALIZED", @"initialize must be called before register", nil);
    return;
  }

  @try {
    NSString *accountId = options[@"accountId"];
    if (accountId.length == 0) {
      reject(@"ERR_REGISTER_FAILED", @"accountId is required", nil);
      return;
    }

    NSDictionary *params = [self sanitizeTrackingParams:options[@"params"]];
    [Tracking setRegisterWithAccountID:accountId withParams:params.count > 0 ? params : nil];
    resolve(nil);
  } @catch (NSException *exception) {
    reject(@"ERR_REGISTER_FAILED", exception.reason, nil);
  }
}

RCT_REMAP_METHOD(login,
                 loginWithOptions:(NSDictionary *)options
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
  if (!_hasInitialized) {
    reject(@"ERR_NOT_INITIALIZED", @"initialize must be called before login", nil);
    return;
  }

  @try {
    NSString *accountId = options[@"accountId"];
    if (accountId.length == 0) {
      reject(@"ERR_LOGIN_FAILED", @"accountId is required", nil);
      return;
    }

    NSDictionary *params = [self sanitizeTrackingParams:options[@"params"]];
    [Tracking setLoginWithAccountID:accountId withParams:params.count > 0 ? params : nil];
    resolve(nil);
  } @catch (NSException *exception) {
    reject(@"ERR_LOGIN_FAILED", exception.reason, nil);
  }
}

RCT_REMAP_METHOD(setAttributionParameter,
                 setAttributionParameterWithValue:(NSString *)gdtClickId
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
  reject(@"ERR_UNSUPPORTED", @"setAttributionParameter 当前仅支持 Android", nil);
}

RCT_REMAP_METHOD(getInstallParams,
                 getInstallParamsWithResolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
  resolve(_cachedInstallParams ?: @{});
}

RCT_REMAP_METHOD(getStartupParams,
                 getStartupParamsWithResolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
  resolve(_cachedStartupParams ?: @{});
}

RCT_REMAP_METHOD(getInitialDeepLink,
                 getInitialDeepLinkWithResolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
  resolve(_cachedInitialDeepLink);
}

@end
